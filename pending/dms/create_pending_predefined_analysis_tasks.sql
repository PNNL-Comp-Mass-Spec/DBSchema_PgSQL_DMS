--
CREATE OR REPLACE PROCEDURE public.create_pending_predefined_analysis_tasks
(
    _maxDatasetsToProcess int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates job for new entries in T_Predefined_Analysis_Scheduling_Queue
**
**      Should be called periodically by a SQL Server Agent job
**
**  Arguments:
**    _maxDatasetsToProcess   Set to a positive number to limit the number of affected datasets
**
**  Auth:   grk
**  Date:   08/26/2010 grk - initial release
**          08/26/2010 mem - Added _maxDatasetsToProcess and _infoOnly
**                         - Now passing _preventDuplicateJobs to CreatePredefinedAnalysisJobs
**          03/27/2013 mem - Now obtaining Dataset name from T_Dataset
**          07/21/2016 mem - Fix logic error examining _myError
**          05/30/2018 mem - Do not create predefined jobs for inactive datasets
**          03/25/2020 mem - Append a row to T_Predefined_Analysis_Scheduling_Queue_History for each dataset processed
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _continue boolean;
    _currentItemID int;
    _currentItem record;
    _datasetsProcessed int;
    _jobsCreated int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _maxDatasetsToProcess := Coalesce(_maxDatasetsToProcess, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Process 'New' entries in t_predefined_analysis_scheduling_queue
    ---------------------------------------------------

    _currentItemID := 0;
    _datasetsProcessed := 0;
    _continue := true;

    While _continue
    LOOP
        _datasetName := '';
        _datasetStateId := 0;

        SELECT SQ.item As ItemID
               SQ.dataset_id As DatasetID,
               DS.dataset As DatasetName,
               DS.dataset_rating_id As DatasetRatingID,
               DS.dataset_state_id As DatasetStateId,
               SQ.calling_user As CallingUser,
               SQ.analysis_tool_name_filter As AnalysisToolNameFilter,
               Case When SQ.exclude_datasets_not_released > 0 Then true Else false End As ExcludeDatasetsNotReleased,
               Case When SQ.prevent_duplicate_jobs > 0 Then true Else false End As PreventDuplicateJobs
        INTO _currentItem
        FROM t_predefined_analysis_scheduling_queue SQ
             INNER JOIN t_dataset DS
               ON SQ.dataset_id = DS.dataset_id
        WHERE SQ.state = 'New' AND
              SQ.item > _currentItemID
        ORDER BY SQ.item ASC
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the For loop
            EXIT;
        End If;

        _currentItemID := _currentItem.ItemID;

        If _infoOnly Then
            RAISE INFO 'Process Item %: %', _currentItemID, _currentItem.DatasetName;
        End If;

        If Coalesce(_currentItem.DatasetNam, '') = '' Then
            -- Dataset not defined; skip this entry
            _returnCode := 'U5250';
            _message := 'Invalid entry: dataset name is blank';

        ElsIf _datasetStateId = 4
            -- Dataset state is Inactive
            _returnCode := 'U5260';
            _message := 'Inactive dataset: will not create predefined jobs';

        Else

            Call create_predefined_analysis_jobs (
                                            currentItem.DatasetName,
                                            currentItem.CallingUser,
                                            currentItem.AnalysisToolNameFilter,
                                            currentItem.ExcludeDatasetsNotReleased,
                                            currentItem.PreventDuplicateJobs,
                                            _infoOnly,
                                            _message => _message,
                                            _jobsCreated => _jobsCreated,
                                            _returnCode => _returnCode);

        End If;

        If Not _infoOnly Then
            UPDATE t_predefined_analysis_scheduling_queue
            SET message = _message,
                result_code = _returnCode,
                state = CASE
                            WHEN _returnCode = 'U5260' THEN 'Skipped'
                            WHEN _returnCode <> '' THEN 'Error'
                            ELSE 'Complete'
                        End If;,
                Jobs_Created = Coalesce(_jobsCreated, 0),
                Last_Affected = CURRENT_TIMESTAMP
            WHERE Item = _currentItemID;

            INSERT INTO t_predefined_analysis_scheduling_queue_history( dataset_id, dataset_rating_id, jobs_created )
            VALUES (_currentItem.DatasetID, _currentItem.DatasetRatingID, Coalesce(_jobsCreated, 0));
        End If;

        _datasetsProcessed := _datasetsProcessed + 1;

        If _maxDatasetsToProcess > 0 And _datasetsProcessed >= _maxDatasetsToProcess Then
            _continue := false;
        End If;

    END LOOP;

    If _infoOnly Then
        If _datasetsProcessed = 0 Then
            _message := 'No candidates were found in t_predefined_analysis_scheduling_queue';
        Else
            _message := 'Processed ' || _datasetsProcessed::text || ' dataset';
            If _datasetsProcessed <> 1 Then
                _message := _message || 's';
            End If;
        End If;

        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.create_pending_predefined_analysis_tasks IS 'CreatePendingPredefinedAnalysisTasks or CreatePendingPredefinedAnalysesTasks';
