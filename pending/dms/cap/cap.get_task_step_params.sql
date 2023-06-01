--
CREATE OR REPLACE FUNCTION cap.get_task_step_params
(
    _job int,
    _step int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
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
**      Return a table with capture task job step parameters for given job step
**      Data comes from tables cap.t_tasks, cap.t_task_steps, and cap.t_task_parameters
**
**  Auth:   grk
**  Date:   09/08/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          08/30/2013 mem - Added MyEMSL_Status_URI
**          01/04/2016 mem - Added EUS_InstrumentID, EUS_ProposalID, and EUS_UploaderID
**          06/15/2017 mem - Only append /xml to the MyEMSL status URI if it contains /status/
**          06/12/2018 mem - Now calling GetMetadataForDataset
**          05/17/2019 mem - Switch from folder to directory
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobStepInfo record;
    _uploadInfo record;
    _stepParmSectionName text := 'StepParameters';
    _dataset text := '';
BEGIN
    _message := '';
    _returnCode := '';

    _myEMSLStatusURI := '';

    _eusInstrumentID := 0;
    _eusProposalID := '';
    _eusUploaderID := 0;

    CREATE TEMP TABLE Tmp_Param_Tab (
        Section text,
        Name text,
        Value text
    )

    ---------------------------------------------------
    -- Get basic capture task job step parameters
    ---------------------------------------------------
    --
    SELECT S.Tool,
           S.Input_Folder_Name,
           S.Output_Folder_Name,
           S.Results_Folder_Name
    INTO _jobStepInfo
    FROM cap.t_task_steps S
         INNER JOIN cap.t_tasks T
           ON S.Job = T.Job
    WHERE S.Job = _job AND
          S.Step = _step;

    If Not FOUND Then
        _message := format('Could not find basic capture task job step parameters for Job %s, Step %s', _job, _step);
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;

        SELECT Section, Name, Value
        FROM Tmp_Param_Tab;

        DROP TABLE Tmp_Param_Tab;
        RETURN;
    End If;

    -- Lookup the MyEMSL Status URI
    -- We will only get a match if this capture task job contains step tool ArchiveUpdate or DatasetArchive
    -- Furthermore, we won't get a row until after the ArchiveUpdate or DatasetArchive step successfully completes
    -- This URI will be used by the ArchiveVerify tool
    --
    SELECT StatusU.uri_path || MU.status_num::text AS myemsl_status_uri,
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

    If _myEMSLStatusURI Like '%/status/%' Then
        -- Need a URL of the form https://ingest.my.emsl.pnl.gov/myemsl/cgi-bin/status/3268638/xml
        _myEMSLStatusURI := _myEMSLStatusURI || '/xml';
    End If;

    ---------------------------------------------------
    -- Get capture task job step parameters
    ---------------------------------------------------
    --
    --
    INSERT INTO Tmp_ParamTab (Section, Name, Value)
    VALUES (_stepParmSectionName, 'Job',                  _job),
    VALUES (_stepParmSectionName, 'Step',                 _step),
    VALUES (_stepParmSectionName, 'StepTool',             _jobStepInfo.Tool),
    VALUES (_stepParmSectionName, 'ResultsDirectoryName', _jobStepInfo.Results_Folder_Name),
    VALUES (_stepParmSectionName, 'InputDirectoryName',   _jobStepInfo.Input_Folder_Name),
    VALUES (_stepParmSectionName, 'OutputDirectoryName',  _jobStepInfo.Output_Folder_Name),
    VALUES (_stepParmSectionName, 'MyEMSL_Status_URI',    _uploadInfo.myemsl_status_uri),
    VALUES (_stepParmSectionName, 'EUS_InstrumentID',     _uploadInfo.eus_instrument_id),
    VALUES (_stepParmSectionName, 'EUS_ProposalID',       _uploadInfo.eus_proposal_id),
    VALUES (_stepParmSectionName, 'EUS_UploaderID',       _uploadInfo.eus_uploader_id);

    ---------------------------------------------------
    -- Get capture task job parameters
    ---------------------------------------------------
    --
    -- To allow for more than one instance of a tool
    -- in a single script, look at parameters in sections
    -- that either are not locked to any step
    -- (step number is null) or are locked to the current step
    --
    INSERT INTO Tmp_ParamTab
    SELECT
        xmlNode.value('_section', 'text') Section,
        xmlNode.value('_name', 'text') Name,
        xmlNode.value('_value', 'text') Value
    FROM
        cap.t_task_parameters cross apply parameters.nodes('//Param') AS R(xmlNode)
    WHERE
        cap.t_task_parameters.Job = _job AND
        ((xmlNode.value('_step', 'text') IS NULL) OR (xmlNode.value('_step', 'text') = _step))

    -- Get metadata for dataset if running the Dataset Info plugin or the Dataset Quality plugin
    -- The Dataset Info tool uses the Reporter_Mz_Min value to validate datasets with reporter ions
    -- The Dataset Quality tool creates file metadata.xml
    If _stepTool In ('DatasetInfo', 'DatasetQuality') Then
        SELECT Dataset
        INTO _dataset
        FROM cap.t_tasks
        WHERE Job = _job;

        INSERT INTO Tmp_Param_Tab (Section, Name, Value)
        SELECT Section, Name, Value
        FROM cap.get_metadata_for_dataset (_dataset);

    End If;

    SELECT Section, Name, Value
    FROM Tmp_Param_Tab;

    DROP TABLE Tmp_Param_Tab;
END
$$;

COMMENT ON PROCEDURE cap.get_task_step_params IS 'GetJobStepParams';
