--
-- Name: update_cached_dataset_links(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_dataset_links(IN _processingmode integer DEFAULT 0, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_cached_dataset_links, which is used by the dataset detail report view (v_dataset_detail_report_ex)
**
**  Arguments:
**    _processingMode   Processing mode:
**                      0 to only process new datasets and datasets with update_required = 1
**                      1 to process new datasets, those with update_required = 1, and the 10,000 most recent datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
**                      2 to process new datasets, those with update_required = 1, and all datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
**                      3 to re-process all of the entries in T_Cached_Dataset_Links (this is the slowest update and will take ~20 seconds)
**    _showDebug        When true, show debug info
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   07/25/2017 mem - Initial version
**          06/12/2018 mem - Send _maxLength to append_to_text
**          07/31/2020 mem - Update MASIC_Directory_Name
**          09/06/2022 mem - When _processingMode is 3, update datasets in batches (to decrease the likelihood of deadlock issues)
**          06/03/2023 mem - Link to the SMAQC P_2C metric for QC_Mam datasets
**          10/06/2023 mem - Update SMAQC metric URLs
**                         - Ported to PostgreSQL
**          01/04/2024 mem - Check for empty strings instead of using char_length()
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
    _addon text;
    _datasetID int;
    _masicDirectoryName text;
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

    If _processingMode In (0, 1) Then
        SELECT MIN(dataset_id)
        INTO _minimumDatasetID
        FROM (SELECT dataset_id
              FROM t_dataset
              ORDER BY dataset_id DESC
              LIMIT 10000) LookupQ;
    End If;

    ------------------------------------------------
    -- Add new datasets to t_cached_dataset_links
    ------------------------------------------------

    INSERT INTO t_cached_dataset_links (
        dataset_id,
        dataset_row_version,
        storage_path_row_version,
        update_required
    )
    SELECT DS.dataset_id,
           DS.xmin,
           DFP.xmin,
           1 AS update_required
    FROM t_dataset DS
         INNER JOIN t_cached_dataset_folder_paths DFP
           ON DS.dataset_id = DFP.dataset_id
         LEFT OUTER JOIN t_cached_dataset_links DL
           ON DL.dataset_id = DS.dataset_id
    WHERE DS.dataset_id >= _minimumDatasetID AND
          DL.dataset_id IS NULL;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _message := format('Added %s new %s', _matchCount, public.check_plural(_matchCount, 'dataset', 'datasets'));
    End If;

    SELECT MAX(dataset_id)
    INTO _datasetIdMax
    FROM t_cached_dataset_links;

    If _datasetIdMax Is Null Then
        _datasetIdMax := 2147483647;
    End If;

    If _processingMode >= 3 And _datasetIdMax < 2147483647 Then
        _datasetBatchSize := 50000;
    Else
        _datasetBatchSize := 0;
    End If;

    If _showDebug Then
        RAISE INFO '';
    End If;

    If _processingMode In (1, 2) Then
        If _showDebug Then
            RAISE INFO 'Setting update_required to 1 in t_cached_dataset_links for datasets with dataset_id >= % and differing row versions', _minimumDatasetID;
        End If;

        ------------------------------------------------
        -- Find datasets that need to be updated
        --
        -- Notes regarding t_cached_dataset_folder_paths
        --   Trigger trig_t_cached_dataset_folder_paths_after_update will set update_required to 1 when a row is changed in t_cached_dataset_folder_paths
        --
        -- Notes regarding t_dataset_archive
        --   Trigger trig_t_dataset_archive_after_insert will set update_required to 1 when a dataset is added to t_dataset_archive
        --   Trigger trig_t_dataset_archive_after_update will set update_required to 1 when any of the following columns is updated:
        --     archive_state_id, storage_path_id, instrument_data_purged, myemsl_state, qc_data_purged
        ------------------------------------------------

        ------------------------------------------------
        -- Find existing entries with a mismatch in dataset_row_version or storage_path_row_version
        ------------------------------------------------

        UPDATE t_cached_dataset_links DL
        SET update_required = 1
        FROM t_cached_dataset_folder_paths DFP
        WHERE DFP.dataset_id = DL.dataset_id AND
              DL.dataset_id >= _minimumDatasetID AND
              (DL.dataset_row_version IS DISTINCT FROM DFP.dataset_row_version OR
               DL.storage_path_row_version IS DISTINCT FROM DFP.storage_path_row_version);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _addon := format('%s %s on dataset_row_version or storage_path_row_version', _updateCount, public.check_plural(_updateCount, 'dataset differs', 'datasets differ'));
            _message := public.append_to_text(_message, _addon);

            _rowCountUpdated := _rowCountUpdated + _updateCount;
        End If;

    End If;

    If _processingMode < 1 Then

        If _showDebug Then
            RAISE INFO 'Updating MASIC Directory Name in t_cached_dataset_links where update_required is 1 (updating one dataset at a time)';
        End If;

        ------------------------------------------------
        -- Iterate over datasets with update_required > 0  (since there should not be many)
        -- For each, make sure they have an up-to-date MASIC_Directory_Name
        --
        -- This query should be kept in sync with the bulk update query below
        ------------------------------------------------

        FOR _datasetID IN
            SELECT dataset_id
            FROM t_cached_dataset_links
            WHERE update_required > 0
            ORDER BY dataset_id
        LOOP

            SELECT MasicDirectoryName
            INTO _masicDirectoryName
            FROM (SELECT OrderQ.DatasetID,
                         OrderQ.Job,
                         OrderQ.MasicDirectoryName,
                         Row_Number() OVER (PARTITION BY OrderQ.DatasetID
                                            ORDER BY OrderQ.JobStateRank ASC, OrderQ.Job DESC) AS JobRank
                  FROM (SELECT J.dataset_id AS DatasetID,
                               J.job AS Job,
                               J.Results_Folder_Name AS MasicDirectoryName,
                               CASE
                                   WHEN J.job_state_id = 4 THEN 1
                                   WHEN J.job_state_id = 14 THEN 2
                                   ELSE 3
                               END AS JobStateRank
                        FROM t_analysis_job J
                             INNER JOIN t_analysis_tool T
                               ON J.analysis_tool_id = T.analysis_tool_id
                        WHERE J.dataset_id = _datasetID AND
                              T.analysis_tool LIKE 'MASIC%' AND
                              NOT J.results_folder_name IS NULL
                       ) OrderQ
                 ) RankQ
            WHERE JobRank = 1;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _matchCount > 0 And Trim(Coalesce(_masicDirectoryName, '')) <> '' Then
                UPDATE t_cached_dataset_links
                SET masic_directory_name = _masicDirectoryName
                WHERE dataset_id = _datasetID;

                _rowCountUpdated := _rowCountUpdated + 1;
            End If;

        END LOOP;

    Else
        -- _processingMode is 1, 2, or 3

        If _showDebug Then
            If _processingMode >= 3 Then
                If _datasetBatchSize > 0 Then
                    RAISE INFO 'Validating masic_directory_name for all rows in t_cached_dataset_links, processing % datasets at a time', _datasetBatchSize;
                Else
                    RAISE INFO 'Validating masic_directory_name for all rows in t_cached_dataset_links; note that batch size is 0, which should never be the case';
                End If;
            Else
                RAISE INFO 'Updating masic_directory_name in t_cached_dataset_links where update_required is 1 (bulk update)';
            End If;
        End If;

        _datasetIdStart := 0;

        If _datasetBatchSize > 0 Then
            _datasetIdEnd := _datasetIdStart + _datasetBatchSize - 1;
        Else
            _datasetIdEnd := _datasetIdMax;
        End If;

        WHILE true
        LOOP
            ------------------------------------------------
            -- Make sure that entries with update_required > 0 have an up-to-date MASIC_Directory_Name
            -- This is a bulk update query, which can take some time to run, though if _processingMode is 3, datasets are processed in baches
            -- It should be kept in sync with the above query that includes Row_Number()
            ------------------------------------------------

            UPDATE t_cached_dataset_links Target
            SET masic_directory_name = JobDirectoryQ.MasicDirectoryName
            FROM (SELECT DatasetID,
                         MasicDirectoryName
                  FROM (SELECT OrderQ.DatasetID,
                               OrderQ.Job,
                               OrderQ.MasicDirectoryName,
                               Row_Number() OVER (PARTITION BY OrderQ.DatasetID
                                                  ORDER BY OrderQ.JobStateRank ASC, OrderQ.Job DESC) AS JobRank
                        FROM (SELECT J.dataset_id AS DatasetID,
                                     J.job AS Job,
                                     J.Results_Folder_Name AS MasicDirectoryName,
                                     CASE
                                         WHEN J.job_state_id = 4 THEN 1
                                         WHEN J.job_state_id = 14 THEN 2
                                         ELSE 3
                                     END AS JobStateRank
                              FROM t_analysis_job J
                                   INNER JOIN t_analysis_tool T
                                     ON J.analysis_tool_id = T.analysis_tool_id
                              WHERE J.dataset_id BETWEEN _datasetIdStart AND _datasetIdEnd AND
                                    T.analysis_tool LIKE 'MASIC%' AND
                                    NOT J.results_folder_name IS NULL
                             ) OrderQ
                       ) RankQ
                  WHERE JobRank = 1
                 ) JobDirectoryQ
            WHERE (Target.update_required > 0 OR _processingMode >= 3) AND
                  Target.dataset_id = JobDirectoryQ.DatasetID AND
                  Coalesce(Target.MASIC_Directory_Name, '') <> JobDirectoryQ.MasicDirectoryName;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _rowCountUpdated := _rowCountUpdated + _updateCount;

            If _datasetBatchSize <= 0 Then
                -- Break out of the while loop
                EXIT;
            End If;

            _datasetIdStart := _datasetIdStart + _datasetBatchSize;
            _datasetIdEnd   := _datasetIdEnd + _datasetBatchSize;

            If _datasetIdStart > _datasetIdMax Then
                -- Break out of the while loop
                EXIT;
            End If;

        END LOOP;
    End If;

    If _processingMode < 3 Then
        If _showDebug Then
            RAISE INFO 'Updating cached paths for all rows in t_cached_dataset_links where update_required is 1 (bulk update)';
        End If;

        ------------------------------------------------
        -- Update entries with update_required > 0
        -- Note that this query runs 2x faster than the merge statement below
        -- If you update this query, be sure to update the merge statement
        ------------------------------------------------

        UPDATE t_cached_dataset_links Target
        SET dataset_row_version = DFP.dataset_row_version,
            storage_path_row_version = DFP.storage_path_row_version,
            dataset_folder_path = CASE
                WHEN DA.archive_state_id = 4 THEN format('Purged: %s', DFP.dataset_folder_path)
                ELSE CASE
                        WHEN DA.instrument_data_purged > 0 THEN format('Raw Data Purged: %s', DFP.Dataset_Folder_Path)
                        ELSE DFP.Dataset_Folder_Path
                     END
                END,
            archive_folder_path = CASE
                WHEN DA.myemsl_state > 0 And DS.Created >= make_date(2013, 9, 17) THEN ''
                ELSE DFP.Archive_Folder_Path
                END,
            myemsl_url = format('https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/%s', DS.Dataset_ID),
            qc_link = CASE
                WHEN DA.QC_Data_Purged > 0 THEN ''
                ELSE format('%sQC/index.html', DFP.Dataset_URL)
                END,
            qc_2d = CASE
                WHEN DA.QC_Data_Purged > 0 THEN ''
                ELSE format('%s%s/', DFP.Dataset_URL, J.Results_Folder_Name)
                END,
            qc_metric_stats = CASE
                WHEN Experiment SIMILAR TO 'QC[_]Shew%' THEN
                       format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/P_2C/inst/%s/filterDS/QC_Shew', Inst.instrument)
                WHEN Experiment SIMILAR TO 'QC[_]Mam%'  THEN
                       format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/P_2C/inst/%s/filterDS/QC_Mam', Inst.instrument)
                WHEN Experiment SIMILAR TO 'TEDDY[_]DISCOVERY%' THEN
                       format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/qcart/inst/%s/filterDS/TEDDY_DISCOVERY', Inst.instrument)
                ELSE   format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/MS2_Count/inst/%s/filterDS/%s', Inst.instrument, Substring(DS.Dataset, 1, 4))
                END,
            update_required = 0,
            last_affected = CURRENT_TIMESTAMP
        FROM t_dataset DS
             INNER JOIN t_cached_dataset_folder_paths DFP
               ON DFP.dataset_id = DS.dataset_id
             INNER JOIN t_experiments E
               ON E.exp_id = DS.exp_id
             INNER JOIN t_instrument_name Inst
               ON Inst.instrument_id = DS.instrument_id
             LEFT OUTER JOIN t_analysis_job J
               ON DS.decontools_job_for_qc = J.job
             LEFT OUTER JOIN t_dataset_archive DA
                             INNER JOIN t_archive_path AP
                               ON DA.storage_path_id = AP.archive_path_id
               ON DS.dataset_id = DA.dataset_id
        WHERE Target.update_required = 1 AND
              Target.dataset_id = DS.dataset_id;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _rowCountUpdated := _rowCountUpdated + _updateCount;
    Else

        -- _processingMode is 3
        If _showDebug Then
            If _datasetBatchSize > 0 Then
                RAISE INFO 'Updating cached paths for all rows in t_cached_dataset_links, processing % datasets at a time', _datasetBatchSize;
            Else
                RAISE INFO 'Updating cached paths for all rows in t_cached_dataset_links; note that batch size is 0, which should never be the case';
            End If;
        End If;

        _datasetIdStart := 0;

        If _datasetBatchSize > 0 Then
            _datasetIdEnd := _datasetIdStart + _datasetBatchSize - 1;
        Else
            _datasetIdEnd := _datasetIdMax;
        End If;

        WHILE true
        LOOP
            If _showDebug Then
                RAISE INFO 'Updating Dataset IDs % to %', _datasetIdStart, _datasetIdEnd;
            End If;

            ------------------------------------------------
            -- Update all of the entries (if the stored value disagrees)
            --
            -- Note that this merge statement runs 2x slower than the query above
            -- If you update this merge statement, be sure to update the query
            ------------------------------------------------

            MERGE INTO t_cached_dataset_links AS target
            USING (SELECT DS.dataset_id,
                          DFP.dataset_row_version,
                          DFP.storage_path_row_version,
                          CASE
                               WHEN DA.archive_state_id = 4 THEN format('Purged: %s', DFP.dataset_folder_path)
                               ELSE CASE
                                       WHEN DA.instrument_data_purged > 0 THEN format('Raw Data Purged: %s', DFP.Dataset_Folder_Path)
                                       ELSE DFP.Dataset_Folder_Path
                                    END
                          END AS Dataset_Folder_Path,
                          CASE
                               WHEN DA.myemsl_state > 0 And DS.Created >= make_date(2013, 9, 17) Then ''
                               ELSE DFP.Archive_Folder_Path
                          END AS Archive_Folder_Path,
                          format('https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/%s', DS.Dataset_ID) AS MyEMSL_URL,
                          CASE
                               WHEN DA.QC_Data_Purged > 0 THEN ''
                               ELSE format('%sQC/index.html', DFP.Dataset_URL)
                          END AS QC_Link,
                          CASE
                               WHEN DA.QC_Data_Purged > 0 THEN ''
                               ELSE format('%s%s/', DFP.Dataset_URL, J.Results_Folder_Name)
                          END AS QC_2D,
                          CASE
                               WHEN Experiment SIMILAR TO 'QC[_]Shew%' THEN
                                      format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/P_2C/inst/%s/filterDS/QC_Shew', Inst.instrument)
                               WHEN Experiment SIMILAR TO 'QC[_]Mam%'  THEN
                                      format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/P_2C/inst/%s/filterDS/QC_Mam', Inst.instrument)
                               WHEN Experiment SIMILAR TO 'TEDDY[_]DISCOVERY%' THEN
                                      format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/qcart/inst/%s/filterDS/TEDDY_DISCOVERY', Inst.instrument)
                               ELSE   format('https://prismsupport.pnl.gov/smaqc/smaqc/metric/MS2_Count/inst/%s/filterDS/%s', Inst.instrument, Substring(DS.Dataset, 1, 4))
                          END AS QC_Metric_Stats
                   FROM t_dataset DS
                       INNER JOIN t_cached_dataset_links DL
                         ON DL.dataset_id = DS.dataset_id
                       INNER JOIN t_cached_dataset_folder_paths DFP
                         ON DFP.dataset_id = DS.dataset_id
                       INNER JOIN t_experiments E
                         ON E.exp_id = DS.exp_id
                       INNER JOIN t_instrument_name Inst
                         ON Inst.instrument_id = DS.instrument_id
                       LEFT OUTER JOIN t_analysis_job J
                         ON DS.decontools_job_for_qc = J.job
                       LEFT OUTER JOIN t_dataset_archive DA
                                       INNER JOIN t_archive_path AP
                                         ON DA.storage_path_id = AP.archive_path_id
                         ON DS.dataset_id = DA.dataset_id
                   WHERE DS.dataset_id BETWEEN _datasetIdStart AND _datasetIdEnd
                  ) AS Source
            ON (target.dataset_id = source.dataset_id)
            WHEN MATCHED AND
                 (target.dataset_row_version      IS DISTINCT FROM source.dataset_row_version OR
                  target.storage_path_row_version IS DISTINCT FROM source.storage_path_row_version OR
                  target.dataset_folder_path      IS DISTINCT FROM source.dataset_folder_path OR
                  target.archive_folder_path      IS DISTINCT FROM source.archive_folder_path OR
                  target.myemsl_url               IS DISTINCT FROM source.myemsl_url OR
                  target.qc_link                  IS DISTINCT FROM source.qc_link OR
                  target.qc_2d                    IS DISTINCT FROM source.qc_2d OR
                  target.qc_metric_stats          IS DISTINCT FROM source.qc_metric_stats) THEN
                UPDATE SET
                    dataset_row_version      = source.dataset_row_version,
                    storage_path_row_version = source.storage_path_row_version,
                    dataset_folder_path      = source.dataset_folder_path,
                    archive_folder_path      = source.archive_folder_path,
                    myemsl_url               = source.myemsl_url,
                    qc_link                  = source.qc_link,
                    qc_2d                    = source.qc_2d,
                    qc_metric_stats          = source.qc_metric_stats,
                    update_required          = 0,
                    last_affected            = CURRENT_TIMESTAMP;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _rowCountUpdated := _rowCountUpdated + _updateCount;

            If _datasetBatchSize <= 0 Then
                -- Break out of the while loop
                EXIT;
            End If;

            _datasetIdStart := _datasetIdStart + _datasetBatchSize;
            _datasetIdEnd   := _datasetIdEnd + _datasetBatchSize;

            If _datasetIdStart > _datasetIdMax Then
                -- Break out of the while loop
                EXIT;
            End If;

        END LOOP;
    End If;

    If _rowCountUpdated > 0 Then
        _addon := format('Updated %s %s in t_cached_dataset_links', _rowCountUpdated, public.check_plural(_rowCountUpdated, 'row', 'rows'));
        _message := public.append_to_text(_message, _addon);

        -- CALL post_log_entry ('Debug', _message, 'Update_Cached_Dataset_Links');
    End If;

    _runtimeSeconds := Round(Extract(epoch from (clock_timestamp() - _startTime)), 3);

    If _showDebug Or _runtimeSeconds > 5 Then
        RAISE INFO 'Processing time: % seconds', _runtimeSeconds;
    End If;
END
$$;


ALTER PROCEDURE public.update_cached_dataset_links(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_dataset_links(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_dataset_links(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedDatasetLinks';

