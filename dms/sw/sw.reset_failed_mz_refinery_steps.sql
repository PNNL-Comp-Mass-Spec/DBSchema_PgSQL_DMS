--
-- Name: reset_failed_mz_refinery_steps(boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.reset_failed_mz_refinery_steps(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Reset Mz_Refinery in-progress job steps if a manager reports "flag file exists" in public.t_log_entries
**
**      This procedure runs on a regular basis to look for cases where the Analysis Manager crashed while running Mz_Refinery (using Java)
**      In addition to a "flag file" message, there must be an in-progress Mz_Refinery job step reporting a Job Progress of 0 %
**
**  Auth:   mem
**          08/23/2023 mem - Initial version
**          08/24/2023 mem - Ported to PostgreSQL
**          10/12/2023 mem - Add missing call to format()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobStep record;
    _baseMsg text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    BEGIN
        -----------------------------------------------------------
        -- Create a temporary table for the query results
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Managers (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Manager_Description text Not Null,
            Manager_Name text Null,
            Entry_ID_Min int
        );

        -----------------------------------------------------------
        -- Find managers that have recently reported 'flag file exists'
        -- (for example: Pub-15: Flag file exists in directory AnalysisToolManager5)
        -----------------------------------------------------------

        INSERT INTO Tmp_Managers (Manager_Description, Manager_Name,  Entry_ID_Min)
        SELECT posted_by, null, MIN(entry_id) As Entry_ID_Min
        FROM public.t_log_entries
        WHERE entered >= CURRENT_TIMESTAMP - INTERVAL '48 hours' AND
              type = 'Error' AND
              posted_by ILIKE 'Analysis Tool Manager%' AND
              message ILIKE '%flag file exists%'
        GROUP BY posted_by;

        If Not FOUND Then
            -- Nothing to do

            _message := 'Did not find any flag file errors in public.t_log_entries; nothing to reset';

            If _infoOnly Then
                RAISE INFO '';
                RAISE INFO '%', _message;
            End If;

            DROP TABLE Tmp_Managers;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Determine the manager name
        -----------------------------------------------------------

        UPDATE Tmp_Managers
        SET Manager_Name = LTrim(RTrim(Substring(Manager_Description, CharIndex(':', Manager_Description) + 1, 128)))
        WHERE CharIndex(':', Manager_Description) > 0;

        If Exists (SELECT Entry_ID FROM Tmp_Managers WHERE Manager_Name Is Null) Then
            _message := 'Warning: one or more log entries did not have a colon in the manager description; they will be ignored';

            RAISE INFO '';
            RAISE WARNING '%', _message;
        End If;

        -----------------------------------------------------------
        -- Look for job steps to reset
        -----------------------------------------------------------

        CREATE TABLE Tmp_Job_Steps_to_Reset (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Job int,
            Step int,
            Processor text,
            Entry_ID_Min int
        );

        INSERT INTO Tmp_Job_Steps_to_Reset (Job, Step, Processor, Entry_ID_Min)
        SELECT JS.Job,
               JS.Step,
               JS.Processor,
               M.Entry_ID_Min
        FROM T_Job_Steps JS
             INNER JOIN Tmp_Managers M
               ON JS.Processor = M.Manager_Name
             INNER JOIN T_Processor_Status Status
               ON M.Manager_Name = Status.Processor_Name
        WHERE JS.State = 4 AND
              JS.Tool = 'Mz_Refinery' AND
              JS.Start < CURRENT_TIMESTAMP - Interval '15 minutes' AND
              Status.Progress < 0.1;

        If Not FOUND Then
            -- Did not find any job steps to reset

            If _infoOnly Then
                _message := 'public.T_Log_Entries has flag file error messages, but there are no corresponding running Mz_Refinery job steps';

                RAISE INFO '';
                RAISE INFO '%', _message;

                _formatSpecifier := '%-8s %-20s %-20s %-12s';

                _infoHead := format(_formatSpecifier,
                                    'Entry_ID',
                                    'Manager_Description',
                                    'Manager_Name',
                                    'Entry_ID_Min'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------',
                                             '--------------------',
                                             '--------------------',
                                             '------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Entry_ID,
                           Manager_Description,
                           Manager_Name,
                           Entry_ID_Min
                    FROM Tmp_Managers
                    ORDER BY Manager_Description
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Entry_ID,
                                        _previewData.Manager_Description,
                                        _previewData.Manager_Name,
                                        _previewData.Entry_ID_Min
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            End If;

            DROP TABLE Tmp_Managers;
            DROP TABLE Tmp_Job_Steps_to_Reset;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Process each entry in Tmp_Job_Steps_To_Reset
        -----------------------------------------------------------

        FOR _jobStep IN
            SELECT Entry_ID,
                   Job,
                   Step,
                   Processor,
                   Entry_ID_Min
            FROM Tmp_Job_Steps_to_Reset
            ORDER BY Entry_ID
        LOOP

            _baseMsg := format('Mz_Refinery for job %s, step %s, since processor %s crashed', _job, _step, _processor);

            If _infoOnly Then
                _message := format('Would reset %s', _baseMsg);

                RAISE INFO '';
                RAISE INFO '%', _message;

                CONTINUE;
            End If;

            -----------------------------------------------------------
            -- Reset the step state back to 2 (enabled)
            -----------------------------------------------------------

            UPDATE sw.t_job_steps
            SET state = 2
            WHERE job = _jobStep.Job AND step = _jobStep.Step AND state = 4;

            If Not FOUND Then
                _message := format('Attempted to reset %s, but no rows were updated; this is unexpected', _baseMsg);

                RAISE INFO '';
                RAISE WARNING '%', _message;

                CONTINUE;
            End If;

            _message := format('Reset %s', _baseMsg);

            CALL public.post_log_entry ('Warning', _message, 'reset_failed_mz_refinery_steps', 'sw');

            RAISE INFO '';
            RAISE INFO '%', _message;

            -----------------------------------------------------------
            -- Set the manager's cleanup mode to 1
            -----------------------------------------------------------

            CALL mc.set_manager_error_cleanup_mode (
                        _mgrlist     => _jobStep.Processor,
                        _cleanupMode => 1,
                        _showTable   => true,
                        _infoOnly    => false,
                        _message     => _message,       -- Output
                        _returnCode  => _returnCode);   -- Output

            -----------------------------------------------------------
            -- Update t_log_entries to change the log type from 'Error' to 'ErrorAutoFixed'
            -----------------------------------------------------------

            UPDATE public.T_Log_Entries
            SET type = 'ErrorAutoFixed'
            WHERE type = 'Error' AND Entry_ID = _jobStep.Entry_ID_Min;

            UPDATE public.t_log_entries
            SET type = 'ErrorIgnore'
            WHERE Entered >= CURRENT_TIMESTAMP - INTERVAL '48 hours' AND
                  type = 'Error' AND
                  posted_by = format('Analysis Tool Manager: %s', _jobStep.Processor)::citext AND
                  message ILIKE '%flag file exists%';

        END LOOP;

        DROP TABLE Tmp_Managers;
        DROP TABLE Tmp_Job_Steps_to_Reset;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_Managers;
    DROP TABLE IF EXISTS Tmp_Job_Steps_to_Reset;
END
$$;


ALTER PROCEDURE sw.reset_failed_mz_refinery_steps(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

