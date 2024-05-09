--
-- Name: update_cached_dataset_stats(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_dataset_stats(IN _processingmode integer DEFAULT 0, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update job counts in t_cached_dataset_stats, which is used by the dataset detail report view (v_dataset_detail_report_ex)
**
**      This procedure does not update cached instrument info for existing rows in t_cached_dataset_stats
**      - Use procedure update_cached_dataset_instruments to update the cached instrument name and ID
**
**  Arguments:
**    _processingMode   Processing mode:
**                      0 to only process new datasets and datasets with update_required = 1
**                      1 to process new datasets, those with update_required = 1, and the 10,000 most recent datasets in DMS
**                      2 to re-process all of the entries in t_cached_dataset_stats (this is the slowest update)
**    _showDebug        When true, show debug info
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   05/08/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _matchCount int;
    _updateCount int;
    _rowCountUpdated int := 0;
    _minimumDatasetID int := 0;
    _datasetIdStart int;
    _datasetIdEnd int;
    _datasetIdMax int;
    _datasetBatchSize int;
    _currentBatchDatasetIdStart int;
    _currentBatchDatasetIdEnd int;
    _addon text;
    _startTime timestamp;
    _runtimeSeconds numeric;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _processingMode := Coalesce(_processingMode, 0);
    _showDebug      := Coalesce(_showDebug, false);

    _startTime := clock_timestamp();

    If _processingMode IN (0, 1) Then
        SELECT MIN(dataset_id)
        INTO _minimumDatasetID
        FROM (SELECT dataset_id
              FROM t_dataset
              ORDER BY dataset_id DESC
              LIMIT 10000) LookupQ;

        If Not FOUND Then
            _minimumDatasetID := 0;
        End If;
    End If;

    If _showDebug Then
        RAISE INFO '';
    End If;

    ------------------------------------------------
    -- Add new datasets to t_cached_dataset_stats
    -- Instrument name and ID are required because the columns cannot have null values
    ------------------------------------------------

    INSERT INTO t_cached_dataset_stats (dataset_id,
                                        instrument_id,
                                        instrument)
    SELECT DS.dataset_id,
           DS.instrument_id,
           InstName.instrument
    FROM t_dataset DS
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         LEFT OUTER JOIN t_cached_dataset_stats CachedStats
           ON DS.dataset_id = CachedStats.dataset_id
    WHERE CachedStats.dataset_id IS NULL;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _message := format('Added %s new %s', _matchCount, check_plural(_matchCount, 'dataset', 'datasets'));

        If _showDebug Then
            RAISE INFO '%', _message;
        End If;
    End If;

    SELECT MAX(dataset_id)
    INTO _datasetIdMax
    FROM t_cached_dataset_stats;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If Not FOUND Then
        _datasetIdMax := 2147483647;
    End If;

    If _processingMode >= 2 And _datasetIdMax < 2147483647 Then
        _datasetBatchSize := 50000;
    Else
        _datasetBatchSize := 0;
    End If;

    -- Cache the Dataset IDs to update
    CREATE TEMP TABLE Tmp_Dataset_IDs (
        dataset_id int NOT NULL PRIMARY KEY
    );

    If _processingMode IN (0, 1) Then
        ------------------------------------------------
        -- Find datasets with update_required > 0
        -- If _processingMode is 1, also process the 10,000 most recent datasets, regardless of the value of update_required
        --
        -- Notes regarding t_analysis_job
        --   Trigger trig_t_analysis_job_after_insert      will set update_required to 1 when an analysis job is added to t_analysis_job
        --   Trigger trig_t_analysis_job_after_update_rows will set update_required to 1 when the dataset_id column is updated in t_analysis_job
        --   Trigger trig_t_analysis_job_after_delete_row  will set update_required to 1 when a job is deleted from t_analysis_job
        ------------------------------------------------

        If _processingMode = 0 Then
            INSERT INTO Tmp_Dataset_IDs (dataset_id)
            SELECT dataset_id
            FROM t_cached_dataset_stats
            WHERE update_required > 0;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;
        Else
            INSERT INTO Tmp_Dataset_IDs (dataset_id)
            SELECT dataset_id
            FROM t_cached_dataset_stats
            WHERE update_required > 0
            UNION
            SELECT dataset_id
            FROM t_dataset
            WHERE dataset_id >= _minimumDatasetID;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;
        End If;

        If _matchCount > 50000 And _datasetBatchSize = 0 Then
            _datasetBatchSize := 50000;
        End If;

        If _showDebug Then
            RAISE INFO 'Updating cached stats for % % in t_cached_dataset_stats where %',
                     _matchCount,
                     public.check_plural(_matchCount, 'row', 'rows'),
                     CASE WHEN _processingMode = 0
                          THEN 'update_required is 1'
                          ELSE format('dataset_id >= %s Or update_required is 1', _minimumDatasetID)
                     END;
        End If;
    Else
        ------------------------------------------------
        -- Process all datasets in t_cached_dataset_stats since _processingMode is 2
        ------------------------------------------------

        INSERT INTO Tmp_Dataset_IDs (dataset_id)
        SELECT dataset_id
        FROM t_cached_dataset_stats;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _showDebug Then
            If _datasetBatchSize > 0 Then
                RAISE INFO 'Updating cached stats for all rows in t_cached_dataset_stats, processing % datasets at a time', _datasetBatchSize;
            Else
                RAISE INFO 'Updating cached stats for all rows in t_cached_dataset_stats; note that batch size is 0, which should never be the case';
            End If;
        End If;
    End If;

    If Not Exists (SELECT dataset_id FROM Tmp_Dataset_IDs) Then
        If _showDebug Then
            RAISE INFO 'Exiting, since nothing to do';
        End If;

        DROP TABLE Tmp_Dataset_IDs;
        RETURN;
    End If;

    _datasetIdStart := 0;

    If _datasetBatchSize > 0 Then
        _datasetIdEnd := _datasetIdStart + _datasetBatchSize - 1;
    Else
        _datasetIdEnd := _datasetIdMax;
    End If;

    WHILE true
    LOOP
        If _datasetBatchSize > 0 Then
            _currentBatchDatasetIdStart := _datasetIdStart;
            _currentBatchDatasetIdEnd   := _datasetIdEnd;

            If _showDebug Then
                RAISE INFO 'Updating Dataset IDs % to %', _datasetIdStart, _datasetIdEnd;
            End If;
        Else
            SELECT Min(Dataset_ID),
                   Max(Dataset_ID)
            INTO _currentBatchDatasetIdStart, _currentBatchDatasetIdEnd
            FROM Tmp_Dataset_IDs;

            If _showDebug Then
                RAISE INFO 'Updating Dataset IDs % to %', _currentBatchDatasetIdStart, _currentBatchDatasetIdEnd;
            End If;
        End If;

        ------------------------------------------------
        -- Update job counts for entries in Tmp_Dataset_IDs
        ------------------------------------------------

        UPDATE t_cached_dataset_stats
        SET Job_Count     = Coalesce(StatsQ.Job_Count, 0),
            PSM_Job_Count = Coalesce(StatsQ.PSM_Job_Count, 0)
        FROM (SELECT DS.Dataset_ID,
                     JobsQ.Job_Count,
                     PSMJobsQ.PSM_Job_Count
              FROM Tmp_Dataset_IDs DS
                   LEFT OUTER JOIN (SELECT J.dataset_id,
                                           COUNT(J.job) AS Job_Count
                                    FROM t_analysis_job J
                                    WHERE J.dataset_ID BETWEEN _currentBatchDatasetIdStart AND _currentBatchDatasetIdEnd
                                    GROUP BY J.dataset_id
                                   ) AS JobsQ
                     ON JobsQ.dataset_id = DS.Dataset_ID
                   LEFT OUTER JOIN (SELECT J.dataset_id,
                                           COUNT(PSMs.job) AS PSM_Job_Count
                                    FROM t_analysis_job_psm_stats PSMs
                                         INNER JOIN t_analysis_job J ON PSMs.job = J.job
                                    WHERE J.dataset_ID BETWEEN _currentBatchDatasetIdStart AND _currentBatchDatasetIdEnd
                                    GROUP BY J.dataset_id
                                   ) AS PSMJobsQ
                     ON PSMJobsQ.dataset_id = DS.Dataset_ID
              WHERE DS.Dataset_ID BETWEEN _datasetIdStart AND _datasetIdEnd
             ) StatsQ
        WHERE t_cached_dataset_stats.dataset_id = StatsQ.Dataset_ID AND
              (t_cached_dataset_stats.Job_Count       <> Coalesce(StatsQ.Job_Count, 0) OR
               t_cached_dataset_stats.PSM_Job_Count   <> Coalesce(StatsQ.PSM_Job_Count, 0));
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _rowCountUpdated := _rowCountUpdated + _matchCount;

        If _datasetBatchSize <= 0 Then
            UPDATE t_cached_dataset_stats
            SET update_required = 0
            WHERE update_required > 0 AND
                  dataset_id IN (SELECT DS.dataset_id FROM Tmp_Dataset_IDs DS);

            -- Break out of the while loop
            EXIT;
        End If;

        UPDATE t_cached_dataset_stats
        SET update_required = 0
        WHERE update_required > 0 AND
              dataset_id IN (SELECT DS.dataset_id
                             FROM Tmp_Dataset_IDs DS
                             WHERE DS.dataset_id BETWEEN _datasetIdStart AND _datasetIdEnd);

        _datasetIdStart := _datasetIdStart + _datasetBatchSize;
        _datasetIdEnd   := _datasetIdEnd   + _datasetBatchSize;

        If _datasetIdStart > _datasetIdMax Then
            -- Break out of the while loop
            EXIT;
        End If;

    END LOOP;

    If _rowCountUpdated > 0 Then
        _addon := format('Updated %s %s in t_cached_dataset_stats', _rowCountUpdated, public.check_plural(_rowCountUpdated, 'row', 'rows'));
        _message := public.append_to_text(_message, _addon);

        -- CALL post_log_entry ('Debug', _message, 'update_cached_dataset_stats');
    End If;

    _runtimeSeconds := Round(Extract(epoch from (clock_timestamp() - _startTime)), 3);

    If _showDebug Or _runtimeSeconds > 5 Then
        RAISE INFO 'Processing time: % seconds', _runtimeSeconds;
    End If;

    DROP TABLE Tmp_Dataset_IDs;
END
$$;


ALTER PROCEDURE public.update_cached_dataset_stats(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

