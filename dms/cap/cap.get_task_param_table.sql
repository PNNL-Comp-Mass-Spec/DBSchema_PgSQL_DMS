--
-- Name: get_task_param_table(integer, text, integer, text, text, text, integer, text, text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text, _scriptname text) RETURNS TABLE(job integer, section public.citext, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the parameters for the given capture task job in Section, Name, Value rows
**
**      Data comes from both the procedure arguments and view cap.V_DMS_Dataset_Metadata,
**      which uses tables in the public schema
**
**  Arguments:
**    _job                      Capture task job number
**    _dataset                  Dataset name
**    _datasetID                Dataset ID
**    _storageServer            Storage server
**    _instrument               Instrument
**    _instrumentClass          Instrument class
**    _maxSimultaneousCaptures  Maximum simultaneous capture tasks
**    _captureSubdirectory      Capture subdirectory
**    _scriptName               Capture task script
**
**  Example usage:
**      SELECT * FROM cap.get_task_param_table(6122256, 'MeOH_Blank_01_met_C18_Pos_14Aug23_Lola-WCSH815142', 1176806,
**                                             'proto-9', 'QExactP02', 'LTQ_FT', 1, '', 'DatasetCapture');
**
**      SELECT * FROM cap.get_task_param_table(6122256, 'MeOH_Blank_01_met_C18_Pos_14Aug23_Lola-WCSH815142', 1176806,
**                                             'proto-9', 'QExactP02', 'LTQ_FT', 1, '', 'LCDatasetCapture');
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/04/2010 grk - Added instrument class params
**          03/23/2012 mem - Now including EUS_Instrument_ID
**          04/09/2013 mem - Now looking up Perform_Calibration from public.T_Instrument_Name
**          08/20/2013 mem - Now looking up EUS_Proposal_ID
**          09/04/2013 mem - Now including TransferFolderPath (later renamed to TransferDirectoryPath)
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          11/16/2015 mem - Now including EUS_Operator_ID and Operator_PRN
**          05/17/2019 mem - Switch from folder to directory in temp tables
**                         - Rename job parameter to TransferDirectoryPath
**                         - Add parameter SHA1_Hash
**          08/31/2022 mem - Rename view V_DMS_Capture_Job_Parameters to V_DMS_Dataset_Metadata
**          09/28/2022 mem - Ported to PostgreSQL
**          02/09/2023 mem - Switch from Operator_PRN to Operator_Username
**          06/07/2023 mem - Rename temp table
**          06/20/2023 mem - Use citext for columns in the output table
**          06/21/2023 mem - Store instrument raw_data_type in the parameter table
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/25/2023 mem - Use renamed "directory" column in V_DMS_Dataset_Metadata
**          10/28/2023 mem - Add _scriptName argument
**                         - Add parameter modifications for script 'LCDatasetCapture' (bcg)
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**          05/21/2024 mem - Add parameters request_run_start and request_run_finish (which come from t_requested_run)
**
*****************************************************/
DECLARE
    _paramXML xml;
    _rawDataType text;
    _performCalibration int;
    _performCalibrationText text;
    _storageVolExternal text;
    _transferDirectoryPath text;
    _fileHash text := '';

    _captureMethod text;
    _sourceVolume text;
    _sourcePath text;
BEGIN
    ---------------------------------------------------
    -- Temp table to hold capture task job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Param_Tab (
        Section citext,
        Name citext,
        Value citext
    );

    ---------------------------------------------------
    -- Get alternate values to use when the script is 'LCDatasetCapture'
    ---------------------------------------------------

    If _scriptName::citext = 'LCDatasetCapture' Then
        SELECT lc_instrument_name,
               lc_instrument_class,
               lc_instrument_capture_method,
               source_vol,
               source_path
        INTO _instrument, _instrumentClass, _captureMethod, _sourceVolume, _sourcePath
        FROM cap.v_dms_dataset_lc_instrument
        WHERE dataset_id = _datasetID;
    End If;

    ---------------------------------------------------
    -- Job parameters
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab ( Section, Name, Value)
    VALUES ('JobParameters', 'Dataset_ID', _datasetID),
           ('JobParameters', 'Dataset', _dataset),
           ('JobParameters', 'Storage_Server_Name', _storageServer),
           ('JobParameters', 'Instrument_Name', _instrument),
           ('JobParameters', 'Instrument_Class', _instrumentClass),
           ('JobParameters', 'Max_Simultaneous_Captures', _maxSimultaneousCaptures),
           ('JobParameters', 'Capture_Subdirectory', _captureSubdirectory);

    ---------------------------------------------------
    -- Dataset Parameters
    --
    -- Convert columns of data from V_DMS_Dataset_Metadata into rows added to Tmp_Param_Tab
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab ( section, name, value)
    SELECT 'JobParameters' AS Section,
           UnpivotQ.Name,
           UnpivotQ.Value
    FROM ( SELECT type AS dataset_type,
                  directory,
                  method,
                  capture_exclusion_window::text,
                  timestamp_text(created) AS created,
                  source_vol,
                  source_path,
                  storage_vol,
                  storage_path,
                  storage_vol_external,
                  archive_server,
                  archive_path,
                  archive_network_share_path,
                  eus_instrument_id::text AS eus_instrument_id,
                  eus_proposal_id::text AS eus_proposal_id,
                  eus_operator_id::text AS eus_operator_id,
                  operator_username,
                  timestamp_text(acq_time_start) AS acq_time_start,
                  timestamp_text(acq_time_end) AS acq_time_end,
                  timestamp_text(request_run_start) AS request_run_start,
                  timestamp_text(request_run_finish) AS request_run_finish
           FROM cap.V_DMS_Dataset_Metadata
           WHERE Dataset_ID = _datasetID) AS m
         CROSS JOIN LATERAL (
           VALUES
                ('Dataset_Type', m.dataset_type),
                ('Directory', m.directory),
                ('Method', m.method),
                ('Capture_Exclusion_Window', m.capture_exclusion_window),
                ('Created', m.created),
                ('Source_Vol', m.source_vol),
                ('Source_Path', m.source_path),
                ('Storage_Vol', m.storage_vol),
                ('Storage_Path', m.storage_path),
                ('Storage_Vol_External', m.storage_vol_external),
                ('Archive_Server', m.archive_server),
                ('Archive_Path', m.archive_path),
                ('Archive_Network_Share_Path', m.archive_network_share_path),
                ('EUS_Instrument_ID', m.eus_instrument_id),
                ('EUS_Proposal_ID', m.eus_proposal_id),
                ('EUS_Operator_ID', m.eus_operator_id),
                ('Operator_Username', m.operator_username),
                ('Acq_Time_Start', m.acq_time_start),
                ('Acq_Time_End', m.acq_time_end),
                ('Request_Run_Start', m.request_run_start),
                ('Request_Run_Finish', m.request_run_finish)
           ) AS UnpivotQ(Name, Value)
    WHERE NOT UnpivotQ.value IS NULL;

    ---------------------------------------------------
    -- Use alternate values when the script is 'LCDatasetCapture'
    ---------------------------------------------------

    If _scriptName::citext = 'LCDatasetCapture' Then
        UPDATE Tmp_Param_Tab P
        SET Value = P.Value || '\LC'
        WHERE P.Section = 'JobParameters' AND P.Name = 'Directory';

        UPDATE Tmp_Param_Tab P
        SET Value = _captureMethod
        WHERE P.Section = 'JobParameters' AND P.Name = 'Method';

        UPDATE Tmp_Param_Tab P
        SET Value = _sourceVolume
        WHERE P.Section = 'JobParameters' AND P.Name = 'Source_Vol';

        UPDATE Tmp_Param_Tab P
        SET Value = _sourcePath
        WHERE P.Section = 'JobParameters' AND P.Name = 'Source_Path';
    End If;

    ---------------------------------------------------
    -- Instrument class parameters from t_instrument_class
    --
    -- This includes all of the DatasetQC parameters, typically including:
    --
    --   SaveTICAndBPIPlots, default True
    --   SaveLCMS2DPlots, default True
    --   ComputeOverallQualityScores, default True
    --   CreateDatasetInfoFile, default True
    --   LCMS2DPlotMZResolution, default 0.4
    --   LCMS2DPlotMaxPointsToPlot, default 200000
    --   LCMS2DPlotMinPointsPerSpectrum, default 2
    --   LCMS2DPlotMinIntensity, default 0
    --   LCMS2DOverviewPlotDivisor, default 10
    ---------------------------------------------------

    SELECT raw_data_type,
           params
    INTO _rawDataType, _paramXML
    FROM public.t_instrument_class
    WHERE instrument_class = _instrumentClass;

    ---------------------------------------------------
    -- Extract Section, Name, and Value from _paramXML
    --
    -- XML excerpt:
    --   <sections>
    --     <section name="DatasetQC">
    --       <item key="SaveTICAndBPIPlots" value="True" />
    --       <item key="SaveLCMS2DPlots" value="True" />
    --       <item key="ComputeOverallQualityScores" value="True" />
    --       <item key="CreateDatasetInfoFile" value="True" />
    --     </section>
    --   </sections>
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    SELECT Trim(XmlQ.section), Trim(XmlQ.name), Trim(XmlQ.value)
    FROM (
        SELECT xmltable.section, xmltable.name, xmltable.value
        FROM ( SELECT _paramXML AS params
             ) Src,
             XMLTABLE('//sections/section/item'
                      PASSING Src.params
                      COLUMNS section text PATH '../@name',
                              name    text PATH '@key',
                              value   text PATH '@value'
                              )
         ) XmlQ;

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES ('JobParameters', 'RawDataType', _rawDataType);

    ---------------------------------------------------
    -- Determine whether calibration should be performed
    -- (as of April 2013, only applies to IMS instruments)
    ---------------------------------------------------

    SELECT Perform_Calibration
    INTO _performCalibration
    FROM public.T_Instrument_Name
    WHERE instrument = _instrument::citext;

    If Coalesce(_performCalibration, 0) = 0 Then
        _performCalibrationText := 'False';
    Else
        _performCalibrationText := 'True';
    End If;

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES ('JobParameters', 'PerformCalibration', _performCalibrationText);

    ---------------------------------------------------
    -- Lookup the transfer directory (e.g. \\proto-6\DMS3_Xfer)
    -- This directory is used to store metadata.txt files for dataset archive and archive update tasks
    -- Those files are used by the ArchiveVerify tool to confirm that files were successfully imported into MyEMSL
    ---------------------------------------------------

    SELECT P.Value
    INTO _storageVolExternal
    FROM Tmp_Param_Tab P
    WHERE P.Name = 'Storage_Vol_External';

    SELECT Transfer_Directory_Path
    INTO _transferDirectoryPath
    FROM ( SELECT DISTINCT TStor.vol_name_client AS Storage_Vol_External,
                           public.combine_paths(TStor.vol_name_client, Xfer.Client) AS Transfer_Directory_Path
           FROM public.t_storage_path AS TStor
                CROSS JOIN ( SELECT Client
                             FROM public.V_Misc_Paths
                             WHERE path_function = 'AnalysisXfer'
                             LIMIT 1) AS Xfer
           WHERE Coalesce(TStor.vol_name_client, '') <> '' AND
                 TStor.vol_name_client <> '(na)'
         ) DirectoryQ
    WHERE Storage_Vol_External = _storageVolExternal;

    _transferDirectoryPath := Trim(Coalesce(_transferDirectoryPath, ''));

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES ('JobParameters', 'TransferDirectoryPath', _transferDirectoryPath);

    ---------------------------------------------------
    -- Add the SHA-1 hash for the first instrument file, if defined
    ---------------------------------------------------

    SELECT file_hash
    INTO _fileHash
    FROM public.T_Dataset_Files
    WHERE Dataset_ID = _datasetID AND
          Not Deleted AND
          File_Size_Rank = 1;

    If FOUND Then
        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        VALUES ('JobParameters', 'Instrument_File_Hash', _fileHash);
    End If;

    ---------------------------------------------------
    -- Return the parameters as a result set
    ---------------------------------------------------

    RETURN QUERY
    SELECT _job,
           P.Section,
           P.Name,
           P.Value
    FROM Tmp_Param_Tab P
    ORDER BY P.Section, P.Name;

    DROP TABLE Tmp_Param_Tab;

END
$$;


ALTER FUNCTION cap.get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text, _scriptname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text, _scriptname text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text, _scriptname text) IS 'GetTaskParamTable or GetJobParamTable';

