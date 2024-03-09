--
-- Name: add_update_instrument(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_instrument(IN _instrumentid integer, IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _status text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text DEFAULT 'No'::text, IN _trackusagewheninactive text DEFAULT 'No'::text, IN _scansourcedir text DEFAULT 'Yes'::text, IN _autospvolnameclient text DEFAULT ''::text, IN _autospvolnameserver text DEFAULT ''::text, IN _autosppathroot text DEFAULT ''::text, IN _autospurldomain text DEFAULT ''::text, IN _autosparchiveservername text DEFAULT ''::text, IN _autosparchivepathroot text DEFAULT ''::text, IN _autosparchivesharepathroot text DEFAULT ''::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Edit an existing instrument (the only supported value for _mode is 'update')
**      To add a new instrument, use procedure add_new_instrument
**
**  Arguments:
**    _instrumentID                 Instrument ID
**    _instrumentName               Instrument name (validated against instrument ID); this procedure cannot be used to rename an instrument
**    _instrumentClass              Instrument class
**    _instrumentGroup              Instrument group
**    _captureMethod                Capture method: 'secfso' for bionet instruments, 'fso' for instruments on the pnl.gov domain
**    _status                       Instrument status: 'Active', 'Inactive', or 'Offline'
**    _roomNumber                   Room number, e.g. 'BSF 1217', 'EMSL 1526', or 'Offsite'
**    _description                  Instrument description
**    _usage                        Instrument usage (empty string if no specific usage)
**    _operationsRole               Operations role: 'Research', 'Production', or 'Offsite'
**    _percentEMSLOwned             Percent of instrument owned by EMSL; number between 0 and 100
**    _autoDefineStoragePath        Set to 'Yes' to enable auto-defining the storage path based on the _spPath and _archivePath related parameters
**    _trackUsageWhenInactive       'Yes' or 'No'
**    _scanSourceDir                Set to 'No' to skip this instrument when the DMS_InstDirScanner looks for files and directories on the instrument's source share
**    _autoSPVolNameClient          Storage server name,                                     e.g. \\proto-8\
**    _autoSPVolNameServer          Drive letter on storage server (local to server itself), e.g. F:\
**    _autoSPPathRoot               Storage path (share name) on storage server,             e.g. Lumos01\
**    _autoSPUrlDomain              Domain name,                                             e.g. pnl.gov
**    _autoSPArchiveServerName      Archive server name           (obsolete),                e.g. agate.emsl.pnl.gov
**    _autoSPArchivePathRoot        Storage path on EMSL archive  (obsolete),                e.g. /archive/dmsarch/Lumos01
**    _autoSPArchiveSharePathRoot   Archive share path            (obsolete),                e.g. \\agate.emsl.pnl.gov\dmsarch\Lumos01
**    _mode                         Mode; only 'update' is supported. To add an instrument, use https://dms2.pnl.gov/new_instrument/create (which in turn calls Add_New_Instrument)
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   grk
**  Date:   06/07/2005 grk - Initial release
**          10/15/2008 grk - Allowed for null Usage
**          08/27/2010 mem - Add parameter _instrumentGroup
**                         - Use try-catch for error handling
**          05/12/2011 mem - Add _autoDefineStoragePath and related _autoSP parameters
**          05/13/2011 mem - Now calling Validate_Auto_Storage_Path_Params
**          11/30/2011 mem - Add parameter _percentEMSLOwned
**          04/01/2013 mem - Expanded _description to varchar(255)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          04/10/2018 mem - Add parameter _scanSourceDir
**          12/06/2018 mem - Change variable names to camelCase
**                         - Use Try_Cast instead of Try_Convert
**          05/28/2019 mem - Add parameter _trackUsageWhenInactive
**          09/01/2023 mem - Expand _instrumentName to varchar(64), _description to varchar(1024), and _usage to varchar(128)
**          10/05/2023 mem - Make _instrumentID an input parameter
**                         - Do not allow renaming the instrument with this procedure
**                         - Validate instrument name specified by _instrumentName vs. the instrument name associated with _instrumentID
**                         - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**          01/11/2024 mem - Show a custom message when _mode is 'update' but _instrumentID is null
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _percentEMSLOwnedVal int;
    _nextContainerID int;
    _valTrackUsageWhenInactive int;
    _valScanSourceDir int;
    _valAutoDefineStoragePath int;
    _msg text;
    _existingName citext;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

        _instrumentName      := Trim(Coalesce(_instrumentName, ''));
        _description         := Trim(Coalesce(_description, ''));
        _usage               := Trim(Coalesce(_usage, ''));
        _mode                := Trim(Lower(Coalesce(_mode, '')));
        _percentEMSLOwnedVal := public.try_cast(_percentEMSLOwned, null::int);

        If _percentEMSLOwnedVal Is Null Or _percentEMSLOwnedVal < 0 Or _percentEMSLOwnedVal > 100 Then
            RAISE EXCEPTION 'Percent EMSL Owned should be a number between 0 and 100' USING ERRCODE = 'U5201';
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If _instrumentID Is Null Then
                _message := 'Cannot update: instrument ID cannot be null';
                RAISE WARNING '%', _message;

                _returnCode := 'U5202';
                RETURN;
            End If;

            SELECT instrument
            INTO _existingName
            FROM t_instrument_name
            WHERE instrument_id = _instrumentID;

            -- Cannot update a non-existent entry
            If Not FOUND Then
                _msg := format('Cannot update: instrument ID %s does not exist', _instrumentID);
                RAISE EXCEPTION '%', _msg USING ERRCODE = 'U5203';
            End If;

            If _existingName <> _instrumentName::citext Then
                _msg := format('Instrument ID %s is instrument "%s", which does not match the specified instrument name ("%s")',
                                _instrumentID, _existingName, _instrumentName);
                RAISE EXCEPTION '%', _msg USING ERRCODE = 'U5204';
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Resolve Yes/No parameters to 0 or 1
        ---------------------------------------------------

        _valTrackUsageWhenInactive := public.boolean_text_to_integer(_trackUsageWhenInactive);
        _valScanSourceDir          := public.boolean_text_to_integer(_scanSourceDir);
        _valAutoDefineStoragePath  := public.boolean_text_to_integer(_autoDefineStoragePath);

        ---------------------------------------------------
        -- Validate the _autoSP parameters
        -- Procedure validate_auto_storage_path_params will raise an exception if there is a problem
        ---------------------------------------------------

        CALL public.validate_auto_storage_path_params (
                        _autoDefineStoragePath      => _valAutoDefineStoragePath::boolean,
                        _autoSPVolNameClient        => _autoSPVolNameClient,
                        _autoSPVolNameServer        => _autoSPVolNameServer,
                        _autoSPPathRoot             => _autoSPPathRoot,
                        _autoSPArchiveServerName    => _autoSPArchiveServerName,
                        _autoSPArchivePathRoot      => _autoSPArchivePathRoot,
                        _autoSPArchiveSharePathRoot => _autoSPArchiveSharePathRoot);

        ---------------------------------------------------
        -- Note: the add mode is not enabled in this procedure
        ---------------------------------------------------

        If _mode = 'add' Then
            _logErrors := false;
            RAISE EXCEPTION 'The "add" instrument mode is disabled for this page; instead, use https://dms2.pnl.gov/new_instrument/create' USING ERRCODE = 'U5205';
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_instrument_name
            SET -- instrument = _instrumentName         -- If an instrument needs to be renamed, manually update table t_instrument_name
                instrument_class                = _instrumentClass,
                instrument_group                = _instrumentGroup,
                capture_method                  = _captureMethod,
                status                          = _status,
                room_number                     = _roomNumber,
                description                     = _description,
                usage                           = _usage,
                operations_role                 = _operationsRole,
                tracking                        = _valTrackUsageWhenInactive,
                scan_source_dir                 = _valScanSourceDir,
                percent_emsl_owned              = _percentEMSLOwnedVal,
                auto_define_storage_path        = _valAutoDefineStoragePath,
                auto_sp_vol_name_client         = _autoSPVolNameClient,
                auto_sp_vol_name_server         = _autoSPVolNameServer,
                auto_sp_path_root               = _autoSPPathRoot,
                auto_sp_url_domain              = _autoSPUrlDomain,
                auto_sp_archive_server_name     = _autoSPArchiveServerName,
                auto_sp_archive_path_root       = _autoSPArchivePathRoot,
                auto_sp_archive_share_path_root = _autoSPArchiveSharePathRoot
            WHERE instrument_id = _instrumentID;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Instrument %s', _exceptionMessage, _instrumentName);

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


ALTER PROCEDURE public.add_update_instrument(IN _instrumentid integer, IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _status text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text, IN _trackusagewheninactive text, IN _scansourcedir text, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autospurldomain text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_instrument(IN _instrumentid integer, IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _status text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text, IN _trackusagewheninactive text, IN _scansourcedir text, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autospurldomain text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_instrument(IN _instrumentid integer, IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _status text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text, IN _trackusagewheninactive text, IN _scansourcedir text, IN _autospvolnameclient text, IN _autospvolnameserver text, IN _autosppathroot text, IN _autospurldomain text, IN _autosparchiveservername text, IN _autosparchivepathroot text, IN _autosparchivesharepathroot text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateInstrument';

