--
CREATE OR REPLACE PROCEDURE public.update_cached_dataset_links
(
    _processingMode int = 0,
    -- 1 to process new datasets, those with UpdateRequired=1, and the 10,000 most recent datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
    -- 2 to process new datasets, those with UpdateRequired=1, and all datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
    -- 3 to re-process all of the entries in T_Cached_Dataset_Links (this is the slowest update and will take 10 to 20 seconds)
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _showDebug boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates T_Cached_Dataset_Links, which is used by the Dataset Detail Report view (V_Dataset_Detail_Report_Ex)
**
**  Arguments:
**    _processingMode   0 to only process new datasets and datasets with UpdateRequired = 1
**
**  Auth:   mem
**  Date:   07/25/2017 mem - Initial version
**          06/12/2018 mem - Send _maxLength to append_to_text
**          07/31/2020 mem - Update MASIC_Directory_Name
**          09/06/2022 mem - When _processingMode is 3, update datasets in batches (to decrease the likelihood of deadlock issues)
**          12/15/2023 mem - Ported to PostgreSQL
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
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    _processingMode := Coalesce(_processingMode, 0);
    _showDebug := Coalesce(_showDebug, false);

    If _processingMode IN (0, 1) Then
        SELECT MIN(dataset_id)
        INTO _minimumDatasetID
        FROM ( SELECT dataset_id
               FROM t_dataset
               ORDER BY dataset_id DESC
               LIMIT 10000) LookupQ;
    End If;

    ------------------------------------------------
    -- Add new datasets to t_cached_dataset_links
    ------------------------------------------------
    --
    INSERT INTO t_cached_dataset_links (dataset_id,
                                        dataset_row_version,
                                        storage_path_row_version,
                                        update_required )
    SELECT DS.dataset_id,
           DS.dataset_row_version,
           DFP.storage_path_row_version,
           1 AS UpdateRequired
    FROM t_dataset DS
         INNER JOIN t_cached_dataset_folder_paths DFP
           ON DS.dataset_id = DFP.dataset_id
         LEFT OUTER JOIN t_cached_dataset_links DL
           ON DL.dataset_id = DS.dataset_id
    WHERE DS.dataset_id >= _minimumDatasetID AND
          DL.dataset_id IS NULL
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

    If _processingMode IN (1,2) Then
        If _showDebug Then
            RAISE INFO 'Setting update_required to 1 in t_cached_dataset_links for datasets with dataset_id >= % and differing row versions', _minimumDatasetID;
        End If;

        ------------------------------------------------
        -- Find datasets that need to be updated
        --
        -- Notes regarding t_cached_dataset_folder_paths
        --   Trigger trig_u_Dataset_Folder_Paths will set update_required to 1 when a row is changed in T_Dataset_Folder_Paths
        --
        -- Notes regarding t_dataset_archive
        --   Trigger trig_i_Dataset_Archive will set update_required to 1 when a dataset is added to t_dataset_archive
        --   Trigger trig_u_Dataset_Archive will set update_required to 1 when any of the following columns is updated:
        --     archive_state_id, AS_storage_path_ID, instrument_data_purged, MyEMSLState, qc_data_purged
        ------------------------------------------------

        ------------------------------------------------
        -- Find existing entries with a mismatch in dataset_row_version or storage_path_row_version
        ------------------------------------------------
        --
        UPDATE t_cached_dataset_links
        SET update_required = 1
        FROM t_cached_dataset_folder_paths DFP
        WHERE DFP.dataset_id = DL.dataset_id AND
              DL.dataset_id >= _minimumDatasetID AND
              (DL.dataset_row_version <> DFP.dataset_row_version OR
               DL.storage_path_row_version <> DFP.storage_path_row_version);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _addon := format('%s %s on dataset_row_version or storage_path_row_version', _updateCount, public.check_plural(_updateCount, 'dataset differs', 'datasets differ'));
            _message := public.append_to_text(_message, _addon, 0, '; ', 512);

            _rowCountUpdated := _rowCountUpdated + _updateCount;
        End If;

    End If;

    If _processingMode < 1 Then

        If _showDebug Then
            RAISE INFO 'Updating MASIC Directory Name in t_cached_dataset_links where update_required is 1 (updating one dataset at a time)';
        End If;

        ------------------------------------------------
        -- Iterate over datasets with UpdateRequired > 0  (since there should not be many)
        -- For each, make sure they have an up-to-date MASIC_Directory_Name
        --
        -- This query should be kept in sync with the bulk update query below
        ------------------------------------------------

        _datasetID := 0;

        WHILE true
        LOOP

            -- This While loop can probably be converted to a For loop; for example:
            --    FOR _itemName IN
            --        SELECT item_name
            --        FROM TmpSourceTable
            --        ORDER BY entry_id
            --    LOOP
            --        ...
            --    END LOOP;


            SELECT dataset_id
            INTO _datasetID
            FROM t_cached_dataset_links
            WHERE update_required > 0 AND dataset_id > _datasetID
            ORDER BY dataset_id
            LIMIT 1;

            If Not FOUND Then
                -- Break out of the while loop
                EXIT;
            End If;

            _masicDirectoryName := '';

            SELECT MasicDirectoryName
            INTO _masicDirectoryName
            FROM ( SELECT OrderQ.DatasetID,
                          OrderQ.Job,
                          OrderQ.MasicDirectoryName,
                          Row_Number() OVER ( PARTITION BY OrderQ.DatasetID
                                              ORDER BY OrderQ.JobStateRank ASC, OrderQ.Job DESC ) AS JobRank
                   FROM ( SELECT J.AJ_DatasetID AS DatasetID,
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
            WHERE JobRank = 1
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount > 0 And char_length(_masicDirectoryName) > 0 Then
                UPDATE t_cached_dataset_links
                SET masic_directory_name = _masicDirectoryName
                WHERE dataset_id = _datasetID;

                _rowCountUpdated := _rowCountUpdated + _updateCount;
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
            -- Make sure that entries with UpdateRequired > 0 have an up-to-date MASIC_Directory_Name
            -- This is a bulk update query, which can take some time to run, though if _processingMode is 3, datasets are processed in baches
            -- It should be kept in sync with the above query that includes Row_Number()
            ------------------------------------------------
            --
            UPDATE t_cached_dataset_links
            SET masic_directory_name = JobDirectoryQ.MasicDirectoryName
            FROM t_cached_dataset_links Target

            /********************************************************************************
            ** This UPDATE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE t_cached_dataset_links
            **   SET ...
            **   FROM source
            **   WHERE source.id = t_cached_dataset_links.id;
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN ( SELECT DatasetID,
                                     MasicDirectoryName
                              FROM ( SELECT OrderQ.DatasetID,
                                            OrderQ.Job,
                                            OrderQ.MasicDirectoryName,
                                            Row_Number() OVER ( PARTITION BY OrderQ.DatasetID
                                                                ORDER BY OrderQ.JobStateRank ASC, OrderQ.Job DESC ) AS JobRank
                                     FROM ( SELECT J.AJ_DatasetID AS DatasetID,
                                                   J.job AS Job,
                                                   J.Results_Folder_Name AS MasicDirectoryName,
                                                   CASE
                                                       WHEN J.job_state_id = 4 THEN 1
                                                       WHEN J.job_state_id = 14 THEN 2
                                                       ELSE 3
                                                   END LOOP; AS JobStateRank
                                            FROM t_analysis_job J
                                                 INNER JOIN t_analysis_tool T
                                                   ON J.analysis_tool_id = T.analysis_tool_id
                                            WHERE T.analysis_tool LIKE 'MASIC%' AND
                                                  NOT J.results_folder_name IS NULL AND
                                                  J.dataset_id BETWEEN _datasetIdStart AND _datasetIdEnd
                                          ) OrderQ
                                    ) RankQ
                              WHERE JobRank = 1
                           ) JobDirectoryQ
                   ON Target.dataset_id = JobDirectoryQ.DatasetID
            WHERE (Target.UpdateRequired > 0 OR
                   _processingMode >= 3) AND
                  Coalesce(Target.MASIC_Directory_Name, '') <> JobDirectoryQ.MasicDirectoryName
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _rowCountUpdated := _rowCountUpdated + _updateCount;

            If _datasetBatchSize <= 0 Then
                -- Break out of the while loop
                EXIT;
            End If;

            _datasetIdStart := _datasetIdStart + _datasetBatchSize;
            _datasetIdEnd := _datasetIdEnd + _datasetBatchSize;

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
        -- Update entries with UpdateRequired > 0
        -- Note that this query runs 2x faster than the merge statement below
        -- If you update this query, be sure to update the merge statement
        ------------------------------------------------
        --
        UPDATE t_cached_dataset_links
        SET dataset_row_version = DFP.dataset_row_version,
            storage_path_row_version = DFP.storage_path_row_version,
            dataset_folder_path = CASE
                WHEN DA.archive_state_id = 4 THEN 'Purged: ' || DFP.dataset_folder_path
                ELSE CASE
                        WHEN DA.AS_instrument_data_purged > 0 THEN 'Raw Data Purged: ' || DFP.Dataset_Folder_Path
                        ELSE DFP.Dataset_Folder_Path
                     End If;
                END,
            Archive_Folder_Path = CASE
                WHEN DA.MyEMSLState > 0 And DS.Created >= make_date(2013, 9, 17) Then ''
                ELSE DFP.Archive_Folder_Path
                END,
            MyEMSL_URL = format('https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/%s', DS.Dataset_ID),
            QC_Link = CASE
                WHEN DA.QC_Data_Purged > 0 THEN ''
                ELSE DFP.Dataset_URL || 'QC/index.html'
                END,
            QC_2D = CASE
                WHEN DA.QC_Data_Purged > 0 THEN ''
                ELSE DFP.Dataset_URL || J.Results_Folder_Name || '/'
                END,
            QC_Metric_Stats = CASE
                WHEN Experiment SIMILAR TO 'QC[_]Shew%' THEN
                        'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/' || Inst.IN_Name || '/filterDS/QC_Shew'
                WHEN Experiment SIMILAR TO 'TEDDY[_]DISCOVERY%' THEN
                        'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/qcart/inst/' || Inst.IN_Name || '/filterDS/TEDDY_DISCOVERY'
                ELSE 'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/MS2_Count/inst/' || Inst.IN_Name || '/filterDS/' || SUBSTRING(DS.Dataset_Name, 1, 4)
                END,
            update_required = 0,
            last_affected = CURRENT_TIMESTAMP
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
        WHERE DL.update_required = 1
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
            --
            MERGE INTO t_cached_dataset_links as target
            USING ( SELECT DS.dataset_id,
                           DFP.dataset_row_version,
                           DFP.storage_path_row_version,
                           CASE
                                WHEN DA.archive_state_id = 4 THEN 'Purged: ' || DFP.dataset_folder_path
                                ELSE CASE
                                        WHEN DA.AS_instrument_data_purged > 0 THEN 'Raw Data Purged: ' || DFP.Dataset_Folder_Path
                                        ELSE DFP.Dataset_Folder_Path
                                     END;
                           END AS Dataset_Folder_Path,
                           CASE
                                WHEN DA.MyEMSLState > 0 And DS.Created >= make_date(2013, 9, 17) Then ''
                                ELSE DFP.Archive_Folder_Path
                           END AS Archive_Folder_Path,
                           format('https://metadata.my.emsl.pnl.gov/fileinfo/files_for_keyvalue/omics.dms.dataset_id/%s', DS.Dataset_ID) AS MyEMSL_URL,
                           CASE
                                WHEN DA.QC_Data_Purged > 0 THEN ''
                                ELSE DFP.Dataset_URL || 'QC/index.html'
                           END AS QC_Link,
                           CASE
                                WHEN DA.QC_Data_Purged > 0 THEN ''
                                ELSE DFP.Dataset_URL || J.Results_Folder_Name || '/'
                           END AS QC_2D,
                           CASE
                                WHEN Experiment::citext SIMILAR TO 'QC[_]Shew%'::citext THEN
                                    'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/' || Inst.IN_Name || '/filterDS/QC_Shew'
                                WHEN Experiment::citext SIMILAR TO 'TEDDY[_]DISCOVERY%'::citext THEN
                                    'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/qcart/inst/' || Inst.IN_Name || '/filterDS/TEDDY_DISCOVERY'
                                ELSE 'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/MS2_Count/inst/' || Inst.IN_Name || '/filterDS/' || SUBSTRING(DS.Dataset_Name, 1, 4)
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
                 (target.dataset_row_version <> source.dataset_row_version OR
                  target.storage_path_row_version <> source.storage_path_row_version OR
                  target.dataset_folder_path IS DISTINCT FROM source.dataset_folder_path OR
                  target.archive_folder_path IS DISTINCT FROM source.archive_folder_path OR
                  target.myemsl_url IS DISTINCT FROM source.myemsl_url OR
                  target.qc_link IS DISTINCT FROM source.qc_link OR
                  target.qc_2d IS DISTINCT FROM source.qc_2d OR
                  target.qc_metric_stats IS DISTINCT FROM source.qc_metric_stats) THEN
                UPDATE SET
                    dataset_row_version = source.dataset_row_version,
                    storage_path_row_version = source.storage_path_row_version,
                    dataset_folder_path = source.dataset_folder_path,
                    archive_folder_path = source.archive_folder_path,
                    myemsl_url = source.myemsl_url,
                    qc_link = source.qc_link,
                    qc_2d = source.qc_2d,
                    qc_metric_stats = source.qc_metric_stats,
                    update_required = 0,
                    last_affected = CURRENT_TIMESTAMP
            ;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _rowCountUpdated := _rowCountUpdated + _updateCount;

            If _datasetBatchSize <= 0 Then
                -- Break out of the while loop
                EXIT;
            End If;

            _datasetIdStart := _datasetIdStart + _datasetBatchSize;
            _datasetIdEnd := _datasetIdEnd + _datasetBatchSize;

            If _datasetIdStart > _datasetIdMax Then
                -- Break out of the while loop
                EXIT;
            End If;

        END LOOP;
    End If;

    If _rowCountUpdated > 0 Then
        _addon := format('Updated %s %s in t_cached_dataset_links', _rowCountUpdated, public.check_plural(_rowCountUpdated, 'row', 'rows'));
        _message := public.append_to_text(_message, _addon, 0, '; ', 512);

        -- CALL PostLogEntry ('Debug', _message, 'UpdateCachedDatasetLinks');
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_cached_dataset_links IS 'UpdateCachedDatasetLinks';
