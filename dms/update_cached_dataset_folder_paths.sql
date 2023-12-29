--
-- Name: update_cached_dataset_folder_paths(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_dataset_folder_paths(IN _processingmode integer DEFAULT 0, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_cached_dataset_folder_paths
**
**  Arguments:
**    _processingMode   Processing mode:
**                      0 to only process new datasets and datasets with UpdateRequired = 1
**                      1 to process new datasets, those with UpdateRequired=1, and the 10,000 most recent datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
**                      2 to process new datasets, those with UpdateRequired=1, and all datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
**                      3 to re-process all of the entries in T_Cached_Dataset_Folder_Paths (this is the slowest update and will take ~30 seconds to complete)
**    _showDebug        When true, show debug info
**
**  Auth:   mem
**  Date:   11/14/2013 mem - Initial version
**          11/15/2013 mem - Added parameter
**          11/19/2013 mem - Tweaked logging
**          06/12/2018 mem - Send _maxLength to append_to_text
**          02/27/2019 mem - Use T_Storage_Path_Hosts instead of SP_URL
**          09/06/2022 mem - When _processingMode is 3, update datasets in batches (to decrease the likelihood of deadlock issues)
**          10/04/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int;
    _updateCount int := 0;
    _mergeCount int;
    _minimumDatasetID int := 0;
    _datasetIdStart int;
    _datasetIdEnd int;
    _datasetIdMax int;
    _datasetBatchSize int;
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

    If _showDebug Then
        RAISE INFO '';
    End If;

    _startTime := clock_timestamp();

    If _processingMode In (0, 1) Then
        SELECT MIN(dataset_id)
        INTO _minimumDatasetID
        FROM ( SELECT dataset_id
               FROM t_dataset
               ORDER BY dataset_id DESC
               LIMIT 10000) LookupQ;
    End If;

    ------------------------------------------------
    -- Add new datasets to t_cached_dataset_folder_paths
    ------------------------------------------------

    INSERT INTO t_cached_dataset_folder_paths (dataset_id,
                                               dataset_row_version,
                                               update_required )
    SELECT DS.dataset_id,
           DS.xmin,
           1 AS UpdateRequired
    FROM t_dataset DS
         LEFT OUTER JOIN t_cached_dataset_folder_paths DFP
           ON DFP.dataset_id = DS.dataset_id
         LEFT OUTER JOIN t_storage_path SPath
           ON SPath.storage_path_id = DS.storage_path_id
         LEFT OUTER JOIN t_dataset_archive DA
                         INNER JOIN t_archive_path AP
                           ON DA.storage_path_id = AP.archive_path_id
           ON DS.dataset_id = DA.dataset_id
    WHERE DS.dataset_id >= _minimumDatasetID AND
          DFP.dataset_id IS NULL;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _message := format('Added %s new %s to t_cached_dataset_folder_paths', _matchCount, public.check_plural(_matchCount, 'dataset', 'datasets'));

        If _showDebug Then
            RAISE INFO '%', _message;
        End If;
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

    If _processingMode In (1, 2) Then
        If _showDebug Then
            RAISE INFO 'Setting update_required to 1 in t_cached_dataset_folder_paths for datasets with dataset_id >= % and differing row versions', _minimumDatasetID;
        End If;

        ------------------------------------------------
        -- Find datasets that need to be updated
        --
        -- Notes regarding t_dataset_archive
        --   Trigger trig_i_Dataset_Archive will set UpdateRequired to 1 when a dataset is added to t_dataset_archive
        --   Trigger trig_u_Dataset_Archive will set UpdateRequired to 1 when storage_path_id is updated
        ------------------------------------------------

        ------------------------------------------------
        -- Find existing entries with a mismatch in storage_path_row_version
        ------------------------------------------------

        UPDATE t_cached_dataset_folder_paths DFP
        SET update_required = 1
        FROM t_dataset DS
             INNER JOIN t_storage_path SPath
               ON SPath.storage_path_id = DS.storage_path_id
        WHERE DFP.dataset_id = DS.dataset_id AND
              DS.dataset_id >= _minimumDatasetID AND
              SPath.xmin IS DISTINCT FROM DFP.storage_path_row_version;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _matchCount > 0 Then
            _addon := format('%s %s on storage_path_row_version', _matchCount, public.check_plural(_matchCount, 'dataset differs', 'datasets differ'));
            _message := public.append_to_text(_message, _addon);
        End If;

        ------------------------------------------------
        -- Find existing entries with a mismatch in dataset_row_version
        ------------------------------------------------

        UPDATE t_cached_dataset_folder_paths DFP
        SET update_required = 1
        FROM t_dataset DS
        WHERE DFP.dataset_id = DS.dataset_id AND
              DS.dataset_id >= _minimumDatasetID AND
              DS.xmin IS DISTINCT FROM DFP.dataset_row_version;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _matchCount > 0 Then
            _addon := format('%s %s on dataset_row_version', _matchCount, public.check_plural(_matchCount, 'dataset differs', 'datasets differ'));
            _message := public.append_to_text(_message, _addon);
        End If;

        If _showDebug And _message <> '' Then
            RAISE INFO '%', _message;
        End If;

    End If;

    If _processingMode < 3 Then
        If _showDebug Then
            RAISE INFO '%', 'Updating cached paths for all rows in t_cached_dataset_folder_paths where update_required is 1';
        End If;

        ------------------------------------------------
        -- Update entries with UpdateRequired > 0
        -- Note that this query runs 2x faster than the merge statement below
        -- If you update this query, be sure to update the merge statement
        ------------------------------------------------

        UPDATE t_cached_dataset_folder_paths DFP
        SET dataset_row_version = DS.xmin,
            storage_path_row_version = SPath.xmin,
            dataset_folder_path = Coalesce(public.combine_paths(SPath.vol_name_client,
                                           public.combine_paths(SPath.storage_path, Coalesce(DS.folder_name, DS.dataset))), ''),
            archive_folder_path = CASE WHEN AP.network_share_path IS NULL
                                       THEN ''
                                       ELSE public.combine_paths(AP.network_share_path,
                                                                 Coalesce(DS.folder_name, DS.Dataset))
                                  END,
            MyEMSL_Path_Flag = format('\\MyEMSL\%s', public.combine_paths(SPath.storage_path, Coalesce(DS.folder_name, DS.Dataset))),
            -- Old: Dataset_URL = format('%s%s/', SPath.url, Coalesce(DS.folder_name, DS.Dataset)),
            Dataset_URL = format('%s%s/',
                                 CASE WHEN SPath.storage_path_function LIKE '%inbox%'
                                      THEN ''
                                      ELSE format('%s%s%s/%s', SPH.URL_Prefix, SPH.Host_Name, SPH.DNS_Suffix, Replace(storage_path, '\', '/'))
                                 END,
                                 Coalesce(DS.folder_name, DS.dataset)),
            update_required = 0,
            last_affected = CURRENT_TIMESTAMP
        FROM t_dataset DS
             LEFT OUTER JOIN t_storage_path SPath
               ON SPath.storage_path_id = DS.storage_path_id
             LEFT OUTER JOIN t_storage_path_hosts SPH
               ON SPath.machine_name = SPH.machine_name
             LEFT OUTER JOIN t_dataset_archive DA
                             INNER JOIN t_archive_path AP
                               ON DA.storage_path_id = AP.archive_path_id
               ON DS.dataset_id = DA.dataset_id
        WHERE DFP.dataset_id = DS.dataset_id AND
              DFP.update_required = 1;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

    Else

        -- _processingMode is 3

        If _showDebug Then
            If _datasetBatchSize > 0 Then
                RAISE INFO 'Updating cached paths for all rows in t_cached_dataset_folder_paths, processing % datasets at a time', _datasetBatchSize;
            Else
                RAISE INFO 'Updating cached paths all rows in t_cached_dataset_folder_paths; note that batch size is 0, which should never be the case';
            End If;
        End If;

        _datasetIdStart := 0;

        If _datasetBatchSize > 0 Then
            _datasetIdEnd := _datasetIdStart + _datasetBatchSize - 1;
        Else
            _datasetIdEnd := _datasetIdMax;
        End If;

        _updateCount := 0;

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

            MERGE INTO t_cached_dataset_folder_paths As target
            USING ( SELECT DS.dataset_id,
                           DS.xmin AS XMin_Dataset,
                           SPath.xmin AS XMin_SPath,
                           Coalesce(public.combine_paths(SPath.vol_name_client,
                                    public.combine_paths(SPath.storage_path, Coalesce(DS.folder_name, DS.Dataset))), '') AS Dataset_Folder_Path,
                           CASE WHEN AP.network_share_path IS NULL
                                THEN ''
                                ELSE public.combine_paths(AP.network_share_path,
                                                          Coalesce(DS.folder_name, DS.Dataset))
                           END AS Archive_Folder_Path,
                           format('\\MyEMSL\%s', public.combine_paths(SPath.storage_path, Coalesce(DS.folder_name, DS.Dataset))) AS MyEMSL_Path_Flag,
                           -- Old: format('%s%s/', SPath.url, Coalesce(DS.folder_name, DS.Dataset)) AS Dataset_URL
                           format('%s%s/',
                                  CASE WHEN SPath.storage_path_function LIKE '%inbox%'
                                       THEN ''
                                       ELSE format('%s%s%s/%s', SPH.URL_Prefix, SPH.Host_Name, SPH.DNS_Suffix, Replace(storage_path, '\', '/'))
                                  END,
                                  Coalesce(DS.folder_name, DS.dataset)) AS Dataset_URL
                    FROM t_dataset DS
                         INNER JOIN t_cached_dataset_folder_paths DFP
                           ON DFP.dataset_id = DS.dataset_id
                         LEFT OUTER JOIN t_storage_path SPath
                           ON SPath.storage_path_id = DS.storage_path_id
                         LEFT OUTER JOIN t_storage_path_hosts SPH
                           ON SPath.machine_name = SPH.machine_name
                         LEFT OUTER JOIN t_dataset_archive DA
                                         INNER JOIN t_archive_path AP
                                           ON DA.storage_path_id = AP.archive_path_id
                           ON DS.dataset_id = DA.dataset_id
                    WHERE DS.dataset_id BETWEEN _datasetIdStart AND _datasetIdEnd
                  ) AS Source
            ON (target.dataset_id = source.dataset_id)
            WHEN MATCHED AND
                 (target.dataset_row_version      IS DISTINCT FROM source.XMin_Dataset OR
                  target.storage_path_row_version IS DISTINCT FROM source.XMin_SPath OR
                  target.dataset_folder_path      IS DISTINCT FROM source.dataset_folder_path OR
                  target.archive_folder_path      IS DISTINCT FROM source.archive_folder_path OR
                  target.myemsl_path_flag         IS DISTINCT FROM source.myemsl_path_flag OR
                  target.dataset_url              IS DISTINCT FROM source.dataset_url) THEN
                UPDATE SET
                    dataset_row_version = source.XMin_Dataset,
                    storage_path_row_version = source.XMin_SPath,
                    dataset_folder_path = source.dataset_folder_path,
                    archive_folder_path = source.archive_folder_path,
                    myemsl_path_flag = source.myemsl_path_flag,
                    dataset_url = source.dataset_url,
                    update_required = 0,
                    last_affected = CURRENT_TIMESTAMP
            ;

            GET DIAGNOSTICS _mergeCount = ROW_COUNT;

            _updateCount := _updateCount + _mergeCount;

            If _datasetBatchSize <= 0 Then
                -- Break out of the While Loop
                EXIT;
            End If;

            _datasetIdStart := _datasetIdStart + _datasetBatchSize;
            _datasetIdEnd   := _datasetIdEnd   + _datasetBatchSize;

            If _datasetIdStart > _datasetIdMax Then
                -- Break out of the While Loop
                EXIT;
            End If;
        END LOOP;

    End If;

    If _updateCount > 0 Then
        _addon := format('Updated %s %s in t_cached_dataset_folder_paths', _updateCount, public.check_plural(_updateCount, 'row', 'rows'));
        _message := public.append_to_text(_message, _addon);

        -- Call post_log_entry ('Debug', _message, 'Update_Cached_Dataset_Folder_Paths');
    End If;

    _runtimeSeconds := Round(extract(epoch FROM (clock_timestamp() - _startTime)), 3);

    If _showDebug Or _runtimeSeconds > 5 Then
        RAISE INFO 'Processing time: % seconds', _runtimeSeconds;
    End If;
END
$$;


ALTER PROCEDURE public.update_cached_dataset_folder_paths(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_dataset_folder_paths(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_dataset_folder_paths(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedDatasetFolderPaths';

