--
CREATE OR REPLACE PROCEDURE sw.reset_aggregation_job
(
    _job int,
    _infoOnly boolean = true,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resets an aggregation job
**
**      Case 1:
**      If the job is complete (state 4), renames the Output_Folder and resets all steps
**
        Case 2:
**      If the job has one or more failed steps, leaves the Output Folder name unchanged but resets the failed steps
**
**  Arguments:
**    _job        Job that needs to be rerun, including re-generating the shared results
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   03/06/2013 mem - Initial version
**          03/07/2013 mem - Now only updating failed job steps when not resetting the entire job
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _dataset text := '';
    _jobState int;
    _script text;
    _tag text;
    _resultsDirectoryName text;
    _folderLikeClause citext;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    _job := Coalesce(_job, 0);
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';

    If _job = 0 Then
        _message := 'Job number not supplied';
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Make sure the job exists and is an aggregation job
    -----------------------------------------------------------

    SELECT dataset, state, script
    INTO _dataset, _jobState, _script
    FROM sw.t_jobs
    WHERE job = _job;

    If Not FOUND Then
        _message := format('Job not found in sw.t_jobs: %s', _job);
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    If Coalesce(_dataset, '') <> 'Aggregation' Then
        _message := format('Job is not an aggregation job; reset this job by updating its state in DMS5: %s', _job);
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    -- See if we have any failed job steps
    If Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state = 6) Then
        -- Override _jobState
        _jobState := 5;
    End If;

    If _jobState = 5 AND Not Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state IN (6,7)) Then
        _message := format('Job %s is marked as failed (State=5 in sw.t_jobs) yet there are no failed or holding job steps; the job cannot be reset at this time', _job);
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    If Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state = 4) Then
        _message := format('Job %s has running steps (state=4); the job cannot be reset while steps are running', _job);
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    If Not _jobState IN (4, 5) Then
        _message := format('Job %s is not complete or failed; the job cannot be reset at this time', _job);
        RAISE INFO '%', _message;
        RAISE EXCEPTION '%', _message;
    End If;

    If _jobState = 4 Then
        -- Job is complete; give the job a new results directory name and reset it

        SELECT results_tag
        INTO _tag
        FROM sw.t_scripts
        WHERE (script = _script)

        _resultsDirectoryName := sw.get_results_directory_name (_job, _tag);

        RAISE INFO '%', _resultsDirectoryName;

        _folderLikeClause := _tag || '%';

        If _infoOnly Then
            -- ToDo: Preview the job steps using RAISE INFO

            -- Show job steps
            SELECT job, step, output_folder_name as Output_Folder_Old, _resultsDirectoryName as Output_Folder_New
            FROM sw.t_job_steps
            WHERE job = _job And (state <> 1 OR input_folder_name Like _folderLikeClause OR  Output_Folder_Name Like _folderLikeClause)
            ORDER BY step

            -- Show dependencies
            SELECT *,
                    CASE
                        WHEN Evaluated <> 0 OR
                            Triggered <> 0 THEN 'Dependency will be reset'
                        ELSE ''
                    END AS Message
            FROM sw.t_job_step_dependencies
            WHERE job = _job
            ORDER BY step;

        Else

            BEGIN

                -- Reset dependencies
                UPDATE sw.t_job_step_dependencies
                SET evaluated = 0, triggered = 0
                WHERE job = _job;

                UPDATE sw.t_job_steps
                SET state = 1,                      -- 1=waiting
                    tool_version_id = 1,            -- 1=Unknown
                    next_try = CURRENT_TIMESTAMP,
                    remote_info_id = 1              -- 1=Unknown
                WHERE job = _job AND state <> 1;

                UPDATE sw.t_job_steps
                SET input_folder_name = _resultsDirectoryName
                WHERE job = _job AND input_folder_name Like _folderLikeClause;

                UPDATE sw.t_job_steps
                SET output_folder_name = _resultsDirectoryName
                WHERE job = _job AND output_folder_name Like _folderLikeClause;

                UPDATE sw.t_jobs
                SET state = 1, results_folder_name = _resultsDirectoryName
                WHERE job = _job AND state <> 1;

                COMMIT;
            END;

        End If;

    End If;

    If _jobState = 5 Then

        If _infoOnly Then

            -- ToDo: Preview the job steps using RAISE INFO

            -- Show job steps that would be reset
            SELECT job,
                   step,
                   state AS State_Current,
                   1 AS State_New
            FROM sw.t_job_steps
            WHERE job = _job AND
                  state IN (6, 7)
            ORDER BY step;

            -- Show dependencies
            SELECT *,
                   CASE
                       WHEN JS.State IN (6, 7) AND
                            (Evaluated <> 0 OR
                             Triggered <> 0) THEN 'Dependency will be reset'
                       ELSE ''
                   END AS Message
            FROM sw.t_job_step_dependencies JSD
                 INNER JOIN sw.t_job_steps JS
                   ON JSD.step = JS.step AND
                      JSD.job = JS.job
            WHERE JSD.job = _job
            ORDER BY JSD.step;

        Else

            BEGIN

                -- Reset dependencies
                UPDATE sw.t_job_step_dependencies JSD
                SET evaluated = 0,
                    triggered = 0
                FROM sw.t_job_steps JS
                WHERE JSD.job = JS.job AND
                      JSD.step = JS.step AND
                      JSD.job = _job AND
                      JS.state IN (6, 7);

                UPDATE sw.t_job_steps
                SET state = 1,                      -- 1=Waiting
                    tool_version_id = 1,            -- 1=Unknown
                    next_try = CURRENT_TIMESTAMP,
                    remote_info_id = 1              -- 1=Unknown
                WHERE job = _job AND state IN (6, 7) And state <> 1;

                UPDATE sw.t_jobs
                SET state = 2
                WHERE job = _job AND state <> 2;

                COMMIT;
            END;
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

END
$$;

COMMENT ON PROCEDURE sw.reset_aggregation_job IS 'ResetAggregationJob';
