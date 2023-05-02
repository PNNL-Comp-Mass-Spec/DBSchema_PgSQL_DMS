--
CREATE OR REPLACE PROCEDURE sw.adjust_params_for_local_job
(
    _scriptName text,
    _datasetName text = 'na',
    _dataPackageID int,
    INOUT _jobParamXML xml,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adjust the job parameters for special cases, for example
**      local jobs that target other jobs (typically as defined by a data package)
**
**  Arguments:
**    _jobParamXML   Input / Output parameter
**
**  Auth:   grk
**  Date:   10/16/2010 grk - Initial release
**          01/19/2012 mem - Added parameter _dataPackageID
**          01/03/2014 grk - Added logic for CacheFolderRootPath
**          03/14/2014 mem - Added job parameter InstrumentDataPurged
**          06/16/2016 mem - Move data package transfer folder path logic to AddUpdateTransferPathsInParamsUsingDataPkg
**          04/11/2022 mem - Use varchar(4000) when populating temp table Tmp_Job_Params using _jobParamXML
**          03/22/2023 mem - Rename job parameter to DatasetName
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _paramsUpdated boolean := false;
    _sourceJob int := 0;
    _jobInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    _dataPackageID := Coalesce(_dataPackageID, 0);

    ---------------------------------------------------
    -- Convert job params from XML to temp table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Job_Params (
        Section text,
        Name text,
        Value text
    )

    INSERT INTO Tmp_Job_Params (Section, Name, Value)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _jobParamXML::text || '</params>')::xml as rooted_xml ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

    ---------------------------------------------------
    -- If this job has a 'DataPackageID' defined, update parameters
    --   'CacheFolderPath'
    --   'TransferFolderPath'
    --   'DataPackagePath'
    ---------------------------------------------------

    Call sw.add_update_transfer_paths_in_params_using_data_pkg (
            _dataPackageID,
            _paramsUpdated => _paramsUpdated,   -- Input / Output
            _message => _message,               -- Output
            _returnCode => _returnCode);        -- Output

    ---------------------------------------------------
    -- If this job has a 'SourceJob' parameter, update parameters
    --   'DatasetArchivePath'
    --   'DatasetName'
    --   'RawDataType'
    --   'DatasetStoragePath'
    --   'TransferFolderPath'
    --   'DatasetFolderName'
    --   'InstrumentDataPurged'
    --
    -- Also update Input_Directory_Name in Tmp_Job_Steps for steps that are not 'Results_Transfer' steps
    ---------------------------------------------------

    SELECT Value
    INTO _sourceJob
    FROM Tmp_Job_Params
    WHERE Name::citext = 'sourceJob';

    If FOUND And _sourceJob > 0 Then

        -- PRINT 'sourceJob:' || _sourceJob::text
        -- look up path to results directory for job given by _sourceJob and add it to temp parameters table
        --
        SELECT Archive_Folder_Path AS ArchiveFolderPath,
               Dataset,
               Dataset_Storage_Path AS DatasetStoragePath,
               Raw_Data_Type AS RawDataType,
               Results_Folder AS SourceResultsDirectory,
               Transfer_Folder_Path AS TransferFolderPath,
               Instrument_Data_Purged AS InstrumentDataPurged
        INTO _jobInfo
        FROM public.V_Source_Analysis_Job
        WHERE Job = _sourceJob;

        If FOUND Then
            -- UPDATE Input_Directory_Name for job steps
            -- (in the future, we may want to be more selective about which steps are not updated)

            UPDATE Tmp_Job_Steps
            SET Input_Directory_Name = _jobInfo.SourceResultsDirectory
            WHERE NOT Tool IN ('Results_Transfer');

            DELETE FROM Tmp_Job_Params
            WHERE Name IN ('DatasetArchivePath',
                           'DatasetName',
                           'DatasetNum',
                           'RawDataType',
                           'DatasetStoragePath',
                           'TransferFolderPath',
                           'DatasetFolderName',
                           'InstrumentDataPurged');

            INSERT INTO Tmp_Job_Params ( Section, Name, Value )
            SELECT 'JobParameters', 'DatasetArchivePath', _jobInfo.ArchiveFolderPath
            UNION
            SELECT 'JobParameters', 'DatasetName', _jobInfo.Dataset
            UNION
            SELECT 'JobParameters', 'RawDataType', _jobInfo.RawDataType
            UNION
            SELECT 'JobParameters', 'DatasetStoragePath', _jobInfo.DatasetStoragePath
            UNION
            SELECT 'JobParameters', 'TransferFolderPath', _jobInfo.TransferFolderPath
            UNION
            SELECT 'JobParameters', 'DatasetFolderName', _jobInfo.Dataset
            UNION
            SELECT 'JobParameters', 'InstrumentDataPurged', _jobInfo.InstrumentDataPurged;

            _paramsUpdated := true;

        End If;
    End If;

    ---------------------------------------------------
    -- Update _jobParamXML if changes were made
    ---------------------------------------------------
    --
    If _paramsUpdated Then
        -- ToDo: convert this to use XMLAGG(XMLELEMENT(
        --       Look for similar capture task code in cap.*
        _jobParamXML := ( SELECT * FROM Tmp_Job_Params AS Param FOR XML AUTO, TYPE);
    End If;

    DROP TABLE Tmp_Job_Params;
END
$$;

COMMENT ON PROCEDURE sw.adjust_params_for_local_job IS 'AdjustParamsForLocalJob';
