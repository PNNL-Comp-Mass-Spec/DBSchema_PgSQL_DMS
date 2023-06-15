--
-- Name: get_job_step_params_from_history_work(integer, integer, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_step_params_from_history_work(_job integer, _step integer, _debugmode boolean DEFAULT false) RETURNS TABLE(section text, name text, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a table with the parameters for the given job and step
**
**      Data comes from sw.T_Job_Parameters_History, not from the public schema tables
**
**  Auth:   mem
**  Date:   07/31/2013 mem - Ported from GetJobStepParamsWork
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/20/2016 mem - Update procedure name shown when using _debugMode
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          04/11/2022 mem - Use varchar(4000) when extracting values from the XML
**          06/07/2023 mem - Set _stepInputFolderName to '' if step = 1 (matching the behavior of get_job_step_params_work)
**                         - Add step parameter 'ParamFileStoragePath'
**                         - Add job parameter 'ToolName' if not present in T_Job_Parameters_History
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stepTool text := '';
    _inputFolderName text := '';
    _outputFolderName text := '';
    _dataPackageID int := 0;
    _scriptName text := '';
    _sharedFolderList text;
    _stepOutputFolderName text := '';
    _stepInputFolderName text := '';
    _paramFileStoragePath text := '';
    _stepParamSectionName text := 'StepParameters';
BEGIN

    _debugMode := Coalesce(_debugMode, false);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params: Get basic job step parameters from sw.t_job_steps_history', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get basic job step parameters
    ---------------------------------------------------

    SELECT JSH.tool,
           JSH.input_folder_name,
           JSH.output_folder_name
    INTO _stepTool, _inputFolderName, _outputFolderName
    FROM sw.t_job_steps_history JSH
    WHERE JSH.job = _job AND
          JSH.step = _step AND
          JSH.most_recent_entry = 1;

    If Not FOUND Then
        RAISE WARNING 'Job %, step % not found in sw.t_job_steps_history', _job, _step;
        RETURN;
    End If;

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params: Get data package ID and script from sw.t_jobs', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Lookup data package ID and script name in sw.t_jobs_history
    ---------------------------------------------------

    SELECT data_pkg_id,
           script
    INTO _dataPackageID, _scriptName
    FROM sw.t_jobs_history
    WHERE job = _job AND
          most_recent_entry = 1;

    _dataPackageID := Coalesce(_dataPackageID, 0);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params: Get shared results directory name list', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get shared results directory name list
    -- Be sure to sort by increasing step number so that the newest shared result folder is last
    ---------------------------------------------------

    SELECT string_agg(output_folder_name, ', ' ORDER BY step)
    INTO _sharedFolderList
    FROM sw.t_job_steps_history
    WHERE job = _job AND
          shared_result_version > 0 AND
          state IN (3, 5) AND
          most_recent_entry = 1;

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params: Get job step parameters from sw.t_job_steps_history', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get input and output folder names for individual steps
    -- (used by aggregation jobs created in broker)
    -- Also lookup the parameter file storage path and the CPU_Load
    ---------------------------------------------------

    SELECT format('Step_%s_%s', JSH.step, ST.tag),
           ST.param_file_storage_path
    INTO _stepOutputFolderName, _paramFileStoragePath
    FROM sw.t_job_steps_history JSH
         INNER JOIN sw.t_step_tools ST
           ON JSH.tool = ST.step_tool
    WHERE JSH.job = _job AND
          JSH.step = _step AND
          JSH.most_recent_entry = 1;

    If _step > 1 Then
        SELECT format('Step_%s_NotDefined', JSH.step - 1)
        INTO _stepInputFolderName
        FROM sw.t_job_steps_history AS JSH
             INNER JOIN sw.t_step_tools AS ST
               ON JSH.tool = ST.step_tool
        WHERE JSH.job = _job AND
              JSH.step = _step AND
              JSH.most_recent_entry = 1;
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
    VALUES ('JobParameters', 'DataPackageID', _dataPackageID);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params: Get job parameters from sw.t_job_parameters_history', public.timestamp_text_immutable(clock_timestamp());
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
    -- Thus, the following uses a series of REPLACE commands to remove text from the Step attribute,
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
                   Coalesce(public.try_cast(XmlQ.Step, null::int), 0) As StepNumber
            FROM (
                    SELECT xmltable.section,
                           xmltable.name,
                           xmltable.value,
                           REPLACE(REPLACE(REPLACE( Coalesce(xmltable.step, ''), 'Yes (', ''), 'No (', ''), ')', '') AS Step
                    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml As rooted_xml
                           FROM sw.t_job_parameters_history
                           WHERE sw.t_job_parameters_history.job = _job AND
                                 sw.t_job_parameters_history.most_recent_entry = 1 ) Src,
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


ALTER FUNCTION sw.get_job_step_params_from_history_work(_job integer, _step integer, _debugmode boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_step_params_from_history_work(_job integer, _step integer, _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_step_params_from_history_work(_job integer, _step integer, _debugmode boolean) IS 'GetJobStepParamsFromHistoryWork';

