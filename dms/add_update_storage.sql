--
-- Name: add_update_storage(text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_storage(IN _path text, IN _volnameclient text, IN _volnameserver text, IN _storfunction text, IN _instrumentname text, IN _description text DEFAULT '(na)'::text, IN _urldomain text DEFAULT 'pnl.gov'::text, INOUT _id text DEFAULT '0'::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update existing storage path
**      (save current state of storage and instrument tables in backup tables)
**
**       Mode    Function:                Action
**               (cur.)    (new)
**       ----    ------    -----         --------------------
**
**       Add     (any)     raw-storage   Change any existing raw-storage
**                                       for instrument to old-storage,
**                                       then set assigned storage of
**                                       instrument to new path
**
**       Update  old       raw-storage   Change any existing raw-storage
**                                       for instrument to old-storage,
**                                       then set assigned storage of
**                                       instrument to new path
**
**       Update  raw       old-storage   Not allowed
**
**       Add     (any)     inbox         Not allowed if there is
**                                       an existing inbox path
**                                       for the instrument
**
**       Update  inbox     (any)         Not allowed
**
**  Arguments:
**    _path             Storage path                    QEHFX01\2023_1\
**    _volNameClient    Volume name used by clients     \\proto-3\
**    _volNameServer    Volume name used on the server  I:\
**    _storFunction     Storage function                raw-storage, old-storage, results_transfer, inbox, etc.
**    _instrumentName   Instrument name                 QEHFX01
**    _description      Storage description
**    _urlDomain        Domain name                     pnl.gov
**    _id               Input/output: Storage path ID (as text)
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   04/15/2002
**          05/01/2009 mem - Updated description field in T_Storage_Path to be named SP_description
**          05/09/2011 mem - Now validating _instrumentName
**          07/15/2015 mem - Now checking for an existing entry to prevent adding a duplicate
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/27/2020 mem - Add parameter _urlDomain and update SP_URL_Domain
**          06/24/2021 mem - Add support for re-using an existing storage path when _mode is 'add'
**          05/08/2023 mem - Ported to PostgreSQL
**          05/12/2023 mem - Rename variables
**          05/22/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/07/2023 mem - Add Order By to string_agg()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/07/2023 mem - Update warning messages
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/12/2023 mem - Prevent adding a second inbox for an instrument
**                         - Validate machine name vs. t_storage_path_hosts
**          01/03/2024 mem - Update warning message
**          01/11/2024 mem - Check for empty strings instead of using char_length()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          07/19/2025 mem - Raise an exception if _mode is undefined or unsupported
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _updateCount int := 0;
    _machineName citext;
    _matchCount int := 0;
    _tmpID int := 0;
    _oldFunction citext;
    _spID int;
    _existingID int := -1;
    _storagePathID int;
    _pathIDs text;

    _currentlocation text := 'Start';
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
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

        _currentlocation := 'Validate inputs';

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _path           := Trim(Coalesce(_path, ''));
        _instrumentName := Trim(Coalesce(_instrumentName, ''));
        _storFunction   := Lower(Trim(Coalesce(_storFunction, '')));
        _mode           := Lower(Trim(Coalesce(_mode, '')));
        _urlDomain      := Trim(Coalesce(_urlDomain, ''));
        _id             := Trim(Coalesce(_id, ''));
        _mode           := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Empty string specified for parameter _mode';
        ElsIf Not _mode IN ('add', 'update', 'check_add', 'check_update') Then
            RAISE EXCEPTION 'Unsupported value for parameter _mode: %', _mode;
        End If;

        If _path = '' Then
            _message := 'Storage path must be specified';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        If _instrumentName = '' Then
            _message := 'Instrument name must be specified';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        If Not _storFunction In ('inbox', 'old-storage', 'raw-storage') Then
            _message := format('Function "%s" is not recognized', _storFunction);
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        _urlDomain := Trim(Coalesce(_urlDomain, ''));

        ---------------------------------------------------
        -- Resolve machine name (e.g. 'Lumos02.bionet' or 'Proto-2')
        ---------------------------------------------------

        If _storFunction = 'inbox' Then
            _machineName := Replace(_volNameServer, '\', '');
        Else
            _machineName := Replace(_volNameClient, '\', '');
        End If;

        ---------------------------------------------------
        -- Validate instrument name
        ---------------------------------------------------

        If Not Exists (SELECT instrument FROM t_instrument_name WHERE instrument = _instrumentName) Then
            _message := format('Unknown instrument "%s"', _instrumentName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate machine name
        ---------------------------------------------------

        If Not Exists (SELECT machine_name FROM t_storage_path_hosts WHERE machine_name = _machineName) Then
            _message := format('Unknown machine name "%s" (not in t_storage_path_hosts)', _machineName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5206';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Only one input path allowed for given instrument
        ---------------------------------------------------

        SELECT COUNT(storage_path_id)
        INTO _matchCount
        FROM t_storage_path
        WHERE instrument = _instrumentName AND
              storage_path_function = _storFunction;

        If _storFunction = 'inbox' And _matchCount > 0 Then
            _message := format('Inbox already defined for instrument "%s"; change the old inbox to function "old-inbox" in t_storage_path)', _instrumentName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        _oldFunction := '';
        _spID := public.try_cast(_id, 0);

        -- Cannot update a non-existent entry

        If _mode = 'update' Then
            SELECT storage_path_id,
                   storage_path_function
            INTO _tmpID, _oldFunction
            FROM t_storage_path
            WHERE storage_path_id = _spID;

            If Not FOUND Then
                _message := format('Cannot update: storage path "%s" does not exist', _spID);
                RAISE WARNING '%', _message;

                _returnCode := 'U5208';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            _currentlocation := 'Check for existing row before adding a new row';

            -- Check for an existing row to avoid adding a duplicate

            SELECT storage_path_id
            INTO _existingID
            FROM t_storage_path
            WHERE storage_path = _path AND
                  vol_name_client = _volNameClient AND
                  vol_name_server = _volNameServer AND
                  storage_path_function = _storFunction AND
                  machine_name = _machineName;

            If FOUND Then
                -- Do not add a duplicate row
                _storagePathID := _existingID;
                _message := format('Storage path already exists; ID %s', _existingID);
                RETURN;
            End If;

            BEGIN
                _currentlocation := 'Call backup_storage_state';

                ---------------------------------------------------
                -- Save existing state of instrument and storage tables
                ---------------------------------------------------

                CALL public.backup_storage_state (
                                _message    => _message,        -- Output
                                _returnCode => _returnCode);    -- Output

                If _returnCode <> '' Then
                    ROLLBACK;

                    _message := format('Backup failed: %s', _message);
                    RAISE WARNING '%', _message;

                    _returnCode := 'U5209';
                    RETURN;
                End If;

                _currentlocation := 'Clean up existing assignments';

                ---------------------------------------------------
                -- Clean up any existing raw-storage assignments
                -- for instrument
                ---------------------------------------------------

                If _storFunction = 'raw-storage' Then

                    -- Build list of paths that will be changed

                    SELECT string_agg(storage_path_id::text, ', ' ORDER BY storage_path_id)
                    INTO _pathIDs
                    FROM t_storage_path
                    WHERE storage_path_function = 'raw-storage' AND
                          instrument = _instrumentName;

                    -- Set any existing raw-storage paths for instrument
                    -- already in storage table to old-storage

                    UPDATE t_storage_path
                    SET storage_path_function = 'old-storage'
                    WHERE storage_path_function = 'raw-storage' AND
                          instrument = _instrumentName;
                    --
                    GET DIAGNOSTICS _updateCount = ROW_COUNT;

                    _message := format('%s %s changed from raw-storage to old-storage (%s)',
                                        _updateCount, public.check_plural(_updateCount, 'path was', 'paths were'), _pathIDs);

                End If;

                ---------------------------------------------------
                -- Validate against any existing inbox assignments
                ---------------------------------------------------

                If _storFunction = 'inbox' Then

                    SELECT storage_path_id
                    INTO _tmpID
                    FROM t_storage_path
                    WHERE storage_path_function = 'inbox' AND
                          instrument = _instrumentName;

                    If FOUND Then
                        ROLLBACK;

                        _message := format('Cannot add new inbox path if one (%s) already exists for instrument', _tmpID);
                        RAISE WARNING '%', _message;

                        _returnCode := 'U5210';
                        RETURN;
                    End If;
                End If;

                _currentlocation := 'Add a row to t_storage_path';

                ---------------------------------------------------
                -- Add the new entry
                ---------------------------------------------------

                INSERT INTO t_storage_path (
                    storage_path,
                    vol_name_client,
                    vol_name_server,
                    storage_path_function,
                    instrument,
                    description,
                    machine_name,
                    url_domain
                ) VALUES (
                    _path,
                    _volNameClient,
                    _volNameServer,
                    _storFunction,
                    _instrumentName,
                    _description,
                    _machineName,
                    _urlDomain
                )
                RETURNING storage_path_id
                INTO _storagePathID;

            END;

            _currentlocation := 'Update assigned storage for the instrument';

            ---------------------------------------------------
            -- Update the assigned storage for the instrument
            ---------------------------------------------------

            If _storFunction = 'raw-storage' Then
                UPDATE t_instrument_name
                SET storage_path_id = _storagePathID
                WHERE instrument = _instrumentName;
            End If;

            If _storFunction = 'inbox' Then
                UPDATE t_instrument_name
                SET source_path_id = _storagePathID
                WHERE instrument = _instrumentName;
            End If;

            -- Return storage path ID as text

            _id := _storagePathID;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            _currentlocation := 'Call backup_storage_state';

            ---------------------------------------------------
            -- Save existing state of instrument and storage tables
            ---------------------------------------------------

            CALL public.backup_storage_state (
                            _message    => _message,        -- Output
                            _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                ROLLBACK;

                _message := format('Backup failed: %s', _message);
                RAISE WARNING '%', _message;

                _returnCode := 'U5211';
                RETURN;
            End If;

            _currentlocation := 'Clean up existing assignments';

            ---------------------------------------------------
            -- Clean up any existing raw-storage assignments
            -- for instrument when changing to new raw-storage path
            ---------------------------------------------------

            If _storFunction = 'raw-storage' And _oldFunction <> 'raw-storage' Then

                -- Build list of paths that will be changed

                SELECT string_agg(storage_path_id::text, ', ' ORDER BY storage_path_id)
                INTO _pathIDs
                FROM t_storage_path
                WHERE storage_path_function = 'raw-storage' AND
                      instrument = _instrumentName;

                -- Set any existing raw-storage paths for instrument
                -- already in storage table to old-storage

                UPDATE t_storage_path
                SET storage_path_function = 'old-storage'
                WHERE storage_path_function = 'raw-storage' AND
                      instrument = _instrumentName;

                ---------------------------------------------------
                -- Update the assigned storage for the instrument
                ---------------------------------------------------

                UPDATE t_instrument_name
                SET storage_path_id = _tmpID
                WHERE instrument = _instrumentName;
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                _message := format('%s %s changed from raw-storage to old-storage (%s)',
                            _updateCount, public.check_plural(_updateCount, 'path was', 'paths were'), _pathIDs);

            End If;

            ---------------------------------------------------
            -- Do not allow changing current raw-storage path to old-storage
            ---------------------------------------------------

            If _storFunction <> 'raw-storage' And _oldFunction = 'raw-storage' Then
                ROLLBACK;

                _message := 'Cannot change existing raw-storage path to old-storage';
                RAISE WARNING '%', _message;

                _returnCode := 'U5212';
                RETURN;
            End If;

            ---------------------------------------------------
            -- Validate against any existing inbox assignments
            ---------------------------------------------------

            If _storFunction <> 'inbox' And _oldFunction = 'inbox' Then
                ROLLBACK;

                _message := 'Cannot change existing inbox path to another function';
                RAISE WARNING '%', _message;

                _returnCode := 'U5213';
                RETURN;
            End If;

            _currentlocation := 'Update existing row in t_storage_path';

            ---------------------------------------------------
            -- Update storage path info
            ---------------------------------------------------

            UPDATE t_storage_path
            SET storage_path          =_path,
                vol_name_client       =_volNameClient,
                vol_name_server       =_volNameServer,
                storage_path_function =_storFunction,
                instrument            =_instrumentName,
                description           =_description,
                machine_name          = _machineName
            WHERE storage_path_id = _spID;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.add_update_storage(IN _path text, IN _volnameclient text, IN _volnameserver text, IN _storfunction text, IN _instrumentname text, IN _description text, IN _urldomain text, INOUT _id text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_storage(IN _path text, IN _volnameclient text, IN _volnameserver text, IN _storfunction text, IN _instrumentname text, IN _description text, IN _urldomain text, INOUT _id text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_storage(IN _path text, IN _volnameclient text, IN _volnameserver text, IN _storfunction text, IN _instrumentname text, IN _description text, IN _urldomain text, INOUT _id text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateStorage';

