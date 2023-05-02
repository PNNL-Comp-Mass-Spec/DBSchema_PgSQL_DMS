--
CREATE OR REPLACE PROCEDURE public.update_dataset_file_info_xml
(
    _datasetID int = 0,
    _datasetInfoXML xml,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _validateDatasetType boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the information for the dataset specified by _datasetID
**
**      If _datasetID is 0, will use the dataset name defined in _datasetInfoXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <DatasetInfo>
**        <Dataset>QC_Shew_17_01_Run_2_7Jun18_Oak_18-03-08</Dataset>
**        <ScanTypes>
**          <ScanType ScanCount="10574" ScanFilterText="FTMS + p NSI Full ms">HMS</ScanType>
**          <ScanType ScanCount="42861" ScanFilterText="FTMS + p NSI d Full ms2 0@hcd32.00">HCD-HMSn</ScanType>
**        </ScanTypes>
**        <AcquisitionInfo>
**          <ScanCount>53435</ScanCount>
**          <ScanCountMS>10574</ScanCountMS>
**          <ScanCountMSn>42861</ScanCountMSn>
**          <ScanCountDIA>0</ScanCountDIA>
**          <Elution_Time_Max>120.00</Elution_Time_Max>
**          <AcqTimeMinutes>120.00</AcqTimeMinutes>
**          <StartTime>2018-06-07 07:19:59 PM</StartTime>
**          <EndTime>2018-06-07 09:19:58 PM</EndTime>
**          <FileSizeBytes>1623020913</FileSizeBytes>
**          <InstrumentFiles>
**            <InstrumentFile Hash="cc7b7c917a7eedf82dbea7382d01a67a9ccd7908" HashType="SHA1" Size="1623020913">
**              QC_Shew_17_01_Run_2_7Jun18_Oak_18-03-08.raw
**            </InstrumentFile>
**          </InstrumentFiles>
**          <DeviceList>
**            <Device Type="MS" Number="1" Name="Q Exactive Plus Orbitrap" Model="Q Exactive Plus"
**                    SerialNumber="Exactive Series slot #300" SoftwareVersion="2.8-280502/2.8.1.2806">
**              Mass Spectrometer
**            </Device>
**          </DeviceList>
**          <ProfileScanCountMS1>10573</ProfileScanCountMS1>
**          <ProfileScanCountMS2>42658</ProfileScanCountMS2>
**          <CentroidScanCountMS1>1</CentroidScanCountMS1>
**          <CentroidScanCountMS2>203</CentroidScanCountMS2>
**        </AcquisitionInfo>
**        <TICInfo>
**          <TIC_Max_MS>5.4277E+09</TIC_Max_MS>
**          <TIC_Max_MSn>3.6099E+08</TIC_Max_MSn>
**          <BPI_Max_MS>6.2221E+08</BPI_Max_MS>
**          <BPI_Max_MSn>4.5959E+07</BPI_Max_MSn>
**          <TIC_Median_MS>9.1757E+07</TIC_Median_MS>
**          <TIC_Median_MSn>1.8929E+06</TIC_Median_MSn>
**          <BPI_Median_MS>3.881E+06</BPI_Median_MS>
**          <BPI_Median_MSn>103457</BPI_Median_MSn>
**        </TICInfo>
**      </DatasetInfo>
**
**  Arguments:
**    _datasetID             If this value is 0, will determine the dataset name using the contents of _datasetInfoXML
**    _datasetInfoXML        XML describing the properties of a single dataset
**    _validateDatasetType   If true, will call ValidateDatasetType after updating T_Dataset_ScanTypes
**
**  Auth:   mem
**  Date:   05/03/2010 mem - Initial version
**          05/13/2010 mem - Added parameter _validateDatasetType
**          05/14/2010 mem - Now updating T_Dataset_Info.Scan_Types
**          08/03/2010 mem - Removed unneeded fields from the T_Dataset_Info MERGE Source
**          09/01/2010 mem - Now checking for invalid dates and storing Null in Acq_Time_Start and Acq_Time_End If invalid
**          09/09/2010 mem - Fixed bug extracting StartTime and EndTime values
**          09/02/2011 mem - Now calling post_usage_log_entry
**          08/21/2012 mem - Now including DatasetID in the error message
**          04/18/2014 mem - Added support for ProfileScanCountMS1, ProfileScanCountMS2, CentroidScanCountMS1, and CentroidScanCountMS2
**          02/24/2015 mem - Now validating that _datasetID exists in T_Dataset
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW If not authorized
**          06/13/2018 mem - Store instrument files info in T_Dataset_Files
**          06/25/2018 mem - Populate the File_Size_Rank column
**          08/08/2018 mem - Fix null value where clause bug in _duplicateDatasetsTable
**          08/09/2018 mem - Use _duplicateEntryHoldoffHours when logging the duplicate dataset error
**          08/10/2018 mem - Update duplicate dataset message and use PostEmailAlert to add to T_Email_Alerts
**          11/09/2018 mem - Set deleted to 0 when updating existing entries
**                           No longer removed deleted files and sort them last when updating File_Size_Rank
**          02/11/2020 mem - Ignore zero-byte files when checking for duplicates
**          02/29/2020 mem - Refactor code into get_dataset_details_from_dataset_info_xml
**          03/01/2020 mem - Add call to update_dataset_device_info_xml
**          10/10/2020 mem - Use auto_update_separation_type to auto-update the dataset separation type, based on the acquisition length
**          02/14/2022 mem - Log an error if the acquisition length is overly long
**          06/13/2022 mem - Update call to get_dataset_scan_type_list since now a scalar-valued function
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          03/23/2023 mem - Add support for datasets with multiple instrument files with the same name (e.g. 20220105_JL_kpmp_3504 with ser files in eight .d directories)
**          04/24/2023 mem - Store DIA scan count values
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _datasetName text;
    _datasetIDCheck int;
    _startTime text;
    _endTime text;
    _acqTimeStart timestamp;
    _acqTimeEnd timestamp;
    _acqLengthMinutes int;
    _separationType text;
    _optimalSeparationType text := '';
    _msg text;
    _duplicateDatasetInfoSuffix text;
    _unrecognizedHashType text := '';
    _instrumentFileCount int := 0;
    _duplicateDatasetID int := 0;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);
    _message := '';
    _returnCode:= '';
    _infoOnly := Coalesce(_infoOnly, false);
    _validateDatasetType := Coalesce(_validateDatasetType, true);

    ---------------------------------------------------
    -- Examine the XML to determine the dataset name and update or validate _datasetID
    ---------------------------------------------------
    --
    Call get_dataset_details_from_dataset_info_xml (
        _datasetInfoXML,
        _datasetID => _datasetID,       -- Input/Output
        _datasetName => _datasetName,   -- Output
        _message => _message,           -- Output
        _returnCode => _returnCode);    -- Output

    If _returnCode <> '' Then
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Create temporary tables to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DSInfoTable (
        Dataset_ID int NULL,
        Dataset_Name text NOT NULL,
        Scan_Count int NULL,
        Scan_Count_MS int NULL,
        Scan_Count_MSn int NULL,
        Scan_Count_DIA int Null,
        Elution_Time_Max numeric NULL,
        Acq_Time_Minutes numeric NULL,
        Acq_Time_Start timestamp NULL,
        Acq_Time_End timestamp NULL,
        File_Size_Bytes bigint NULL,
        TIC_Max_MS numeric NULL,
        TIC_Max_MSn numeric NULL,
        BPI_Max_MS numeric NULL,
        BPI_Max_MSn numeric NULL,
        TIC_Median_MS numeric NULL,
        TIC_Median_MSn numeric NULL,
        BPI_Median_MS numeric NULL,
        BPI_Median_MSn numeric NULL,
        Profile_Scan_Count_MS int NULL,
        Profile_Scan_Count_MSn int NULL,
        Centroid_Scan_Count_MS int NULL,
        Centroid_Scan_Count_MSn int NULL
    )

    CREATE TEMP TABLE Tmp_ScanTypes (
        ScanType text NOT NULL,
        ScanCount int NULL,
        ScanFilter text NULL
    )

    CREATE TEMP TABLE Tmp_InstrumentFiles (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        InstFilePath text NOT NULL,     -- Relative file path of the instrument file
        InstFileHash text NULL,
        InstFileHashType text NULL,     -- Should always be SHA1
        InstFileSize bigint NULL,
        FileSizeRank int NULL      -- File size rank, across all instrument files for this dataset
    )

    CREATE TEMP TABLE Tmp_DuplicateDatasets (
        Dataset_ID int NOT NULL,
        MatchingFileCount int NOT NULL,
        Allow_Duplicates boolean NOT NULL
    )

    ---------------------------------------------------
    -- Parse the contents of _datasetInfoXML to populate Tmp_DSInfoTable
    -- Columns StartTime and EndTime will be populated below
    --
    -- Extract values using xpath() since XMLTABLE can only extract all of the nodes below a given parent node,
    -- and we need to extract data from multiple sections
    --
    -- Note that "text()" means to return the text inside each node (e.g., 53435 from <ScanCount>53435</ScanCount>)
    -- [1] is used to select the first match, since xpath() returns an array
    ---------------------------------------------------

    INSERT INTO Tmp_DSInfoTable (
        Dataset_ID,
        Dataset_Name,
        Scan_Count,
        Scan_Count_MS,
        Scan_Count_MSn,
        Scan_Count_DIA,
        Elution_Time_Max,
        Acq_Time_Minutes,
        File_Size_Bytes,
        TIC_Max_MS,
        TIC_Max_MSn,
        BPI_Max_MS,
        BPI_Max_MSn,
        TIC_Median_MS,
        TIC_Median_MSn,
        BPI_Median_MS,
        BPI_Median_MSn,
        Profile_Scan_Count_MS,
        Profile_Scan_Count_MSn,
        Centroid_Scan_Count_MS,
        Centroid_Scan_Count_MSn
    )
    SELECT  _datasetID AS DatasetID,
            _datasetName AS Dataset,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ScanCount/text()', _datasetInfoXML))[1]::text, 0) AS Scan_Count,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ScanCountMS/text()', _datasetInfoXML))[1]::text, 0) AS Scan_Count_MS,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ScanCountMSn/text()', _datasetInfoXML))[1]::text, 0) AS Scan_Count_MSn,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ScanCountDIA/text()', _datasetInfoXML))[1]::text, 0) AS Scan_Count_DIA,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/Elution_Time_Max/text()', _datasetInfoXML))[1]::text, 0::numeric) AS Elution_Time_Max,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/AcqTimeMinutes/text()', _datasetInfoXML))[1]::text, 0::numeric) AS Acq_Time_Minutes,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/FileSizeBytes/text()', _datasetInfoXML))[1]::text, 0::bigint) AS File_Size_Bytes,
            public.try_cast((xpath('//DatasetInfo/TICInfo/TIC_Max_MS/text()', _datasetInfoXML))[1]::text, 0::numeric) AS TIC_Max_MS,
            public.try_cast((xpath('//DatasetInfo/TICInfo/TIC_Max_MSn/text()', _datasetInfoXML))[1]::text, 0::numeric) AS TIC_Max_MSn,
            public.try_cast((xpath('//DatasetInfo/TICInfo/BPI_Max_MS/text()', _datasetInfoXML))[1]::text, 0::numeric) AS BPI_Max_MS,
            public.try_cast((xpath('//DatasetInfo/TICInfo/BPI_Max_MSn/text()', _datasetInfoXML))[1]::text, 0::numeric) AS BPI_Max_MSn,
            public.try_cast((xpath('//DatasetInfo/TICInfo/TIC_Median_MS/text()', _datasetInfoXML))[1]::text, 0::numeric) AS TIC_Median_MS,
            public.try_cast((xpath('//DatasetInfo/TICInfo/TIC_Median_MSn/text()', _datasetInfoXML))[1]::text, 0::numeric) AS TIC_Median_MSn,
            public.try_cast((xpath('//DatasetInfo/TICInfo/BPI_Median_MS/text()', _datasetInfoXML))[1]::text, 0::numeric) AS BPI_Median_MS,
            public.try_cast((xpath('//DatasetInfo/TICInfo/BPI_Median_MSn/text()', _datasetInfoXML))[1]::text, 0::numeric) AS BPI_Median_MSn,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ProfileScanCountMS1/text()', _datasetInfoXML))[1]::text, 0) AS Profile_Scan_Count_MS,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/ProfileScanCountMS2/text()', _datasetInfoXML))[1]::text, 0) AS Profile_Scan_Count_MSn,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/CentroidScanCountMS1/text()', _datasetInfoXML))[1]::text, 0) AS Centroid_Scan_Count_MS,
            public.try_cast((xpath('//DatasetInfo/AcquisitionInfo/CentroidScanCountMS2/text()', _datasetInfoXML))[1]::text, 0) AS Centroid_Scan_Count_MSn;

    ---------------------------------------------------
    -- Make sure Dataset_ID is up-to-date in Tmp_DSInfoTable
    ---------------------------------------------------
    --
    UPDATE Tmp_DSInfoTable
    SET Dataset_ID = _datasetID;

    ---------------------------------------------------
    -- Parse out the start and end times
    -- Initially extract as strings in case they're out of range for the timestamp date type
    ---------------------------------------------------
    --
    _startTime := (xpath('//DatasetInfo/AcquisitionInfo/StartTime/text()', _datasetInfoXML))[1]::text;
    _endTime   := (xpath('//DatasetInfo/AcquisitionInfo/EndTime/text()', _datasetInfoXML))[1]::text;

    _acqTimeStart := public.try_cast(_startTime, null::timestamp)
    _acqTimeEnd   := public.try_cast(_endTime, null::timestamp)

    If _acqTimeEnd Is Null Then
        -- End Time is invalid
        -- If the start time is valid, add the acquisition time length to the End time
        -- (though, typically, If one is invalid the other will be invalid too)
        -- IMS .UIMF files acquired in summer 2010 had StartTime values of 0410-08-29 (year 410) due to a bug

        If Not _acqTimeStart Is Null Then
            SELECT _acqTimeStart + make_interval(mins => Acq_Time_Minutes)
            INTO _acqTimeEnd
            FROM Tmp_DSInfoTable;
        End If;
    End If;

    UPDATE Tmp_DSInfoTable
    Set Acq_Time_Start = _acqTimeStart,
        Acq_Time_End = _acqTimeEnd;

    ---------------------------------------------------
    -- Extract out the ScanType information
    -- There could be multiple scan types defined in the XML
    ---------------------------------------------------
    --
    INSERT INTO Tmp_ScanTypes (ScanType, ScanCount, ScanFilter)
    SELECT XmlQ.ScanType, XmlQ.ScanCount, XmlQ.ScanFilter
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _datasetInfoXML as rooted_xml
             ) Src,
             XMLTABLE('//DatasetInfo/ScanTypes/ScanType'
                      PASSING Src.rooted_xml
                      COLUMNS ScanType text PATH '.',
                              ScanCount text PATH '@ScanCount',
                              ScanFilter text PATH '@ScanFilterText')
         ) XmlQ
    WHERE Not XmlQ.ScanType IS NULL

    ---------------------------------------------------
    -- Now extract out the instrument files
    ---------------------------------------------------
    --
    INSERT INTO Tmp_InstrumentFiles ( InstFilePath, InstFileHash, InstFileHashType, InstFileSize)
    SELECT XmlQ.InstFilePath, XmlQ.InstFileHash, XmlQ.InstFileHashType, XmlQ.InstFileSize
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _datasetInfoXML as rooted_xml
             ) Src,
             XMLTABLE('//DatasetInfo/AcquisitionInfo/InstrumentFiles/InstrumentFile'
                      PASSING Src.rooted_xml
                      COLUMNS InstFilePath text PATH '.',
                              InstFileHash text PATH '@Hash',
                              InstFileHashType text PATH '@HashType'),
                              InstFileSize bigint PATH '@Size')
         ) XmlQ;

    ---------------------------------------------------
    -- Update FileSizeRank in Tmp_InstrumentFiles
    ---------------------------------------------------

    UPDATE Tmp_InstrumentFiles
    SET FileSizeRank = RankQ.FileSizeRank
    FROM (
        SELECT Entry_ID, Row_Number() Over (Order By InstFileSize Desc) As FileSizeRank
        FROM #Tmp_InstrumentFilesTable
        ) As RankQ
    WHERE Tmp_InstrumentFilesTable.Entry_ID = RankQ.Entry_ID;

    ---------------------------------------------------
    -- Validate the hash type
    ---------------------------------------------------
    --

    SELECT InstFileHashType
    INTO _unrecognizedHashType
    FROM Tmp_InstrumentFiles
    WHERE Not InstFileHashType In ('SHA1');

    If FOUND Then
        _msg := 'Unrecognized file hash type: ' || _unrecognizedHashType || '; all rows in T_Dataset_File are assumed to be SHA1. ' ||;
                'Will add the file info anyway, but this hashtype could be problematic elsewhere'

        Call post_log_entry ('Error', _msg, 'UpdateDatasetFileInfoXML');
    End If;

    ---------------------------------------------------
    -- Check whether this is a duplicate dataset
    -- Look for an existing dataset with the same file hash values but a different dataset ID
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _instrumentFileCount
    FROM Tmp_InstrumentFiles

    If _instrumentFileCount > 0 Then
        INSERT INTO Tmp_DuplicateDatasets( dataset_id,
                                           MatchingFileCount,
                                           allow_duplicates)
        SELECT DSFiles.dataset_id,
               COUNT(*) AS MatchingFiles,
               false As Allow_Duplicates
        FROM t_dataset_files DSFiles
             INNER JOIN Tmp_InstrumentFiles NewDSFiles
               ON DSFiles.file_hash = NewDSFiles.InstFileHash
        WHERE DSFiles.dataset_id <> _datasetID And DSFiles.deleted = 0 And DSFiles.file_size_bytes > 0
        GROUP BY DSFiles.dataset_id
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If Exists (SELECT * FROM Tmp_DuplicateDatasets WHERE MatchingFileCount >= _instrumentFileCount) Then
            UPDATE Tmp_DuplicateDatasets
            SET Allow_Duplicates = true
            FROM t_dataset_files Src
            WHERE Tmp_DuplicateDatasets.dataset_id = Src.dataset_id AND Src.allow_duplicates;
        End If;

        If Exists (SELECT * FROM _duplicateDatasetsTable WHERE MatchingFileCount >= _instrumentFileCount And Not Allow_Duplicates) Then

            SELECT Dataset_ID
            INTO _duplicateDatasetID
            FROM _duplicateDatasetsTable
            WHERE MatchingFileCount >= _instrumentFileCount And Not Allow_Duplicates
            ORDER BY Dataset_ID Desc
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            -- Duplicate dataset found: DatasetID 693058 has the same instrument file as DatasetID 692115; see table t_dataset_files
            _duplicateDatasetInfoSuffix := format(' has the same instrument file as DatasetID %s; ' ||
                                                  'to allow this duplicate, set allow_duplicates to true for DatasetID %s in table t_dataset_files',
                                                    _duplicateDatasetID, _duplicateDatasetID);

            -- The message 'Duplicate dataset found' is used by a SQL Server Agent job that notifies admins hourly if a duplicate dataset is uploaded
            _message := format('Duplicate dataset found: DatasetID %s%s', _datasetId, _duplicateDatasetInfoSuffix);

            Call post_email_alert 'Error', _message, 'UpdateDatasetFileInfoXML', _recipients => 'admins', _postMessageToLogEntries => 1, _duplicateEntryHoldoffHours => 6

            -- Error code 'U5360' is used by several procedures in the capture scema (previously used 53600), including:
            --   handle_dataset_capture_validation_failure
            --   update_dms_dataset_state
            --   update_dms_file_info_xml
            --   update_missed_dms_file_info

            -- Example call stack: update_context -> update_job_state -> update_dms_dataset_state -> update_dms_file_info_xml -> update_dataset_file_info_xml

            _returnCode := 'U5360';

            DROP TABLE Tmp_DSInfoTable;
            DROP TABLE Tmp_ScanTypes;
            DROP TABLE Tmp_InstrumentFiles;
            DROP TABLE Tmp_DuplicateDatasets;
            RETURN;
        End If;

        If Exists (SELECT * FROM _duplicateDatasetsTable WHERE MatchingFileCount >= _instrumentFileCount And Allow_Duplicates) Then

            SELECT Dataset_ID INTO _duplicateDatasetID
            FROM _duplicateDatasetsTable
            WHERE MatchingFileCount >= _instrumentFileCount And Allow_Duplicates
            ORDER BY Dataset_ID Desc
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _duplicateDatasetInfoSuffix := ' has the same instrument file as DatasetID ' ||;
                                              Cast(_duplicateDatasetID As text) || '; see table t_dataset_files'

            _msg := format('Allowing duplicate dataset to be added since Allow_Duplicates is true: DatasetID %s%s',
                            _datasetId, _duplicateDatasetInfoSuffix);

            Call post_log_entry ('Warning', _msg, 'UpdateDatasetFileInfoXML');
        End If;
    End If;

    -----------------------------------------------
    -- Possibly update the separation type for the dataset
    -----------------------------------------------

    SELECT separation_type INTO _separationType
    FROM t_dataset
    WHERE dataset_id = _datasetID
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    SELECT Acq_Time_Minutes
    INTO _acqLengthMinutes
    From Tmp_DSInfoTable;

    If _acqLengthMinutes > 1 AND Coalesce(_separationType, '') <> '' Then
        -- Possibly update the separation type
        -- Note that the Analysis Manager will also call update_dataset_file_info_xml when the MSFileInfoScanner tool runs
        Call auto_update_separation_type (
                _separationType,
                _acqLengthMinutes,
                _optimalSeparationType => _optimalSeparationType);      -- Output

        If _optimalSeparationType <> _separationType AND Not _infoOnly Then
            UPDATE t_dataset
            SET separation_type = _optimalSeparationType
            WHERE dataset_id = _datasetID

            If NOT Exists (SELECT * FROM t_log_entries WHERE message LIKE 'Auto-updated separation type%' And Entered >= CURRENT_TIMESTAMP - INTERVAL '2 hours') Then
                _msg := format('Auto-updated separation type from %s to %s for dataset %s', _separationType, _optimalSeparationType, _datasetName);
                Call post_log_entry ('Normal', _msg, 'UpdateDatasetFileInfoXML');
            End If;

        End If;
    End If;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT *, _separationType As Separation_Type, _optimalSeparationType as Optimal_Separation_Type
        FROM Tmp_DSInfoTable

        SELECT *
        FROM Tmp_ScanTypes

        SELECT *
        FROM Tmp_InstrumentFiles

        Call update_dataset_device_info_xml (_datasetID => _datasetID, _datasetInfoXML => _datasetInfoXML, _infoOnly => true, _skipValidation => true);

        DROP TABLE Tmp_DSInfoTable;
        DROP TABLE Tmp_ScanTypes;
        DROP TABLE Tmp_InstrumentFiles;
        DROP TABLE Tmp_DuplicateDatasets;
        RETURN;
    End If;

    -----------------------------------------------
    -- Validate/fix the Acq_Time entries
    -----------------------------------------------

    -- First look for any entries in the temporary table
    -- where Acq_Time_Start is Null while Acq_Time_End is defined
    --
    UPDATE Tmp_DSInfoTable
    SET Acq_Time_Start = Acq_Time_End
    WHERE Acq_Time_Start IS NULL AND NOT Acq_Time_End IS NULL
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Now look for the reverse case
    --
    UPDATE Tmp_DSInfoTable
    SET Acq_Time_End = Acq_Time_Start
    WHERE Acq_Time_End IS NULL AND NOT Acq_Time_Start IS NULL
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------
    -- Check for Acq_Time_End being more than 7 days after Acq_Time_Start
    -----------------------------------------------

    SELECT extract(epoch FROM Acq_Time_End - Acq_Time_Start) / 60.0
           Acq_Time_Start,
           Acq_Time_End
    INTO _acqLengthMinutes, _acqTimeStart, _acqTimeEnd
    FROM Tmp_DSInfoTable;

    If _acqLengthMinutes > 10080 Then
        Update Tmp_DSInfoTable
        Set Acq_Time_End = Acq_Time_Start + Interval '1 hour';

        _message := format(
            'Acquisition length for dataset %s is over 7 days; ' ||
            'the Acq_Time_End value (%s) is likely invalid, ' ||
            'relative to Acq_Time_Start (%s); ' ||
            'setting Acq_Time_End to be 60 minutes after Acq_Time_Start',
            _datasetName,
            public.timestamp_text(_acqTimeEnd),
            public.timestamp_text(_acqTimeStart));

        Call post_log_entry ('Error', _message, 'UpdateDatasetFileInfoXML');
    End If;

    -----------------------------------------------
    -- Update t_dataset with any new or changed values
    --
    -- If acq_time_start Is Null or is <= 1/1/1900 then
    -- the created time is used for both
    -- acq_time_start and acq_time_end
    -----------------------------------------------

    UPDATE t_dataset
    SET acq_time_start= CASE WHEN Coalesce(NewInfo.acq_time_start, make_date(1900, 1, 1)) <= make_date(1900, 1, 1)
                        THEN DS.created
                        ELSE NewInfo.Acq_Time_Start END,
        Acq_Time_End =  CASE WHEN Coalesce(NewInfo.Acq_Time_Start, make_date(1900, 1, 1)) <= make_date(1900, 1, 1)
                        THEN DS.Created
                        ELSE NewInfo.Acq_Time_End END,
        scan_count = NewInfo.Scan_Count,
        file_size_bytes = NewInfo.File_Size_Bytes,
        file_info_last_modified = CURRENT_TIMESTAMP
    FROM Tmp_DSInfoTable NewInfo INNER JOIN
         t_dataset DS ON
          NewInfo.Dataset_Name = DS.dataset;

    -----------------------------------------------
    -- Add/Update t_dataset_info using a MERGE statement
    -----------------------------------------------
    --
    MERGE INTO t_dataset_info AS target
    USING ( SELECT dataset_id, scan_count_ms, scan_count_msn,
                   scan_count_dia, elution_time_max,
                   tic_max_ms, tic_max_msn,
                   bpi_max_ms, bpi_max_msn,
                   tic_median_ms, tic_median_msn,
                   bpi_median_ms, bpi_median_msn,
                   profile_scan_count_ms, profile_scan_count_msn,
                   centroid_scan_count_ms, centroid_scan_count_msn
            FROM Tmp_DSInfoTable
          ) AS Source
    ON (target.dataset_id = Source.dataset_id)
    WHEN MATCHED THEN
        UPDATE SET
            scan_count_ms = Source.scan_count_ms,
            scan_count_msn = Source.scan_count_msn,
            scan_count_dia = Source.scan_count_dia,
            elution_time_max = Source.elution_time_max,
            tic_max_ms = Source.tic_max_ms,
            tic_max_msn = Source.tic_max_msn,
            bpi_max_ms = Source.bpi_max_ms,
            bpi_max_msn = Source.bpi_max_msn,
            tic_median_ms = Source.tic_median_ms,
            tic_median_msn = Source.tic_median_msn,
            bpi_median_ms = Source.bpi_median_ms,
            bpi_median_msn = Source.bpi_median_msn,
            profile_scan_count_ms = Source.profile_scan_count_ms,
            profile_scan_count_msn = Source.profile_scan_count_msn,
            centroid_scan_count_ms = Source.centroid_scan_count_ms,
            centroid_scan_count_msn = Source.centroid_scan_count_msn,
            last_affected = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (dataset_id, scan_count_ms, scan_count_msn,
                scan_count_dia, elution_time_max,
                tic_max_ms, tic_max_msn,
                bpi_max_ms, bpi_max_msn,
                tic_median_ms, tic_median_msn,
                bpi_median_ms, bpi_median_msn,
                profile_scan_count_ms, profile_scan_count_msn,
                centroid_scan_count_ms, centroid_scan_count_msn,
                last_affected)
        VALUES (Source.dataset_id, Source.scan_count_ms, Source.scan_count_msn,
                Source.scan_count_dia, Source.Elution_Time_Max,
                Source.tic_max_ms, Source.tic_max_msn,
                Source.bpi_max_ms, Source.bpi_max_msn,
                Source.tic_median_ms, Source.tic_median_msn,
                Source.bpi_median_ms, Source.bpi_median_msn,
                Source.profile_scan_count_ms , Source.profile_scan_count_msn,
                Source.centroid_scan_count_ms, Source.centroid_scan_count_msn,
                CURRENT_TIMESTAMP);

    -----------------------------------------------
    -- Cannot use a Merge statement on t_dataset_scan_types
    -- since some datasets (e.g. MRM) will have multiple entries
    -- of the same scan type but different scan_filter values
    --
    -- Instead, delete existing rows then add new ones
    -----------------------------------------------
    --
    DELETE FROM t_dataset_scan_types
    WHERE dataset_id = _datasetID;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    INSERT INTO t_dataset_scan_types ( dataset_id, scan_type, scan_count, ScanFilter )
    SELECT _datasetID AS Dataset_ID, ScanType, ScanCount, ScanFilter
    FROM Tmp_ScanTypes
    ORDER BY dataset_id, scan_type;

    -----------------------------------------------
    -- Update the scan_types field in t_dataset_info for this dataset
    -----------------------------------------------
    --
    UPDATE t_dataset_info
    SET scan_types = get_dataset_scan_type_list(_datasetID)
    FROM t_dataset DS
         INNER JOIN t_dataset_info DSInfo
           ON DSInfo.dataset_id = DS.dataset_id
    WHERE DS.dataset_id = _datasetID;

    -----------------------------------------------
    -- Add/Update t_dataset_files using a Merge statement
    -----------------------------------------------
    --
    MERGE INTO t_dataset_files As target
    USING ( SELECT _datasetID AS Dataset_ID, InstFilePath, InstFileSize, InstFileHash, FileSizeRank
            FROM Tmp_InstrumentFiles
          ) AS Source
    ON (target.dataset_id = Source.dataset_id And
        target.file_path = Source.InstFilePath And
        target.file_size_rank = Source.FileSizeRank)
    WHEN MATCHED THEN
        UPDATE SET
            file_size_bytes = Source.InstFileSize,
            file_hash = Source.InstFileHash,
            file_size_rank = Source.FileSizeRank,
            deleted = 0
    WHEN NOT MATCHED THEN
        INSERT (dataset_id, file_path, file_size_bytes, file_hash, File_Size_Rank)
        VALUES (Source.dataset_id, Source.InstFilePath, Source.InstFileSize, Source.InstFileHash, Source.FileSizeRank);

    -- Look for extra files that need to be deleted
    --
    DELETE FROM t_dataset_files target
    WHERE target.Dataset_ID = _datasetID AND
          target.Deleted = 0 AND
          NOT EXISTS (SELECT InstFiles.InstFilePath
                      FROM Tmp_InstrumentFiles Instfiles
                      WHERE target.file_path = InstFiles.InstFilePath AND
                            Target.file_size_rank = Source.FileSizeRank);

       -----------------------------------------------
    -- Possibly validate the dataset type defined for this dataset
    -----------------------------------------------
    --
    If _validateDatasetType Then
        Call public.validate_dataset_type (_datasetID, _message => _message, _infoOnly => _infoOnly);
    End If;

    -----------------------------------------------
    -- Add/update t_dataset_device_map
    -----------------------------------------------
    --
    Call update_dataset_device_info_xml (_datasetID => _datasetID, _datasetInfoXML => _datasetInfoXML, _infoOnly => false, _skipValidation => true);

    _message := 'Dataset info update successful';

    -- Note: ignore error code 'U5360' (previously 53600); a log message has already been made
    If Not _returnCode In ('', 'U5360') Then
        If _message = '' Then
            _message := 'Error in UpdateDatasetFileInfoXML';
        End If;

        _message := _message || '; error code = ' || _myError::text;

        If Not _infoOnly Then
            Call post_log_entry ('Error', _message, 'UpdateDatasetFileInfoXML');
        End If;
    End If;

    If char_length(_message) > 0 AND _infoOnly Then
        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := format('Dataset ID: %s', _datasetId);
    Else
        _usageMessage := 'Dataset: ' || _datasetName;
    End If;

    If Not _infoOnly Then
        Call post_usage_log_entry ('UpdateDatasetFileInfoXML', _usageMessage;);
    End If;

    DROP TABLE Tmp_DSInfoTable;
    DROP TABLE Tmp_ScanTypes;
    DROP TABLE Tmp_InstrumentFiles;
    DROP TABLE Tmp_DuplicateDatasets;

END
$$;

COMMENT ON PROCEDURE public.update_dataset_file_info_xml IS 'UpdateDatasetFileInfoXML';
