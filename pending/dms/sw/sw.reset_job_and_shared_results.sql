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
    _myRowCount int := 0;
    _entryID int;
    _outputFolder text;
    _removeJobsMessage text;
    _jobMatch int;
BEGIN

    BEGIN TRY

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    _job := Coalesce(_job, 0);
    _sharedResultFolderName := Coalesce(_sharedResultFolderName, '');
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode:= '';

    If _job = 0 Then
        _message := 'Job number not supplied';
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Create the temporary tables
    -----------------------------------------------------------
    --

    CREATE TEMP TABLE Tmp_SharedResultFolders (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Output_Folder text
    )

    -- This table is used by RemoveSelectedJobs and must be named Tmp_SJL
    CREATE TEMP TABLE Tmp_SJL (
        Job int,
        State int
    );

    If _sharedResultFolderName = '' Then
        -----------------------------------------------------------
        -- Find the shared result folders for this job
        -----------------------------------------------------------
        --
        INSERT INTO Tmp_SharedResultFolders( Output_Folder )
        SELECT DISTINCT output_folder_name
        FROM sw.t_job_steps
        WHERE (job = _job) AND
            (Coalesce(signature, 0) > 0) AND
             NOT output_folder_name IS NULL
        UNION
        SELECT DISTINCT output_folder_name
        FROM sw.t_job_steps_history
        WHERE (job = _job) AND
            (Coalesce(signature, 0) > 0) AND
             NOT output_folder_name IS NULL;

    Else
        INSERT INTO Tmp_SharedResultFolders( Output_Folder )
        VALUES (_sharedResultFolderName)
    End If;

    -----------------------------------------------------------
    -- Process each entry in Tmp_SharedResultFolders
    -----------------------------------------------------------

    FOR _entryID, _outputFolder IN
        SELECT Entry_ID, Output_Folder
        FROM Tmp_SharedResultFolders
        ORDER BY Entry_ID
    LOOP
        RAISE INFO '%', 'Removing all records of output folder "' || _outputFolder || '"';

        If _infoOnly Then

            -- ToDo: Update these queries to use RAISE INFO

            SELECT 'Delete from sw.t_shared_results' as Message, *
            FROM sw.t_shared_results
            WHERE (results_name = _outputFolder)

            SELECT 'Remove job from sw.t_jobs, but leave in sw.t_jobs_history' as Message,
                   V_Job_Steps.job AS JobToRemoveFromTJobs,
                   sw.t_jobs.state AS Job_State
            FROM V_Job_Steps
                 INNER JOIN sw.t_jobs
                   ON V_Job_Steps.job = sw.t_jobs.job
            WHERE (V_Job_Steps.Output_Folder = _outputFolder) AND
                  (V_Job_Steps.state = 5) AND
                  (sw.t_jobs.state = 4)

            SELECT 'Update sw.t_job_steps_history' as Message, Output_Folder_Name, Output_Folder_Name || '_BAD' as Output_Folder_Name_New
            FROM sw.t_job_steps_history
            WHERE (output_folder_name = _outputFolder) AND state = 5;

            CONTINUE;
        End If;


        -- Remove from sw.t_shared_results
        DELETE FROM sw.t_shared_results
        WHERE (results_name = _outputFolder)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount <> 0 Then
            _message := 'Removed ' || _myRowCount::text || ' row(s) from sw.t_shared_results';
        Else
            _message := 'Match not found in sw.t_shared_results';
        End If;

        TRUNCATE TABLE Tmp_SJL

        -- Remove any completed jobs that had this output folder
        -- (the job details should already be in sw.t_job_steps_history)
        INSERT INTO Tmp_SJL
        SELECT V_Job_Steps.job AS JobToDelete, sw.t_jobs.State
        FROM V_Job_Steps INNER JOIN
            sw.t_jobs ON V_Job_Steps.job = sw.t_jobs.job
        WHERE (V_Job_Steps.Output_Folder = _outputFolder)
            AND (V_Job_Steps.state = 5) AND (sw.t_jobs.state = 4);

        If Exists (SELECT * FROM Tmp_SJL) Then
            Call sw.remove_selected_jobs (
                    _infoOnly => false,
                    _message => _removeJobsMessage,
                    _logDeletions => true,
                    _logToConsoleOnly => false);

            _message := _message || '; ' || _removeJobsMessage;
        End If;

        -- Rename Output Folder in sw.t_job_steps_history for any completed job steps
        UPDATE sw.t_job_steps_history
        SET output_folder_name = output_folder_name || '_BAD'
        WHERE (output_folder_name = _outputFolder) AND state = 5
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount <> 0 Then
            _message := _message || '; Updated ' || _myRowCount::text || ' row(s) in sw.t_job_steps_history';
        Else
            _message := _message || '; Match not found in sw.t_job_steps_history';
        End If;

        -- Look for any jobs that remain in sw.t_job_steps and have completed steps with Output_Folder = _outputFolder

        SELECT COUNT(Distinct Job)
        INTO _myRowCount
        FROM V_Job_Steps
        WHERE (Output_Folder = _outputFolder) AND
              (State = 5);

        If _myRowCount > 0 Then

            SELECT Job, 'This job likely needs to have it''s Output_Folder field renamed to not be ' || _outputFolder as Message
            FROM V_Job_Steps
            WHERE (Output_Folder = _outputFolder) AND
                (State = 5)

            If _myRowCount = 1 Then
                SELECT Job
                INTO _jobMatch
                FROM V_Job_Steps
                WHERE (Output_Folder = _outputFolder) AND (State = 5)

                _message := _message || '; job ' || _job::text || ' in sw.t_job_steps likely needs to have it''s Output_Folder field renamed to not be ' || _outputFolder;
            Else
                _message := _message || '; ' || _myRowCount::text || ' jobs in sw.t_job_steps likely need to have their Output_Folder field renamed to not be ' || _outputFolder;
            End If;
        End If;

    END LOOP;

    If _resetJob <> 0 Then
        If _infoOnly Then
            -- Show dependencies
            SELECT *,
                   CASE
                       WHEN Evaluated <> 0 OR
                            Triggered <> 0 THEN 'Dependency will be reset'
                       ELSE ''
                   END AS Message
            FROM sw.t_job_step_dependencies
            WHERE (job = _job)

        Else
            -- Reset the job (but don't delete it from the tables, and don't use RemoveSelectedJobs since it would update sw.t_shared_results)

            -- Reset dependencies
            UPDATE sw.t_job_step_dependencies
            SET evaluated = 0, triggered = 0
            WHERE (job = _job)

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

    END TRY
    BEGIN CATCH
        Call public.format_error_message _message => _message, _myError output

        -- Rollback any open transactions
        ROLLBACK;

        Call public.post_log_entry ('Error', _message, 'Reset_Job_And_Shared_Results', 'sw');
    END CATCH

    DROP TABLE Tmp_SharedResultFolders;
    DROP TABLE Tmp_SJL;
END
$$;

COMMENT ON PROCEDURE sw.reset_job_and_shared_results IS 'ResetJobAndSharedResults';