--
-- Name: add_update_param_file(integer, text, text, text, integer, text, integer, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_param_file(INOUT _paramfileid integer, IN _paramfilename text, IN _paramfiledesc text, IN _paramfiletype text, IN _paramfilevalid integer DEFAULT 1, IN _paramfilemassmods text DEFAULT ''::text, IN _replaceexistingmassmods integer DEFAULT 0, IN _validateunimod integer DEFAULT 1, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing parameter file in database
**
**      When updating an existing parameter file, the name and type can be changed
**      only if the file is not used with any analysis jobs
**
**  Arguments:
**    _paramFileID              -- Parameter file ID (for use when _mode is 'update')
**    _paramFileName            -- Parameter file name
**    _paramFileDesc            -- Parameter file description
**    _paramFileType            -- Parameter file type
**    _paramFileValid           -- 1 if the parameter file is valid, 0 if invalid (leave as an integer since called from a web page)
**    _paramfileMassMods        -- Dynamic and static mods
**    _replaceExistingMassMods  -- When _mode is 'update', set this to 1 to replace existing mass mods, 0 to leave them unchanged (leave as an integer since called from a web page)
**    _validateUnimod           -- When 1, require that mods are known UniMod modifications; 0 to disable validation (leave as an integer since called from a web page)
**    _mode                     -- 'add', 'previewadd', or 'update'
**    _message
**    _returnCode
**
**    Note that _paramFileValid will be set to 1 if _mode is 'add'
**
**  Auth:   kja
**  Date:   07/22/2004 kja - Initial version
**          12/06/2016 mem - Add parameters _paramFileID, _paramFileValid, _paramfileMassMods, and _replaceExistingMassMods
**                     mem - Replaced parameter _paramFileTypeID with _paramFileType
**          05/26/2017 mem - Update _paramfileMassMods to remove tabs
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/28/2017 mem - Add _validateUnimod
**          10/02/2017 mem - Abort adding a new parameter file if _paramfileMassMods does not validate (when _validateUnimod is 1)
**          08/17/2018 mem - Pass _paramFileType to Store_Param_File_Mass_Mods
**          11/19/2018 mem - Pass 0 to the _maxRows parameter to Parse_Delimited_List_Ordered
**          11/30/2018 mem - Make _paramFileID an input/output parameter
**          11/04/2021 mem - Populate the Mod_List field using get_param_file_mass_mod_code_list
**          04/11/2022 mem - Check for whitespace in _paramFileName
**          02/23/2023 mem - Add mode 'previewadd'
**                         - If the mode is 'previewadd', set _infoOnly to true when calling Store_Param_File_Mass_Mods
**          02/23/2023 mem - Ported to PostgreSQL
**          05/12/2023 mem - Rename variables
**          05/22/2023 mem - Remove local variable use when raising exceptions
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/07/2023 mem - Update warning messages
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingCount int := 0;
    _updateMassMods boolean := false;
    _validateMods boolean := false;
    _paramFileTypeID int := 0;
    _existingParamFileID int := 0;
    _currentName text := '';
    _currentTypeID int := 0;
    _action text := 'rename';
    _delimiter text := '';
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, 'add')));

        If _paramFileID Is Null And Not _mode like '%add%' Then
            _returnCode := 'U5200';
            RAISE EXCEPTION 'ParamFileID was null';
        End If;

        _paramFileName := Trim(Coalesce(_paramFileName, ''));
        If _paramFileName = '' Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'ParamFileName must be specified';
        End If;

        _paramFileDesc := Trim(Coalesce(_paramFileDesc, ''));
        If _paramFileDesc = '' Then
            _returnCode := 'U5202';
            RAISE EXCEPTION 'ParamFileDesc must be specified';
        End If;

        _paramFileType := Trim(Coalesce(_paramFileType, ''));
        If _paramFileType = '' Then
            _returnCode := 'U5203';
            RAISE EXCEPTION 'ParamFileType was null';
        End If;

        If public.has_whitespace_chars(_paramFileName, 0) Then
            If Position(chr(9) In _paramFileName) > 0 Then
                RAISE EXCEPTION 'Parameter file name cannot contain tabs';
            Else
                RAISE EXCEPTION 'Parameter file name cannot contain spaces';
            End If;
        End If;

        _paramFileValid := Coalesce(_paramFileValid, 1);

        _paramfileMassMods := Coalesce(_paramfileMassMods, '');

        -- Assure that _paramfileMassMods does not have any tabs
        _paramfileMassMods := Replace(_paramfileMassMods, chr(9), ' ');

        _replaceExistingMassMods := Coalesce(_replaceExistingMassMods, 0);

        _validateUnimod := Coalesce(_validateUnimod, 1);

        ---------------------------------------------------
        -- Validate _paramFileType
        ---------------------------------------------------

        SELECT param_file_type_id
        INTO _paramFileTypeID
        FROM t_param_file_types
        WHERE param_file_type = _paramFileType;

        If _paramFileTypeID = 0 Then
            _returnCode := 'U5204';
            RAISE EXCEPTION 'ParamFileType is not valid: %', _paramFileType;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT param_file_id
        INTO _existingParamFileID
        FROM t_param_files
        WHERE param_file_name = _paramFileName::citext;
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        -- Check for a name conflict when adding
        --
        If _mode Like '%add%' And _existingCount > 0 Then
            RAISE EXCEPTION 'Cannot add: Param File "%" already exists', _paramFileName;
        End If;

        -- Check for a name conflict when renaming
        --
        If _mode Like '%update%' And _existingCount > 0 And _existingParamFileID <> _paramFileID Then
            RAISE EXCEPTION 'Cannot rename: Param File "%" already exists', _paramFileName;
        End If;

        ---------------------------------------------------
        -- Check for renaming or changing the type when the parameter file has already been used
        ---------------------------------------------------

        If _mode Like '%update%' Then

            SELECT param_file_name,
                   param_file_type_id
            INTO _currentName, _currentTypeID
            FROM t_param_files
            WHERE param_file_id = _paramFileID;

            If _paramFileName <> _currentName Or _paramFileTypeID <> _currentTypeID Then

                If _paramFileName = _currentName Then
                    _action := 'change param file type';
                End If;

                If Exists (SELECT * FROM t_analysis_job WHERE param_file_name = _currentName) Then
                    RAISE EXCEPTION 'Cannot %: Param File "%" is used by an analysis job', _action, _currentName;
                End If;

                If Exists (SELECT * FROM t_analysis_job_request WHERE param_file_name = _currentName) Then
                    RAISE EXCEPTION 'Cannot %: Param File "%" is used by a job request', _action, _currentName;
                End If;
            End If;
        End If;

        If _paramfileMassMods <> '' Then
        -- <a>
            -----------------------------------------
            -- Check whether all of the lines in _paramfileMassMods are blank or start with a # sign (comment character)
            -- Split _paramfileMassMods on carriage returns
            -- Store the data in Tmp_Mods_Precheck
            -----------------------------------------

            If Position(chr(10) In _paramfileMassMods) > 0 Then
                _delimiter := chr(10);
            Else
                _delimiter := chr(13);
            End If;

            CREATE TEMP TABLE Tmp_Mods_Precheck (
                EntryID int NOT NULL,
                Value text null
            );

            INSERT INTO Tmp_Mods_Precheck (EntryID, Value)
            SELECT Entry_ID, Value
            FROM public.parse_delimited_list_ordered(_paramfileMassMods, _delimiter, 0);

            DELETE FROM Tmp_Mods_Precheck
            WHERE Value Is Null Or Value Like '#%' or Trim(Value) = '';

            If Not Exists (SELECT * FROM Tmp_Mods_Precheck) Then
                _paramfileMassMods := '';
            End If;

            DROP TABLE Tmp_Mods_Precheck;

            If _paramfileMassMods <> '' And (
                _mode IN ('add', 'previewadd') OR
                _mode = 'update' And _replaceExistingMassMods = 1 Or
                _mode = 'update' And _replaceExistingMassMods = 0 AND Not Exists (Select * FROM t_param_file_mass_mods WHERE param_file_id = _paramFileID)) Then

                ---------------------------------------------------
                -- Validate the mods by calling Store_Param_File_Mass_Mods with @paramFileID = 0
                ---------------------------------------------------

                _validateMods := CASE WHEN _validateUnimod > 0 THEN true ELSE false END;

                CALL store_param_file_mass_mods (
                     _paramFileID      => 0,
                     _mods             => _paramfileMassMods,
                     _infoOnly         => CASE WHEN _mode Like 'preview%' THEN true ELSE false END,
                     _showresiduetable => CASE WHEN _mode Like 'preview%' THEN true ELSE false END,
                     _replaceExisting  => true,
                     _validateUnimod   => _validateMods,
                     _paramFileType    => _paramFileType,
                     _message          => _message,           -- Output
                     _returnCode       => _returnCode);       -- Output

                If _returnCode <> '' Then

                    If Coalesce(_message, '') = '' Then
                        RAISE EXCEPTION 'store_param_file_mass_mods returned error code %; unknown error', _returnCode;
                    Else
                        RAISE EXCEPTION 'store_param_file_mass_mods: %', _message;
                    End If;

                End If;

            End If; -- </b>

        End If; -- </a>

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_param_files (
                param_file_name,
                param_file_description,
                param_file_type_id,
                date_created,
                date_modified,
                valid
            ) VALUES (
                _paramFileName,
                _paramFileDesc,
                _paramFileTypeID,
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP,
                1        -- valid
            )
            RETURNING param_file_id
            INTO _paramFileID;

            _updateMassMods := true;

            raise info 'Added param file % to t_param_files, assigned ID %', _paramFileName, _paramFileID;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_param_files
            SET param_file_name = _paramFileName,
                param_file_description = _paramFileDesc,
                param_file_type_id = _paramFileTypeID,
                valid = _paramFileValid,
                date_modified = CURRENT_TIMESTAMP
            WHERE param_file_id = _paramFileID;

            _updateMassMods := true;

        End If;

        If _paramFileID > 0 And _paramfileMassMods <> '' And _updateMassMods Then
            If _replaceExistingMassMods = 0 And Exists (Select * FROM t_param_file_mass_mods WHERE param_file_id = _paramFileID) Then
                _updateMassMods := false;
                _message := 'Warning: existing mass mods were not updated because _updateMassMods is false';
            End If;

            If _updateMassMods Then
                -- Store the param file mass mods in t_param_file_mass_mods

                _validateMods := CASE WHEN _validateUnimod > 0 THEN true ELSE false END;

                CALL store_param_file_mass_mods (
                    _paramFileID,
                    _mods => _paramfileMassMods,
                    _infoOnly => false,
                    _showresiduetable => false,
                    _replaceExisting => CASE WHEN _replaceExistingMassMods > 0 THEN true ELSE false END,
                    _validateUnimod => _validateMods,
                    _message => _message,                       -- Output
                    _returnCode => _returnCode);                -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Store_Param_File_Mass_Mods: "%"', _message;
                End If;
            End If;
        End If;

        If _mode In ('add', 'update') Then

            -- Update the Mod_List field
            Update t_param_files
            Set mod_list = public.get_param_file_mass_mod_code_list(param_file_id, 0)
            Where param_file_id = _paramFileID;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If Not _exceptionMessage Like '%already exists%' And
           Not _exceptionMessage Like '%must be specified%' And
           Not _exceptionMessage Like '%is used by%' Then

            _logMessage := format('%s; Param file %s', _exceptionMessage, _paramFileName);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_param_file(INOUT _paramfileid integer, IN _paramfilename text, IN _paramfiledesc text, IN _paramfiletype text, IN _paramfilevalid integer, IN _paramfilemassmods text, IN _replaceexistingmassmods integer, IN _validateunimod integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

