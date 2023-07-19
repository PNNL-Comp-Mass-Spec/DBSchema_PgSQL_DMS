--
CREATE OR REPLACE PROCEDURE public.request_purge_task
(
    _storageServerName text,
    _serverDisk text,
    _excludeStageMD5RequiredDatasets boolean = true,
    INOUT _results refcursor DEFAULT '_results'::refcursor
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _previewCount int = 5,
    _previewSql boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for dataset that is best candidate to be purged
**      If found, dataset archive status is set to 'Purge In Progress'
**      and information needed for purge task is returned
**      in the output arguments
**
**      Alternatively, if _infoOnly is true, will return the
**      next _datasetsPerShare datasets that would be purged on the specified server,
**      or on a series of servers (if _storageServerName and/or _serverDisk are blank)
**
**      Note that PreviewPurgeTaskCandidates calls this procedure with_infoOnly to true
**
**  If DatasetID is returned 0, no available dataset was found
**
**  Example syntax for Preview:
**     SELECT request_purge_task ('proto-9', _serverDisk => 'g:\', _infoOnly => true);
**
**  Arguments:
**    _storageServerName                Storage server to use, for example 'proto-9'; if blank, returns candidates for all storage servers; when blank, _serverDisk is ignored
**    _serverDisk                       Disk on storage server to use, for example 'g:\'; if blank, returns candidates for all drives on given server (or all servers if _storageServerName is blank)
**    _excludeStageMD5RequiredDatasets  If true, excludes datasets with StageMD5_Required > 0
**    _results                          Cursor for retrieving the job parameters
**    _message                          Output: message (if an error)
**    _returnCode                       Output: return code (if an error)
**    _infoOnly                         When true, preview the first _previewCount candidates
**    _previewCount                     Number of purge candidates to show when _infoOnly is true; set to -1 to preview the Parameter table that would be returned if a single purge task candidate was chosen from Tmp_PurgeableDatasets
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL cap.request_purge_task (
**              _storageServerName => 'Proto-3',
**              _serverDisk => 'F',
**              _message => _message,
**              _returnCode => _returnCode
**          );
**          FETCH ALL FROM _results;
**      END;
**
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
**          01/16/2012 mem - Now returning Instrument, Dataset_Created, and Dataset_YearQuarter when _previewSql
**          01/18/2012 mem - Now including Instrument, DatasetCreated, and DatasetYearQuarter when requesting an actual purge task (_infoOnly = false)
**                         - Using _infoOnly = true and _previewCount = -1 will now show the parameter table that would be returned if an actual purge task were assigned
**          06/14/2012 mem - Now sorting by Purge_Priority, then by OrderByCol
**                         - Now including PurgePolicy in the job parameters table (0=Auto, 1=Purge All except QC Subfolder, 2=Purge All)
**                         - Now looking for state 3, 14, or 15 when actually selecting a dataset to purge
**          06/07/2013 mem - Now sorting by Archive_State_ID, Purge_Priority, then OrderByCol
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/02/2018 mem - Change the return code for 'dataset not found' to 53000
**          02/01/2023 mem - Use new view names
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _candidateCount int := 0;
    _purgeInfo record;
    _purgeViewSourceDesc text;
    _sql text;
    _noDatasetFound text = 'U5300';
    _datasetID int = 0,

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _excludeStageMD5RequiredDatasets := Coalesce(_excludeStageMD5RequiredDatasets, true);
    _infoOnly := Coalesce(_infoOnly, false);
    _previewCount := Coalesce(_previewCount, 10);
    _previewSql := Coalesce(_previewSql, false);

    --------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------
    _storageServerName := Coalesce(_storageServerName, '');

    If _storageServerName = '' Then
        _serverDisk := '';
    Else
        _serverDisk := Coalesce(_serverDisk, '');
    End If;


    If Not _infoOnly Or _infoOnly And _previewCount < 0 Then
        -- Verify that both _storageServerName and _serverDisk are specified
        If _storageServerName = '' OR _serverDisk = '' Then
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
        DatasetID int,
        MostRecent timestamp,
        Source text,
        StorageServerName text NULL,
        ServerVol text NULL,
        Purge_Priority int
    );

    CREATE INDEX IX_Tmp_PurgeableDatasets_StorageServerAndVol ON Tmp_PurgeableDatasets (StorageServerName, ServerVol);

    CREATE TEMP TABLE Tmp_StorageVolsToSkip (
        StorageServerName text,
        ServerVol text
    );

    CREATE TEMP TABLE Tmp_PurgeViews (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        PurgeViewName text,
        HoldoffDays int,
        OrderByCol text
    )

    ---------------------------------------------------
    -- Reset AS_StageMD5_Required for any datasets with AS_purge_holdoff_date older than the current date/time
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
    VALUES ('V_Purgeable_Datasets_NoInterest_NoRecentJob', 120, 'Created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoJob',                  180, 'Created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets',                        365, 'MostRecentJob');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoInterest_NoRecentJob', 21,  'Created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoJob',                  21,  'Created');

    INSERT INTO Tmp_PurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets',     21,  'MostRecentJob');

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
        ** The following is a simpler query that can be used when
        **   looking for candidates on a specific volume on a specific server
        ** It is more efficient than the larger query below (which uses Row_Number() to rank things)
        ** However, it doesn't run that much faster, and thus, for simplicity, we're always using the larger query
        **
            _sql :=        'INSERT INTO Tmp_PurgeableDatasets( DatasetID, MostRecent, Source, StorageServerName, ServerVol, Purge_Priority) '
                           'SELECT Dataset_ID, '                                    ||
                            format('%s, ', _purgeInfo.OrderByCol)                   ||
                            format('''%s'' AS Source, ', _purgeInfo.PurgeViewName)  ||
                                  'StorageServerName, '                             ||
                                  'ServerVol, '                                     ||
                                  'Purge_Priority '                                 ||
                    format('FROM %s ', _purgeInfo.PurgeViewName)                    ||
                    format('WHERE StorageServerName = ''%s'' ', _storageServerName) ||
                    format(      'AND ServerVol = ''%s''', _serverDisk);

            If _excludeStageMD5RequiredDatasets Then
                _sql := format('%s AND StageMD5_Required = 0 ', _sql);
            End If;

            If _purgeInfo.HoldoffDays >= 0 Then
                _sql := format('%s AND (%s < CURRENT_TIMESTAMP - make_interval(days => %s)', _sql, _purgeInfo.OrderByCol, _purgeInfo.HoldoffDays);
            End If;

            _sql := format('%s ORDER BY Purge_Priority, %s, Dataset_ID', _sql, _purgeInfo.OrderByCol);
            _sql := format('%s LIMIT %s', _sql, _previewCount);
        */

        _purgeViewSourceDesc := _purgeInfo.PurgeViewName;

        If _purgeInfo.HoldoffDays >= 0 Then
            _purgeViewSourceDesc := format('%s_%sMinDays', _purgeViewSourceDesc, _purgeInfo.HoldoffDays);
        End If;

        ---------------------------------------------------
        -- Find the top _previewCount candidates for each drive on each server
        -- (limiting by _storageServerName or _serverDisk if they are defined)
        ---------------------------------------------------

        _sql :=  'INSERT INTO Tmp_PurgeableDatasets( DatasetID, MostRecent, Source, StorageServerName, ServerVol, Purge_Priority) '
                 'SELECT Dataset_ID, '                                                                    ||
                 format('%s, ', _purgeInfo.OrderByCol)                                                    ||
                       'Source, '
                       'StorageServerName, '
                       'ServerVol, '
                       'Purge_Priority '
                 'FROM (SELECT Src.Dataset_ID, '                                                          ||
                       format('Src.%s, ', _purgeInfo.OrderByCol)                                          ||
                       format('''%s'' AS Source, ', _purgeViewSourceDesc)                                 ||
                              'Row_Number() OVER ( PARTITION BY Src.StorageServerName, Src.ServerVol '    ||
                                           format('ORDER BY Src.Archive_State_ID, Src.Purge_Priority, Src.%s, Src.Dataset_ID ) AS RowNumVal, ', _purgeInfo.OrderByCol) ||
                              'Src.StorageServerName, '
                              'Src.ServerVol, '
                              'Src.StageMD5_Required, '
                              'Src.Archive_State_ID, '
                              'Src.Purge_Priority '                                                       ||
                format('FROM %s Src ', _purgeInfo.PurgeViewName)                                          ||
                            'LEFT OUTER JOIN Tmp_StorageVolsToSkip '
                              'ON Src.StorageServerName = Tmp_StorageVolsToSkip.StorageServerName AND '
                                 'Src.ServerVol         = Tmp_StorageVolsToSkip.ServerVol '
                 'LEFT OUTER JOIN Tmp_PurgeableDatasets '
                                'ON Src.Dataset_ID = Tmp_PurgeableDatasets.DatasetID '
                       'WHERE Tmp_StorageVolsToSkip.StorageServerName IS NULL '
                              'AND Tmp_PurgeableDatasets.DatasetID IS NULL';

        If _excludeStageMD5RequiredDatasets Then
            _sql :=  format('%s AND (StageMD5_Required = 0) ', _sql);
        End If;

        If _storageServerName <> '' Then
            _sql :=  format('%s AND (Src.StorageServerName = ''%s'')', _sql, _storageServerName);
        End If;

        If _serverDisk <> '' Then
            _sql :=  format('%s AND (Src.ServerVol = '''')', _sql, _serverDisk);
        End If;

        If _purgeInfo.HoldoffDays >= 0 Then
            _sql :=  format('%s AND (%s < CURRENT_TIMESTAMP - make_interval(days => %s)', _sql, _purgeInfo.OrderByCol, _purgeInfo.HoldoffDays);
        End If;

        _sql := format('%s) LookupQ', _sql);
        _sql := format('%s WHERE RowNumVal <= %s', _sql, _previewCount);
        _sql := format('%s ORDER BY StorageServerName, ServerVol, Archive_State_ID, Purge_Priority, %s, Dataset_ID', _sql, _purgeInfo.OrderByCol);

        If _previewSql Then
            RAISE INFO '%', _sql;
        End If;

        EXECUTE _sql;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _candidateCount := _candidateCount + _matchCount;


        If Not _infoOnly Then
            If _CandidateCount > 0 Then
                -- Break out of the For Loop
                EXIT;
            End If;

            CONTINUE;
        End If;

        If _storageServerName <> '' AND _serverDisk <> '' Then
            If _candidateCount >= _previewCount Then
                -- Break out of the For Loop
                EXIT;
            End If;

            CONTINUE;
        End If;


        ---------------------------------------------------
        -- Count the number of candidates on each volume on each storage server
        -- Add entries to Tmp_StorageVolsToSkip
        ---------------------------------------------------

        INSERT INTO Tmp_StorageVolsToSkip( StorageServerName,
                                           ServerVol )
        SELECT Src.StorageServerName,
               Src.ServerVol
        FROM ( SELECT StorageServerName,
                      ServerVol
               FROM Tmp_PurgeableDatasets
               GROUP BY StorageServerName, ServerVol
               HAVING COUNT(*) >= _previewCount
             ) AS Src
             LEFT OUTER JOIN Tmp_StorageVolsToSkip AS Target
               ON Src.StorageServerName = Target.StorageServerName AND
                  Src.ServerVol = Target.ServerVol
        WHERE Target.ServerVol IS NULL

    END LOOP;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        ---------------------------------------------------
        -- Preview the purge task candidates, then exit
        ---------------------------------------------------


        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---',
                                     '---',
                                     '---',
                                     '---',
                                     '---'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Tmp_PurgeableDatasets.EntryID As Entry_ID,
                   Tmp_PurgeableDatasets.DatasetID As Dataset_ID,
                   Tmp_PurgeableDatasets.MostRecent As Most_Recent,
                   Tmp_PurgeableDatasets.Source,
                   Tmp_PurgeableDatasets.StorageServerName As Storage_Server,
                   Tmp_PurgeableDatasets.ServerVol As Server_Vol,
                   Tmp_PurgeableDatasets.Purge_Priority,
                   DFP.Dataset,
                   DFP.Dataset_Folder_Path,
                   DFP.Archive_Folder_Path,
                   DA.archive_state_id AS Achive_State_ID,
                   DA.archive_state_last_affected AS Achive_State_Last_Affected,
                   DA.purge_holdoff_date AS Purge_Holdoff_Date,
                   DA.instrument_data_purged AS Instrument_Data_Purged,
                   public.combine_paths(SPath.vol_name_client, SPath.storage_path) AS Storage_Path_Client,
                   public.combine_paths(SPath.vol_name_server, SPath.storage_path) AS Storage_Path_Server,
                   ArchPath.archive_path AS Archive_Path_Unix,
                   DS.folder_name AS Dataset_Folder_Name,
                   DFP.Instrument,
                   DFP.Dataset_Created,
                   DFP.Dataset_YearQuarter
            FROM Tmp_PurgeableDatasets
                 INNER JOIN t_dataset_archive DA
                   ON DA.dataset_id = Tmp_PurgeableDatasets.DatasetID
                 INNER JOIN V_Dataset_Folder_Paths_Ex DFP
                   ON DA.dataset_id = DFP.dataset_id
                 INNER JOIN t_dataset DS
                   ON DS.dataset_id = DA.dataset_id
                 INNER JOIN t_storage_path SPath
             ON DS.storage_path_id = SPath.storage_path_id
                 INNER JOIN t_archive_path ArchPath
                   ON DA.storage_path_id = ArchPath.AP_path_ID
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
                                    _previewData.Dataset_YearQuarter
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

        SELECT dataset_id
        INTO _datasetID
        FROM t_dataset_archive
             INNER JOIN Tmp_PurgeableDatasets
               ON DatasetID = dataset_id
        WHERE archive_state_id IN (3, 14, 15)
        ORDER BY Tmp_PurgeableDatasets.EntryID
        LIMIT 1;

        If Not FOUND Then
            _message := 'no datasets found';
            _returnCode := _noDatasetFound;

            DROP TABLE Tmp_PurgeableDatasets;
            DROP TABLE Tmp_StorageVolsToSkip;
            DROP TABLE Tmp_PurgeViews;

            RETURN;
        End If;

        If Not _infoOnly Then
            ---------------------------------------------------
            -- Update archive state to show purge in progress
            ---------------------------------------------------

            UPDATE t_dataset_archive
            SET archive_state_id = 7 -- 'purge in progress'
            WHERE dataset_id = _datasetID;

        End If;
    END;

    COMMIT;

    ---------------------------------------------------
    -- Get information for assigned dataset
    ---------------------------------------------------

    SELECT DS.dataset As Dataset,
           DS.dataset_id As DatasetID,
           DS.folder_name As Folder,
           SPath.vol_name_server As ServerDisk,
           SPath.storage_path As StoragePath,
           SPath.vol_name_client As ServerDiskExternal,
           InstClass.raw_data_type As RawDataType,
           t_archive_path.network_share_path As SambaStoragePath,
           DFP.instrument As Instrument,
           DFP.Dataset_Created As DatasetCreated,
           DFP.Dataset_YearQuarter As DatasetYearQuarter,
           DA.purge_policy As PurgePolicy
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
        SELECT 'dataset' As Parameter, _datasetInfo.Dataset::text As Value            -- Yes, the parameter name is lowercase "dataset"
        UNION
        SELECT 'DatasetID' As Parameter, _datasetInfo.DatasetID::text As Value
        UNION
        SELECT 'Folder' As Parameter, _datasetInfo.Folder::text As Value
        UNION
        SELECT 'StorageVol' As Parameter, _datasetInfo.ServerDisk::text As Value
        UNION
        SELECT 'storagePath' As Parameter, _datasetInfo.StoragePath::text As Value
        UNION
        SELECT 'StorageVolExternal' As Parameter, _datasetInfo.ServerDiskExternal::text As Value
        UNION
        SELECT 'RawDataType' As Parameter, _datasetInfo.RawDataType::text As Value
        UNION
        SELECT 'SambaStoragePath' As Parameter, _datasetInfo.SambaStoragePath::text As Value
        UNION
        SELECT 'Instrument' As Parameter, _datasetInfo.Instrument::text As Value
        UNION
        SELECT 'DatasetCreated' As Parameter, public.timestamp_text(_datasetInfo.DatasetCreated) As Value
        UNION
        SELECT 'DatasetYearQuarter' As Parameter, _datasetInfo.DatasetYearQuarter::text As Value
        UNION
        SELECT 'PurgePolicy' As Parameter, _datasetInfo.PurgePolicy::text As Value;

    DROP TABLE Tmp_PurgeableDatasets;
    DROP TABLE Tmp_StorageVolsToSkip;
    DROP TABLE Tmp_PurgeViews;
END
$$;

COMMENT ON FUNCTION public.request_purge_task IS 'RequestPurgeTask';
