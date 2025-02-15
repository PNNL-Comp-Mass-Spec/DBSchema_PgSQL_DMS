--
-- Name: create_pending_predefined_analysis_tasks(integer, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.create_pending_predefined_analysis_tasks(IN _maxdatasetstoprocess integer DEFAULT 0, IN _datasetid integer DEFAULT 0, IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create analysis jobs for new entries in t_predefined_analysis_scheduling_queue
**
**      Should be called periodically by a SQL Server Agent job or a pgAgent/pg_timetable task
**
**  Arguments:
**    _maxDatasetsToProcess     Set to a positive number to limit the number of affected datasets
**    _datasetID                When non-zero, only create jobs for the given dataset ID
**    _infoOnly                 When true, preview jobs that would be created
**    _showDebug                When true, show debug messages
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   08/26/2010 grk - Initial version
**          08/26/2010 mem - Add arguments_maxDatasetsToProcess and _infoOnly
**                         - Now passing _preventDuplicateJobs to CreatePredefinedAnalysisJobs
**          03/27/2013 mem - Now obtaining Dataset name from T_Dataset
**          07/21/2016 mem - Fix logic error examining _myError
**          05/30/2018 mem - Do not create predefined jobs for inactive datasets
**          03/25/2020 mem - Append a row to T_Predefined_Analysis_Scheduling_Queue_History for each dataset processed
**          12/13/2023 mem - Add argument _datasetID, which can be used to process a single dataset
**                         - Ported to PostgreSQL
**          08/14/2024 mem - Add argument _showDebug
**          02/15/2025 mem - Set update_required to 1 in t_cached_dataset_stats
**
*****************************************************/
DECLARE
    _continue boolean;
    _currentItemID int;
    _currentItem record;
    _resultCode int;
    _queueState text;
    _datasetsProcessed int;
    _jobsCreated int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _maxDatasetsToProcess := Coalesce(_maxDatasetsToProcess, 0);
    _datasetID            := Coalesce(_datasetID, 0);
    _infoOnly             := Coalesce(_infoOnly, false);
    _showDebug            := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Process 'New' entries in t_predefined_analysis_scheduling_queue
    ---------------------------------------------------

    _currentItemID := 0;
    _datasetsProcessed := 0;
    _continue := true;

    WHILE _continue
    LOOP
        SELECT SQ.item AS ItemID,
               SQ.dataset_id AS DatasetID,
               DS.dataset AS DatasetName,
               DS.dataset_rating_id AS DatasetRatingID,
               DS.dataset_state_id AS DatasetStateId,
               SQ.calling_user AS CallingUser,
               SQ.analysis_tool_name_filter AS AnalysisToolNameFilter,
               CASE WHEN SQ.exclude_datasets_not_released > 0 THEN true ELSE false END AS ExcludeDatasetsNotReleased,
               CASE WHEN SQ.prevent_duplicate_jobs > 0        THEN true ELSE false END AS PreventDuplicateJobs
        INTO _currentItem
        FROM t_predefined_analysis_scheduling_queue SQ
             INNER JOIN t_dataset DS
               ON SQ.dataset_id = DS.dataset_id
        WHERE SQ.state = 'New' AND
              SQ.item > _currentItemID AND
              (_datasetID = 0 OR SQ.dataset_id = _datasetID)
        ORDER BY SQ.item ASC
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        _currentItemID := _currentItem.ItemID;

        If _infoOnly Or _showDebug Then
            RAISE INFO '';
            RAISE INFO 'Process Item %: %', _currentItemID, _currentItem.DatasetName;
        End If;

        If Coalesce(_currentItem.DatasetName, '') = '' Then
            -- Dataset not defined; skip this entry
            _message := 'Invalid entry: dataset name must be specified';
            _returnCode := 'U5610';

        ElsIf _currentItem.DatasetStateId = 4 Then
            -- Dataset state is Inactive; procedure create_pending_predefined_analysis_tasks also uses 'U5260' for this warning
            _message := 'Inactive dataset: will not create predefined jobs';
            _returnCode := 'U5260';

        Else
            CALL public.create_predefined_analysis_jobs (
                            _datasetName                => _currentItem.DatasetName,
                            _callingUser                => _currentItem.CallingUser,
                            _analysisToolNameFilter     => _currentItem.AnalysisToolNameFilter,
                            _excludeDatasetsNotReleased => _currentItem.ExcludeDatasetsNotReleased,
                            _preventDuplicateJobs       => _currentItem.PreventDuplicateJobs,
                            _infoOnly                   => _infoOnly,
                            _showDebug                  => _showDebug,
                            _message                    => _message,        -- Output
                            _returnCode                 => _returnCode,     -- Output
                            _jobsCreated                => _jobsCreated);   -- Output

            If _jobsCreated > 0 Then
                UPDATE t_cached_dataset_stats
                SET update_required = 1
                WHERE dataset_id = _currentItem.DatasetID;
            End If;
        End If;

        _returnCode := Upper(Trim(Coalesce(_returnCode, '')));

        -- Return code 'U5250' means 'Job not created since duplicate job exists'        (in add_update_analysis_job)
        -- Return code 'U5260' means 'Inactive dataset: will not create predefined jobs' (in create_pending_predefined_analysis_tasks and this procedure)
        -- Return codes 'U6251', 'U6253', 'U6254' are warnings from validate_analysis_job_request_datasets and are non-critical errors

        If _infoOnly Then
            If _returnCode IN ('U5250', 'U5260', 'U6251', 'U6253', 'U6254') Then
                -- These are warnings; change _returnCode to an empty string
                _returnCode := '';
            End If;
        Else
            If Upper(Trim(Coalesce(_returnCode, ''))) IN ('', 'U5250', 'U5260', 'U6251', 'U6253', 'U6254') Then
                _resultCode := 0;
                _queueState := CASE WHEN _returnCode = 'U5260' THEN 'Skipped' ELSE 'Complete' END;

                -- Change _returnCode to an empty string
                _returnCode := '';
            Else
                _resultCode := Coalesce(public.extract_integer(_returnCode), -1);
                _queueState := CASE WHEN _returnCode <> '' THEN 'Error' ELSE 'Complete' END;
            End If;

            UPDATE t_predefined_analysis_scheduling_queue
            SET message = _message,
                result_code = _resultCode,
                state = _queueState,
                Jobs_Created = Coalesce(_jobsCreated, 0),
                Last_Affected = CURRENT_TIMESTAMP
            WHERE Item = _currentItemID;

            INSERT INTO t_predefined_analysis_scheduling_queue_history (
                dataset_id,
                dataset_rating_id,
                jobs_created
            )
            VALUES (_currentItem.DatasetID, _currentItem.DatasetRatingID, Coalesce(_jobsCreated, 0));
        End If;

        _datasetsProcessed := _datasetsProcessed + 1;

        If _maxDatasetsToProcess > 0 And _datasetsProcessed >= _maxDatasetsToProcess Then
            _continue := false;
        End If;

    END LOOP;

    If _infoOnly Or _showDebug Then
        If _datasetsProcessed = 0 Then
            _message := 'No candidates were found in t_predefined_analysis_scheduling_queue';
        Else
            _message := format('Processed %s %s', _datasetsProcessed, public.check_plural(_datasetsProcessed, 'dataset', 'datasets'));
        End If;

        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.create_pending_predefined_analysis_tasks(IN _maxdatasetstoprocess integer, IN _datasetid integer, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE create_pending_predefined_analysis_tasks(IN _maxdatasetstoprocess integer, IN _datasetid integer, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.create_pending_predefined_analysis_tasks(IN _maxdatasetstoprocess integer, IN _datasetid integer, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) IS 'CreatePendingPredefinedAnalysisTasks or CreatePendingPredefinedAnalysesTasks';

