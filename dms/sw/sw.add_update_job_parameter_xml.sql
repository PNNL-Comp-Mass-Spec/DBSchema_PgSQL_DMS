--
-- Name: add_update_job_parameter_xml(xml, text, text, text, boolean, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.add_update_job_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean DEFAULT false, _showdebug boolean DEFAULT false) RETURNS TABLE(updated_xml xml, success boolean, message text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters, returning the updated XML
**      Alternatively, use _deleteParam => true to delete the given parameter
**      Note that case is ignored when matching section and parameter names in the XML to _section and _paramName
**
**  Arguments:
**    _xmlParameters    XML parameters (if empty XML or null, this function will create a new XML instance with the specified parameter and value)
**    _section          Section name, e.g., JobParameters
**    _paramName        Parameter name, e.g., InstClass
**    _value            Value for the parameter
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**    _showDebug        When true, show the existing parameter names and values, followed by any updated or deleted parameters
**
**  Example input XML:
**
**      <Param Section="JobParameters" Name="DatasetArchivePath" Value="\\agate.emsl.pnl.gov\dmsarch\Lumos02\2023_2" />
**      <Param Section="JobParameters" Name="DatasetFolderName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" />
**      <Param Section="JobParameters" Name="DatasetID" Value="1146056" />
**      <Param Section="JobParameters" Name="DatasetName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" />
**      <Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\Lumos02\2023_2\" />
**      <Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-HMSn" />
**      <Param Section="JobParameters" Name="Experiment" Value="QC_Mam_19_01" />
**      <Param Section="JobParameters" Name="InstClass" Value="LTQ_FT" />
**      <Param Section="JobParameters" Name="Instrument" Value="Lumos02" />
**      <Param Section="JobParameters" Name="InstrumentDataPurged" Value="0" />
**      <Param Section="JobParameters" Name="InstrumentGroup" Value="Lumos" />
**      <Param Section="JobParameters" Name="OrgDbReqd" Value="1" />
**      <Param Section="JobParameters" Name="RawDataType" Value="dot_raw_files" />
**      <Param Section="JobParameters" Name="ResultType" Value="MSG_Peptide_Hit" />
**      <Param Section="JobParameters" Name="SearchEngineInputFileFormats" Value="mzML" />
**      <Param Section="JobParameters" Name="SettingsFileName" Value="IonTrapDefSettings_MzML.xml" />
**      <Param Section="JobParameters" Name="Special_Processing" Value="" />
**      <Param Section="JobParameters" Name="ToolName" Value="MSGFPlus_MzML_NoRefine" />
**      <Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-8\DMS3_Xfer\" />
**      <Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" />
**      <Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" />
**      <Param Section="MSXMLGenerator" Name="CentroidMSXML" Value="True" />
**      <Param Section="MSXMLGenerator" Name="CentroidPeakCountToRetain" Value="-1" />
**      <Param Section="MSXMLGenerator" Name="MSXMLGenerator" Value="MSConvert.exe" />
**      <Param Section="MSXMLGenerator" Name="MSXMLOutputType" Value="mzML" />
**      <Param Section="MSXMLOptions" Name="StoreMSXmlInCache" Value="True" />
**      <Param Section="MSXMLOptions" Name="StoreMSXmlInDataset" Value="False" />
**      <Param Section="MzRefinery" Name="MzRefParamFile" Value="MzRef_NoMods.txt" />
**      <Param Section="MzRefineryRuntimeOptions" Name="MzRefMSGFPlusJavaMemorySize" Value="4000" />
**      <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="na" />
**      <Param Section="PeptideSearch" Name="OrganismName" Value="Mus_musculus" />
**      <Param Section="PeptideSearch" Name="ParamFileName" Value="MSGFPlus_Tryp_MetOx_StatCysAlk_20ppmParTol.txt" />
**      <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MSGFPlus" />
**      <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="M_musculus_UniProt_SPROT_2013_09_2013-09-18,Tryp_Pig_Bov" />
**      <Param Section="PeptideSearch" Name="ProteinOptions" Value="seq_direction=forward,filetype=fasta" />
**
**  Example usage:
**
**      -- This function can be called from a procedure, sending in the XML via a variable and storing the results in variables (or in a single record variable)
**
**      _xmlParams := '<Param Section="JobParameters" Name="DatasetFolderName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetID" Value="1146056" /><Param Section="JobParameters" Name="DatasetName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\Lumos02\2023_2\" /><Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-HMSn" /><Param Section="JobParameters" Name="Experiment" Value="QC_Mam_19_01" /><Param Section="JobParameters" Name="InstClass" Value="LTQ_FT" /><Param Section="JobParameters" Name="Instrument" Value="Lumos02" /><Param Section="JobParameters" Name="ToolName" Value="MSGFPlus_MzML_NoRefine" /><Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-8\DMS3_Xfer\" /><Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" /><Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" /><Param Section="PeptideSearch" Name="ProteinCollectionList" Value="M_musculus_UniProt_SPROT_2013_09_2013-09-18,Tryp_Pig_Bov" />'::xml;
**
**      SELECT updated_xml, success, message
**      INTO _updatedXml, _success, _message
**      FROM sw.add_update_job_parameter_xml(
**              _xmlParams,
**              'PeptideSearch',
**              'ProteinCollectionList',
**              'M_musculus_UniProt_SPROT_2013_09_2013-09-18',
**              _deleteParam => false,
**              _showDebug => true);
**
**
**      -- This function can also be called as part of a query, using a LATERAL join
**
**      -- Option 1: Use JOIN LATERAL ... ON
**      --
**      SELECT JobParams.parameters, UpdateQ.*
**      FROM sw.t_job_parameters JobParams
**           JOIN LATERAL (
**              SELECT *
**              FROM sw.add_update_job_parameter_xml(
**                  JobParams.parameters,
**                  'PeptideSearch',
**                  'ProteinCollectionList',
**                  'M_musculus_UniProt_SPROT_2013_09_2013-09-18',
**                   _deleteParam => false,       -- Optional, defaults to false
**                   _showDebug => false)         -- Optional, defaults to false
**               ) UpdateQ ON JobParams.job = 2177045;
**
**      -- Option 2: Use WHERE clause
**      --
**      SELECT JobParams.parameters, UpdateQ.*
**      FROM sw.t_job_parameters JobParams,      -- Note the comma here
**           LATERAL (
**              SELECT *
**              FROM sw.add_update_job_parameter_xml(
**                  JobParams.parameters,
**                  'PeptideSearch',
**                  'ProteinCollectionList',
**                  'M_musculus_UniProt_SPROT_2013_09_2013-09-18')
**               ) UpdateQ
**      WHERE JobParams.job = 2177045;
**
**
**      -- Alternatively, query t_job_parameters to obtain XML parameters for a given job
**
**      SELECT parameters::text
**      FROM sw.t_job_parameters
**      WHERE job = 2177045;
**
**      -- Next query this function with _showDebug => true and examine the text output
**      SELECT *
**      FROM sw.add_update_job_parameter_xml(
**          '<Param Section="JobParameters" Name="DatasetFolderName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetID" Value="1146056" /><Param Section="JobParameters" Name="DatasetName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\Lumos02\2023_2\" /><Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-HMSn" /><Param Section="JobParameters" Name="Experiment" Value="QC_Mam_19_01" /><Param Section="JobParameters" Name="InstClass" Value="LTQ_FT" /><Param Section="JobParameters" Name="Instrument" Value="Lumos02" /><Param Section="JobParameters" Name="ToolName" Value="MSGFPlus_MzML_NoRefine" /><Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-8\DMS3_Xfer\" /><Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" /><Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" /><Param Section="PeptideSearch" Name="ProteinCollectionList" Value="M_musculus_UniProt_SPROT_2013_09_2013-09-18,Tryp_Pig_Bov" />',
**          'JobParameters',
**          'SettingsFileName',
**          'IonTrapDefSettings_MzML.xml',
**          _showDebug => true);
**
**      SELECT *
**      FROM sw.add_update_job_parameter_xml(
**          '<Param Section="JobParameters" Name="DatasetFolderName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetID" Value="1146056" /><Param Section="JobParameters" Name="DatasetName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\Lumos02\2023_2\" /><Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-HMSn" /><Param Section="JobParameters" Name="Experiment" Value="QC_Mam_19_01" /><Param Section="JobParameters" Name="InstClass" Value="LTQ_FT" /><Param Section="JobParameters" Name="Instrument" Value="Lumos02" /><Param Section="JobParameters" Name="ToolName" Value="MSGFPlus_MzML_NoRefine" /><Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-8\DMS3_Xfer\" /><Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" /><Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" /><Param Section="PeptideSearch" Name="ProteinCollectionList" Value="M_musculus_UniProt_SPROT_2013_09_2013-09-18,Tryp_Pig_Bov" />',
**          'JobParameters',
**          'NewProcessingOption',
**          '5',
**          _showDebug => true);
**
**      SELECT *
**      FROM sw.add_update_job_parameter_xml(
**          '<Param Section="JobParameters" Name="DatasetFolderName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetID" Value="1146056" /><Param Section="JobParameters" Name="DatasetName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" /><Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\Lumos02\2023_2\" /><Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-HMSn" /><Param Section="JobParameters" Name="Experiment" Value="QC_Mam_19_01" /><Param Section="JobParameters" Name="InstClass" Value="LTQ_FT" /><Param Section="JobParameters" Name="Instrument" Value="Lumos02" /><Param Section="JobParameters" Name="ToolName" Value="MSGFPlus_MzML_NoRefine" /><Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-8\DMS3_Xfer\" /><Param Section="JobParameters" Name="NewProcessingOption" Value="5" /><Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" /><Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" /><Param Section="PeptideSearch" Name="ProteinCollectionList" Value="M_musculus_UniProt_SPROT_2013_09_2013-09-18,Tryp_Pig_Bov" />',
**          'JobParameters',
**          'NewProcessingOption',
**          'n/a',
**          _deleteParam => true,
**          _showDebug => true);
**
**      SELECT *, updated_xml::text
**      FROM sw.add_update_job_parameter_xml(
**          Null,
**          'JobParameters',
**          'NewProcessingOption',
**          '64',
**          _showDebug => true);
**
**  Auth:   mem
**  Date:   01/19/2012 mem - Initial Version (refactored from Add_Update_Job_Parameter)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**                         - Expand _value to varchar(4000)
**          07/19/2023 mem - Ported to PostgreSQL
**          07/28/2023 mem - Rename temporary table to avoid conflicts with calling procedures
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

    _section := Coalesce(_section, '');
    _paramName := Coalesce(_paramName, '');
    _value := Coalesce(_value, '');
    _deleteParam := Coalesce(_deleteParam, false);
    _showDebug := Coalesce(_showDebug, false);

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

    CREATE TEMP TABLE Tmp_Job_Params_Updated (
        Section citext,
        Name citext,
        Value text,
        State text not null
    );

    ---------------------------------------------------
    -- Surround the job parameter XML with <params></params> so that the XML will be rooted, as required by XMLTABLE()
    ---------------------------------------------------

    INSERT INTO Tmp_Job_Params_Updated (Section, Name, Value, State)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value, 'Unchanged'
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _xmlParameters || '</params>')::xml As rooted_xml
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
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
            SELECT 'Initial Value' As State, Section, Name, Value
            FROM Tmp_Job_Params_Updated
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

        UPDATE Tmp_Job_Params_Updated
        SET Value = _value,
            State = Case When Value Is Distinct From _value Then 'Updated Value' Else 'Unchanged Value' End
        WHERE Section = _section::citext AND
              Name = _paramName::citext;

        If Not FOUND Then
            -- Match not found; Insert a new parameter
            INSERT INTO Tmp_Job_Params_Updated(Section, Name, Value, State)
            VALUES (_section, _paramName, _value, 'Added');
        End If;

    Else
        ---------------------------------------------------
        -- Delete the specified parameter
        ---------------------------------------------------

        UPDATE Tmp_Job_Params_Updated
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
            FROM Tmp_Job_Params_Updated
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
    -- Convert the parameters in table Tmp_Job_Params_Updated into XML
    ---------------------------------------------------

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
           FROM Tmp_Job_Params_Updated
           WHERE State <> _deletedFlag
        ) AS LookupQ;

    DROP TABLE Tmp_Job_Params_Updated;
END
$$;


ALTER FUNCTION sw.add_update_job_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean, _showdebug boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_update_job_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean, _showdebug boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.add_update_job_parameter_xml(_xmlparameters xml, _section text, _paramname text, _value text, _deleteparam boolean, _showdebug boolean) IS 'AddUpdateJobParameterXML';

