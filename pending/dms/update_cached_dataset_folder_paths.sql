--
CREATE OR REPLACE PROCEDURE public.update_cached_dataset_folder_paths
(
    _processingMode int = 0,
    -- 1 to process new datasets, those with UpdateRequired=1, and the 10,000 most recent datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
    -- 2 to process new datasets, those with UpdateRequired=1, and all datasets in DMS (looking for dataset_row_version or storage_path_row_version differing)
    -- 3 to re-process all of the entries in T_Cached_Dataset_Folder_Paths (this is the slowest update and will take 10 to 20 seconds)
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _showDebug int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates T_Cached_Dataset_Folder_Paths
**
**  Arguments:
**    _processingMode   0 to only process new datasets and datasets with UpdateRequired = 1
**
**  Auth:   mem
**  Date:   11/14/2013 mem - Initial version
**          11/15/2013 mem - Added parameter
**          11/19/2013 mem - Tweaked logging
**          06/12/2018 mem - Send _maxLength to AppendToText
**          02/27/2019 mem - Use T_Storage_Path_Hosts instead of SP_URL
**          09/06/2022 mem - When _processingMode is 3, update datasets in batches (to decrease the likelihood of deadlock issues)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _minimumDatasetID int := 0;
    _datasetIdStart int;
    _datasetIdEnd int;
    _datasetIdMax int;
    _datasetBatchSize int;
    _continue boolean;
    _addon text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    _processingMode := Coalesce(_processingMode, 0);
    _showDebug := Coalesce(_showDebug, 0);

    If _processingMode IN (0, 1) Then
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
    --
    INSERT INTO t_cached_dataset_folder_paths (dataset_id,
                                               dataset_row_version,
                                               update_required )
    SELECT DS.dataset_id,
           DS.dataset_row_version,
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
          DFP.dataset_id IS NULL
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := format('Added %s new %s', _myRowCount, public.check_plural(_myRowCount, 'dataset', 'datasets'));
    End If;

    SELECT MAX(dataset_id) INTO _datasetIdMax
    FROM t_cached_dataset_links
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        _datasetIdMax := 2147483647;
    End If;

    If _processingMode >= 3 And _datasetIdMax < 2147483647 Then
        _datasetBatchSize := 50000;
    Else
        _datasetBatchSize := 0;
    End If;

    If _processingMode IN (1,2) Then
        If _showDebug Then
            RAISE INFO '%', 'Setting update_required to 1 in t_cached_dataset_folder_paths for datasets with dataset_id >= ' || Cast(_minimumDatasetID as text) || ' and differing row versions';
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
        --
        UPDATE t_cached_dataset_folder_paths
        SET update_required = 1
        FROM t_dataset DS
             INNER JOIN t_storage_path SPath
               ON SPath.storage_path_id = DS.storage_path_id
             INNER JOIN t_cached_dataset_folder_paths DFP
               ON DS.dataset_id = DFP.dataset_id
        WHERE DS.dataset_id >= _minimumDatasetID AND
              SPath.storage_path_row_version <> DFP.storage_path_row_version;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _addon := format('%s %s on storage_path_row_version', _myRowCount, public.check_plural(_myRowCount, 'dataset differs', 'datasets differ'));
            _message := public.append_to_text(_message, _addon, 0, '; ', 512)

        End If;

        ------------------------------------------------
        -- Find existing entries with a mismatch in dataset_row_version
        ------------------------------------------------
        --
        UPDATE t_cached_dataset_folder_paths
        SET update_required = 1
        FROM t_dataset DS
             INNER JOIN t_cached_dataset_folder_paths DFP
               ON DFP.dataset_id = DS.dataset_id
        WHERE DS.dataset_id >= _minimumDatasetID AND
              DS.dataset_row_version <> DFP.dataset_row_version
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _addon := format('%s %s on dataset_row_version', _myRowCount, public.check_plural(_myRowCount, 'dataset differs', 'datasets differ'));
            _message := public.append_to_text(_message, _addon, 0, '; ', 512)
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
        --
        UPDATE t_cached_dataset_folder_paths
        SET dataset_row_version = DS.dataset_row_version,
            storage_path_row_version = SPath.storage_path_row_version,
            dataset_folder_path = Coalesce(public.combine_paths(SPath.SP_vol_name_client,
                                         public.combine_paths(SPath.SP_path, Coalesce(DS.DS_folder_name, DS.Dataset_Name))), ''),
            archive_folder_path = CASE
                                      WHEN AP.AP_network_share_path IS NULL THEN ''
                                      ELSE public.combine_paths(AP.AP_network_share_path,
                                                               Coalesce(DS.DS_folder_name, DS.Dataset_Name))
                                  End If;,
            MyEMSL_Path_Flag = '\\MyEMSL\' || public.combine_paths(SPath.SP_path, Coalesce(DS.DS_folder_name, DS.Dataset_Name)),
            -- Old: Dataset_URL =             SPath.SP_URL + Coalesce(DS.DS_folder_name, DS.Dataset_Name) || '/',
            Dataset_URL = CASE WHEN SPath.storage_path_function Like '%inbox%'
                          THEN ''
                          ELSE SPH.URL_Prefix +
                               SPH.Host_Name + SPH.DNS_Suffix || '/' ||
                               Replace(SP_path, '\', '/')
                          END +
                          Coalesce(DS.folder_name, DS.dataset) || '/',
            update_required = 0,
            last_affected = CURRENT_TIMESTAMP
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
        WHERE DFP.update_required = 1
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    Else

        -- _processingMode is 3

        If _showDebug Then
            If _datasetBatchSize > 0 Then
                RAISE INFO '%', 'Updating cached paths for all rows in t_cached_dataset_folder_paths, processing ' || Cast(_datasetBatchSize As text) || ' datasets at a time';
            Else
                RAISE INFO '%', 'Updating cached paths all rows in t_cached_dataset_folder_paths; note that batch size is 0, which should never be the case';
            End If;
        End If;

        _datasetIdStart := 0;

        If _datasetBatchSize > 0 Then
            _datasetIdEnd := _datasetIdStart + _datasetBatchSize - 1;
        Else
            _datasetIdEnd := _datasetIdMax;
        End If;

        _continue := true;

        WHILE _continue
        LOOP
            If _showDebug Then
                RAISE INFO '%', 'Updating Dataset IDs ' || Cast(_datasetIdStart As text) || ' to ' || Cast(_datasetIdEnd As text);
            End If;

            ------------------------------------------------
            -- Update all of the entries (if the stored value disagrees)
            --
            -- Note that this merge statement runs 2x slower than the query above
            -- If you update this merge statement, be sure to update the query
            ------------------------------------------------
            --
            MERGE INTO t_cached_dataset_folder_paths as target
            USING ( SELECT DS.dataset_id,
                           DS.dataset_row_version,
                           SPath.storage_path_row_version,
                           Coalesce(public.combine_paths(SPath.SP_vol_name_client,
                                  public.combine_paths(SPath.SP_path, Coalesce(DS.DS_folder_name, DS.Dataset_Name))), '') AS Dataset_Folder_Path,
                           CASE
                               WHEN AP.AP_network_share_path IS NULL THEN ''
                               ELSE public.combine_paths(AP.AP_network_share_path,
                                                        Coalesce(DS.DS_folder_name, DS.Dataset_Name))
                           END LOOP; AS Archive_Folder_Path,
                           '\\MyEMSL\' || public.combine_paths(SPath.SP_path, Coalesce(DS.DS_folder_name, DS.Dataset_Name)) AS MyEMSL_Path_Flag,
                           -- Old:             SPath.SP_URL + Coalesce(DS.DS_folder_name, DS.Dataset_Name) || '/' AS Dataset_URL
                           CASE WHEN SPath.storage_path_function Like '%inbox%'
                                THEN ''
                                ELSE SPH.URL_Prefix +
                                     SPH.Host_Name + SPH.DNS_Suffix || '/' ||
                                     Replace(SP_path, '\', '/')
                                END +
                                Coalesce(DS.folder_name, DS.dataset) || '/' AS Dataset_URL
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
                 (target.dataset_row_version      IS DISTINCT FROM source.dataset_row_version OR
                  target.storage_path_row_version IS DISTINCT FROM source.storage_path_row_version OR
                  target.dataset_folder_path      IS DISTINCT FROM source.dataset_folder_path OR
                  target.archive_folder_path      IS DISTINCT FROM source.archive_folder_path OR
                  target.myemsl_path_flag         IS DISTINCT FROM source.myemsl_path_flag OR
                  target.dataset_url              IS DISTINCT FROM source.dataset_url) THEN
                UPDATE SET
                    dataset_row_version = source.dataset_row_version,
                    storage_path_row_version = source.storage_path_row_version,
                    dataset_folder_path = source.dataset_folder_path,
                    archive_folder_path = source.archive_folder_path,
                    myemsl_path_flag = source.myemsl_path_flag,
                    dataset_url = source.dataset_url,
                    update_required = 0,
                    last_affected = CURRENT_TIMESTAMP
            ;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _datasetBatchSize <= 0 Then
                _continue := false;
            Else
                _datasetIdStart := _datasetIdStart + _datasetBatchSize;
                _datasetIdEnd := _datasetIdEnd + _datasetBatchSize;

                If _datasetIdStart > _datasetIdMax Then
                    _continue := false;
                End If;
            End If;
        End If;
    End If;

    If _myRowCount > 0 Then
        _addon := format('Updated %s %s in t_cached_dataset_folder_paths', _myRowCount, public.check_plural(_myRowCount, 'row', 'rows'));
        _message := public.append_to_text(_message, _addon, 0, '; ', 512)

        -- call PostLogEntry ('Debug', _message, 'UpdateCachedDatasetFolderPaths');
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_cached_dataset_folder_paths IS 'UpdateCachedDatasetFolderPaths';
