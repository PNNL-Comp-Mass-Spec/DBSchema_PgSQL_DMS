--
-- Name: add_update_settings_file(integer, text, text, text, integer, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_settings_file(INOUT _settingsfileid integer, IN _analysistool text, IN _filename text, IN _description text, IN _active integer, IN _contents text, IN _hmsautosupersede text DEFAULT ''::text, IN _msgfplusautocentroid text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing entity in T_Settings_Files
**
**  Arguments:
**    _settingsFileID           Settings file ID to edit, or the ID of the newly created settings file
**    _analysisTool             Analysis tool name
**    _fileName                 Settings file name
**    _description              Settings file description
**    _active                   1 if active, 0 if inactive
**    _contents                 Settings file contents (XML as text)
**    _hmsAutoSupersede         Settings file name to use instead of this settings file if the dataset comes from a high res MS instrument
**    _msgfPlusAutoCentroid     Settings file name to use instead of this settings file if MSGF+ reports that not enough spectra are centroided; see SP AutoResetFailedJobs
**    _mode                     Mode: 'add' or 'update'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
**
**  Auth:   grk
**  Date:   08/22/2008
**          03/30/2015 mem - Added parameters _hmsAutoSupersede and _msgfPlusAutoCentroid
**          03/21/2016 mem - Update column Last_Updated
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/10/2018 mem - Rename parameters and make _settingsFileID an output parameter
**          04/11/2022 mem - Check for existing settings file (by name) when _mode is 'add'
**                         - Check for whitespace in _fileName
**          08/23/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _xmlContents xml;
    _analysisToolForAutoSupersede citext := '';
    _analysisToolForAutoCentroid citext := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _analysisTool         := Trim(Coalesce(_analysisTool, ''));
    _fileName             := Trim(Coalesce(_fileName, ''));
    _hmsAutoSupersede     := Trim(Coalesce(_hmsAutoSupersede, ''));
    _msgfPlusAutoCentroid := Trim(Coalesce(_msgfPlusAutoCentroid, ''));
    _contents             := Trim(Coalesce(_contents, ''));

    If _analysisTool = '' Then
        _message := 'Analysis Tool cannot be empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _fileName = '' Then
        _message := 'Filename cannot be empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _contents = '' Then
        _message := 'Settings file contents cannot be empty';
         RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    _xmlContents := public.try_cast(_contents, null::xml);

    If _xmlContents Is Null Then
        _message := 'Settings file contents are not valid XML';
         RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    If public.has_whitespace_chars(_fileName, _allowspace => false) Then
        If Position(chr(9) In _fileName) > 0 Then
            RAISE EXCEPTION 'Settings file name cannot contain tabs';
        Else
            RAISE EXCEPTION 'Settings file name cannot contain spaces';
        End If;
    End If;

    If _hmsAutoSupersede <> '' Then
        If _hmsAutoSupersede::citext = _fileName::citext Then
            _message := 'The HMS_AutoSupersede file cannot have the same name as this settings file';
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;

        If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _hmsAutoSupersede::citext) Then
            _message := format('hms_auto_supersede settings file does not exist: %s', _hmsAutoSupersede);
            RAISE WARNING '%', _message;

            _returnCode := 'U5206';
            RETURN;
        End If;

        SELECT analysis_tool
        INTO _analysisToolForAutoSupersede
        FROM t_settings_files
        WHERE file_name = _hmsAutoSupersede::citext;

        If _analysisToolForAutoSupersede <> _analysisTool::citext Then
            _message := format('The Analysis Tool for the HMS_AutoSupersede file ("%s") must match the analysis tool for this settings file: %s vs. %s',
                               _hmsAutoSupersede, _analysisToolForAutoSupersede, _analysisTool);
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

    Else
        _hmsAutoSupersede := null;
    End If;

    If _msgfPlusAutoCentroid <> '' Then
        If _msgfPlusAutoCentroid::citext = _fileName::citext Then
            _message := 'The MSGFPlus_AutoCentroid file cannot have the same name as this settings file';
            RAISE WARNING '%', _message;

            _returnCode := 'U5208';
            RETURN;
        End If;

        If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _msgfPlusAutoCentroid::citext) Then
            _message := format('MSGFPlus AutoCentroid settings file does not exist: %s', _msgfPlusAutoCentroid);
            RAISE WARNING '%', _message;

            _returnCode := 'U5209';
            RETURN;
        End If;

        SELECT analysis_tool
        INTO _analysisToolForAutoCentroid
        FROM t_settings_files
        WHERE file_name = _msgfPlusAutoCentroid::citext;

        If _analysisToolForAutoCentroid <> _analysisTool::citext Then
            _message := format('The Analysis Tool for the MSGFPlus_AutoCentroid file ("%s") must match the analysis tool for this settings file: %s vs. %s',
                               _msgfPlusAutoCentroid, _analysisToolForAutoCentroid, _analysisTool);
            RAISE WARNING '%', _message;

            _returnCode := 'U5210';
            RETURN;
        End If;

    Else
        _msgfPlusAutoCentroid := null;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _mode = 'add' Then
        ---------------------------------------------------
        -- Check for an existing settings file
        ---------------------------------------------------

        SELECT settings_file_id
        INTO _settingsFileID
        FROM t_settings_files
        WHERE file_name = _fileName::citext;

        If FOUND Then
            _message := format('Settings file ID %s is named "%s"; cannot create a new, duplicate settings file',
                               _settingsFileID, _fileName);

            RAISE WARNING '%', _message;

            _returnCode := 'U5211';
            RETURN;
        End If;
    End If;

    If _mode = 'update' Then
        ---------------------------------------------------
        -- Assure that the settings file exists
        ---------------------------------------------------

        If _settingsFileID Is Null Then
            _message := 'Settings file ID is null; cannot update';
            RAISE EXCEPTION '%', _message;
        End If;

        -- Cannot update a non-existent entry

        If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE settings_file_id = _settingsFileID) Then
            _message := format('Cannot update: settings file ID %s does not exist', _settingsFileID);
            RAISE WARNING '%', _message;

            _returnCode := 'U5212';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_settings_files (
            analysis_tool,
            file_name,
            description,
            active,
            contents,
            hms_auto_supersede,
            msgfplus_auto_centroid
        ) VALUES (
            _analysisTool,
            _fileName,
            _description,
            _active,
            _xmlContents,
            _hmsAutoSupersede,
            _msgfPlusAutoCentroid
        )
        RETURNING settings_file_id
        INTO _settingsFileID;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_settings_files
        SET analysis_tool          = _analysisTool,
            file_name              = _fileName,
            description            = _description,
            active                 = _active,
            contents               = _xmlContents,
            hms_auto_supersede     = _hmsAutoSupersede,
            msgfplus_auto_centroid = _msgfPlusAutoCentroid,
            last_updated           = CURRENT_TIMESTAMP
        WHERE settings_file_id = _settingsFileID;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_settings_file(INOUT _settingsfileid integer, IN _analysistool text, IN _filename text, IN _description text, IN _active integer, IN _contents text, IN _hmsautosupersede text, IN _msgfplusautocentroid text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_settings_file(INOUT _settingsfileid integer, IN _analysistool text, IN _filename text, IN _description text, IN _active integer, IN _contents text, IN _hmsautosupersede text, IN _msgfplusautocentroid text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_settings_file(INOUT _settingsfileid integer, IN _analysistool text, IN _filename text, IN _description text, IN _active integer, IN _contents text, IN _hmsautosupersede text, IN _msgfplusautocentroid text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateSettingsFile';

