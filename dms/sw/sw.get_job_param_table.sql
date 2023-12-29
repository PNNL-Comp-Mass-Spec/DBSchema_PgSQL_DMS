--
-- Name: get_job_param_table(integer, text, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_param_table(_job integer, _settingsfileoverride text DEFAULT ''::text, _debugmode boolean DEFAULT false) RETURNS TABLE(job integer, section text, name text, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the parameters for the given job in Section/Name/Value rows
**      Data comes from the public schema tables (via view v_get_pipeline_job_parameters)
**
**  Arguments:
**    _job                      Job number to obtain parameters for (should exist in sw.t_jobs, but not required)
**    _settingsFileOverride     When defined, use this settings file name instead of the one obtained with public.v_get_pipeline_job_parameters
**    _debugMode                When true, show additional debug messages
**
**  Example usage:
**
**      SELECT * FROM sw.get_job_param_table(2023504);
**      SELECT * FROM sw.get_job_param_table(2023504, '', true);
**      SELECT * FROM sw.get_job_param_table(2023504, 'IonTrapDefSettings_MzML_StatCysAlk_16plexTMT.xml', true);
**
**  Auth:   grk
**  Date:   08/21/2008 grk - Initial release
**          01/14/2009 mem - Increased maximum parameter length to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          04/10/2009 grk - Added DTA folder name override (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          06/02/2009 mem - Updated to run within the DMS_Pipeline DB and to use view v_get_pipeline_job_parameters (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          07/29/2009 mem - Updated to look in T_Jobs.Comment for the 'DTA:' tag when 'ExternalDTAFolderName' is defined in the script
**          01/05/2010 mem - Added parameter _settingsFileOverride
**          02/23/2010 mem - Updated to not return any debug info using SELECT statements; required since CreateParametersForJob calls this SP using the notation: INSERT INTO ... exec Get_Job_Param_Table ...
**          04/04/2011 mem - Updated to support public.t_settings_files returning true XML for the Contents column (using S_DMS_V_GetPipelineSettingsFiles)
**                         - Added support for field Special_Processing
**          04/20/2011 mem - Now calling Check_Add_Special_Processing_Param to look for an AMTDB entry in the Special_Processing parameter
**                         - Additionally, adding parameter AMTDBServer if the AMTDB entry is present
**          08/01/2011 mem - Now filtering on Analysis_Tool when querying public.t_settings_files
**          05/07/2012 mem - Now including DatasetType
**          05/07/2012 mem - Now including Experiment
**          08/23/2012 mem - Now calling Check_Add_Special_Processing_Param to look for a DataImportFolder entry
**          04/23/2013 mem - Now including Instrument and InstrumentGroup
**          01/30/2014 mem - Now using S_DMS_V_Settings_File_Lookup when a match is not found in public.t_settings_files for the given settings file and analysis tool
**          03/14/2014 mem - Added InstrumentDataPurged
**          12/12/2018 mem - Update comments and capitalization
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**                         - Cast ProteinCollectionList to varchar(4000)
**          07/01/2022 mem - Rename job parameters to ParamFileName and ParamFileStoragePath
**          08/17/2022 mem - Remove reference to MTS view
**                           (previously looked for tag AMTDB in the Special_Processing field for MultiAlign jobs;
**                            given the AMT tag DB name, the code used a view to determine the server on which the MT DB resides)
**                         - Remove check for DataImportFolder in the Special_Processing field
**          10/14/2022 mem - Ported to PostgreSQL
**          03/22/2023 mem - Rename dataset name parameter to DatasetName
**          05/12/2023 mem - Rename variables
**          06/05/2023 mem - Rename temp table
**          07/25/2023 mem - Do not show a warning message when _debugMode is true and the settings file is 'na'
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _paramXML xml;
    _settingsFileName text;
    _analysisToolName text;
    _settingsFileNameMappedTool text;
    _analysisToolNameMappedTool text;
    _settingsFileFound boolean;
    _extDTA text := '';
    _insertCount int;
BEGIN
    ---------------------------------------------------
    -- Temp table to hold job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Param_Tab (
      Section text,
      Name text,
      Value text
    );

    _settingsFileOverride := Trim(Coalesce(_settingsFileOverride, ''));
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Job Parameters
    --
    -- Convert columns of data from public.v_get_pipeline_job_parameters into rows added to Tmp_Param_Tab
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    SELECT 'JobParameters' As Section,
           UnpivotQ.Name,
           UnpivotQ.Value
    FROM ( SELECT Dataset AS DatasetName,
                  Dataset_ID::text AS DatasetID,
                  Dataset_Folder_Name AS DatasetFolderName,
                  Archive_Folder_Path AS DatasetArchivePath,
                  Dataset_Storage_Path AS DatasetStoragePath,
                  Transfer_Folder_Path AS TransferFolderPath,
                  Instrument_Data_Purged::text AS InstrumentDataPurged,
                  Param_File_Name AS ParamFileName,
                  Settings_File_Name AS SettingsFileName,
                  Special_Processing AS Special_Processing,
                  Param_File_Storage_Path AS ParamFileStoragePath,     -- Storage path for the primary tool of the script
                  Organism_DB_Name AS LegacyFastaFileName,
                  Protein_Collection_List AS ProteinCollectionList,
                  Protein_Options_List AS ProteinOptions,
                  Instrument_Class AS InstClass,
                  Instrument_Group AS InstrumentGroup,
                  Instrument,
                  Raw_Data_Type AS RawDataType,
                  Dataset_Type AS DatasetType,
                  Experiment,
                  Search_Engine_Input_File_Formats AS SearchEngineInputFileFormats,
                  Organism AS OrganismName,
                  Org_DB_Required::text AS OrgDbReqd,
                  Tool_Name AS ToolName,
                  Result_Type AS ResultType
                FROM public.v_get_pipeline_job_parameters P
                WHERE P.Job = _job) as m
         CROSS JOIN LATERAL (
           VALUES
                ('DatasetName', m.DatasetName),
                ('DatasetID', m.DatasetID),
                ('DatasetFolderName', m.DatasetFolderName),
                ('DatasetStoragePath', m.DatasetStoragePath),
                ('DatasetArchivePath', m.DatasetArchivePath),
                ('TransferFolderPath', m.TransferFolderPath),
                ('InstrumentDataPurged', m.InstrumentDataPurged),
                ('ParamFileName', m.ParamFileName),
                ('SettingsFileName', m.SettingsFileName),
                ('Special_Processing', m.Special_Processing),
                ('ParamFileStoragePath', m.ParamFileStoragePath),
                ('LegacyFastaFileName', m.LegacyFastaFileName),
                ('ProteinCollectionList', m.ProteinCollectionList),
                ('ProteinOptions', m.ProteinOptions),
                ('InstClass', m.InstClass),
                ('InstrumentGroup', m.InstrumentGroup),
                ('Instrument', m.Instrument),
                ('RawDataType', m.RawDataType),
                ('DatasetType', m.DatasetType),
                ('Experiment', m.Experiment),
                ('SearchEngineInputFileFormats', m.SearchEngineInputFileFormats),
                ('OrganismName', m.OrganismName),
                ('OrgDbReqd', m.OrgDbReqd),
                ('ToolName', m.ToolName),
                ('ResultType', m.ResultType)
           ) AS UnpivotQ(Name, Value)
    WHERE Not UnpivotQ.value Is Null;

    ---------------------------------------------------
    -- Simulate section association for step tool
    ---------------------------------------------------

    UPDATE Tmp_Param_Tab target
    SET Section = 'PeptideSearch'
    WHERE target.Name in ('ParamFileName', 'ParamFileStoragePath', 'OrganismName',  'LegacyFastaFileName',  'ProteinCollectionList',  'ProteinOptions');

    ---------------------------------------------------
    -- Possibly override the settings file name
    ---------------------------------------------------

    If _settingsFileOverride <> '' Then
        UPDATE Tmp_Param_Tab target
        SET Value = _settingsFileOverride
        WHERE target.Name = 'SettingsFileName';

        If FOUND Then
            If _debugMode Then
                RAISE INFO 'Updated settings file to: %', _settingsFileOverride;
            End If;
        Else
            INSERT INTO Tmp_Param_Tab (Section, Name, Value)
            SELECT 'JobParameters' AS Section,
                   'SettingsFileName' AS Name,
                   _settingsFileOverride AS Value;

            If _debugMode Then
                RAISE INFO 'Settings file was not defined; defined it as: %', _settingsFileOverride;
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Get settings file parameters from DMS
    ---------------------------------------------------

    -- Lookup the settings file name
    --
    SELECT P.Value
    INTO _settingsFileName
    FROM Tmp_Param_Tab P
    WHERE P.Name = 'SettingsFileName';

    If Not FOUND Or _settingsFileName Is Null Then
        _settingsFileName := 'na';

        If _debugMode Then
            RAISE WARNING 'Warning: Settings file was not defined in the job parameters; assuming "na"';
        End If;
    End If;

    -- Lookup the analysis tool name
    --
    SELECT P.Value
    INTO _analysisToolName
    FROM Tmp_Param_Tab P
    WHERE P.Name = 'ToolName';

    If Not FOUND Or _analysisToolName Is Null Then
        _analysisToolName := '';

        If _debugMode Then
            RAISE WARNING 'Warning: Analysis tool was not defined in the job parameters; may choose the wrong settings file (if files for different tools have the same name)';
        End If;
    End If;

    -- Retrieve the settings file contents (as XML)
    --
    SELECT Contents
    INTO _paramXML
    FROM public.t_settings_files
    WHERE file_name = _settingsFileName AND
          (analysis_tool = _analysisToolName OR _analysisToolName = '');

    If FOUND Then
        _settingsFileFound := true;
    Else
        _settingsFileFound := false;

        -- Settings file not found for tool _analysisToolName
        -- Try relaxing the tool name specification

        SELECT File_Name, Mapped_Tool
        INTO _settingsFileNameMappedTool,
             _analysisToolNameMappedTool
        FROM public.V_Settings_File_Lookup
        WHERE File_Name = _settingsFileName AND
              Analysis_Tool = _analysisToolName
        LIMIT 1;

        If FOUND Then
            SELECT Contents
            INTO _paramXML
            FROM public.t_settings_files
            WHERE file_name = _settingsFileNameMappedTool AND
                  analysis_tool = _analysisToolNameMappedTool;

            If FOUND Then
                _settingsFileFound := true;
            End If;
        End If;
    End If;

    If Not _settingsFileFound Then
        If _debugMode And _settingsFileName <> 'na' Then
            RAISE WARNING 'Warning: Settings file % not defined in public.t_settings_files', _settingsFileName;
        End If;
    Else
        If _debugMode Then
            RAISE INFO 'XML for settings file %: %', _settingsFileName, _paramXML::text;
        End If;

        ---------------------------------------------------
        -- Extract Section, Name, and Value from _paramXML
        --
        -- XML excerpt:
        --   <sections>
        --     <section name="MzRefinery">
        --       <item key="MzRefParamFile" value="MzRef_StatCysAlk_iTRAQ_8plex.txt" />
        --     </section>
        --     <section name="MzRefineryRuntimeOptions">
        --       <item key="MzRefMSGFPlusJavaMemorySize" value="4000" />
        --     </section>
        --     <section name="MSGFDB">
        --       <item key="MSGFDBJavaMemorySize" value="4000" />
        --       <item key="MSGFDBThreads" value="all" />
        --     </section>
        --   </sections>

        ---------------------------------------------------

        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
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
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Added % new entries using settings file %', _insertCount, _settingsFileName;
        End If;
    End If;

    ---------------------------------------------------
    -- Check whether the settings file has an
    -- External DTA folder defined
    ---------------------------------------------------

    If Exists (SELECT * FROM Tmp_Param_Tab P WHERE P.Name = 'ExternalDTAFolderName') Then
        ---------------------------------------------------
        -- Look for a Special_Processing entry in the job parameters
        -- If one exists, look for the DTA: tag
        -- Otherwise, look in the job's comment for the DTA: tag
        --
        -- If the DTA: tag is found, the name after the column represents an external DTA folder name
        -- to override the external DTA folder name defined in the settings file
        ---------------------------------------------------

        SELECT sw.extract_tagged_name('DTA:', P.Value)
        INTO _extDTA
        FROM Tmp_Param_Tab P
        WHERE P.Name = 'Special_Processing';

        If _extDTA = '' Then
            SELECT sw.extract_tagged_name('DTA:', J.Comment)
            INTO _extDTA
            FROM sw.t_jobs J
            WHERE J.job = _job;
        End If;

        If _extDTA <> '' Then
            UPDATE Tmp_Param_Tab P
            SET Value = _extDTA
            WHERE P.Name = 'ExternalDTAFolderName';

            If _debugMode Then
                RAISE INFO 'External DTA Folder Name parameter has been overridden to "%" using the DTA: tag in the job comment', _extDTA;
            End If;
        Else
            SELECT P.Value
            INTO _extDTA
            FROM P.Tmp_Param_Tab
            WHERE P.Name = 'ExternalDTAFolderName';

            If _debugMode Then
                RAISE INFO 'Note: ExternalDTAFolderName is "%", as defined in the settings file', _extDTA;
            End If;
        End If;
    End If;

    If _debugMode Then
        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        VALUES ('Misc', 'DebugMode', _debugMode::text);
    End If;

    ---------------------------------------------------
    -- Output the table of parameters
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


ALTER FUNCTION sw.get_job_param_table(_job integer, _settingsfileoverride text, _debugmode boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_param_table(_job integer, _settingsfileoverride text, _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_param_table(_job integer, _settingsfileoverride text, _debugmode boolean) IS 'GetJobParamTable';

