--
-- Name: request_purge_task(text, text, boolean, refcursor, text, text, boolean, integer, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.request_purge_task(IN _storageservername text, IN _serverdisk text, IN _excludestagemd5requireddatasets boolean DEFAULT true, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _previewcount integer DEFAULT 5, IN _previewsql boolean DEFAULT false, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Look for dataset that is best candidate to be purged
**
**      If found, dataset archive status is set to 'Purge In Progress'
**      and information needed for purge task is returned in the the _results cursor
**
**      Alternatively, if _infoOnly is true, will display the next _datasetsPerShare datasets
**      that would be purged on the specified server, or on a series of servers (if _storageServerName and/or _serverDisk are blank)
**
**      Note that Preview_Purge_Task_Candidates calls this procedure with_infoOnly to true
**
**  Example syntax for preview:
**     CALL request_purge_task ('Proto-9', _serverDisk => 'G:\', _infoOnly => true);
**
**     CALL preview_purge_task_candidates ('Proto-9', 'G:\');
**
**  Arguments:
**    _storageServerName                Storage server to use, for example 'Proto-9'; if blank, returns candidates for all storage servers; when blank, _serverDisk is ignored
**    _serverDisk                       Disk on storage server to use, for example 'G:\'; if blank, returns candidates for all drives on given server (or all servers if _storageServerName is blank)
**    _excludeStageMD5RequiredDatasets  If true, excludes datasets with StageMD5_Required > 0
**    _results                          Output: cursor for retrieving the purge task parameters
**    _message                          Status message
**    _returnCode                       Return code
**    _infoOnly                         When true, preview the first _previewCount candidates
**    _previewCount                     Number of purge candidates to show when _infoOnly is true; set to -1 to preview the parameter table that would be returned if a single purge task candidate was chosen from Tmp_PurgeableDatasets
**    _previewSql                       When true, preview SQL Insert statements
**    _showDebug                        When true, show debug messages
**
**  As an alternative to using "CALL request_purge_task ()" as shown above, use an anonymous code block:

    DO
    LANGUAGE plpgsql
    $$
    DECLARE
        _results refcursor;
        _message text;
        _returnCode text;
        _previewSql boolean;
        _taskParams record;
        _formatSpecifier text;
    BEGIN
        _previewSql := false;

        CALL public.request_purge_task (
                    _storageServerName               => 'Proto-9'  ,
                    _serverDisk                      => 'G:\',
                    _excludeStageMD5RequiredDatasets => true,
                    _results           => _results,
                    _message           => _message,
                    _returnCode        => _returnCode,
                    _infoOnly          => true,
                    _previewCount      => 5,
                    _previewSql        => _previewSql,
                    _showDebug         => false
                );

        If _previewSql Then
            RETURN;
        End If;

        RAISE INFO '';
        RAISE INFO 'Purge task info';
        RAISE INFO '';

        _formatSpecifier := '%-35s %-40s';

        RAISE INFO '%', format(_formatSpecifier, 'Parameter', 'Value');

        RAISE INFO '%', format(_formatSpecifier,
                               '-----------------------------------',
                               '----------------------------------------');

        WHILE NOT _results IS NULL
        LOOP
            FETCH NEXT FROM _results
            INTO _taskParams;

            If Not FOUND Then
                 EXIT;
            End If;

            RAISE INFO '%', format(_formatSpecifier,
                                   _taskParams.Parameter,
                                   _taskParams.Value);
        END LOOP;
    END
    $$;

**  Auth:   grk
**  Date:   03/04/2003
**          02/11/2005 grk - Added _rawDataType to output
**          06/02/2009 mem - Decreased population of Tmp_PurgeableDatasets to be limited to 2 rows
**          12/13/2010 mem - Added _infoOnly and defined defaults for several parameters
**          12/30/2010 mem - Updated to allow _storageServerName and/or _serverDisk to be blank
**                         - Added _previewSql
**          01/04/2011 mem - Now initially favoring datasets at least 4 months old, then checking datasets where the most recent job was a year ago, then looking at newer datasets
**          01/11/2011 dac/mem - Modified for use with new space manager
**          01/11/2011 dac - Added samba path for dataset as return param
**          02/01/2011 mem - Added parameter _excludeStageMD5RequiredDatasets
**          01/10/2012 mem - Now using V_Purgeable_Datasets_NoInterest_NoRecentJob instead of V_Purgeable_Datasets_NoInterest
**          01/16/2012 mem - Now returning Instrument, Dataset_Created, and Dataset_Year_Quarter when _previewSql is true
**          01/18/2012 mem - Now including Instrument, DatasetCreated, and DatasetYearQuarter when requesting an actual purge task (_infoOnly = false)
**                         - Using _infoOnly = true and _previewCount = -1 will now show the parameter table that would be returned if an actual purge task were assigned
**          06/14/2012 mem - Now sorting by Purge_Priority, then by OrderByCol
**                         - Now including PurgePolicy in the job parameters table (0=Auto, 1=Purge All except QC Subfolder, 2=Purge All)
**                         - Now looking for state 3, 14, or 15 when actually selecting a dataset to purge
**          06/07/2013 mem - Now sorting by Archive_State_ID, Purge_Priority, then OrderByCol
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/02/2018 mem - Change the return code for 'dataset not found' to 53000
**          02/01/2023 mem - Use new view names
**          02/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _candidateCount int := 0;
    _purgeInfo record;
    _purgeViewSourceDesc text;
    _sql text;
    _noDatasetFound text = 'U5300';
    _datasetID int = 0;
    _datasetInfo record;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------

    _storageServerName := Trim(Coalesce(_storageServerName, ''));

    If _storageServerName = '' Then
        _serverDisk := '';
    Else
        _serverDisk := Trim(Coalesce(_serverDisk, ''));
    End If;

    _excludeStageMD5RequiredDatasets := Coalesce(_excludeStageMD5RequiredDatasets, true);

    _infoOnly     := Coalesce(_infoOnly, false);
    _previewCount := Coalesce(_previewCount, 10);
    _previewSql   := Coalesce(_previewSql, false);
    _showDebug    := Coalesce(_showDebug, false);

    If Not _infoOnly Or _infoOnly And _previewCount < 0 Then
        -- Verify that both _storageServerName and _serverDisk are specified
        If _storageServerName = '' Or _serverDisk = '' Then
            _message := 'Error, both a storage server and a storage disk must be specified when requesting a purge task or when previewing the task that would be returned';
            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    --------------------------------------------------
    -- Temporary table to hold candidate purgeable datasets
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_PurgeableDatasets (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Dataset_ID int,
        MostRecent timestamp,
        Source text,
        Storage_Server_Name text NULL,
        Server_Vol text NULL,
        Purge_Priority int
    );

    CREATE INDEX IX_Tmp_PurgeableDatasets_StorageServerAndVol ON Tmp_PurgeableDatasets (Storage_Server_Name, Server_Vol);

    CREATE TEMP TABLE Tmp_StorageVolsToSkip (
        Storage_Server_Name text,
        Server_Vol text
    );

    CREATE TEMP TABLE Tmp_PurgeViews (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        PurgeViewName text,
        HoldoffDays int,
        OrderByCol text
    );

    ---------------------------------------------------
    -- Reset stagemd5_required for any datasets with purge_holdoff_date older than the current date/time
    ---------------------------------------------------

    UPDATE t_dataset_archive
    SET stagemd5_required = 0
    WHERE stagemd5_required > 0 AND
          Coalesce(purge_holdoff_date, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP;

    ---------------------------------------------------
    -- Populate temporary table with a small pool of
    -- purgeable datasets for given storage server
    ---------------------------------------------------

    -- The candidates come from three separate views, which we define in Tmp_PurgeViews
    --
    -- We're querying each view twice because we want to first purge datasets at least
    --   ~4 months old with rating No Interest,
    --   then purge datasets that are 6 months old and don't have a job,
    --   then purge datasets with the most recent job over 365 days ago,
    -- If we still don't have enough candidates, we query the views again to start purging newer datasets

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoInterest_NoRecentJob', 120, 'created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoJob',                  180, 'created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets',                        365, 'most_recent_job');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoInterest_NoRecentJob', 21,  'created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoJob',                  21,  'created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets',     21,  'most_recent_job');

    ---------------------------------------------------
    -- Process each of the views in Tmp_PurgeViews
    ---------------------------------------------------

    FOR _purgeInfo IN
        SELECT PurgeViewName,
               HoldoffDays,
               OrderByCol
        FROM Tmp_PurgeViews
        ORDER BY EntryID
    LOOP
        /*
        ** The following is a simpler query that can be used when looking for candidates on a specific volume on a specific server
        ** It is more efficient than the larger query below (which uses Row_Number() to rank things)
        ** However, it doesn't run that much faster, and thus, for simplicity, we're always using the larger query
        **
            _sql :=        'INSERT INTO Tmp_PurgeableDatasets (Dataset_ID, MostRecent, Source, Storage_Server_Name, Server_Vol, Purge_Priority) '
                           'SELECT dataset_id, '                                      ||
                            format('%s, ', _purgeInfo.OrderByCol)                     ||
                            format('''%s'' AS Source, ', _purgeInfo.PurgeViewName)    ||
                                  'storage_server_name, '                             ||
                                  'server_vol, '                                      ||
                                  'purge_priority '                                   ||
                    format('FROM %s ', _purgeInfo.PurgeViewName)                      ||
                    format('WHERE storage_server_name = ''%s'' ', _storageServerName) ||
                    format(      'AND server_vol = ''%s''', _serverDisk);

            If _excludeStageMD5RequiredDatasets Then
                _sql := format('%s AND stage_md5_required = 0 ', _sql);
            End If;

            If _purgeInfo.HoldoffDays >= 0 Then
                _sql := format('%s AND (%s < CURRENT_TIMESTAMP - make_interval(days => %s)', _sql, _purgeInfo.OrderByCol, _purgeInfo.HoldoffDays);
            End If;

            _sql := format('%s ORDER BY purge_priority, %s, dataset_id', _sql, _purgeInfo.OrderByCol);
            _sql := format('%s LIMIT %s', _sql, _previewCount);
        */

        _purgeViewSourceDesc := _purgeInfo.PurgeViewName;

        If _purgeInfo.HoldoffDays >= 0 Then
            _purgeViewSourceDesc := format('%s_%sMinDays', _purgeViewSourceDesc, _purgeInfo.HoldoffDays);
        End If;

        If _showDebug Then
            RAISE INFO '';

            If _purgeInfo.HoldoffDays >= 0 Then
                RAISE INFO 'Query view % with HoldoffDays = %', _purgeViewSourceDesc, _purgeInfo.HoldoffDays;
            Else
                RAISE INFO 'Query view %', _purgeViewSourceDesc;
            End If;
        End If;

        ---------------------------------------------------
        -- Find the top _previewCount candidates for each drive on each server
        -- (limiting by _storageServerName or _serverDisk if they are defined)
        ---------------------------------------------------

        _sql := 'INSERT INTO Tmp_PurgeableDatasets (Dataset_ID, MostRecent, Source, Storage_Server_Name, Server_Vol, Purge_Priority) '
                'SELECT dataset_id, '                                                                    ||
                format('%s, ', _purgeInfo.OrderByCol)                                                    ||
                      'Source, '
                      'storage_server_name, '
                      'server_vol, '
                      'purge_priority '
                'FROM (SELECT Src.Dataset_ID, '                                                          ||
                      format('Src.%s, ', _purgeInfo.OrderByCol)                                          ||
                      format('''%s'' AS Source, ', _purgeViewSourceDesc)                                 ||
                             'Row_Number() OVER (PARTITION BY Src.storage_server_name, Src.server_vol ' ||
                                         format('ORDER BY Src.archive_state_id, Src.purge_priority, Src.%s, Src.Dataset_ID) AS RowNumVal, ', _purgeInfo.OrderByCol) ||
                             'Src.storage_server_name, '
                             'Src.server_vol, '
                             'Src.stage_md5_required, '
                             'Src.archive_state_id, '
                             'Src.purge_priority '                                                       ||
               format('FROM %s Src ', _purgeInfo.PurgeViewName)                                          ||
                           'LEFT OUTER JOIN Tmp_StorageVolsToSkip '
                             'ON Src.storage_server_name = Tmp_StorageVolsToSkip.Storage_Server_Name AND '
                                'Src.server_vol          = Tmp_StorageVolsToSkip.Server_Vol '
                'LEFT OUTER JOIN Tmp_PurgeableDatasets '
                               'ON Src.Dataset_ID = Tmp_PurgeableDatasets.Dataset_ID '
                      'WHERE Tmp_StorageVolsToSkip.Storage_Server_Name IS NULL '
                             'AND Tmp_PurgeableDatasets.Dataset_ID IS NULL';

        If _excludeStageMD5RequiredDatasets Then
            _sql := format('%s AND stage_md5_required = 0 ', _sql);
        End If;

        If _storageServerName <> '' Then
            _sql := format('%s AND Src.storage_server_name = ''%s''', _sql, _storageServerName);
        End If;

        If _serverDisk <> '' Then
            _sql := format('%s AND Src.server_vol = ''%s''', _sql, _serverDisk);
        End If;

        If _purgeInfo.HoldoffDays >= 0 Then
            _sql := format('%s AND %s < CURRENT_TIMESTAMP - make_interval(days => %s)', _sql, _purgeInfo.OrderByCol, _purgeInfo.HoldoffDays);
        End If;

        _sql := format('%s) LookupQ', _sql);
        _sql := format('%s WHERE RowNumVal <= %s', _sql, _previewCount);
        _sql := format('%s ORDER BY storage_server_name, server_vol, archive_state_id, purge_priority, %s, dataset_id', _sql, _purgeInfo.OrderByCol);

        If _previewSql Then
            RAISE INFO '%', _sql;
        End If;

        EXECUTE _sql;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _candidateCount := _candidateCount + _matchCount;

        If Not _infoOnly Then
            If _candidateCount > 0 Then
                If _showDebug Then
                    RAISE INFO 'Found % candidate datasets', _candidateCount;
                End If;

                -- Break out of the for loop
                EXIT;
            End If;

            CONTINUE;
        End If;

        If _storageServerName <> '' And _serverDisk <> '' Then
            If _candidateCount >= _previewCount Then
                -- Break out of the for loop
                EXIT;
            End If;

            CONTINUE;
        End If;

        ---------------------------------------------------
        -- Count the number of candidates on each volume on each storage server
        -- Add entries to Tmp_StorageVolsToSkip
        ---------------------------------------------------

        INSERT INTO Tmp_StorageVolsToSkip (
            Storage_Server_Name,
            Server_Vol
        )
        SELECT Src.Storage_Server_Name,
               Src.Server_Vol
        FROM (SELECT Storage_Server_Name,
                     Server_Vol
              FROM Tmp_PurgeableDatasets
              GROUP BY Storage_Server_Name, Server_Vol
              HAVING COUNT(*) >= _previewCount
             ) AS Src
             LEFT OUTER JOIN Tmp_StorageVolsToSkip AS Target
               ON Src.Storage_Server_Name = Target.Storage_Server_Name AND
                  Src.Server_Vol = Target.Server_Vol
        WHERE Target.Server_Vol IS NULL;

    END LOOP;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview the purge task candidates, then exit
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-8s %-10s %-20s %-55s %-15s %-10s %-14s %-80s %-100s %-100s %-15s %-26s %-20s %-22s %-50s %-50s %-50s %-80s %-25s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'Dataset_ID',
                            'Most_Recent',
                            'Source',
                            'Storage_Server',
                            'Server_Vol',
                            'Purge_Priority',
                            'Dataset',
                            'Dataset_Folder_Path',
                            'Archive_Folder_Path',
                            'Achive_State_ID',
                            'Achive_State_Last_Affected',
                            'Purge_Holdoff_Date',
                            'Instrument_Data_Purged',
                            'Storage_Path_Client',
                            'Storage_Path_Server',
                            'Archive_Path_Unix',
                            'Dataset_Folder_Name',
                            'Instrument',
                            'Dataset_Created',
                            'Dataset_Year_Quarter'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------',
                                     '----------',
                                     '--------------------',
                                     '-------------------------------------------------------',
                                     '---------------',
                                     '----------',
                                     '--------------',
                                     '--------------------------------------------------------------------------------',
                                     '----------------------------------------------------------------------------------------------------',
                                     '----------------------------------------------------------------------------------------------------',
                                     '---------------',
                                     '--------------------------',
                                     '--------------------',
                                     '----------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '-------------------------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Tmp_PurgeableDatasets.EntryID AS Entry_ID,
                   Tmp_PurgeableDatasets.Dataset_ID AS Dataset_ID,
                   public.timestamp_text(Tmp_PurgeableDatasets.MostRecent) AS Most_Recent,
                   Tmp_PurgeableDatasets.Source,
                   Tmp_PurgeableDatasets.Storage_Server_Name AS Storage_Server,
                   Tmp_PurgeableDatasets.Server_Vol AS Server_Vol,
                   Tmp_PurgeableDatasets.Purge_Priority,
                   DFP.Dataset,
                   Left(DFP.Dataset_Folder_Path, 100) AS Dataset_Folder_Path,
                   Left(DFP.Archive_Folder_Path, 100) AS Archive_Folder_Path,
                   DA.archive_state_id AS Achive_State_ID,
                   public.timestamp_text(DA.archive_state_last_affected) AS Achive_State_Last_Affected,
                   public.timestamp_text(DA.purge_holdoff_date) AS Purge_Holdoff_Date,
                   DA.instrument_data_purged AS Instrument_Data_Purged,
                   public.combine_paths(SPath.vol_name_client, SPath.storage_path) AS Storage_Path_Client,
                   public.combine_paths(SPath.vol_name_server, SPath.storage_path) AS Storage_Path_Server,
                   ArchPath.archive_path AS Archive_Path_Unix,
                   DS.folder_name AS Dataset_Folder_Name,
                   DFP.Instrument,
                   public.timestamp_text(DFP.Dataset_Created) AS Dataset_Created,
                   DFP.Dataset_Year_Quarter
            FROM Tmp_PurgeableDatasets
                 INNER JOIN t_dataset_archive DA
                   ON DA.dataset_id = Tmp_PurgeableDatasets.Dataset_ID
                 INNER JOIN V_Dataset_Folder_Paths_Ex DFP
                   ON DA.dataset_id = DFP.dataset_id
                 INNER JOIN t_dataset DS
                   ON DS.dataset_id = DA.dataset_id
                 INNER JOIN t_storage_path SPath
             ON DS.storage_path_id = SPath.storage_path_id
                 INNER JOIN t_archive_path ArchPath
                   ON DA.storage_path_id = ArchPath.archive_path_ID
            ORDER BY Tmp_PurgeableDatasets.EntryID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.Dataset_ID,
                                _previewData.Most_Recent,
                                _previewData.Source,
                                _previewData.Storage_Server,
                                _previewData.Server_Vol,
                                _previewData.Purge_Priority,
                                _previewData.Dataset,
                                _previewData.Dataset_Folder_Path,
                                _previewData.Archive_Folder_Path,
                                _previewData.Achive_State_ID,
                                _previewData.Achive_State_Last_Affected,
                                _previewData.Purge_Holdoff_Date,
                                _previewData.Instrument_Data_Purged,
                                _previewData.Storage_Path_Client,
                                _previewData.Storage_Path_Server,
                                _previewData.Archive_Path_Unix,
                                _previewData.Dataset_Folder_Name,
                                _previewData.Instrument,
                                _previewData.Dataset_Created,
                                _previewData.Dataset_Year_Quarter
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_PurgeableDatasets;
        DROP TABLE Tmp_StorageVolsToSkip;
        DROP TABLE Tmp_PurgeViews;

        RETURN;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Select and lock a specific purgeable dataset by joining
        -- from the local pool to the actual archive table
        ---------------------------------------------------

        SELECT DA.dataset_id
        INTO _datasetID
        FROM t_dataset_archive DA
             INNER JOIN Tmp_PurgeableDatasets DS
               ON DS.Dataset_ID = DA.dataset_id
        WHERE DA.archive_state_id IN (3, 14, 15)
        ORDER BY DS.EntryID
        LIMIT 1
        FOR UPDATE;         -- Lock the row to prevent other managers from purging this dataset

        If Not FOUND Then
            _message := 'No datasets found';
            _returnCode := _noDatasetFound;

            DROP TABLE Tmp_PurgeableDatasets;
            DROP TABLE Tmp_StorageVolsToSkip;
            DROP TABLE Tmp_PurgeViews;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Update archive state to show purge in progress
        ---------------------------------------------------

        UPDATE t_dataset_archive
        SET archive_state_id = 7 -- 'purge in progress'
        WHERE dataset_id = _datasetID;
    END;

    COMMIT;

    ---------------------------------------------------
    -- Get information for assigned dataset
    ---------------------------------------------------

    SELECT DS.dataset AS Dataset,
           DS.dataset_id AS DatasetID,
           DS.folder_name AS Folder,
           SPath.vol_name_server AS ServerDisk,
           SPath.storage_path AS StoragePath,
           SPath.vol_name_client AS ServerDiskExternal,
           InstClass.raw_data_type AS RawDataType,
           t_archive_path.network_share_path AS SambaStoragePath,
           DFP.instrument AS Instrument,
           DFP.Dataset_Created AS DatasetCreated,
           DFP.Dataset_Year_Quarter AS DatasetYearQuarter,
           DA.purge_policy AS PurgePolicy
    INTO _datasetInfo
    FROM t_dataset DS
         INNER JOIN t_dataset_archive DA
           ON DS.dataset_id = DA.dataset_id
         INNER JOIN t_storage_path SPath
           ON DS.storage_path_id = SPath.storage_path_id
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_instrument_class InstClass
           ON InstName.instrument_class = InstClass.instrument_class
         INNER JOIN t_archive_path
           ON DA.storage_path_id = t_archive_path.archive_path_id
         INNER JOIN V_Dataset_Folder_Paths_Ex DFP
           ON DA.dataset_id = DFP.dataset_id
    WHERE DS.dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Find purgeable dataset operation failed (empty results populating _datasetInfo for Dataset ID %s', _datasetID);

        DROP TABLE Tmp_PurgeableDatasets;
        DROP TABLE Tmp_StorageVolsToSkip;
        DROP TABLE Tmp_PurgeViews;

        RETURN;
    End If;

    Open _results For
        SELECT 'dataset' AS Parameter, _datasetInfo.Dataset::text AS Value            -- Yes, the parameter name is lowercase "dataset"
        UNION
        SELECT 'DatasetID' AS Parameter, _datasetInfo.DatasetID::text AS Value
        UNION
        SELECT 'Folder' AS Parameter, _datasetInfo.Folder::text AS Value
        UNION
        SELECT 'StorageVol' AS Parameter, _datasetInfo.ServerDisk::text AS Value
        UNION
        SELECT 'storagePath' AS Parameter, _datasetInfo.StoragePath::text AS Value
        UNION
        SELECT 'StorageVolExternal' AS Parameter, _datasetInfo.ServerDiskExternal::text AS Value
        UNION
        SELECT 'RawDataType' AS Parameter, _datasetInfo.RawDataType::text AS Value
        UNION
        SELECT 'SambaStoragePath' AS Parameter, _datasetInfo.SambaStoragePath::text AS Value
        UNION
        SELECT 'Instrument' AS Parameter, _datasetInfo.Instrument::text AS Value
        UNION
        SELECT 'DatasetCreated' AS Parameter, public.timestamp_text(_datasetInfo.DatasetCreated) AS Value
        UNION
        SELECT 'DatasetYearQuarter' AS Parameter, _datasetInfo.DatasetYearQuarter::text AS Value
        UNION
        SELECT 'PurgePolicy' AS Parameter, _datasetInfo.PurgePolicy::text AS Value;

    DROP TABLE Tmp_PurgeableDatasets;
    DROP TABLE Tmp_StorageVolsToSkip;
    DROP TABLE Tmp_PurgeViews;
END
$_$;


ALTER PROCEDURE public.request_purge_task(IN _storageservername text, IN _serverdisk text, IN _excludestagemd5requireddatasets boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _previewcount integer, IN _previewsql boolean, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE request_purge_task(IN _storageservername text, IN _serverdisk text, IN _excludestagemd5requireddatasets boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _previewcount integer, IN _previewsql boolean, IN _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.request_purge_task(IN _storageservername text, IN _serverdisk text, IN _excludestagemd5requireddatasets boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _previewcount integer, IN _previewsql boolean, IN _showdebug boolean) IS 'RequestPurgeTask';

