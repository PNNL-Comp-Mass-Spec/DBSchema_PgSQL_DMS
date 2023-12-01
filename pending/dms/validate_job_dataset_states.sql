--
CREATE OR REPLACE PROCEDURE public.validate_job_dataset_states
(
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates job and dataset states vs. sw.t_jobs and cap.t_tasks
**
**  Arguments:
**    _infoOnly     When true, preview updates
**
**  Auth:   mem
**  Date:   11/11/2016 mem - Initial Version
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _itemList text;
    _message text;
    _callingProcName text;
    _currentLocation text := 'Start';

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
    BEGIN

        _infoOnly := Coalesce(_infoOnly, false);

        CREATE TEMP TABLE Tmp_Datasets (
            Dataset_ID int not null,
            State_Old int not null,
            State_New int not null
        );

        CREATE TEMP TABLE Tmp_Jobs (
            Job int not null,
            State_Old int not null,
            State_New int not null
        );

        ---------------------------------------------------
        -- Look for datasets with an incorrect state
        ---------------------------------------------------

        _currentLocation := 'Populate Tmp_Datasets';

        -- Find datasets with a complete DatasetCapture task, yet a state of 1 or 2 in public.t_dataset
        -- Exclude datasets that finished within the last 2 hours
        --
        INSERT INTO Tmp_Datasets (dataset_id, State_Old, State_New)
        SELECT DS.dataset_id, DS.dataset_state_id, PipelineQ.NewState
        FROM t_dataset DS
             INNER JOIN ( SELECT dataset_id, State AS NewState
                          FROM cap.V_Capture_Tasks_Active_Or_Complete
                          WHERE Script = 'DatasetCapture' AND
                                State = 3 AND
                                Finish < CURRENT_TIMESTAMP - INTERVAL '1 hour'
                        ) PipelineQ
               ON DS.dataset_id = PipelineQ.dataset_id
        WHERE DS.dataset_state_id IN (1, 2)

        ---------------------------------------------------
        -- Look for analysis jobs with an incorrect state
        ---------------------------------------------------

        _currentLocation := 'Populate Tmp_Jobs';

        -- Find jobs complete in sw.t_jobs, yet a state of 1, 2, or 8 in public.t_analysis_job
        -- Exclude jobs that finished within the last 2 hours
        --
        INSERT INTO Tmp_Jobs (job, State_Old, State_New)
        SELECT J.job, J.job_state_id, PipelineQ.NewState
        FROM t_analysis_job J
             INNER JOIN ( SELECT job, State AS NewState
                          FROM sw.V_Pipeline_Jobs_Active_Or_Complete
                          WHERE State IN (4, 7, 14) AND
                                Finish < CURRENT_TIMESTAMP - INTERVAL '1 hour'
                        ) PipelineQ
               ON J.job = PipelineQ.job
        WHERE J.job_state_id IN (1, 2, 8);

        If _infoOnly Then

            _currentLocation := 'Preview the updates';

            RAISE INFO '';

            _formatSpecifier := '%-10s %-9s %-9s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'State_Old',
                                'State_New',
                                'Dataset'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '---------',
                                         '---------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Src.Dataset_ID,
                       Src.State_Old,
                       Src.State_New,
                       DS.Dataset
                FROM Tmp_Datasets Src
                     INNER JOIN t_dataset DS
                       ON Src.dataset_id = DS.dataset_id
                ORDER BY Src.Dataset_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.State_Old,
                                    _previewData.State_New,
                                    _previewData.Dataset
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            RAISE INFO '';

            _formatSpecifier := '%-10s %-9s %-9s %-25s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'State_Old',
                                'State_New',
                                'Tool',
                                'Dataset'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '---------',
                                         '---------',
                                         '-------------------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Src.Job,
                       Src.State_Old,
                       Src.State_New,
                       T.analysis_tool AS Tool,
                       DS.Dataset
                FROM Tmp_Jobs Src
                     INNER JOIN t_analysis_job J
                       ON Src.job = J.job
                     INNER JOIN t_analysis_tool T
                       ON J.analysis_tool_id = T.analysis_tool_id
                     INNER JOIN t_dataset DS
                       ON J.dataset_id = DS.dataset_id
                ORDER BY Src.Job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.State_Old,
                                    _previewData.State_New,
                                    _previewData.Tool,
                                    _previewData.Dataset
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_Datasets;
            DROP TABLE Tmp_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Update tables
        ---------------------------------------------------

        If Exists (Select * FROM Tmp_Datasets) Then

            _currentLocation := 'Update datasets';

            UPDATE t_dataset Target
            SET dataset_state_id = Src.State_New
            FROM Tmp_Datasets Src
            WHERE Src.Dataset_ID = Target.Dataset_ID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            -- Log the update
            --
            SELECT string_agg(Dataset_ID::text, ',' ORDER BY Dataset_ID)
            INTO _itemList
            FROM Tmp_Datasets;

            _message := format('Updated dataset state for %s dataset %s due to mismatch with cap.t_tasks: %s',
                                    _updateCount,
                                    public.check_plural(_updateCount, 'ID', 'IDs'),
                                    _itemList);

            CALL post_log_entry ('Warning', _message, 'Validate_Job_Dataset_States');
        End If;

        If Exists (SELECT * FROM Tmp_Jobs) Then

            _currentLocation := 'Update analysis jobs';

            UPDATE t_analysis_job Target
            SET job_state_id = Src.State_New
            FROM Tmp_Jobs Src
            WHERE Src.Job = Target.job;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            -- Log the update
            --
            SELECT string_agg(Job::text, ',' ORDER BY Job)
            INTO _itemList
            FROM Tmp_Jobs;

            _message := format('Updated job state for %s %s due to mismatch with sw.t_jobs: %s',
                                _updateCount,
                                public.check_plural(_updateCount, 'job', 'jobs'),
                                _itemList);

            CALL post_log_entry ('Warning', _message, 'Validate_Job_Dataset_States');
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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_Datasets;
    DROP TABLE IF EXISTS Tmp_Jobs;
END
$$;

COMMENT ON PROCEDURE public.validate_job_dataset_states IS 'ValidateJobDatasetStates';
