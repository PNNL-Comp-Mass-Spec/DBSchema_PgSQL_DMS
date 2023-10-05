--
CREATE OR REPLACE PROCEDURE public.add_update_instrument
(
    INOUT _instrumentID int,
    _instrumentName text,
    _instrumentClass text,
    _instrumentGroup text,
    _captureMethod text,
    _status text,
    _roomNumber text,
    _description text,
    _usage text,
    _operationsRole text,
    _percentEMSLOwned text,
    _autoDefineStoragePath text default 'No',
    _trackUsageWhenInactive text default 'No',
    _scanSourceDir text default 'Yes',
    _autoSPVolNameClient text,
    _autoSPVolNameServer text,
    _autoSPPathRoot text,
    _autoSPUrlDomain text,
    _autoSPArchiveServerName text,
    _autoSPArchivePathRoot text,
    _autoSPArchiveSharePathRoot text,
    _mode text default 'update',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Edits existing Instrument
**
**  Arguments:
**    _scanSourceDir           Set to No to skip this instrument when the DMS_InstDirScanner looks for files and directories on the instrument's source share
**    _percentEMSLOwned        % of instrument owned by EMSL; number between 0 and 100
**    _autoDefineStoragePath   Set to Yes to enable auto-defining the storage path based on the _spPath and _archivePath related parameters
**    _autoSPVolNameClient     Example: \\proto-8\
**    _autoSPVolNameServer     Example: F:\
**    _autoSPPathRoot          Example: Lumos01\
**    _autoSPUrlDomain         Example: pnl.gov
**    _mode                    Note that 'add' is not allowed in this procedure; instead use https://dms2.pnl.gov/new_instrument/create (which in turn calls Add_New_Instrument)
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
**          12/15/2023 mem - Ported to PostgreSQL
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

        _instrumentName      := Trim(Coalesce(_instrumentName, ''));
        _description         := Trim(Coalesce(_description, ''));
        _usage               := Trim(Coalesce(_usage, ''));
        _mode                := Trim(Coalesce(_mode, ''));
        _percentEMSLOwnedVal := public.try_cast(_percentEMSLOwned, null::int);
        _mode                := Trim(Lower(Coalesce(_mode, '')));

        If _percentEMSLOwnedVal Is Null Or _percentEMSLOwnedVal < 0 Or _percentEMSLOwnedVal > 100 Then
            RAISE EXCEPTION 'Percent EMSL Owned should be a number between 0 and 100' USING ERRCODE = 'U5201';
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            If Not Exists (SELECT instrument_id FROM t_instrument_name WHERE instrument = _instrumentName) Then
                RAISE EXCEPTION 'No entry could be found in database for update' USING ERRCODE = 'U5202';
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Resolve Yes/No parameters to 0 or 1
        ---------------------------------------------------

        _valTrackUsageWhenInactive := public.boolean_text_to_tinyint(_trackUsageWhenInactive);
        _valScanSourceDir          := public.boolean_text_to_tinyint(_scanSourceDir);
        _valAutoDefineStoragePath  := public.boolean_text_to_tinyint(_autoDefineStoragePath);

        ---------------------------------------------------
        -- Validate the _autoSP parameteres
        ---------------------------------------------------

        CALL validate_auto_storage_path_params (_valAutoDefineStoragePath, _autoSPVolNameClient, _autoSPVolNameServer,
                                                _autoSPPathRoot, _autoSPArchiveServerName,
                                                _autoSPArchivePathRoot, _autoSPArchiveSharePathRoot,
                                                _returnCode => _returnCode);

        If _returnCode <> '' Then
            RETURN;
        End If;

        ---------------------------------------------------
        -- Note: the add mode is not enabled in this procedure
        ---------------------------------------------------

        If _mode = 'add' Then
            _logErrors := false;
            RAISE EXCEPTION 'The "add" instrument mode is disabled for this page; instead, use https://dms2.pnl.gov/new_instrument/create' USING ERRCODE = 'U5203';
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_instrument_name
            SET instrument = _instrumentName,
                instrument_class = _instrumentClass,
                instrument_group = _instrumentGroup,
                capture_method = _captureMethod,
                status = _status,
                room_number = _roomNumber,
                description = _description,
                usage = _usage,
                operations_role = _operationsRole,
                tracking = _valTrackUsageWhenInactive,
                scan_source_dir = _valScanSourceDir,
                percent_emsl_owned = _percentEMSLOwnedVal,
                auto_define_storage_path = _valAutoDefineStoragePath,
                auto_sp_vol_name_client = _autoSPVolNameClient,
                auto_sp_vol_name_server = _autoSPVolNameServer,
                auto_sp_path_root = _autoSPPathRoot,
                auto_sp_url_domain = _autoSPUrlDomain,
                auto_sp_archive_server_name = _autoSPArchiveServerName,
                auto_sp_archive_path_root = _autoSPArchivePathRoot,
                auto_sp_archive_share_path_root = _autoSPArchiveSharePathRoot
            WHERE instrument_id = _instrumentID;

        End If; -- update mode

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

COMMENT ON PROCEDURE public.add_update_instrument IS 'AddUpdateInstrument';
