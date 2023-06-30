--
CREATE OR REPLACE PROCEDURE sw.reset_job_and_shared_results
(
    _job int,
    _sharedResultFolderName text = '',
    _resetJob int = 0,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resets a job, including updating the appropriate tables
**      so that any shared results for a job will get re-created
**
**
**  Arguments:
**    _job                      Job that needs to be rerun, including re-generating the shared results
**    _sharedResultFolderName   If blank, will be auto-determined for the given job
**    _resetJob                 Will automatically reset the job if 1, otherwise, you must manually reset the job
**    _infoOnly                 True to preview the changes
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
**          12/15/2023 mem - Ported to PostgreSQL
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

        _job := Coalesce(_job, 0);
        _sharedResultFolderName := Coalesce(_sharedResultFolderName, '');
        _infoOnly := Coalesce(_infoOnly, false);

        If _jobs = '' Then
            _message := 'The jobs parameter is empty';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN
        End If;

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_SharedResultFolders (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Output_Folder text
        )

        -- This table is used by Remove_Selected_Jobs and must be named Tmp_Selected_Jobs
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

        FOR _entryID, _outputFolder IN
            SELECT Entry_ID, Output_Folder
            FROM Tmp_SharedResultFolders
            ORDER BY Entry_ID
        LOOP
            RAISE INFO 'Removing all records of output folder "%"', _outputFolder;

            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT 'Delete from sw.t_shared_results' As Message, *
                FROM sw.t_shared_results
                WHERE results_name = _outputFolder;

                SELECT 'Remove job from sw.t_jobs, but leave in sw.t_jobs_history' As Message,
                       V_Job_Steps.job AS JobToRemoveFromTJobs,
                       sw.t_jobs.state AS Job_State
                FROM V_Job_Steps
                     INNER JOIN sw.t_jobs
                       ON V_Job_Steps.job = sw.t_jobs.job
                WHERE V_Job_Steps.Output_Folder = _outputFolder AND
                      V_Job_Steps.state = 5 AND
                      sw.t_jobs.state = 4;

                SELECT 'Update sw.t_job_steps_history' As Message, Output_Folder_Name, format('%s_BAD', Output_Folder_Name) As Output_Folder_Name_New
                FROM sw.t_job_steps_history
                WHERE output_folder_name = _outputFolder AND state = 5;

                CONTINUE;
            End If;

            -- Remove from sw.t_shared_results
            DELETE FROM sw.t_shared_results
            WHERE results_name = _outputFolder;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Removed %s %s from sw.t_shared_results', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows'));
            Else
                _message := 'Match not found in sw.t_shared_results';
            End If;

            TRUNCATE TABLE Tmp_Selected_Jobs

            -- Remove any completed jobs that had this output folder
            -- (the job details should already be in sw.t_job_steps_history)
            INSERT INTO Tmp_Selected_Jobs
            SELECT V_Job_Steps.job AS JobToDelete, sw.t_jobs.State
            FROM V_Job_Steps INNER JOIN
                sw.t_jobs ON V_Job_Steps.job = sw.t_jobs.job
            WHERE V_Job_Steps.Output_Folder = _outputFolder AND
                  V_Job_Steps.state = 5 AND
                  sw.t_jobs.state = 4;

            If Exists (SELECT * FROM Tmp_Selected_Jobs) Then
                CALL sw.remove_selected_jobs (
                        _infoOnly => false,
                        _message => _removeJobsMessage,
                        _logDeletions => true,
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
                _message := format('%s; Match not found in sw.t_job_steps_history', _message);
            End If;

            -- Look for any jobs that remain in sw.t_job_steps and have completed steps with Output_Folder = _outputFolder

            SELECT COUNT(Distinct Job)
            INTO _matchCount
            FROM V_Job_Steps
            WHERE Output_Folder = _outputFolder AND State = 5;

            If _matchCount > 0 Then

                FOR _msg IN
                    SELECT format('Job %s, step %s likely needs to have it''s Output_Folder field renamed to not be %s',
                                    Job, Step, _outputFolder) As Message
                    FROM V_Job_Steps
                    WHERE Output_Folder = _outputFolder AND State = 5
                LOOP
                    RAISE INFO '%', _msg;
                END LOOP;

                If _matchCount = 1 Then
                    SELECT Job
                    INTO _jobMatch
                    FROM V_Job_Steps
                    WHERE Output_Folder = _outputFolder AND State = 5;

                    _message := format('%s; job %s in sw.t_job_steps likely needs to have it''s Output_Folder field renamed to not be %s',
                                        _message, _job, _outputFolder);
                Else
                    _message := format('%s; %s jobs in sw.t_job_steps likely need to have their Output_Folder field renamed to not be %s',
                                        _message, _matchCount, _outputFolder);
                End If;
            End If;

        END LOOP;

        If _resetJob <> 0 Then
            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO

                SELECT *,
                       CASE
                           WHEN Evaluated <> 0 OR
                                Triggered <> 0 THEN 'Dependency will be reset'
                           ELSE ''
                       END AS Message
                FROM sw.t_job_step_dependencies
                WHERE job = _job;

            Else
                -- Reset the job (but don't delete it from the tables, and don't use Remove_Selected_Jobs since it would update sw.t_shared_results)

                -- Reset dependencies
                UPDATE sw.t_job_step_dependencies
                SET evaluated = 0, triggered = 0
                WHERE job = _job;

                UPDATE sw.t_job_steps
                SET state = 1,                    -- 1=waiting
                    tool_version_id = 1,        -- 1=Unknown
                    next_try = CURRENT_TIMESTAMP,
                    remote_info_id = 1            -- 1=Unknown
                WHERE job = _job AND state <> 1

                UPDATE sw.t_jobs
                SET state = 1
                WHERE job = _job AND state <> 1

            End If;

        End If;

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

COMMENT ON PROCEDURE sw.reset_job_and_shared_results IS 'ResetJobAndSharedResults';
