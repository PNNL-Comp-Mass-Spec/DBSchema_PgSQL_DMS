--
-- Name: add_update_scripts(text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_update_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _backfilltodms text, IN _contents text, IN _parameters text, IN _fields text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing scripts in sw.t_scripts
**
**  Arguments:
**    _script               Script name
**    _description          Script description
**    _enabled              Enabled: 'Y' or 'N'
**    _resultsTag           Results tag
**    _backfillToDMS        Backfill to DMS: 'Y' or 'N'; this should be 'Y' for scripts that have their jobs directly created in sw.t_jobs
**    _contents             Script step information (XML as text)
**    _parameters           Script parameters (XML as text); only defined for scripts that have _backfillToDMS = 1
**    _fields               Fields for wizard (XML as text); this column is obsolete, but still editable (see script MAC_TMT10Plex)
**    _mode                 Mode: 'add' or 'update'
**
**  Example XML for _contents (for the MaxQuant_DataPkg script):
**      <JobScript Name="MaxQuant">
**        <Step Number="1" Tool="MSXML_Gen" />
**        <Step Number="2" Tool="MaxqPeak">
**          <Depends_On Step_Number="1" />
**        </Step>
**        <Step Number="3" Tool="MaxqS1">
**          <Depends_On Step_Number="2" />
**        </Step>
**        <Step Number="4" Tool="MaxqS2">
**          <Depends_On Step_Number="3" />
**        </Step>
**        <Step Number="5" Tool="MaxqS3">
**          <Depends_On Step_Number="4" />
**        </Step>
**        <Step Number="6" Tool="Results_Cleanup">
**          <Depends_On Step_Number="5" />
**        </Step>
**        <Step Number="7" Tool="DataExtractor">
**          <Depends_On Step_Number="6" />
**        </Step>
**        <Step Number="8" Tool="IDPicker">
**          <Depends_On Step_Number="7" />
**        </Step>
**        <Step Number="9" Tool="Results_Transfer">
**          <Depends_On Step_Number="1" Test="Target_Skipped" />
**          <Depends_On Step_Number="8" Enable_Only="1" />
**        </Step>
**        <Step Number="10" Tool="Results_Transfer">
**          <Depends_On Step_Number="8" />
**        </Step>
**      </JobScript>
**
**  Example XML for _parameters (for the MaxQuant_DataPkg script):
**      <Param Section="JobParameters" Name="CreateMzMLFiles" Value="False" Reqd="Yes" User="Yes" />
**      <Param Section="JobParameters" Name="DatasetName" Value="Aggregation" Reqd="Yes" />
**      <Param Section="JobParameters" Name="CacheFolderRootPath" Value="\\proto-9\MaxQuant_Staging" Reqd="Yes" />
**      <Param Section="MSXMLGenerator" Name="MSXMLGenerator" Value="MSConvert.exe" Reqd="Yes" />
**      <Param Section="MSXMLGenerator" Name="MSXMLOutputType" Value="mzML" Reqd="Yes" />
**      <Param Section="MSXMLGenerator" Name="CentroidMSXML" Value="True" Reqd="Yes" />
**      <Param Section="MSXMLGenerator" Name="CentroidPeakCountToRetain" Value="-1" Reqd="Yes" />
**      <Param Section="PeptideSearch" Name="ParamFileName" Value="MaxQuant_Tryp_Dyn_MetOx_NTermAcet_20ppmParTol.xml" Reqd="Yes" User="Yes" />
**      <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MaxQuant" Reqd="Yes" />
**      <Param Section="PeptideSearch" Name="OrganismName" Value="Homo_sapiens" Reqd="Yes" User="Yes" />
**      <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="" Reqd="Yes" User="Yes" />
**      <Param Section="PeptideSearch" Name="ProteinOptions" Value="seq_direction=forward,filetype=fasta" Reqd="Yes" />
**      <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="na" Reqd="Yes" />
**
**  Auth:   grk
**  Date:   09/23/2008 grk - Initial Veresion
**          03/24/2009 mem - Now calling Alter_Entered_By_User when _callingUser is defined
**          10/06/2010 grk - Added _parameters field
**          12/01/2011 mem - Expanded _description to varchar(2000)
**          01/09/2012 mem - Added parameter _backfillToDMS
                           - Changed ID field in T_Scripts to a non-identity based int
**          08/13/2013 mem - Added _fields field  (used by MAC Job Wizard on DMS website)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/28/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _contentsXML xml;
    _parametersXML xml;
    _fieldsXML xml;

    _existingRowCount int := 0;
    _id int;
    _backFill int;
    _scriptIDNew int := 1;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _description :=   Trim(Coalesce(_description, ''));
    _enabled :=       Trim(Upper(Coalesce(_enabled, 'Y')));
    _backfillToDMS := Trim(Upper(Coalesce(_backfillToDMS, 'Y')));
    _mode :=          Trim(Lower(Coalesce(_mode, '')));
    _callingUser :=   Coalesce(_callingUser, '');

    If _backfillToDMS = 'Y' Then
        _backFill := 1;
    ElsIf _backfillToDMS = 'N' Then
        _backFill := 0;
    Else
        _message := 'BackfillToDMS must be be "Y" or "N"';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _description = '' Then
        _message := 'Description cannot be blank';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If Not _mode::citext In ('add', 'update') Then
        _message := format('Unknown Mode: %s', _mode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If Trim(Coalesce(_contents, '')) = '' Then
        _message := 'Script contents cannot be an empty string; must be valid XML';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    Else
        _contentsXML := public.try_cast(_contents, null::xml);

        If _contentsXML Is Null Then
            _message := format('Script contents is not valid XML: ', _contents);
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;
    End If;

    If Trim(Coalesce(_parameters, '')) <> '' Then
        _parametersXML := public.try_cast(_parameters, null::xml);

        If _parametersXML Is Null Then
            _message := format('Script parameters is not valid XML: ', _parameters);
            RAISE WARNING '%', _message;

            _returnCode := 'U5206';
            RETURN;
        End If;

    Else
        _parametersXML := null;
    End If;

    If Trim(Coalesce(_fields, '')) <> '' Then
        _fieldsXML := public.try_cast(_fields, null::xml);

        If _fieldsXML Is Null Then
            _message := format('Script fields is not valid XML: ', _fields);
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

    Else
        _fieldsXML := null;
    End If;



    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT COUNT(script_id)
    INTO _existingRowCount
    FROM sw.t_scripts
    WHERE script = _script::citext;

    -- Cannot update a non-existent entry
    --
    If _mode = 'update' And _existingRowCount = 0 Then
        _message := format('Could not find "%s" in database', _script);
        RAISE WARNING '%', _message;

        _returnCode := 'U5208';
        RETURN;
    End If;

    -- Cannot add an existing entry
    --
    If _mode = 'add' And _existingRowCount > 0 Then
        _message := format('Script "%s" already exists in database', _script);
        RAISE WARNING '%', _message;

        _returnCode := 'U5209';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        SELECT Coalesce(MAX(script_id), 0) + 1
        INTO _scriptIDNew
        FROM sw.t_scripts;

        INSERT INTO sw.t_scripts (
            script_id,
            script,
            description,
            enabled,
            results_tag,
            backfill_to_dms,
            contents,
            parameters,
            fields
        ) VALUES (
            _scriptIDNew,
            _script,
            _description,
            _enabled,
            _resultsTag,
            _backFill,
            _contentsXML,
            _parametersXML,
            _fieldsXML
        )
        RETURNING script_id
        INTO _id;

        -- If _callingUser is defined, update entered_by in sw.t_scripts_history
        If char_length(_callingUser) > 0 And Not _id Is Null Then
            CALL public.alter_entered_by_user ('sw', 't_scripts_history', 'script_id', _id, _callingUser, _message => _alterEnteredByMessage);
        End If;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE sw.t_scripts
        SET
          description = _description,
          enabled = _enabled,
          results_tag = _resultsTag,
          backfill_to_dms = _backFill,
          contents = _contentsXML,
          parameters = _parametersXML,
          fields = _fieldsXML
        WHERE script = _script;

        -- If _callingUser is defined, update entered_by in sw.t_scripts_history
        If char_length(_callingUser) > 0 Then

            SELECT script_id
            INTO _id
            FROM sw.t_scripts
            WHERE script = _script;

            If FOUND And Not _id Is Null Then
                CALL public.alter_entered_by_user ('sw', 't_scripts_history', 'script_id', _id, _callingUser, _message => _alterEnteredByMessage);
            End If;
        End If;

    End If;

END
$$;


ALTER PROCEDURE sw.add_update_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _backfilltodms text, IN _contents text, IN _parameters text, IN _fields text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _backfilltodms text, IN _contents text, IN _parameters text, IN _fields text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_update_scripts(IN _script text, IN _description text, IN _enabled text, IN _resultstag text, IN _backfilltodms text, IN _contents text, IN _parameters text, IN _fields text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateScripts';

