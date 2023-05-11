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
**      Validates job and dataset states vs. DMS_Pipeline and DMS_Capture
**
**  Auth:   mem
**  Date:   11/11/2016 mem - Initial Version
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _itemList text;
    _message text;
    _callingProcName text;
    _currentLocation text := 'Start';

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
        )

        CREATE TEMP TABLE Tmp_Jobs (
            Job int not null,
            State_Old int not null,
            State_New int not null
        )

        ---------------------------------------------------
        -- Look for datasets with an incorrect state
        ---------------------------------------------------
        --
        _currentLocation := 'Populate Tmp_Datasets';

        -- Find datasets with a complete DatasetCapture task, yet a state of 1 or 2 in DMS5
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
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        ---------------------------------------------------
        -- Look for analysis jobs with an incorrect state
        ---------------------------------------------------
        --
        _currentLocation := 'Populate Tmp_Jobs';

        -- Find jobs complete in DMS_Pipeline, yet a state of 1, 2, or 8 in DMS5
        -- Exclude jobs that finished within the last 2 hours
        --
        INSERT INTO Tmp_Jobs (job, State_Old, State_New)
        SELECT J.job, J.job_state_id, PipelineQ.NewState
        FROM t_analysis_job J
             INNER JOIN ( SELECT job, State AS NewState
                          FROM S_V_Pipeline_Jobs_ActiveOrComplete
                          WHERE State IN (4, 7, 14) AND
                                Finish < CURRENT_TIMESTAMP - INTERVAL '1 hour'
                        ) PipelineQ
               ON J.job = PipelineQ.job
        WHERE (J.job_state_id IN (1, 2, 8))
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _infoOnly Then
        -- <Preview>
            _currentLocation := 'Preview the updates';

            SELECT Src.*,
                   DS.dataset AS Dataset
            FROM Tmp_Datasets Src
                 INNER JOIN t_dataset DS
                   ON Src.dataset_id = DS.dataset_id

            SELECT Src.*,
                   T.analysis_tool AS Tool,
                   DS.dataset AS Dataset
            FROM Tmp_Jobs Src
                 INNER JOIN t_analysis_job J
                   ON Src.job = J.job
                 INNER JOIN t_analysis_tool T
                   ON J.analysis_tool_id = T.analysis_tool_id
                 INNER JOIN t_dataset DS
                   ON J.dataset_id = DS.dataset_id

        Else
        -- <ApplyChanges>
            -- Update items
            If Exists (Select * FROM Tmp_Datasets) Then
            -- <datasets>
                _currentLocation := 'Update datasets';

                UPDATE t_dataset
                SET dataset_state_id = Src.State_New
                FROM t_dataset Target

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE t_dataset
                **   SET ...
                **   FROM source
                **   WHERE source.id = t_dataset.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_Datasets Src
                       ON Src.Dataset_ID = Target.Dataset_ID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                -- Log the update
                --
                _itemList := '';

                SELECT string_agg(Dataset_ID::text, ',')
                INTO _itemList
                FROM Tmp_Datasets
                ORDER BY Dataset_ID

                _message := format('Updated dataset state for %s dataset %s due to mismatch with DMS_Capture: %s',
                                        _myRowCount,
                                        CASE WHEN _itemList LIKE '%,%' THEN 'IDs' ELSE 'ID' END,
                                        _itemList);

                Call post_log_entry ('Warning', _message, 'Validate_Job_Dataset_States');
            End If; -- </datasets>

            If Exists (Select * FROM Tmp_Jobs) Then
            -- <jobs>
                _currentLocation := 'Update analysis jobs';

                UPDATE t_analysis_job
                SET job_state_id = Src.State_New
                FROM t_analysis_job Target

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE t_analysis_job
                **   SET ...
                **   FROM source
                **   WHERE source.id = t_analysis_job.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_Jobs Src
                       ON Src.Job = Target.job
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                -- Log the update
                --
                _itemList := '';

                SELECT string_agg(Job::int, ',')
                INTO _itemList
                FROM Tmp_Jobs
                ORDER BY Job

                _message := format('Updated job state for %s %s due to mismatch with DMS_Pipeline: %s',
                                    _myRowCount,
                                    CASE WHEN _itemList LIKE '%,%' THEN 'jobs' ELSE 'job' END,
                                    _itemList);

                Call post_log_entry ('Warning', _message, 'Validate_Job_Dataset_States');
            End If; -- </jobs>

        End If; -- </ApplyChanges>

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
