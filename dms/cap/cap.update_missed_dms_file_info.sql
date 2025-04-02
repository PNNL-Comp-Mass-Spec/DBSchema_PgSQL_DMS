--
-- Name: update_missed_dms_file_info(boolean, boolean, text, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_missed_dms_file_info(IN _deletefromtableonsuccess boolean DEFAULT true, IN _replaceexistingdata boolean DEFAULT false, IN _datasetids text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Call public.update_dataset_file_info_xml for datasets that have info defined in cap.t_dataset_info_xml,
**      yet the dataset has a null value for File_Info_Last_Modified in public.t_dataset_info
**
**  Arguments:
**    _deleteFromTableOnSuccess     When true, delete from cap.t_dataset_info_xml after storing the data in public.t_dataset_info
**    _replaceExistingData          When true, replace existing data
**    _datasetIDs                   Comma-separated list of dataset IDs
**    _message                      Status message
**    _returnCode                   Return code
**    _infoOnly                     When true, preview updates
**
**  Auth:   mem
**  Date:   12/19/2011 mem - Initial version
**          02/24/2015 mem - Now skipping deleted datasets
**          05/05/2015 mem - Added parameter _replaceExistingData
**          08/02/2016 mem - Continue processing on errors (but log the error)
**          06/13/2018 mem - Check for error code 53600 (aka 'U5360') returned by update_dms_file_info_xml to indicate a duplicate dataset
**                         - Add parameter _datasetIDs
**          08/09/2018 mem - Filter out dataset info XML entries where Ignore is true (previously 1)
**          06/28/2023 mem - Fix bug that deleted all rows in the temporary table when _datasetIDs was an empty string
**                         - Ported to PostgreSQL
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          01/15/2025 mem - Set _logErrorsToPublicLogTable to false when logging errors
**          03/31/2025 mem - Show an update summary message
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _datasetsProcessed int := 0;
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
    _replaceExistingData      := Coalesce(_replaceExistingData, false);
    _datasetIDs               := Trim(Coalesce(_datasetIDs, ''));
    _infoOnly                 := Coalesce(_infoOnly, false);

    --------------------------------------------
    -- Create a table to hold datasets to process
    --------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToProcess (
        Dataset_ID int NOT NULL
    );

    CREATE INDEX IX_Tmp_DatasetsToProcess ON Tmp_DatasetsToProcess (Dataset_ID);

    --------------------------------------------
    -- Look for Datasets with entries in cap.t_dataset_info_xml but null values for File_Info_Last_Modified in cap.t_dataset_info_xml
    -- Alternatively, if _replaceExistingData is true, process all entries in cap.t_dataset_info_xml
    --------------------------------------------

    INSERT INTO Tmp_DatasetsToProcess (dataset_id)
    SELECT DI.dataset_id
    FROM cap.t_dataset_info_xml DI
         LEFT OUTER JOIN public.t_dataset DS
           ON DI.dataset_id = DS.dataset_id
    WHERE (DS.File_Info_Last_Modified IS NULL OR _replaceExistingData) AND
          NOT DI.ignore;

    --------------------------------------------
    -- Possibly filter on _datasetIDs
    --------------------------------------------

    If _datasetIDs <> '' Then
        DELETE FROM Tmp_DatasetsToProcess
        WHERE NOT Dataset_ID IN (SELECT Value
                                 FROM public.parse_delimited_integer_list(_datasetIDs));
    End If;

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
        _message := format('Ignoring %s %s in cap.t_dataset_info_xml because %s exist in public.t_dataset',
                            _matchCount,
                            public.check_plural(_matchCount, 'dataset', 'datasets'),
                            public.check_plural(_matchCount, 'it does not', 'they do not'));

        CALL public.post_log_entry ('Info', _message, 'Update_Missed_DMS_File_Info', 'cap');

        --------------------------------------------
        -- Delete any entries in cap.t_dataset_info_xml that were cached over 7 days ago and do not exist in public.t_dataset
        --------------------------------------------

        DELETE FROM cap.t_dataset_info_xml
        WHERE Cache_Date < CURRENT_TIMESTAMP - INTERVAL '7 days' AND
              NOT EXISTS (SELECT DS.Dataset_ID
                          FROM public.t_dataset DS
                          WHERE DS.Dataset_ID = cap.t_dataset_info_xml.Dataset_ID);

    End If;

    --------------------------------------------
    -- Look for datasets with conflicting values for scan count or file size
    -- Will only update if the cache_date in cap.t_dataset_info_xml is newer than
    -- the File_Info_Last_Modified date in T_Dataset
    --------------------------------------------

    INSERT INTO Tmp_DatasetsToProcess (Dataset_ID)
    SELECT Dataset_ID
           -- , Scan_Count_Old, ScanCountNew
           -- , File_Size_Bytes_Old, FileSizeBytesNew
    FROM (SELECT dataset_id,
                 Scan_Count_Old,
                 File_Size_Bytes_Old,
                 public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ScanCount/text()',     ds_info_xml))[1]::text, 0) AS ScanCountNew,
                 public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/FileSizeBytes/text()', ds_info_xml))[1]::text, 0::bigint) AS FileSizeBytesNew
           FROM (SELECT DI.dataset_id,
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
                 WHERE NOT DI.ignore
                ) InnerQ
         ) FilterQ
    WHERE ScanCountNew <> Coalesce(Scan_Count_Old, 0) OR
          FileSizeBytesNew <> Coalesce(File_Size_Bytes_Old, 0) AND FileSizeBytesNew > 0;

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
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _infoOnly   => _infoOnly);

        If Coalesce(_returnCode, '') <> '' Then
            If _returnCode = 'U5360' Then
                -- A duplicate dataset was detected
                -- An error message will have already been logged in public.t_log_entries, so we can log a warning message here
                _logMsgType := 'Warning';
            Else
                _logMsgType := 'Error';
            End If;

            If Coalesce(_message, '') = '' Then
                _logMsg := format('update_dms_file_info_xml returned error code %s for DatasetID %s', _returnCode, _datasetID);
            Else
                _logMsg := format('update_dms_file_info_xml error: %s', _message);
            End If;

            If _infoOnly Then
                RAISE INFO '%', _logMsg;
            Else
                CALL public.post_log_entry (_logMsgType, _logMsg, 'Update_Missed_DMS_File_Info', 'cap', _duplicateEntryHoldoffHours => 22, _logErrorsToPublicLogTable => false);
            End If;
        End If;

        _datasetsProcessed := _datasetsProcessed + 1;
    END LOOP;

    If _infoOnly Then
        _message := format('Dataset info XML updates are pending for %s %s',
                            _datasetsProcessed, public.check_plural(_datasetsProcessed, 'dataset', 'datasets'));
    Else
        _message := format('Processed dataset info XML for %s %s (_deleteFromTableOnSuccess = %s)',
                            _datasetsProcessed, public.check_plural(_datasetsProcessed, 'dataset', 'datasets'),
                            CASE WHEN _deleteFromTableOnSuccess THEN 'true' ELSE 'false' END);
    End If;

    RAISE INFO '';
    RAISE INFO '%', _message;

    DROP TABLE Tmp_DatasetsToProcess;
END
$$;


ALTER PROCEDURE cap.update_missed_dms_file_info(IN _deletefromtableonsuccess boolean, IN _replaceexistingdata boolean, IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_missed_dms_file_info(IN _deletefromtableonsuccess boolean, IN _replaceexistingdata boolean, IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_missed_dms_file_info(IN _deletefromtableonsuccess boolean, IN _replaceexistingdata boolean, IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'UpdateMissedDMSFileInfo';

