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
**          02/11/2005 grk - added _rawDataType to output
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
    _myRowCount int := 0;
    _candidateCount int := 0;
    _purgeQuery record;
    _purgeViewSourceDesc text;
    _s text;
    _noDatasetFound text = 'U5300';

    /*
        _dataset text = '',
        _datasetID int = 0,
        _folder text = '',
        _storagePath text,
        _serverDiskExternal text = '',
        _rawDataType text = '',
        _sambaStoragePath text = '',
        _instrument text = '',
        _datasetCreated timestamp,
        _datasetYearQuarter text = '',
        _purgePolicy int
    */

BEGIN

    _excludeStageMD5RequiredDatasets := Coalesce(_excludeStageMD5RequiredDatasets, true);
    _infoOnly := Coalesce(_infoOnly, false);
    _previewCount := Coalesce(_previewCount, 10);
    _previewSql := Coalesce(_previewSql, false);

    _message := '';
    _returnCode := '';

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
        DatasetID  int,
        MostRecent  timestamp,
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

    FOR _purgeQuery IN
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
                _s := '';

                _s := _s || ' INSERT INTO Tmp_PurgeableDatasets( DatasetID,';
                _s := _s ||                  ' MostRecent,';
                _s := _s ||                  ' Source,';
                _s := _s ||                  ' StorageServerName,';
                _s := _s ||                  ' ServerVol,';
                _s := _s ||                  ' Purge_Priority)';
                _s := _s || ' SELECT Dataset_ID, ';
                _s := _s ||          _orderByCol || ', ';
                _s := _s ||        '''' || _purgeViewName || ''' AS Source,';
                _s := _s ||        ' StorageServerName,';
                _s := _s ||        ' ServerVol,';
                _s := _s ||        ' Purge_Priority';
                _s := _s || ' FROM ' || _purgeViewName;
                _s := _s || ' WHERE     (StorageServerName = ''' || _storageServerName || ''')';
                _s := _s ||       ' AND (ServerVol = ''' || _serverDisk || ''')';

                If _excludeStageMD5RequiredDatasets Then
                    _s := _s ||   ' AND (StageMD5_Required = 0) ';
                End If;

                If _holdoffDays >= 0 Then
                    _s := _s ||   ' AND (round(extract(epoch FROM CURRENT_TIMESTAMP - ' || _orderByCol || ') / 86400) > ' || _holdoffDays::text || ')';
                End If;

                _s := _s || ' ORDER BY Purge_Priority, ' || _orderByCol || ', Dataset_ID';
                _s := _s || ' LIMIT ' || _previewCount::text;
            */

            _purgeViewSourceDesc := _purgeViewName;
            If _holdoffDays >= 0 Then
                _purgeViewSourceDesc := _purgeViewSourceDesc || '_' || _holdoffDays::text || 'MinDays';
            End If;

            ---------------------------------------------------
            -- Find the top _previewCount candidates for each drive on each server
            -- (limiting by _storageServerName or _serverDisk if they are defined)
            ---------------------------------------------------
            --
            _s := '';
            _s := _s || ' INSERT INTO Tmp_PurgeableDatasets( DatasetID,';
            _s := _s ||                  ' MostRecent,';
            _s := _s ||                  ' Source,';
            _s := _s ||                  ' StorageServerName,';
            _s := _s ||                  ' ServerVol,';
            _s := _s ||                  ' Purge_Priority)';
            _s := _s || ' SELECT Dataset_ID, ';
            _s := _s ||        _orderByCol || ', ';
            _s := _s ||        ' Source,';
            _s := _s ||        ' StorageServerName,';
            _s := _s ||        ' ServerVol,';
            _s := _s ||        ' Purge_Priority';
            _s := _s || ' FROM ( SELECT Src.Dataset_ID, ';
            _s := _s ||                'Src.' || _orderByCol || ', ';
            _s := _s ||               '''' || _purgeViewSourceDesc || ''' AS Source,';
            _s := _s ||               ' Row_Number() OVER ( PARTITION BY Src.StorageServerName, Src.ServerVol ';
            _s := _s ||                                   ' ORDER BY Src.Archive_State_ID, Src.Purge_Priority, Src.' || _orderByCol || ', Src.Dataset_ID ) AS RowNumVal,';
            _s := _s ||               ' Src.StorageServerName,';
            _s := _s ||               ' Src.ServerVol,';
            _s := _s ||               ' Src.StageMD5_Required,';
            _s := _s ||               ' Src.Archive_State_ID,';
            _s := _s ||         ' Src.Purge_Priority';
            _s := _s ||        ' FROM ' || _purgeViewName || ' Src';
            _s := _s ||               ' LEFT OUTER JOIN Tmp_StorageVolsToSkip ';
            _s := _s ||                 ' ON Src.StorageServerName = Tmp_StorageVolsToSkip.StorageServerName AND';
            _s := _s ||                ' Src.ServerVol         = Tmp_StorageVolsToSkip.ServerVol ';
            _s := _s || ' LEFT OUTER JOIN Tmp_PurgeableDatasets ';
            _s := _s ||                 ' ON Src.Dataset_ID = Tmp_PurgeableDatasets.DatasetID';
            _s := _s ||        ' WHERE Tmp_StorageVolsToSkip.StorageServerName IS NULL';
            _s := _s ||               ' AND Tmp_PurgeableDatasets.DatasetID IS NULL ';

            If _excludeStageMD5RequiredDatasets Then
                _s := _s ||       ' AND (StageMD5_Required = 0) ';
            End If;

            If _storageServerName <> '' Then
                _s := _s ||  ' AND (Src.StorageServerName = ''' || _storageServerName || ''')';
            End If;

            If _serverDisk <> '' Then
                _s := _s ||           ' AND (Src.ServerVol = ''' || _serverDisk || ''')';
            End If;

            If _holdoffDays >= 0 Then
                _s := _s ||           ' AND (' || _orderByCol || ' < CURRENT_TIMESTAMP - make_interval(days => ' || _holdoffDays::text || ')';
            End If;

            _s := _s ||     ') LookupQ';
            _s := _s || ' WHERE RowNumVal <= ' || Cast(_previewCount as text);
            _s := _s || ' ORDER BY StorageServerName, ServerVol, Archive_State_ID, Purge_Priority, ' || _orderByCol || ', Dataset_ID';

            If _previewSql Then
                RAISE INFO '%', _s;
            End If;

            EXECUTE _s;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _candidateCount := _candidateCount + _myRowCount;

            If (Not _infoOnly Or _infoOnly And _previewCount < 0) Then
                If _candidateCount > 0 Then
                    _continue := false;
                End If;
            Else
            -- <c>
                If _storageServerName <> '' AND _serverDisk <> '' Then
                    If _candidateCount >= _previewCount Then
                        _continue := false;
                    End If;
                Else
                -- <d>
                    ---------------------------------------------------
                    -- Count the number of candidates on each volume on each storage server
                    -- Add entries to Tmp_StorageVolsToSkip
                    ---------------------------------------------------
                    --
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

                End If; -- </d>

            End If; -- </c>

        End If; -- </b>
    END LOOP; -- </a>

    If _infoOnly Then
        ---------------------------------------------------
        -- Preview the purge task candidates, then exit
        ---------------------------------------------------
        --
        -- ToDo: Update this to use RAISE INFO

        SELECT Tmp_PurgeableDatasets.*,
               DFP.dataset,
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
               DFP.instrument,
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

        COMMIT;
    END;

    ---------------------------------------------------
    -- Get information for assigned dataset
    ---------------------------------------------------
    --
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
        SELECT 'dataset' As Parameter, _datasetInfo.Dataset As Value
        UNION
        SELECT 'DatasetID' As Parameter, _datasetInfo.DatasetID As Value
        UNION
        SELECT 'Folder' As Parameter, _datasetInfo.Folder As Value
        UNION
        SELECT 'StorageVol' As Parameter, _datasetInfo.ServerDisk As Value
        UNION
        SELECT 'storagePath' As Parameter, _datasetInfo.StoragePath As Value
        UNION
        SELECT 'StorageVolExternal' As Parameter, _datasetInfo.ServerDiskExternal As Value
        UNION
        SELECT 'RawDataType' As Parameter, _datasetInfo.RawDataType As Value
        UNION
        SELECT 'SambaStoragePath' As Parameter, _datasetInfo.SambaStoragePath As Value
        UNION
        SELECT 'Instrument' As Parameter, _datasetInfo.Instrument As Value
        UNION
        SELECT 'DatasetCreated' As Parameter, public.timestamp_text(_datasetInfo.DatasetCreated) As Value
        UNION
        SELECT 'DatasetYearQuarter' As Parameter, _datasetInfo.DatasetYearQuarter As Value
        UNION
        SELECT 'PurgePolicy' As Parameter, _datasetInfo.PurgePolicy As Value;

    DROP TABLE Tmp_PurgeableDatasets;
    DROP TABLE Tmp_StorageVolsToSkip;
    DROP TABLE Tmp_PurgeViews;
END
$$;

COMMENT ON FUNCTION public.request_purge_task IS 'RequestPurgeTask';
