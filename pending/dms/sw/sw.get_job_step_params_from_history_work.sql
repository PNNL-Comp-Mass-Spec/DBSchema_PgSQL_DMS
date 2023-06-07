--
CREATE OR REPLACE FUNCTION sw.get_job_step_params_from_history_work
(
    _job int,
    _step int,
    _debugMode boolean = false
)
RETURNS TABLE (
    Section text,
    Name text,
    Value text
)
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stepTool text := '';
    _inputFolderName text := '';
    _outputFolderName text := '';
    _dataPackageID int := 0;
    _sharedFolderList text;
    _stepOutputFolderName text := '';
    _stepInputFolderName text := '';
    _stepParmSectionName text;
BEGIN
    _debugMode := Coalesce(_debugMode, false);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_From_History_Work: Get basic job step parameters', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get basic job step parameters
    ---------------------------------------------------
    --
    SELECT JSH.tool,
           JSH.input_folder_name,
           JSH.output_folder_name
    INTO _stepTool, _inputFolderName, _outputFolderName
    FROM sw.t_job_steps_history JSH
    WHERE JSH.job = _job AND
          JSH.step = _step AND
          JSH.most_recent_entry = 1;

    If Not FOUND Then
        _message := 'Could not find basic job step parameters';
        _returnCode := 'U5442';
        RETURN;
    End If;

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_From_History_Work: Get shared results directory name list', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Lookup data package ID in sw.t_jobs
    ---------------------------------------------------
    --
    SELECT data_pkg_id
    INTO _dataPackageID
    FROM sw.t_jobs_history
    WHERE job = _job AND
          most_recent_entry = 1;

    _dataPackageID := Coalesce(_dataPackageID, 0);

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
        RAISE INFO '%, Get_Job_Step_Params_From_History_Work: Get job step parameters', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get input and output folder names for individual steps
    -- (used by aggregation jobs created in broker)
    ---------------------------------------------------

    SELECT format('Step_%s_%s', JSH.step, ST.tag)
    INTO _stepOutputFolderName
    FROM    sw.t_job_steps_history JSH
            INNER JOIN sw.t_step_tools ST ON JSH.tool = ST.step_tool
    WHERE   JSH.job = _job AND
            JSH.step = _step AND
            JSH.most_recent_entry = 1;

    SELECT format('Step_%s_NotDefined', JSH.step)
    INTO _stepInputFolderName
    FROM  sw.t_job_steps_history AS JSH
            INNER JOIN sw.t_step_tools AS ST ON JSH.tool = ST.step_tool
    WHERE   ( JSH.job = _job ) AND
            ( JSH.step = _step ) AND
            JSH.most_recent_entry = 1;

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
    --
    _stepParmSectionName := 'StepParameters';
    --
    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES (_stepParmSectionName, 'Job', _job),
           (_stepParmSectionName, 'Step', _step),
           (_stepParmSectionName, 'StepTool', _stepTool),
           (_stepParmSectionName, 'InputFolderName', _inputFolderName),
           (_stepParmSectionName, 'OutputFolderName', _outputFolderName),
           (_stepParmSectionName, 'SharedResultsFolders', _sharedFolderList),
           (_stepParmSectionName, 'StepOutputFolderName', _stepOutputFolderName),
           (_stepParmSectionName, 'StepInputFolderName', _stepInputFolderName),
           ('JobParameters', 'DataPackageID', _dataPackageID);

    If _debugMode Then
        RAISE INFO '%, Get_Job_Step_Params_From_History_Work: Get job parameters from t_job_parameters_history', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Get job parameters
    -- Exclude DataPackageID since we obtained that from sw.t_jobs
    ---------------------------------------------------
    --
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
                           xmltable.name
                           xmltable.value
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

    RETURN QUERY
    SELECT Section, Name, Value
    FROM Tmp_Param_Tab;

    DROP TABLE Tmp_Param_Tab;

END
$$;

COMMENT ON FUNCTION sw.get_job_step_params_from_history_work IS 'GetJobStepParamsFromHistoryWork';
