--
-- Name: get_task_param_table(integer, text, integer, text, text, text, integer, text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) RETURNS TABLE(job integer, section text, name text, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the parameters for the given capture task job in Section/Name/Value rows
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/04/2010 grk - Added instrument class params
**          03/23/2012 mem - Now including EUS_Instrument_ID
**          04/09/2013 mem - Now looking up Perform_Calibration from public.T_Instrument_Name
**          08/20/2013 mem - Now looking up EUS_Proposal_ID
**          09/04/2013 mem - Now including TransferFolderPath
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          11/16/2015 mem - Now including EUS_Operator_ID and Operator_PRN
**          05/17/2019 mem - Switch from folder to directory in temp tables
**                         - Add parameter SHA1_Hash
**          08/31/2022 mem - Rename view V_DMS_Capture_Job_Parameters to V_DMS_Dataset_Metadata
**          09/28/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _paramXML XML;
    _rawDataType text;
    _performCalibration int;
    _performCalibrationText text;
    _storageVolExternal text;
    _transferDirectoryPath text;
    _fileHash text := '';
BEGIN
    ---------------------------------------------------
    -- Temp table to hold capture task job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamTab(
      Section text,
      Name text,
      Value text
    );

    ---------------------------------------------------
    -- Locally cached params
    ---------------------------------------------------

    INSERT INTO Tmp_ParamTab ( Section, Name, Value)
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
    -- Convert columns of data from V_DMS_Dataset_Metadata into rows added to Tmp_ParamTab
    ---------------------------------------------------

    INSERT INTO Tmp_ParamTab ( Section, Name, Value)
    SELECT 'JobParameters' AS Section,
           UnpivotQ.Name,
           UnpivotQ.Value
    FROM ( SELECT Type AS Dataset_Type,
                  Folder AS Directory,
                  Method,
                  Capture_Exclusion_Window::text AS Capture_Exclusion_Window,
                  timestamp_text(Created) AS Created,
                  Source_Vol AS Source_Vol,
                  source_Path AS Source_Path,
                  Storage_Vol AS Storage_Vol,
                  Storage_Path AS Storage_Path,
                  Storage_Vol_External AS Storage_Vol_External,
                  Archive_Server AS Archive_Server,
                  Archive_Path AS Archive_Path,
                  Archive_Network_Share_Path AS Archive_Network_Share_Path,
                  EUS_Instrument_ID::text AS EUS_Instrument_ID,
                  EUS_Proposal_ID::text AS EUS_Proposal_ID,
                  EUS_Operator_ID::text AS EUS_Operator_ID,
                  Operator_PRN AS Operator_PRN
           FROM cap.V_DMS_Dataset_Metadata
           WHERE Dataset_ID = _datasetID) AS m
         CROSS JOIN LATERAL (
           VALUES
                ('Dataset_Type', m.Dataset_Type),
                ('Directory', m.Directory),
                ('Method', m.Method),
                ('Capture_Exclusion_Window', m.Capture_Exclusion_Window),
                ('Created', m.Created),
                ('Source_Vol', m.Source_Vol),
                ('Source_Path', m.Source_Path),
                ('Storage_Vol', m.Storage_Vol),
                ('Storage_Path', m.Storage_Path),
                ('Storage_Vol_External', m.Storage_Vol_External),
                ('Archive_Server', m.Archive_Server),
                ('Archive_Path', m.Archive_Path),
                ('Archive_Network_Share_Path', m.Archive_Network_Share_Path),
                ('EUS_Instrument_ID', m.EUS_Instrument_ID),
                ('EUS_Proposal_ID', m.EUS_Proposal_ID),
                ('EUS_Operator_ID', m.EUS_Operator_ID),
                ('Operator_PRN', m.Operator_PRN)
           ) AS UnpivotQ(Name, Value)
    WHERE Not UnpivotQ.value Is Null;

    ---------------------------------------------------
    -- Instrument class params from V_DMS_Instrument_Class
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
    --
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

    INSERT INTO Tmp_ParamTab (Section, Name, Value)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _paramXML As params
             ) Src,
             XMLTABLE('//sections/section/item'
                      PASSING Src.params
                      COLUMNS section citext PATH '../@name',
                              name    citext PATH '@key',
                              value   citext PATH '@value'
                              )
         ) XmlQ;

    ---------------------------------------------------
    -- Determine whether calibration should be performed
    -- (as of April 2013, only applies to IMS instruments)
    ---------------------------------------------------

    SELECT Perform_Calibration
    INTO _performCalibration
    FROM public.T_Instrument_Name
    WHERE instrument = _instrument;

    If Coalesce(_performCalibration, 0) = 0 Then
        _performCalibrationText := 'False';
    Else
        _performCalibrationText := 'True';
    End If;

    INSERT INTO Tmp_ParamTab (Section, Name, Value)
    VALUES ('JobParameters', 'PerformCalibration', _performCalibrationText);

    ---------------------------------------------------
    -- Lookup the Analysis Transfer directory (e.g. \\proto-6\DMS3_Xfer)
    -- This directory is used to store metadata.txt files for dataset archive and archive tasks
    -- Those files are used by the ArchiveVerify tool to confirm that files were successfully imported into MyEMSL
    ---------------------------------------------------

    SELECT P.Value
    INTO _storageVolExternal
    FROM Tmp_ParamTab P
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

    _transferDirectoryPath := Coalesce(_transferDirectoryPath, '');

    INSERT INTO Tmp_ParamTab (Section, Name, Value)
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
        INSERT INTO Tmp_ParamTab (Section, Name, Value)
        VALUES ('JobParameters', 'Instrument_File_Hash', _fileHash);
    End If;

    ---------------------------------------------------
    -- Return the parameters as a resultset
    ---------------------------------------------------

    RETURN QUERY
    SELECT _job,
           P.Section,
           P.Name,
           P.Value
    FROM Tmp_ParamTab P
    ORDER BY P.Section, P.Name;

    DROP TABLE Tmp_ParamTab;

END
$$;


ALTER FUNCTION cap.get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_param_table(_job integer, _dataset text, _datasetid integer, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) IS 'GetJobParamTable';

