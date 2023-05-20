--
CREATE OR REPLACE PROCEDURE public.add_update_settings_file
(
    INOUT _settingsFileID int,
    _analysisTool text,
    _fileName text,
    _description text,
    _active int,
    _contents text,
    _hmsAutoSupersede text = '',
    _msgfPlusAutoCentroid text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing entity in T_Settings_Files table
**
**  Arguments:
**    _settingsFileID         Settings file ID to edit, or the ID of the newly created settings file
**    _hmsAutoSupersede       Settings file name to use instead of this settings file if the dataset comes from a high res MS instrument
**    _msgfPlusAutoCentroid   Settings file name to use instead of this settings file if MSGF+ reports that not enough spectra are centroided; see SP AutoResetFailedJobs
**    _mode                   'add' or 'update'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _xmlContents xml;
    _analysisToolForAutoSupersede text := '';
    _analysisToolForAutoCentroid text := '';
BEGIN
    _message := '';
    _returnCode:= '';

    _xmlContents := _contents;

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _analysisTool := Trim(Coalesce(_analysisTool, ''));
    _fileName := Trim(Coalesce(_fileName, ''));
    _hmsAutoSupersede := Trim(Coalesce(_hmsAutoSupersede, ''));
    _msgfPlusAutoCentroid := Trim(Coalesce(_msgfPlusAutoCentroid, ''));

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

    If public.has_whitespace_chars(_fileName, 0) Then
        If Position(chr(9) In _fileName) > 0 Then
            RAISE EXCEPTION 'Settings file name cannot contain tabs';
        Else
            RAISE EXCEPTION 'Settings file name cannot contain spaces';
        End If;
    End If;

    If char_length(_hmsAutoSupersede) > 0 Then
        If _hmsAutoSupersede = _fileName Then
            _message := 'The HMS_AutoSupersede file cannot have the same name as this settings file';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        If Not Exists (SELECT * FROM t_settings_files WHERE file_name = _hmsAutoSupersede) Then
            _message := 'hms_auto_supersede settings file not found in the database: ' || _hmsAutoSupersede;
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
            RETURN;
        End If;

        SELECT analysis_tool
        INTO _analysisToolForAutoSupersede
        FROM t_settings_files
        WHERE file_name = _hmsAutoSupersede

        If _analysisToolForAutoSupersede <> _analysisTool Then
            _message := 'The Analysis Tool for the HMS_AutoSupersede file ("' || _hmsAutoSupersede || '") must match the analysis tool for this settings file: ' || _analysisToolForAutoSupersede || ' vs. ' || _analysisTool;
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;

    Else
        _hmsAutoSupersede := null;
    End If;

    If char_length(_msgfPlusAutoCentroid) > 0 Then
        If _msgfPlusAutoCentroid = _fileName Then
            _message := 'The MSGFPlus_AutoCentroid file cannot have the same name as this settings file';
            RAISE WARNING '%', _message;

            _returnCode := 'U5206';
            RETURN;
        End If;

        If Not Exists (SELECT * FROM t_settings_files WHERE file_name = _msgfPlusAutoCentroid) Then
            _message := 'MSGFPlus AutoCentroid settings file not found in the database: ' || _msgfPlusAutoCentroid;
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

        SELECT analysis_tool
        INTO _analysisToolForAutoCentroid
        FROM t_settings_files
        WHERE file_name = _msgfPlusAutoCentroid

        If _analysisToolForAutoCentroid <> _analysisTool Then
            _message := 'The Analysis Tool for the MSGFPlus_AutoCentroid file ("' || _msgfPlusAutoCentroid || '") must match the analysis tool for this settings file: ' || _analysisToolForAutoCentroid || ' vs. ' || _analysisTool;
            RAISE WARNING '%', _message;

            _returnCode := 'U5208';
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
        WHERE file_name = _fileName;

        If FOUND Then
            _message := 'Settings file ID ' || Cast(_settingsFileID As text)|| ' is named "' || _fileName || '"; cannot create a new, duplicate settings file';
            RAISE WARNING '%', _message;

            _returnCode := 'U5209';
            RETURN;
        End If;
    End If;

    If _mode = 'update' Then
        ---------------------------------------------------
        -- Assure that the settings file exists
        ---------------------------------------------------

        If _settingsFileID Is Null Then
            _message := 'Settings file ID is null; cannot udpate';
            RAISE EXCEPTION '%', _message;
        End If;

        -- Cannot update a non-existent entry
        --
        --
        If Not Exists (SELECT * FROM t_settings_files WHERE settings_file_id = _settingsFileID) Then
            _message := 'Settings file settings_file_id ' || Cast(_settingsFileID As text)|| ' not found in database; cannot update';
            RAISE WARNING '%', _message;

            _returnCode := 'U5210';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If _mode = 'add' Then

        INSERT INTO t_settings_files(
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
    --
    If _mode = 'update' Then

        UPDATE t_settings_files
        SET analysis_tool = _analysisTool,
            file_name = _fileName,
            description = _description,
            active = _active,
            contents = _xmlContents,
            hms_auto_supersede = _hmsAutoSupersede,
            msgfplus_auto_centroid = _msgfPlusAutoCentroid,
            last_updated = CURRENT_TIMESTAMP
        WHERE settings_file_id = _settingsFileID

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_settings_file IS 'AddUpdateSettingsFile';
