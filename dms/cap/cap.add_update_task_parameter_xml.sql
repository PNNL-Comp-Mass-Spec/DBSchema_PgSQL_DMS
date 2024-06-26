--
-- Name: add_update_task_parameter_xml(xml, text, text, text, boolean, boolean); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean DEFAULT false, _showdebug boolean DEFAULT false) RETURNS TABLE(updated_xml xml, success boolean, message text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add or update an entry in the XML parameters, returning the updated XML
**      Alternatively, use _deleteParam => true to delete the given parameter
**      Note that case is ignored when matching section and parameter names in the XML to _section and _paramName
**
**  Arguments:
**    _xmlParameters    XML parameters (if empty XML or null, this function will create a new XML instance with the specified parameter and value)
**    _section          Section name, e.g., JobParameters
**    _paramName        Parameter name, e.g., Instrument_Class
**    _value            Value for the parameter
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**    _showDebug        When true, show the existing parameter names and values, followed by any updated or deleted parameters
**
**  Example input XML:
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
**              _deleteParam => false,
**              _showDebug   => true);
**
**
**      -- This function can also be called as part of a query, using a LATERAL join
**
**      -- Option 1: Use JOIN LATERAL ... ON
**      --
**      SELECT TaskParams.parameters::text,
**             UpdateQ.updated_xml::text,
**             UpdateQ.success,
**             UpdateQ.message
**      FROM cap.t_task_parameters TaskParams
**           JOIN LATERAL (
**              SELECT *
**              FROM cap.add_update_task_parameter_xml(
**                  TaskParams.parameters,
**                  'DatasetQC',
**                  'CreateDatasetInfoFile',
**                  'false',
**                   _deleteParam => false,     -- Optional, defaults to false
**                   _showDebug   => true)      -- Optional, defaults to false
**               ) UpdateQ ON TaskParams.job = 6016844;
**
**      -- Option 2: Use WHERE clause
**      --
**      SELECT TaskParams.parameters::text,
**             UpdateQ.updated_xml::text,
**             UpdateQ.success,
**             UpdateQ.message
**      FROM cap.t_task_parameters TaskParams,      -- Note the comma here
**           LATERAL (
**              SELECT *
**              FROM cap.add_update_task_parameter_xml(
**                  TaskParams.parameters,
**                  'DatasetQC',
**                  'CreateDatasetInfoFile',
**                  'false')
**               ) UpdateQ
**      WHERE TaskParams.job = 6016844;
**
**
**      -- Alternatively, query t_task_parameters to obtain XML parameters for a given capture task job
**
**      SELECT parameters::text
**      FROM cap.t_task_parameters_history
**      WHERE job = 5493935;
**
**      -- Next query this function with _showDebug => true and examine the text output
**      SELECT *
**      FROM cap.add_update_task_parameter_xml(
**          '<Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" /><Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" /><Param Section="DatasetQC" Name="LCMS2DOverviewPlotDivisor" Value="10" /><Param Section="JobParameters" Name="Dataset" Value="AgilentQQQ_Blank_Pos_MRM_04_20220725" /><Param Section="JobParameters" Name="Dataset_ID" Value="1062716" /><Param Section="JobParameters" Name="Dataset_Type" Value="MRM" /><Param Section="JobParameters" Name="RawDataType" Value="dot_d_folders" /><Param Section="JobParameters" Name="Source_Path" Value="ProteomicsData\" /><Param Section="JobParameters" Name="Source_Vol" Value="\\Agilent_QQQ_04.bionet\" />',
**          'DatasetQC',
**          'CreateDatasetInfoFile',
**          'False',
**          _showDebug => true);
**
**      SELECT *
**      FROM cap.add_update_task_parameter_xml(
**          '<Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" /><Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" /><Param Section="DatasetQC" Name="LCMS2DOverviewPlotDivisor" Value="10" /><Param Section="JobParameters" Name="Dataset" Value="AgilentQQQ_Blank_Pos_MRM_04_20220725" /><Param Section="JobParameters" Name="Dataset_ID" Value="1062716" /><Param Section="JobParameters" Name="Dataset_Type" Value="MRM" /><Param Section="JobParameters" Name="RawDataType" Value="dot_d_folders" /><Param Section="JobParameters" Name="Source_Path" Value="ProteomicsData\" /><Param Section="JobParameters" Name="Source_Vol" Value="\\Agilent_QQQ_04.bionet\" />',
**          'DatasetQC',
**          'NewProcessingOption',
**          '5',
**          _showDebug => true);
**
**      SELECT *
**      FROM cap.add_update_task_parameter_xml(
**          '<Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" /><Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" /><Param Section="DatasetQC" Name="LCMS2DOverviewPlotDivisor" Value="10" /><Param Section="DatasetQC" Name="NewProcessingOption" Value="5" /><Param Section="JobParameters" Name="Dataset" Value="AgilentQQQ_Blank_Pos_MRM_04_20220725" /><Param Section="JobParameters" Name="Dataset_ID" Value="1062716" /><Param Section="JobParameters" Name="Dataset_Type" Value="MRM" /><Param Section="JobParameters" Name="RawDataType" Value="dot_d_folders" /><Param Section="JobParameters" Name="Source_Path" Value="ProteomicsData\" /><Param Section="JobParameters" Name="Source_Vol" Value="\\Agilent_QQQ_04.bionet\" />',
**          'DatasetQC',
**          'NewProcessingOption',
**          'n/a',
**          _deleteParam => true,
**          _showDebug   => true);
**
**      SELECT *, updated_xml::text
**      FROM cap.add_update_task_parameter_xml(
**          Null,
**          'DatasetQC',
**          'NewProcessingOption',
**          '64',
**          _showDebug => true);
**
**  Auth:   mem
**  Date:   09/24/2012 mem - Ported from DMS_Pipeline DB
**          08/21/2022 mem - Ported to PostgreSQL
**          08/22/2022 mem - Use case insensitive matching for section and parameter names
**                         - If the _xmlParameters argument is empty or null, return a new XML instance with the specified parameter and value
**          08/23/2022 mem - Raise an exception if the section name or parameter name is null or empty
**                         - Assure that _value is not null
**                         - Report the state as 'Unchanged Value' if the old and new values for the parameter are equivalent
**          08/27/2022 mem - Change arguments _deleteParam and _showDebug from int to boolean
**          09/28/2022 mem - Rename temporary table
**          07/19/2023 mem - Synchronize with sw.add_update_job_parameter_xml
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
    _deletedFlag text := 'Deleted Value';
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _section     := Trim(Coalesce(_section, ''));
    _paramName   := Trim(Coalesce(_paramName, ''));
    _value       := Coalesce(_value, '');
    _deleteParam := Coalesce(_deleteParam, false);
    _showDebug   := Coalesce(_showDebug, false);

    If _xmlParameters Is Null Then
        RAISE INFO 'Null value sent to _xmlParameters; initializing a new XML instance';

        _xmlParameters = ''::xml;
    End If;

    If char_length(Trim(_section)) = 0 Then
        RAISE EXCEPTION 'Section name cannot be null or empty';
    End If;

    If char_length(Trim(_paramName)) = 0 Then
        RAISE EXCEPTION 'Parameter name cannot be null or empty';
    End If;

    ---------------------------------------------------
    -- Parse the XML and store in a table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Task_Parameters (
        Section citext,
        Name citext,
        Value text,
        State text NOT NULL
    );

    ---------------------------------------------------
    -- Surround the task parameter XML with <params></params> so that the XML will be rooted, as required by XMLTABLE()
    ---------------------------------------------------

    INSERT INTO Tmp_Task_Parameters (Section, Name, Value, State)
    SELECT Trim(XmlQ.section), Trim(XmlQ.name), Trim(XmlQ.value), 'Unchanged'
    FROM (
        SELECT xmltable.*
        FROM (SELECT ('<params>' || _xmlParameters || '</params>')::xml AS rooted_xml
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section text PATH '@Section',
                              name    text PATH '@Name',
                              value   text PATH '@Value')
         ) XmlQ;

    If _showDebug Then

        RAISE INFO '';

        _formatSpecifier := '%-15s %-20s %-35s %-60s';

        _infoHead := format(_formatSpecifier,
                            'State',
                            'Section',
                            'Name',
                            'Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------------',
                                     '--------------------',
                                     '-----------------------------------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Initial Value' AS State, Section, Name, Value
            FROM Tmp_Task_Parameters
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

    If Not _deleteParam Then
        ---------------------------------------------------
        -- Add/update the specified parameter
        -- First try an update
        ---------------------------------------------------

        UPDATE Tmp_Task_Parameters
        SET Value = _value,
            State = CASE WHEN Value IS DISTINCT FROM _value THEN 'Updated Value' ELSE 'Unchanged Value' END
        WHERE Section = _section::citext AND
              Name = _paramName::citext;

        If Not FOUND Then
            -- Match not found; Insert a new parameter
            INSERT INTO Tmp_Task_Parameters (Section, Name, Value, State)
            VALUES (_section, _paramName, _value, 'Added');
        End If;

    Else
        ---------------------------------------------------
        -- Delete the specified parameter
        ---------------------------------------------------

        UPDATE Tmp_Task_Parameters
        SET State = _deletedFlag
        WHERE Section = _section::citext AND
              Name    = _paramName::citext;

    End If;

    If _showDebug Then

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT State, Section, Name, Value
            FROM Tmp_Task_Parameters
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

    ---------------------------------------------------
    -- Convert the parameters in table Tmp_Task_Parameters into XML
    ---------------------------------------------------

    RETURN QUERY
    SELECT xml_item, true AS Success, '' AS message
    FROM (SELECT
            XMLAGG(XMLELEMENT(
                   NAME "Param",
                   XMLATTRIBUTES(
                       section AS "Section",
                       name AS "Name",
                       value AS "Value"))
                   ORDER BY section, name
                  ) AS xml_item
          FROM Tmp_Task_Parameters
          WHERE State <> _deletedFlag
        ) AS LookupQ;

    DROP TABLE Tmp_Task_Parameters;
END
$$;


ALTER FUNCTION cap.add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean, _showdebug boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean, _showdebug boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.add_update_task_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean, _showdebug boolean) IS 'AddUpdateTaskParameterXML or AddUpdateJobParameterXML';

