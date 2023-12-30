--
-- Name: reset_job_and_shared_results(integer, text, boolean, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.reset_job_and_shared_results(IN _job integer, IN _sharedresultfoldername text DEFAULT ''::text, IN _resetjob boolean DEFAULT false, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Reset a job, including updating the appropriate tables so that any shared results for a job will get re-created
**
**  Arguments:
**    _job                      Job that needs to be rerun, including re-generating the shared results
**    _sharedResultFolderName   If blank, will be auto-determined for the given job
**    _resetJob                 Will automatically reset the job if true, otherwise, you must manually reset the job
**    _infoOnly                 When true, preview updates
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   06/30/2010 mem - Initial version
**          11/18/2010 mem - Fixed bug resetting dependencies
**                           Added transaction
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          04/13/2012 mem - Now querying T_Job_Steps_History when looking for shared result folders
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**          08/03/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          10/12/2023 mem - Add missing call to format()
**                         - Fix bug using format() to append a message to _message
**
*****************************************************/
DECLARE
    _deleteCount int;
    _updateCount int;
    _matchCount int;
    _entryID int;
    _outputFolder text;
    _removeJobsMessage text;
    _jobMatch int;
    _msg text;

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

    BEGIN

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _job                    := Coalesce(_job, 0);
        _sharedResultFolderName := Trim(Coalesce(_sharedResultFolderName, ''));
        _infoOnly               := Coalesce(_infoOnly, false);
        _resetJob               := Coalesce(_resetJob, false);

        If _job = 0 Then
            _message := 'Job number not supplied';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_SharedResultFolders (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Output_Folder text
        );

        -- This table is used by sw.remove_selected_jobs and must be named Tmp_Selected_Jobs
        CREATE TEMP TABLE Tmp_Selected_Jobs (
            Job int,
            State int
        );

        If _sharedResultFolderName = '' Then
            -----------------------------------------------------------
            -- Find the shared result folders for this job
            -----------------------------------------------------------

            INSERT INTO Tmp_SharedResultFolders( Output_Folder )
            SELECT DISTINCT output_folder_name
            FROM sw.t_job_steps
            WHERE job = _job AND
                  Coalesce(signature, 0) > 0 AND
                  NOT output_folder_name IS NULL
            UNION
            SELECT DISTINCT output_folder_name
            FROM sw.t_job_steps_history
            WHERE job = _job AND
                  Coalesce(signature, 0) > 0 AND
                  NOT output_folder_name IS NULL;

        Else
            INSERT INTO Tmp_SharedResultFolders( Output_Folder )
            VALUES (_sharedResultFolderName);
        End If;

        -----------------------------------------------------------
        -- Process each entry in Tmp_SharedResultFolders
        -----------------------------------------------------------

        If Not _infoOnly Then
            RAISE INFO '';
        End If;

        FOR _entryID, _outputFolder IN
            SELECT Entry_ID, Output_Folder
            FROM Tmp_SharedResultFolders
            ORDER BY Entry_ID
        LOOP
            If _infoOnly Then
                RAISE INFO '';
            End If;

            RAISE INFO 'Removing all records of output folder "%"', _outputFolder;

            If _infoOnly Then
                RAISE INFO '';

                If Not Exists ( SELECT results_name
                                FROM sw.t_shared_results
                                WHERE results_name = _outputFolder)
                Then
                    RAISE INFO 'Did not find output folder % in sw.t_shared_results; nothing to remove', _outputFolder;
                Else

                    _formatSpecifier := '%-35s %-40s %-20s';

                    _infoHead := format(_formatSpecifier,
                                        'Message',
                                        'Results_Name',
                                        'Created'
                                       );

                    _infoHeadSeparator := format(_formatSpecifier,
                                                 '-----------------------------------',
                                                 '----------------------------------------',
                                                 '--------------------'
                                                );

                    RAISE INFO '%', _infoHead;
                    RAISE INFO '%', _infoHeadSeparator;

                    FOR _previewData IN
                        SELECT 'Delete from sw.t_shared_results' AS Message,
                               Results_Name,
                               public.timestamp_text(Created) AS Created
                        FROM sw.t_shared_results
                        WHERE results_name = _outputFolder
                    LOOP
                        _infoData := format(_formatSpecifier,
                                            _previewData.Message,
                                            _previewData.Results_Name,
                                            _previewData.Created
                                           );

                        RAISE INFO '%', _infoData;
                    END LOOP;
                End If;

                RAISE INFO '';

                If Not Exists ( SELECT JS.job
                                FROM sw.V_Job_Steps JS
                                     INNER JOIN sw.t_jobs J
                                       ON JS.job = J.job
                                WHERE JS.Output_Folder = _outputFolder AND
                                      JS.state = 5 AND
                                      J.state = 4)
                Then
                    RAISE INFO 'Did not find any completed jobs in sw.t_jobs with a completed job step with output folder %; nothing to remove', _outputFolder;
                Else
                    _formatSpecifier := '%-60s %-25s %-9s';

                    _infoHead := format(_formatSpecifier,
                                        'Message',
                                        'Job_To_Remove_From_T_Jobs',
                                        'Job_State'
                                       );

                    _infoHeadSeparator := format(_formatSpecifier,
                                                 '------------------------------------------------------------',
                                                 '-------------------------',
                                                 '---------'
                                                );

                    RAISE INFO '%', _infoHead;
                    RAISE INFO '%', _infoHeadSeparator;

                    FOR _previewData IN
                        SELECT 'Remove job from sw.t_jobs, but leave in sw.t_jobs_history' As Message,
                               JS.job AS Job_To_Remove_From_T_Jobs,
                               J.state AS Job_State
                        FROM sw.V_Job_Steps JS
                             INNER JOIN sw.t_jobs J
                               ON JS.job = J.job
                        WHERE JS.Output_Folder = _outputFolder AND
                              JS.state = 5 AND
                              J.state = 4
                    LOOP
                        _infoData := format(_formatSpecifier,
                                            _previewData.Message,
                                            _previewData.Job_To_Remove_From_T_Jobs,
                                            _previewData.Job_State
                                           );

                        RAISE INFO '%', _infoData;
                    END LOOP;
                End If;

                RAISE INFO '';

                If Not Exists ( SELECT job
                                FROM sw.t_job_steps_history
                                WHERE output_folder_name = _outputFolder AND state = 5)
                Then
                    RAISE INFO 'Did not find any completed jobs in sw.t_job_steps_history with output folder %; nothing to remove', _outputFolder;
                Else
                    _formatSpecifier := '%-30s %-30s %-30s';

                    _infoHead := format(_formatSpecifier,
                                        'Message',
                                        'Output_Folder_Name',
                                        'Output_Folder_Name_New'
                                       );

                    _infoHeadSeparator := format(_formatSpecifier,
                                                 '------------------------------',
                                                 '------------------------------',
                                                 '------------------------------'
                                                );

                    RAISE INFO '%', _infoHead;
                    RAISE INFO '%', _infoHeadSeparator;

                    FOR _previewData IN
                        SELECT 'Update sw.t_job_steps_history' As Message,
                               Output_Folder_Name,
                               format('%s_BAD', Output_Folder_Name) As Output_Folder_Name_New
                        FROM sw.t_job_steps_history
                        WHERE output_folder_name = _outputFolder AND state = 5
                    LOOP
                        _infoData := format(_formatSpecifier,
                                            _previewData.Message,
                                            _previewData.Output_Folder_Name,
                                            _previewData.Output_Folder_Name_New
                                           );

                        RAISE INFO '%', _infoData;
                    END LOOP;
                End If;

                CONTINUE;
            End If;

            -- Remove from sw.t_shared_results

            DELETE FROM sw.t_shared_results
            WHERE results_name = _outputFolder;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            RAISE INFO '';

            If _deleteCount > 0 Then
                _message := format('Removed %s %s from sw.t_shared_results', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows'));
            Else
                _message := format('Match not found in sw.t_shared_results for %s', _outputFolder);
            End If;

            TRUNCATE TABLE Tmp_Selected_Jobs;

            -- Remove any completed jobs that had this output folder
            -- (the job details should already be in sw.t_job_steps_history)

            INSERT INTO Tmp_Selected_Jobs
            SELECT JS.job AS JobToDelete, J.State
            FROM sw.V_Job_Steps JS INNER JOIN
                sw.t_jobs J ON JS.job = J.job
            WHERE JS.Output_Folder = _outputFolder AND
                  JS.state = 5 AND
                  J.state = 4;

            If Exists (SELECT * FROM Tmp_Selected_Jobs) Then
                CALL sw.remove_selected_jobs (
                            _infoOnly         => false,
                            _message          => _removeJobsMessage,    -- Output
                            _returncode       => _returncode,           -- Output
                            _logDeletions     => true,
                            _logToConsoleOnly => false);

                _message := format('%s; %s', _message, _removeJobsMessage);
            End If;

            -- Rename Output Folder in sw.t_job_steps_history for any completed job steps
            UPDATE sw.t_job_steps_history
            SET output_folder_name = format('%s_BAD', output_folder_name)
            WHERE output_folder_name = _outputFolder AND state = 5;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount <> 0 Then
                _message := format('%s; Updated %s %s in sw.t_job_steps_history', _message, _updateCount, public.check_plural(_updateCount, 'row', 'rows'));
            Else
                _message := format('%s; Match not found in sw.t_job_steps_history for %s', _message, _outputFolder);
            End If;

            -- Look for any jobs that remain in sw.t_job_steps and have completed steps with Output_Folder = _outputFolder

            SELECT COUNT(Distinct Job)
            INTO _matchCount
            FROM sw.V_Job_Steps
            WHERE Output_Folder = _outputFolder AND State = 5;

            If _matchCount > 0 Then

                FOR _msg IN
                    SELECT format('Job %s, step %s likely needs to have it''s Output_Folder field renamed to not be %s',
                                  Job, Step, _outputFolder) As Message
                    FROM sw.V_Job_Steps
                    WHERE Output_Folder = _outputFolder AND State = 5
                LOOP
                    RAISE INFO '%', _msg;
                END LOOP;

                If _matchCount = 1 Then
                    SELECT Job
                    INTO _jobMatch
                    FROM sw.V_Job_Steps
                    WHERE Output_Folder = _outputFolder AND State = 5;

                    _message := format('%s; job %s in sw.t_job_steps likely needs to have it''s Output_Folder field renamed to not be %s',
                                        _message, _job, _outputFolder);
                Else
                    _message := format('%s; %s jobs in sw.t_job_steps likely need to have their Output_Folder field renamed to not be %s',
                                        _message, _matchCount, _outputFolder);
                End If;
            End If;

        END LOOP;

        If Not _resetJob Then
            DROP TABLE Tmp_SharedResultFolders;
            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        If _infoOnly Then

            RAISE INFO '';

            If Not Exists ( SELECT job
                            FROM sw.t_job_step_dependencies
                            WHERE job = _job)
            Then
                RAISE INFO 'Did not find any rows in sw.t_job_step_dependencies for job %; nothing to remove', _job;
            Else
                _formatSpecifier := '%-9s %-4s %-11s %-15s %-10s %-9s %-9s %-11s %-25s';

                _infoHead := format(_formatSpecifier,
                                    'Job',
                                    'Step',
                                    'Target_Step',
                                    'Condition_Test',
                                    'Test_Value',
                                    'Evaluated',
                                    'Triggered',
                                    'Enable_Only',
                                    'Message'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '---------',
                                             '----',
                                             '-----------',
                                             '---------------',
                                             '----------',
                                             '---------',
                                             '---------',
                                             '-----------',
                                             '-------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Job,
                           Step,
                           Target_Step,
                           Condition_Test,
                           Test_Value,
                           Evaluated,
                           Triggered,
                           Enable_Only,
                           CASE
                               WHEN Evaluated <> 0 OR
                                    Triggered <> 0 THEN 'Dependency will be reset'
                               ELSE ''
                           END AS Message
                    FROM sw.t_job_step_dependencies
                    WHERE job = _job
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Job,
                                        _previewData.Step,
                                        _previewData.Target_Step,
                                        _previewData.Condition_Test,
                                        _previewData.Test_Value,
                                        _previewData.Evaluated,
                                        _previewData.Triggered,
                                        _previewData.Enable_Only,
                                        _previewData.Message
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;
            End If;

            DROP TABLE Tmp_SharedResultFolders;
            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        -- Reset the job (but don't delete it from the tables, and don't use sw.remove_selected_jobs since it would update sw.t_shared_results)

        -- Reset dependencies
        UPDATE sw.t_job_step_dependencies
        SET evaluated = 0,
            triggered = 0
        WHERE job = _job AND (evaluated <> 0 OR triggered <> 0);

        UPDATE sw.t_job_steps
        SET state = 1,                    -- 1=Waiting
            tool_version_id = 1,          -- 1=Unknown
            next_try = CURRENT_TIMESTAMP,
            remote_info_id = 1            -- 1=Unknown
        WHERE job = _job AND (state <> 1 OR Coalesce(tool_version_id, 0) <> 1 OR remote_info_id <> 1);

        UPDATE sw.t_jobs
        SET state = 1
        WHERE job = _job AND state <> 1;

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

    DROP TABLE Tmp_SharedResultFolders;
    DROP TABLE Tmp_Selected_Jobs;
END
$$;


ALTER PROCEDURE sw.reset_job_and_shared_results(IN _job integer, IN _sharedresultfoldername text, IN _resetjob boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_job_and_shared_results(IN _job integer, IN _sharedresultfoldername text, IN _resetjob boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.reset_job_and_shared_results(IN _job integer, IN _sharedresultfoldername text, IN _resetjob boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'ResetJobAndSharedResults';

