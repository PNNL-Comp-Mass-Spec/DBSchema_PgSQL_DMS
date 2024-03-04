--
-- Name: get_task_params(integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_params(_job integer) RETURNS TABLE(section public.citext, name public.citext, value public.citext, step public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table with capture task job parameters for given job
**      Data comes from either cap.t_task_parameters or cap.t_task_parameters_history
**
**      This function is superseded by cap.get_task_param_table_local
**
**  Auth:   mem
**  Date:   06/13/2023 mem - Initial version (based on get_task_step_params)
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _xmlParameters xml;
    _uploadInfo record;
    _stepParamSectionName text := 'StepParameters';
BEGIN

    SELECT parameters
    INTO _xmlParameters
    FROM cap.t_task_parameters WHERE job = _job;

    If Not FOUND Then
        SELECT parameters
        INTO _xmlParameters
        FROM cap.t_task_parameters_history WHERE job = _job;

        If Not FOUND Then
            RAISE WARNING 'Capture task job % not found in cap.t_task_parameters or cap.t_task_parameters_history', _job;
            RETURN;
        End If;
    End If;

    CREATE TEMP TABLE Tmp_Param_Tab (
        Section citext,
        Name citext,
        Value citext,
        Step citext       -- Job parameters can optionally apply to a give step, but that is not actually used, so Step will always be null
    );

    ---------------------------------------------------
    -- Lookup the MyEMSL Status URI
    -- We will only get a match if this capture task job contains step tool ArchiveUpdate or DatasetArchive
    -- Furthermore, we won't get a row until after the ArchiveUpdate or DatasetArchive step successfully completes
    -- This URI is used by the ArchiveVerify tool
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
           (_stepParamSectionName, 'MyEMSL_Status_URI',    _uploadInfo.myemsl_status_uri),
           (_stepParamSectionName, 'EUS_InstrumentID',     _uploadInfo.eus_instrument_id),
           (_stepParamSectionName, 'EUS_ProposalID',       _uploadInfo.eus_proposal_id),
           (_stepParamSectionName, 'EUS_UploaderID',       _uploadInfo.eus_uploader_id);

    ---------------------------------------------------
    -- Get capture task job parameters
    ---------------------------------------------------

    INSERT INTO Tmp_Param_Tab (Section, Name, Value, Step)
    SELECT Trim(XmlQ.section),
           Trim(XmlQ.name),
           Trim(XmlQ.value),
           Trim(XmlQ.step)
    FROM (
            SELECT xmltable.section,
                   xmltable.name,
                   xmltable.value,
                   xmltable.step
            FROM ( SELECT ('<params>' || _xmlParameters::text || '</params>')::xml As rooted_xml ) Src,
                       XMLTABLE('//params/Param'
                          PASSING Src.rooted_xml
                          COLUMNS section text PATH '@Section',
                                  name    text PATH '@Name',
                                  value   text PATH '@Value',
                                  step    text PATH '@Step')
         ) XmlQ;

    RETURN QUERY
    SELECT Src.Section, Src.Name, Src.Value, Src.Step
    FROM Tmp_Param_Tab Src;

    DROP TABLE Tmp_Param_Tab;
END
$$;


ALTER FUNCTION cap.get_task_params(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_params(_job integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_params(_job integer) IS 'GetTaskParams';

