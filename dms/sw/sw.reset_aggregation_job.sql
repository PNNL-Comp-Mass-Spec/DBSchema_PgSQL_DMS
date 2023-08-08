--
-- Name: reset_aggregation_job(integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.reset_aggregation_job(IN _job integer, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Resets an aggregation job
**
**      Case 1:
**        If the job is complete (state 4), renames the Output_Folder and resets all steps
**
**      Case 2:
**        If the job has one or more failed steps, leaves the Output Folder name unchanged but resets the failed steps
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
**          07/27/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _dataset citext := '';
    _jobState int;
    _script text;
    _tag text;
    _resultsDirectoryName text;
    _folderLikeClause citext;

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

    _job := Coalesce(_job, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    If _job = 0 Then
        _message := 'Job number not supplied';
        RAISE WARNING '%', _message;
        _returnCode := 'U5301';
        RETURN;
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
        RAISE WARNING '%', _message;
        _returnCode := 'U5302';
        RETURN;
    End If;

    If Coalesce(_dataset, '') <> 'Aggregation' Then
        _message := format('Job is not an aggregation job; reset this job by updating its state in public.t_analysis_job: %s', _job);
        RAISE WARNING '%', _message;
        _returnCode := 'U5303';
        RETURN;
    End If;

    -- See if we have any failed job steps
    If Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state = 6) Then
        -- Override _jobState
        _jobState := 5;
    End If;

    If _jobState = 5 AND Not Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state IN (6,7)) Then
        _message := format('Job %s is marked As failed (State=5 in sw.t_jobs) yet there are no failed or holding job steps; the job cannot be reset at this time', _job);
        RAISE WARNING '%', _message;
        _returnCode := 'U5304';
        RETURN;
    End If;

    If Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state = 4) Then
        _message := format('Job %s has running steps (state=4); the job cannot be reset while steps are running', _job);
        RAISE WARNING '%', _message;
        _returnCode := 'U5305';
        RETURN;
    End If;

    If Not _jobState IN (4, 5) Then
        _message := format('Job %s is not complete or failed; the job cannot be reset at this time', _job);
        RAISE WARNING '%', _message;
        _returnCode := 'U5306';
        RETURN;
    End If;

    If _jobState = 4 Then
        -- Job is complete; give the job a new results directory name and reset it

        SELECT results_tag
        INTO _tag
        FROM sw.t_scripts
        WHERE script = _script;

        _resultsDirectoryName := sw.get_results_directory_name (_job, _tag);

        If Not _infoOnly Then
            RAISE INFO 'New results directory name: %', _resultsDirectoryName;
        End If;

        _folderLikeClause := _tag || '%';

        If _infoOnly Then

            -- Show job steps

            RAISE INFO '';

            _formatSpecifier := '%-9s %-4s %-30s %-30s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Step',
                                'Output_Folder_Name',
                                'Output_Folder_Name_New'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------',
                                         '----',
                                         '------------------------------',
                                         '------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       Step,
                       Output_Folder_Name,
                       _resultsDirectoryName As Output_Folder_Name_New
                FROM sw.t_job_steps
                WHERE job = _job AND (state <> 1 OR input_folder_name ILIKE _folderLikeClause OR Output_Folder_Name ILIKE _folderLikeClause)
                ORDER BY step
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Step,
                                    _previewData.Output_Folder_Name,
                                    _previewData.Output_Folder_Name_New
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            If Exists (SELECT job FROM sw.t_job_step_dependencies WHERE job = _job) Then
                -- Show dependencies

                RAISE INFO '';

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
                    ORDER BY step
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
        Else
            -- Reset dependencies

            UPDATE sw.t_job_step_dependencies
            SET evaluated = 0, triggered = 0
            WHERE job = _job;

            UPDATE sw.t_job_steps
            SET state = 1,                      -- 1=Waiting
                tool_version_id = 1,            -- 1=Unknown
                next_try = CURRENT_TIMESTAMP,
                remote_info_id = 1              -- 1=Unknown
            WHERE job = _job AND state <> 1;

            UPDATE sw.t_job_steps
            SET input_folder_name = _resultsDirectoryName
            WHERE job = _job AND input_folder_name ILIKE _folderLikeClause;

            UPDATE sw.t_job_steps
            SET output_folder_name = _resultsDirectoryName
            WHERE job = _job AND output_folder_name ILIKE _folderLikeClause;

            UPDATE sw.t_jobs
            SET state = 1, results_folder_name = _resultsDirectoryName
            WHERE job = _job AND state <> 1;

        End If;

    End If;

    If _jobState = 5 Then

        If _infoOnly Then

            -- Show job steps that would be reset

            RAISE INFO '';

            _formatSpecifier := '%-9s %-4s %-13s %-9s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Step',
                                'State_Current',
                                'State_New'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------',
                                         '----',
                                         '-------------',
                                         '---------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       Step,
                       State AS State_Current,
                       1 AS State_New
                FROM sw.t_job_steps
                WHERE job = _job AND
                      state IN (6, 7)
                ORDER BY step
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Step,
                                    _previewData.State_Current,
                                    _previewData.State_New
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            If Exists (SELECT job FROM sw.t_job_step_dependencies WHERE job = _job) Then
                -- Show dependencies

                RAISE INFO '';

                _formatSpecifier := '%-9s %-4s %-25s %-5s %-11s %-15s %-10s %-9s %-9s %-11s %-25s';

                _infoHead := format(_formatSpecifier,
                                    'Job',
                                    'Step',
                                    'Tool',
                                    'State',
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
                                             '-------------------------',
                                             '-----',
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
                    SELECT JS.Job,
                           JS.Step,
                           JS.Tool,
                           JS.State,
                           JSD.Target_Step,
                           JSD.Condition_Test,
                           JSD.Test_Value,
                           JSD.Evaluated,
                           JSD.Triggered,
                           JSD.Enable_Only,
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
                    ORDER BY JSD.step
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Job,
                                        _previewData.Step,
                                        _previewData.Tool,
                                        _previewData.State,
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

        Else
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
            WHERE job = _job AND state IN (6, 7) AND state <> 1;

            UPDATE sw.t_jobs
            SET state = 2
            WHERE job = _job AND state <> 2;

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


ALTER PROCEDURE sw.reset_aggregation_job(IN _job integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_aggregation_job(IN _job integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.reset_aggregation_job(IN _job integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'ResetAggregationJob';

