--
-- Name: retry_myemsl_upload(integer, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE PROCEDURE cap.retry_myemsl_upload(IN _job integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Resets the DatasetArchive and ArchiveUpdate steps in t_task_steps for the
**      given capture task jobs, but only if its ArchiveVerify step is failed
**
**      Calls cap.retry_myemsl_upload that accepts a comma-separated list of jobs
**
**  Arguments:
**    _job        Capture task job number
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   06/25/2023 mem - Initial version
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    If _job Is Null Then
        _message := '_job is null; nothing to do';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    CALL cap.retry_myemsl_upload(_job::text, _infoOnly =>_infoOnly, _message => _message, _returnCode => _returnCode);
END
$$;


ALTER PROCEDURE cap.retry_myemsl_upload(IN _job integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: retry_myemsl_upload(text, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE PROCEDURE cap.retry_myemsl_upload(IN _jobs text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Resets the DatasetArchive and ArchiveUpdate steps in t_task_steps for the
**      specified capture task jobs, but only if the ArchiveVerify step is failed
**
**      Useful for capture task jobs with completion message 'error submitting ingest job'
**
**  Arguments:
**    _jobs       Comma-separated list of capture task jobs whose steps should be reset
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   11/17/2014 mem - Initial version
**          02/23/2016 mem - Add Set XACT_ABORT on
**          01/26/2017 mem - Expand _message to varchar(4000)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          07/09/2017 mem - Clear Completion_Code, Completion_Message, Evaluation_Code, & Evaluation_Message when resetting a capture task job step
**          02/06/2018 mem - Exclude logging some try/catch errors
**          06/25/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _skipCount int := 0;
    _jobList text := '';

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

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _jobs := Trim(Coalesce(_jobs, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    If _jobs = '' Then
        _message := 'Job list is empty';
        RAISE INFO '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    Begin
        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Archive_Jobs (
            Job int
        );

        CREATE TEMP TABLE Tmp_Archive_Jobs_To_Skip (
            Job int
        );

        CREATE TEMP TABLE Tmp_Archive_Jobs_To_Reset (
            Job int
        );

        CREATE TEMP TABLE Tmp_Archive_JobStepsToReset (
            Job int,
            Step int
        );

        -----------------------------------------------------------
        -- Parse the capture task job list
        -----------------------------------------------------------

        INSERT INTO Tmp_Archive_Jobs (Job)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_jobs, ',')
        ORDER BY Value;

        -----------------------------------------------------------
        -- Look for capture task jobs that have a failed ArchiveVerify step
        -----------------------------------------------------------

        INSERT INTO Tmp_Archive_Jobs_To_Reset( Job )
        SELECT TS.Job
        FROM cap.t_task_steps TS
             INNER JOIN Tmp_Archive_Jobs JL
               ON TS.Job = JL.Job
        WHERE Tool = 'ArchiveVerify' AND
              State = 6;

        -----------------------------------------------------------
        -- Look for capture task jobs that do not have a failed ArchiveVerify step
        -----------------------------------------------------------

        INSERT INTO Tmp_Archive_Jobs_To_Skip( Job )
        SELECT JL.Job
        FROM Tmp_Archive_Jobs JL
             LEFT OUTER JOIN Tmp_Archive_Jobs_To_Reset JR
               ON JL.Job = JR.Job
        WHERE JR.Job IS NULL;

        If Not Exists (Select * From Tmp_Archive_Jobs_To_Reset) Then
            _message := 'None of the capture task job(s) has a failed ArchiveVerify step';
            RAISE INFO '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        SELECT COUNT(*)
        INTO _skipCount
        FROM Tmp_Archive_Jobs_To_Skip;

        If Coalesce(_skipCount, 0) > 0 Then
            _message := format('Skipping %s capture task job(s) that do not have a failed ArchiveVerify step', _skipCount);
            RAISE INFO '%', _message;
        End If;

        -- Construct a comma-separated list of capture task jobs
        --
        SELECT string_agg(job::text, ',' ORDER BY Job)
        INTO _jobList
        FROM Tmp_Archive_Jobs_To_Reset;

        -----------------------------------------------------------
        -- Reset the ArchiveUpdate or DatasetArchive step
        -----------------------------------------------------------

        If _infoOnly Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-5s %-20s %-20s %-10s %-20s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Step',
                                'Tool',
                                'Message',
                                'State',
                                'Start',
                                'Finish'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-----',
                                         '--------------------',
                                         '--------------------',
                                         '---------',
                                         '--------------------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT TS.Job,
                       TS.Step,
                       TS.Tool,
                       'Step would be reset' AS Message,
                       TS.State,
                       timestamp_text(TS.Start) As Start,
                       timestamp_text(TS.Finish) As Finish
                FROM cap.t_task_Steps TS
                     INNER JOIN Tmp_Archive_Jobs_To_Reset JR
                       ON TS.Job = JR.Job
                WHERE Tool IN ('ArchiveUpdate', 'DatasetArchive')
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Step,
                                    _previewData.Tool,
                                    _previewData.Message,
                                    _previewData.State,
                                    _previewData.Start,
                                    _previewData.Finish
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            RAISE INFO '';
            RAISE INFO 'Call cap.reset_dependent_task_steps for %', _jobList;

        Else
            _logErrors := true;

            -- Reset the archive step
            --
            UPDATE cap.t_task_steps TS
            Set state = 2,
                completion_code = 0,
                completion_message = Null,
                evaluation_code = Null,
                evaluation_message = Null
            FROM Tmp_Archive_Jobs_To_Reset JR
            WHERE TS.Job = JR.Job AND
                  TS.Tool IN ('ArchiveUpdate', 'DatasetArchive');

            -- Reset the state of the dependent steps
            --
            CALL cap.reset_dependent_task_steps (
                        _jobList,
                        _infoOnly => false,
                        _message => _message,
                        _returncode => _returncode);

            -- Reset the retry counts for the ArchiveVerify step
            --
            UPDATE cap.t_task_steps TS
            SET retry_count = 75,
                next_try = CURRENT_TIMESTAMP + Interval '10 minutes'
            FROM Tmp_Archive_Jobs_To_Reset JR
            WHERE TS.job = JR.Job AND
                  TS.Tool = 'ArchiveVerify';

        End If;

        DROP TABLE Tmp_Archive_Jobs;
        DROP TABLE Tmp_Archive_Jobs_To_Skip;
        DROP TABLE Tmp_Archive_Jobs_To_Reset;
        DROP TABLE Tmp_Archive_JobStepsToReset;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_Archive_Jobs;
        DROP TABLE IF EXISTS Tmp_Archive_Jobs_To_Skip;
        DROP TABLE IF EXISTS Tmp_Archive_Jobs_To_Reset;
        DROP TABLE IF EXISTS Tmp_Archive_JobStepsToReset;

    END;
END
$$;


ALTER PROCEDURE cap.retry_myemsl_upload(IN _jobs text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE retry_myemsl_upload(IN _jobs text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.retry_myemsl_upload(IN _jobs text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'RetryMyEMSLUpload';

