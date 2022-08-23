--
-- Name: add_update_task_parameter_xml(xml, text, text, text, integer, integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam integer DEFAULT 0, _showdebug integer DEFAULT 0) RETURNS TABLE(updated_xml xml, success boolean, message text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters, returning the updated XML
**      Alternatively, use _deleteParam=1 to delete the given parameter
**      Note that case is ignored when matching section and parameter names in the XML to _section and _paramName
**
**  Arguments:
**    _xmlParameters    XML parameters
**    _section          Section name, e.g.   JobParameters
**    _paramName        Parameter name, e.g. SourceJob
**    _value            Value for parameter _paramName in section _section
**    _deleteParam      When 0, adds/updates the given parameter; when 1, deletes the parameter
**
**  Example input XML:
**
**      <Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" />
**      <Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" />
**      <Param Section="DatasetQC" Name="SaveLCMS2DPlots" Value="True" />
**      <Param Section="JobParameters" Name="Capture_Subdirectory" Value="" />
**      <Param Section="JobParameters" Name="Created" Value="Jul 23 2022  1:42PM" />
**      <Param Section="JobParameters" Name="Dataset" Value="QC_Mam_19_01-run04_19July22_Remus_WBEH-22-05-07" />
**      <Param Section="JobParameters" Name="Dataset_ID" Value="1060934" />
**      <Param Section="JobParameters" Name="Dataset_Type" Value="HMS-HCD-HMSn" />
**      <Param Section="JobParameters" Name="Instrument_Class" Value="LTQ_FT" />
**      <Param Section="JobParameters" Name="Instrument_Name" Value="QEHFX03" />
**
**  Example usage:
**
**      -- This function can be called from a procedure, sending in the XML via a variable and storing the results in variables (or in a single record variable)
**
**      _xmlParams := '<Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" /><Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" /><Param Section="DatasetQC" Name="SaveLCMS2DPlots" Value="True" /><Param Section="JobParameters" Name="Dataset" Value="QC_Mam_19_01-run04_19July22_Remus_WBEH-22-05-07" /><Param Section="JobParameters" Name="Dataset_ID" Value="1060934" />'::xml;
**
**      SELECT updated_xml, success, message
**      INTO _updatedXml, _success, _message
**      FROM cap.add_update_task_parameter_xml(
**              _xmlParams,
**              'DatasetQC',
**              'ComputeOverallQualityScores',
**              'false',
**              _deleteParam => 0,
**              _showDebug => 1);
**
**
**      -- This function can also be called as part of a query, using a LATERAL join
**
**      -- Option 1: Use JOIN LATERAL ... ON
**      --
**      SELECT TaskParams.parameters, UpdateQ.*
**      FROM cap.t_task_parameters TaskParams
**           JOIN LATERAL (
**              SELECT *
**              FROM cap.add_update_task_parameter_xml(
**                  TaskParams.parameters,
**                  'DatasetQC',
**                  'CreateDatasetInfoFile',
**                  'false',
**                   0)
**               ) UpdateQ ON TaskParams.job = 5493941;
**
**      -- Option 2: Use WHERE clause
**      SELECT TaskParams.parameters, UpdateQ.*
**      FROM cap.t_task_parameters TaskParams,      -- Note the comma here
**           LATERAL (
**              SELECT *
**              FROM cap.add_update_task_parameter_xml(
**                  TaskParams.parameters,
**                  'DatasetQC',
**                  'CreateDatasetInfoFile',
**                  'false',
**                   0)
**               ) UpdateQ
**      WHERE TaskParams.job = 5493941;
**
**  Auth:   mem
**  Date:   09/24/2012 mem - Ported from DMS_Pipeline DB
**          08/21/2022 mem - Ported to PostgreSQL
**          08/22/2022 mem - Use case insensitive matching for section and parameter names
**
*****************************************************/
DECLARE
    _message text;
    _formatSpecifier text := '%-15s %-20s %-35s %-25s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;
    _deletedFlag text := 'Deleted Value';
BEGIN
    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _deleteParam := Coalesce(_deleteParam, 0);
    _showDebug := Coalesce(_showDebug, 0);

    _message := '';

    If _xmlParameters Is Null Then
        _message := 'Null value sent to _xmlParameters';

        RETURN QUERY
        SELECT null::xml, false, _message;

        Return;
    End If;

    ---------------------------------------------------
    -- Parse the XML and store in a table
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_TaskParameters (
        Section citext,
        Name citext,
        Value text,
        State text not null
    );

    ---------------------------------------------------
    -- We must surround the task parameter XML with <params></params> so that the XML will be rooted, as required by XMLTABLE()
    ---------------------------------------------------

    INSERT INTO Tmp_TaskParameters (Section, Name, Value, State)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value, 'Unchanged'
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _xmlParameters || '</params>')::xml as rooted_xml
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

    If _showDebug <> 0 Then
        RAISE INFO ' ';

        _infoHead := format(_formatSpecifier,
                            'State',
                            'Section',
                            'Name',
                            'Value'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                            '-----',
                            '-------',
                            '----',
                            '-----'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Initial Value' As State, Section, Name, Value
            FROM Tmp_TaskParameters
            ORDER BY Section, Name
        LOOP
            _infoData := format(_formatSpecifier,
                                    _previewData.State,
                                    _previewData.Section,
                                    _previewData.Name,
                                    _previewData.Value
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

    End If;

    If _deleteParam = 0 Then
        ---------------------------------------------------
        -- Add/update the specified parameter
        -- First try an update
        ---------------------------------------------------
        --
        UPDATE Tmp_TaskParameters
        SET Value = _value, State = 'Updated Value'
        WHERE Section = _section::citext AND
              Name = _paramName::citext;

        If Not FOUND Then
            -- Match not found; Insert a new parameter
            INSERT INTO Tmp_TaskParameters(Section, Name, Value, State)
            VALUES (_section, _paramName, _value, 'Added');

        End If;
    Else
        ---------------------------------------------------
        -- Delete the specified parameter
        ---------------------------------------------------
        --
        UPDATE Tmp_TaskParameters
        SET State = _deletedFlag
        WHERE Section = _section::citext AND
              Name    = _paramName::citext;

    End If;

    If _showDebug <> 0 Then

        RAISE INFO ' ';

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT State, Section, Name, Value
            FROM Tmp_TaskParameters
            WHERE State <> 'Unchanged'
            ORDER BY Section, Name
        LOOP

            _infoData := format(_formatSpecifier,
                                    _previewData.State,
                                    _previewData.Section,
                                    _previewData.Name,
                                    _previewData.Value
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

    End If;

    RETURN QUERY
    SELECT xml_item, true as Success, '' As message
    FROM ( SELECT
             XMLAGG(XMLELEMENT(
                    NAME "Param",
                    XMLATTRIBUTES(
                        section As "Section",
                        name As "Name",
                        value As "Value"))
                    ORDER BY section, name
                   ) AS xml_item
           FROM Tmp_TaskParameters
           WHERE State <> _deletedFlag
        ) AS LookupQ;

    DROP TABLE Tmp_TaskParameters;
END
$$;


ALTER FUNCTION cap.add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam integer, _showdebug integer) OWNER TO d3l243;

--
-- Name: FUNCTION add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam integer, _showdebug integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam integer, _showdebug integer) IS 'AddUpdateJobParameterXML';

