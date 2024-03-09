--
-- Name: adjust_params_for_local_job(text, integer, xml, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.adjust_params_for_local_job(IN _scriptname text, IN _datapackageid integer, INOUT _jobparamxml xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adjust the job parameters for special cases, for example
**      local jobs that target other jobs (typically as defined by a data package)
**
**      Uses temp table Tmp_Job_Steps, created by sw.make_local_job_in_broker
**
**  Arguments:
**    _scriptName       Script name
**    _dataPackageID    Data package ID (0 if not applicable)
**    _jobParamXML      XML Job parameters (input/output)
**    _message          Status message
**    _returnCode       Return code
**    _debugMode        When true, show the source job number (if defined) and show the XML job parameters
**
**  Auth:   grk
**  Date:   10/16/2010 grk - Initial release
**          01/19/2012 mem - Added parameter _dataPackageID
**          01/03/2014 grk - Added logic for CacheFolderRootPath
**          03/14/2014 mem - Added job parameter InstrumentDataPurged
**          06/16/2016 mem - Move data package transfer folder path logic to Add_Update_Transfer_Paths_In_Params_Using_Data_Pkg
**          04/11/2022 mem - Use varchar(4000) when populating temp table Tmp_Job_Params using _jobParamXML
**          03/22/2023 mem - Rename job parameter to DatasetName
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          07/28/2023 mem - Ported to PostgreSQL
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _paramsUpdated boolean := false;
    _sourceJob int := 0;
    _jobInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Convert job params from XML to temp table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Job_Params (
        Section citext,
        Name citext,
        Value citext
    );

    INSERT INTO Tmp_Job_Params (Section, Name, Value)
    SELECT Trim(XmlQ.section), Trim(XmlQ.name), Trim(XmlQ.value)
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _jobParamXML::text || '</params>')::xml AS rooted_xml ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section text PATH '@Section',
                              name    text PATH '@Name',
                              value   text PATH '@Value')
         ) XmlQ;

    ---------------------------------------------------
    -- If this job has a 'DataPackageID' defined, update parameters
    --   'CacheFolderPath'
    --   'TransferFolderPath'
    --   'DataPackagePath'
    ---------------------------------------------------

    CALL sw.add_update_transfer_paths_in_params_using_data_pkg (
                _dataPackageID,
                _paramsUpdated => _paramsUpdated,   -- Input/Output
                _message       => _message,         -- Output
                _returnCode    => _returnCode);     -- Output

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
    WHERE Name = 'SourceJob';

    If FOUND And _sourceJob > 0 Then

        If _debugMode Then
            RAISE INFO 'SourceJob: %', _sourceJob;
        End If;

        -- Lookup path to results directory for job given by _sourceJob and add it to temp parameters table

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

        If Not FOUND Then
            RAISE WARNING 'Warning: Source Job % not found in public.V_Source_Analysis_Job', _sourceJob;
        Else
            -- Update Input_Directory_Name for job steps
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

            INSERT INTO Tmp_Job_Params (Section, Name, Value)
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
            SELECT 'JobParameters', 'InstrumentDataPurged', _jobInfo.InstrumentDataPurged::text;

            _paramsUpdated := true;
        End If;

    ElsIf _debugMode Then
        RAISE INFO 'Job does not have job parameter "SourceJob"';
    End If;

    ---------------------------------------------------
    -- Update _jobParamXML if changes were made
    ---------------------------------------------------

    If _paramsUpdated Then
        SELECT xml_item
        INTO _jobParamXML
        FROM ( SELECT
                 XMLAGG(XMLELEMENT(
                        NAME "Param",
                        XMLATTRIBUTES(
                            section AS "Section",
                            name AS "Name",
                            value AS "Value"))
                        ORDER BY section, name
                       ) AS xml_item
               FROM Tmp_Job_Params
            ) AS LookupQ;

        If _debugMode Then
            RAISE INFO 'Job parameters were updated';
        End If;
    End If;

    If _debugMode Then
        RAISE INFO '%', _jobParamXML;
    End If;

    DROP TABLE Tmp_Job_Params;
END
$$;


ALTER PROCEDURE sw.adjust_params_for_local_job(IN _scriptname text, IN _datapackageid integer, INOUT _jobparamxml xml, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE adjust_params_for_local_job(IN _scriptname text, IN _datapackageid integer, INOUT _jobparamxml xml, INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.adjust_params_for_local_job(IN _scriptname text, IN _datapackageid integer, INOUT _jobparamxml xml, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'AdjustParamsForLocalJob';

