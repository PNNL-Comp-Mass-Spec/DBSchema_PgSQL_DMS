--
CREATE OR REPLACE PROCEDURE public.create_pending_predefined_analysis_tasks
(
    _maxDatasetsToProcess int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates analysis jobs for new entries in t_predefined_analysis_scheduling_queue
**
**      Should be called periodically by a SQL Server Agent job
**
**  Arguments:
**    _maxDatasetsToProcess     Set to a positive number to limit the number of affected datasets
**    _infoOnly                 When true, preview jobs that would be created
**    _message                  Output message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   08/26/2010 grk - Initial version
**          08/26/2010 mem - Added _maxDatasetsToProcess and _infoOnly
**                         - Now passing _preventDuplicateJobs to CreatePredefinedAnalysisJobs
**          03/27/2013 mem - Now obtaining Dataset name from T_Dataset
**          07/21/2016 mem - Fix logic error examining _myError
**          05/30/2018 mem - Do not create predefined jobs for inactive datasets
**          03/25/2020 mem - Append a row to T_Predefined_Analysis_Scheduling_Queue_History for each dataset processed
**          12/15/2024 mem - Ported to PostgreSQL
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

        If Coalesce(_currentItem.DatasetName, '') = '' Then
            -- Dataset not defined; skip this entry
            _message := 'Invalid entry: dataset name must be specified';
            _returnCode := 'U5250';

        ElsIf _datasetStateId = 4
            -- Dataset state is Inactive
            _message := 'Inactive dataset: will not create predefined jobs';
            _returnCode := 'U5260';

        Else

            CALL public.create_predefined_analysis_jobs (
                            _datasetName                => currentItem.DatasetName,
                            _callingUser                => currentItem.CallingUser,
                            _analysisToolNameFilter     => currentItem.AnalysisToolNameFilter,
                            _excludeDatasetsNotReleased => currentItem.ExcludeDatasetsNotReleased,
                            _preventDuplicateJobs       => currentItem.PreventDuplicateJobs,
                            _infoOnly                   => _infoOnly,
                            _showDebug                  => false,
                            _message                    => _message,        -- Output
                            _returnCode                 => _returnCode,     -- Output
                            _jobsCreated                => _jobsCreated);   -- Output

        End If;

        If Not _infoOnly Then
            UPDATE t_predefined_analysis_scheduling_queue
            SET message = _message,
                result_code = _returnCode,
                state = CASE
                            WHEN _returnCode = 'U5260' THEN 'Skipped'
                            WHEN _returnCode <> '' THEN 'Error'
                            ELSE 'Complete'
                        END,
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
            _message := format('Processed %s %s', _datasetsProcessed, public.check_plural(_datasetsProcessed, 'dataset', 'datasets'))
        End If;

        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.create_pending_predefined_analysis_tasks IS 'CreatePendingPredefinedAnalysisTasks or CreatePendingPredefinedAnalysesTasks';
