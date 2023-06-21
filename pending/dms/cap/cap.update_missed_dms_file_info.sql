--
CREATE OR REPLACE PROCEDURE cap.update_missed_dms_file_info
(
    _deleteFromTableOnSuccess boolean = true,
    _replaceExistingData boolean = false,
    _datasetIDs text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Calls update_dataset_file_info_xml for datasets
**      that have info defined in T_Dataset_Info_XML
**      yet the dataset has a null value for File_Info_Last_Modified in DMS
**
**  Auth:   mem
**  Date:   12/19/2011 mem - Initial version
**          02/24/2015 mem - Now skipping deleted datasets
**          05/05/2015 mem - Added parameter _replaceExistingData
**          08/02/2016 mem - Continue processing on errors (but log the error)
**          06/13/2018 mem - Check for error code 53600 (aka 'U5360') returned by update_dms_file_info_xml to indicate a duplicate dataset
**                         - Add parameter _datasetIDs
**          08/09/2018 mem - Filter out dataset info XML entries where Ignore is 1
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _datasetID int;
    _logMsg text;
    _logMsgType text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _deleteFromTableOnSuccess := Coalesce(_deleteFromTableOnSuccess, true);
    _replaceExistingData := Coalesce(_replaceExistingData, false);
    _datasetIDs := Coalesce(_datasetIDs, '');
    _infoOnly := Coalesce(_infoOnly, false);

    --------------------------------------------
    -- Create a table to hold datasets to process
    --------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToProcess (
        Dataset_ID int not null
    )

    CREATE INDEX IX_Tmp_DatasetsToProcess ON Tmp_DatasetsToProcess (Dataset_ID)

    --------------------------------------------
    -- Look for Datasets with entries in cap.t_dataset_info_xml but null values for File_Info_Last_Modified in DMS
    -- Alternatively, if _replaceExistingData is true, process all entries in cap.t_dataset_info_xml
    --------------------------------------------

    INSERT INTO Tmp_DatasetsToProcess (dataset_id)
    SELECT DI.dataset_id
    FROM cap.t_dataset_info_xml DI
         LEFT OUTER JOIN public.t_dataset DS
           ON DI.dataset_id = DS.dataset_id
    WHERE (DS.File_Info_Last_Modified IS NULL Or _replaceExistingData) And
          DI.ignore = 0;

    --------------------------------------------
    -- Possibly filter on _datasetIDs
    --------------------------------------------

    DELETE Tmp_DatasetsToProcess
    WHERE NOT Dataset_ID IN ( SELECT Value
                              FROM public.parse_delimited_integer_list ( _datasetIDs, ',' ) )

    --------------------------------------------
    -- Delete any entries that don't exist in public.t_dataset
    --------------------------------------------

    DELETE FROM Tmp_DatasetsToProcess
    WHERE NOT EXISTS (SELECT DS.Dataset_ID
                      FROM public.t_dataset DS
                      WHERE DS.Dataset_ID = Tmp_DatasetsToProcess.Dataset_ID);
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _message := format('Ignoring %s %s in cap.t_dataset_info_xml because they do not exist in public.t_dataset',
                            _matchCount, public.check_plural(_matchCount, 'dataset', 'datasets'));

        CALL public.post_log_entry ('Info', _message, 'Update_Missed_DMS_File_Info', 'cap');

        --------------------------------------------
        -- Delete any entries in cap.t_dataset_info_xml that were cached over 7 days ago and do not exist in public.t_dataset
        --------------------------------------------

        DELETE FROM cap.t_dataset_info_xml
        WHERE Cache_Date < CURRENT_TIMESTAMP - Interval '7 days' AND
              NOT EXISTS (SELECT DS.Dataset_ID
                          FROM public.t_dataset DS
                          WHERE DS.Dataset_ID = cap.t_dataset_info_xml.Dataset_ID);

    End If;

    --------------------------------------------
    -- Look for datasets with conflicting values for scan count or file size
    -- Will only update if the cache_date in cap.t_dataset_info_xml is newer than
    -- the File_Info_Last_Modified date in T_Dataset
    --------------------------------------------


    -- ToDo: Update this to use xpath()

    INSERT INTO Tmp_DatasetsToProcess (Dataset_ID)
    SELECT Dataset_ID
           -- , Scan_Count_Old, ScanCountNew
           -- , File_Size_Bytes_Old, FileSizeBytesNew
    FROM ( SELECT dataset_id,
                  Scan_Count_Old,
                  File_Size_Bytes_Old,
                  ds_info_xml.query('/DatasetInfo/AcquisitionInfo/ScanCount').value('(/ScanCount)[1]', 'int') AS ScanCountNew,
                  ds_info_xml.query('/DatasetInfo/AcquisitionInfo/FileSizeBytes').value('(/FileSizeBytes)[1]', 'bigint') AS FileSizeBytesNew
            FROM ( SELECT DI.dataset_id,
                          DI.cache_date,
                          DS.File_Info_Last_Modified,
                          DS.Dataset,
                          DI.ds_info_xml,
                          DS.Scan_Count AS Scan_Count_Old,
                          DS.File_Size_Bytes AS File_Size_Bytes_Old
                  FROM cap.t_dataset_info_xml DI
                       INNER JOIN public.t_dataset DS
                         ON DI.dataset_id = DS.dataset_id AND
                            DI.cache_date > DS.File_Info_Last_Modified
                  WHERE DI.ignore = 0
                  ) InnerQ
         ) FilterQ
    WHERE (ScanCountNew <> Coalesce(Scan_Count_Old, 0)) OR
          (FileSizeBytesNew <> Coalesce(File_Size_Bytes_Old, 0) AND FileSizeBytesNew > 0);

    --------------------------------------------
    -- Process each of the datasets in Tmp_DatasetsToProcess
    --------------------------------------------

    FOR _datasetID IN
        SELECT Dataset_ID
        FROM Tmp_DatasetsToProcess
        ORDER BY Dataset_ID
    LOOP
        CALL cap.update_dms_file_info_xml (
                        _datasetID,
                        _deleteFromTableOnSuccess,
                        _message => _message,
                        _returnCode => _returnCode,
                        _infoOnly => _infoOnly);

        If Coalesce(_returnCode, '') <> '' Then
            If _returnCode = 'U5360' Then
                -- A duplicate dataset was detected
                -- An error message will have already been logged in public.t_log_entries, so we can log a warning message here
                _logMsgType := 'Warning';
            Else
                _logMsgType := 'Error';
            End If;

            If Coalesce(_message, '') = '' Then
                _logMsg := format('update_dms_file_info_xml returned error code %s for DatasetID %s', _returnCode, _datasetID)
            Else
                _logMsg := format('update_dms_file_info_xml error: %s', _message);
            End If;

            If _infoOnly Then
                RAISE INFO '%', _logMsg;
            Else
                CALL public.post_log_entry (_logMsgType, _logMsg, 'Update_Missed_DMS_File_Info', 'cap', _duplicateEntryHoldoffHours => 22);
            End If;

        End If;

    END LOOP;

    DROP TABLE Tmp_DatasetsToProcess;
END
$$;

COMMENT ON PROCEDURE cap.update_missed_dms_file_info IS 'UpdateMissedDMSFileInfo';
