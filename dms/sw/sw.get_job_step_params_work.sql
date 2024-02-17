--
-- Name: get_job_step_params_work(integer, integer, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_step_params_work(_job integer, _step integer, _debugmode boolean DEFAULT false) RETURNS TABLE(section text, name text, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table with the parameters for the given job and step
**
**      Data comes from sw.T_Job_Parameters, not from the public schema tables
**
**  Auth:   mem
**  Date:   12/04/2009 mem - Extracted code from GetJobStepParams to create this procedure
**          07/01/2010 mem - Now constructing a comma-separated list of shared result folders instead of just returning the first one
**          10/11/2011 grk - Added step input and output folders
**          01/19/2012 mem - Now adding DataPackageID
**          07/09/2012 mem - Updated to support the "step" attribute of a "param" element containing Yes and a number, for example 'Yes (3)'
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/16/2015 mem - Now storing T_Step_Tools.Param_File_Storage_Path if defined
**          11/20/2015 mem - Now including CPU_Load
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/20/2016 mem - Update procedure name shown when using _debugMode
**          05/13/2017 mem - Include info from T_Remote_Info if Remote_Info_ID is not 1
**          05/16/2017 mem - Include RemoteTimestamp if defined
**          03/12/2021 mem - Add ToolName (which tracks the pipeline script name) if not present in T_Job_Parameters
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          04/11/2022 mem - Use varchar(4000) when extracting values from the XML
**          07/27/2022 mem - Move check for missing ToolName parameter to after adding job parameters using T_Job_Parameters
**          06/07/2023 mem - Rename variables and update alias names
**                         - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _stepTool text := '';
    _inputFolderName text := '';
    _outputFolderName text := '';
    _dataPackageID int := 0;
    _scriptName text := '';
    _remoteInfoId int;
    _remoteInfo text := '';
    _remoteTimestamp text;
    _sharedFolderList text := Null;
    _stepOutputFolderName text := '';
    _stepInputFolderName text := '';
    _paramFileStoragePath text := '';
    _cpuLoad int := 1;
    _stepParamSectionName text := 'StepParameters';
BEGIN

    _debugMode := Coalesce(_debugMode, false);

    If _debugMode Then
        RAISE INFO '';
        RAISE INFO '%, Get_Job_Step_Params_Work: Get basic job step parameters from sw.t_job_steps', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get basic job step parameters
    ---------------------------------------------------

    SELECT JS.tool,
           JS.input_folder_name,
           JS.output_folder_name,
           JS.remote_info_id,
           JS.remote_timestamp
    INTO _stepTool, _inputFolderName, _outputFolderName, _remoteInfoId, _remoteTimestamp
    FROM sw.t_job_steps JS
    WHERE JS.job = _job AND
          JS.step = _step;

    If Not FOUND Then
        RAISE WARNING 'Job %, step % not found in sw.t_job_steps', _job, _step;
        RETURN;
    End If;

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_Work: Get data package ID and script from sw.t_jobs', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Lookup data package ID and script name in sw.t_jobs
    ---------------------------------------------------

    SELECT data_pkg_id,
           script
    INTO _dataPackageID, _scriptName
    FROM sw.t_jobs
    WHERE job = _job;

    _dataPackageID := Coalesce(_dataPackageID, 0);

    ---------------------------------------------------
    -- Lookup server info in sw.t_remote_info if _remoteInfoId > 1
    ---------------------------------------------------

    If Coalesce(_remoteInfoId, 0) > 1 Then
        SELECT remote_info
        INTO _remoteInfo
        FROM sw.t_remote_info
        WHERE remote_info_id = _remoteInfoId;

        _remoteInfo := Trim(Coalesce(_remoteInfo, ''));
    End If;


    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_Work: Get shared results directory name list', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get shared results directory name list
    -- Be sure to sort by increasing step number so that the newest shared result folder is last
    ---------------------------------------------------

    SELECT string_agg(output_folder_name, ', ' ORDER BY step)
    INTO _sharedFolderList
    FROM sw.t_job_steps
    WHERE job = _job AND
          shared_result_version > 0 AND
          state IN (3, 5);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_Work: Get job step parameters from sw.t_job_steps', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get input and output folder names for individual steps
    -- (used by aggregation jobs created in broker)
    -- Also lookup the parameter file storage path and the CPU_Load
    ---------------------------------------------------

    SELECT format('Step_%s_%s', JS.step, ST.tag),
           ST.param_file_storage_path,
           JS.cpu_load
    INTO _stepOutputFolderName, _paramFileStoragePath, _cpuLoad
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_step_tools ST
           ON JS.tool = ST.step_tool
    WHERE JS.job = _job AND
          JS.step = _step;

    SELECT format('Step_%s_%s', TSD.target_step, ST.tag)
    INTO _stepInputFolderName
    FROM sw.t_job_step_dependencies AS TSD
         INNER JOIN sw.t_job_steps AS JS
           ON TSD.job = JS.job AND
              TSD.target_step = JS.step
         INNER JOIN sw.t_step_tools AS ST
           ON JS.tool = ST.step_tool
    WHERE TSD.job = _job AND
          TSD.step = _step AND
          TSD.enable_only = 0;

    If Not FOUND Then
        _stepInputFolderName := '';
    End If;

    ---------------------------------------------------
    -- Create a temporary table to hold the job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Param_Tab (
        Section text,
        Name text,
        Value text
    );

    ---------------------------------------------------
    -- Get job step parameters
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES (_stepParamSectionName, 'Job', _job),
           (_stepParamSectionName, 'Step', _step),
           (_stepParamSectionName, 'StepTool', _stepTool),
           (_stepParamSectionName, 'InputFolderName', _inputFolderName),
           (_stepParamSectionName, 'OutputFolderName', _outputFolderName),
           (_stepParamSectionName, 'SharedResultsFolders', _sharedFolderList),
           (_stepParamSectionName, 'StepOutputFolderName', _stepOutputFolderName),
           (_stepParamSectionName, 'StepInputFolderName', _stepInputFolderName);

    If Coalesce(_paramFileStoragePath, '') <> '' Then
        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        VALUES (_stepParamSectionName, 'ParamFileStoragePath', _paramFileStoragePath);
    End If;

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES (_stepParamSectionName, 'CPU_Load', _cpuLoad);

    If Coalesce(_remoteInfo, '') <> '' Then
        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        VALUES (_stepParamSectionName, 'RemoteInfo', _remoteInfo);
    End If;

    If Coalesce(_remoteTimestamp, '') <> '' Then
        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        VALUES (_stepParamSectionName, 'RemoteTimestamp', _remoteTimestamp);
    End If;

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES ('JobParameters', 'DataPackageID', _dataPackageID);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_Work: Get job parameters from sw.t_job_parameters', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get job parameters
    -- Exclude DataPackageID since we obtained that from sw.t_jobs
    ---------------------------------------------------

    -- To allow for more than one instance of a tool in a single script,
    -- look at parameters in sections that either are not locked to any step (step number is null)
    -- or are locked to the current step
    --
    -- Prior to June 2012, step locking would use notation like this:
    -- <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="2" />
    --
    -- We now use notation like this:
    -- <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="Yes (2)" />
    --
    -- Thus, the following uses a series of Replace commands to remove text from the Step attribute,
    -- replacing the following three strings with ""
    --   "Yes ("
    --   "No ("
    --   ")"

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    SELECT ConvertQ.section, ConvertQ.name, ConvertQ.value
    FROM (
            SELECT XmlQ.section,
                   XmlQ.name,
                   XmlQ.value,
                   Coalesce(public.try_cast(XmlQ.Step, null::int), 0) AS StepNumber
            FROM (
                    SELECT xmltable.section,
                           xmltable.name,
                           xmltable.value,
                           Replace(Replace(Replace(Coalesce(xmltable.step, ''), 'Yes (', ''), 'No (', ''), ')', '') AS Step
                    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml AS rooted_xml
                           FROM sw.t_job_parameters
                           WHERE sw.t_job_parameters.job = _job ) Src,
                               XMLTABLE('//params/Param'
                                  PASSING Src.rooted_xml
                                  COLUMNS section citext PATH '@Section',
                                          name citext PATH '@Name',
                                          value citext PATH '@Value',
                                          step citext PATH '@Step')
                   ) XmlQ
          ) ConvertQ
    WHERE ConvertQ.Name <> 'DataPackageID' AND
          (ConvertQ.StepNumber = 0 OR
           ConvertQ.StepNumber = _step);

    ---------------------------------------------------
    -- Add ToolName if not present in Tmp_Param_Tab
    -- This will be the case for jobs created directly in the pipeline database (including MAC jobs and MaxQuant_DataPkg jobs)
    ---------------------------------------------------

    If Not Exists (Select * from Tmp_Param_Tab P Where P.Section = 'JobParameters' And P.Name = 'ToolName') Then
        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        VALUES ('JobParameters', 'ToolName', _scriptName);
    End If;

    RETURN QUERY
    SELECT Src.Section, Src.Name, Src.Value
    FROM Tmp_Param_Tab Src;

    DROP TABLE Tmp_Param_Tab;

END
$$;


ALTER FUNCTION sw.get_job_step_params_work(_job integer, _step integer, _debugmode boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_step_params_work(_job integer, _step integer, _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_step_params_work(_job integer, _step integer, _debugmode boolean) IS 'GetJobStepParamsWork';

