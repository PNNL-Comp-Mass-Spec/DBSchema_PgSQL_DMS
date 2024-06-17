--
-- Name: get_task_step_params(integer, integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_step_params(_job integer, _step integer) RETURNS TABLE(section public.citext, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table with capture task job step parameters for given job step
**
**      Data comes from tables cap.t_tasks, cap.t_task_steps, and cap.t_task_parameters
**
**  Arguments:
**    _job      Capture task job number
**    _step     Job step
**
**  Auth:   grk
**  Date:   09/08/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          08/30/2013 mem - Added MyEMSL_Status_URI
**          01/04/2016 mem - Added EUS_InstrumentID, EUS_ProposalID, and EUS_UploaderID
**          06/15/2017 mem - Only append /xml to the MyEMSL status URI if it contains /status/
**          06/12/2018 mem - Now calling Get_Metadata_For_Dataset
**          05/17/2019 mem - Switch from folder to directory
**          06/06/2023 mem - Ported to PostgreSQL
**          06/20/2023 mem - Use citext for columns in the output table
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _jobStepInfo record;
    _uploadInfo record;
    _stepParamSectionName text := 'StepParameters';
    _dataset text := '';
BEGIN

    CREATE TEMP TABLE Tmp_Param_Tab (
        Section citext,
        Name citext,
        Value citext
    );

    ---------------------------------------------------
    -- Get basic capture task job step parameters
    ---------------------------------------------------

    SELECT S.Tool,
           S.Input_Folder_Name,
           S.Output_Folder_Name,
           T.Results_Folder_Name
    INTO _jobStepInfo
    FROM cap.t_task_steps S
         INNER JOIN cap.t_tasks T
           ON S.Job = T.Job
    WHERE S.Job = _job AND
          S.Step = _step;

    If Not FOUND Then
        RAISE WARNING 'Could not find basic capture task job step parameters for Job %, Step % in cap.t_task_steps', _job, _step;
        DROP TABLE Tmp_Param_Tab;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the MyEMSL Status URI
    -- We will only get a match if this capture task job contains step tool ArchiveUpdate or DatasetArchive
    -- Furthermore, we won't get a row until after the ArchiveUpdate or DatasetArchive step successfully completes
    -- This URI will be used by the ArchiveVerify tool
    ---------------------------------------------------

    SELECT format('%s%s', StatusU.uri_path, MU.status_num) AS myemsl_status_uri,
           eus_instrument_id,
           eus_proposal_id,
           eus_uploader_id
    INTO _uploadInfo
    FROM cap.t_myemsl_uploads MU
         INNER JOIN cap.t_uri_paths StatusU
           ON MU.status_uri_path_id = StatusU.uri_path_id
    WHERE MU.job = _job AND
          MU.status_uri_path_id > 1
    ORDER BY MU.entry_id DESC
    LIMIT 1;

    If _uploadInfo.myemsl_status_uri Like '%/status/%' Then
        -- Need a URL of the form https://ingest.my.emsl.pnl.gov/myemsl/cgi-bin/status/3268638/xml
        _uploadInfo.myemsl_status_uri := format('%s/xml', _uploadInfo.myemsl_status_uri);
    End If;

    ---------------------------------------------------
    -- Get capture task job step parameters
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    VALUES (_stepParamSectionName, 'Job',                  _job),
           (_stepParamSectionName, 'Step',                 _step),
           (_stepParamSectionName, 'StepTool',             _jobStepInfo.Tool),
           (_stepParamSectionName, 'ResultsDirectoryName', _jobStepInfo.Results_Folder_Name),
           (_stepParamSectionName, 'InputDirectoryName',   _jobStepInfo.Input_Folder_Name),
           (_stepParamSectionName, 'OutputDirectoryName',  _jobStepInfo.Output_Folder_Name),
           (_stepParamSectionName, 'MyEMSL_Status_URI',    _uploadInfo.myemsl_status_uri),
           (_stepParamSectionName, 'EUS_InstrumentID',     _uploadInfo.eus_instrument_id),
           (_stepParamSectionName, 'EUS_ProposalID',       _uploadInfo.eus_proposal_id),
           (_stepParamSectionName, 'EUS_UploaderID',       _uploadInfo.eus_uploader_id);

    ---------------------------------------------------
    -- Get capture task job parameters
    ---------------------------------------------------

    -- To allow for more than one instance of a tool
    -- in a single script, look at parameters in sections
    -- that either are not locked to any step
    -- (step number is null) or are locked to the current step

    INSERT INTO Tmp_Param_Tab (Section, Name, Value)
    SELECT Trim(XmlQ.section),
           Trim(XmlQ.name),
           Trim(XmlQ.value)
    FROM (
            SELECT xmltable.section,
                   xmltable.name,
                   xmltable.value,
                   xmltable.step,
                   Coalesce(public.try_cast(xmltable.step, null::int), 0) AS StepNumber
            FROM (SELECT ('<params>' || parameters::text || '</params>')::xml AS rooted_xml
                  FROM cap.t_task_parameters
                  WHERE cap.t_task_parameters.job = _job
                 ) Src,
                 XMLTABLE('//params/Param'
                    PASSING Src.rooted_xml
                    COLUMNS section text PATH '@Section',
                            name    text PATH '@Name',
                            value   text PATH '@Value',
                            step    text PATH '@Step')
         ) XmlQ
    WHERE XmlQ.step IS NULL OR XmlQ.StepNumber = _step;

    ---------------------------------------------------
    -- Get metadata for dataset if running the Dataset Info plugin or the Dataset Quality plugin
    -- The Dataset Info tool uses the Reporter_Mz_Min value to validate datasets with reporter ions
    -- The Dataset Quality tool creates file metadata.xml
    ---------------------------------------------------

    If _jobStepInfo.Tool In ('DatasetInfo', 'DatasetQuality') Then
        SELECT Dataset
        INTO _dataset
        FROM cap.t_tasks
        WHERE Job = _job;

        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        SELECT Src.Section, Src.Name, Src.Value
        FROM cap.get_metadata_for_dataset(_dataset) Src
        ORDER BY Src.Section, Src.Name;

    End If;

    RETURN QUERY
    SELECT Src.Section, Src.Name, Src.Value
    FROM Tmp_Param_Tab Src;

    DROP TABLE Tmp_Param_Tab;
END
$$;


ALTER FUNCTION cap.get_task_step_params(_job integer, _step integer) OWNER TO d3l243;

