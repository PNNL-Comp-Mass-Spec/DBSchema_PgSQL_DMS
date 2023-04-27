--
CREATE OR REPLACE PROCEDURE public.add_update_storage
(
    _path text,
    _volNameClient text,
    _volNameServer text,
    _storFunction text,
    _instrumentName text,
    _description text = '(na)',
    _urlDomain text = 'pnl.gov',
    INOUT _id text,
    _mode text = 'add',
    INOUT _message text = '',
    INOUT _returnCode text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing storage path
**      (saves current state of storage and instrument
**      tables in backup tables)
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
**    _storFunction   'inbox', 'old-storage', or 'raw-storage'
**    _mode           'add' or 'update'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _msg text;
    _machineName text;
    _num int := 0;
    _tmpID int := 0;
    _oldFunction text;
    _spID int;
    _existingID int := -1;
    _storagePathID Int;
    _newID int;
    _pathList text;
BEGIN
    _message := '';
    _returnCode := '';

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
    -- Validate input fields
    ---------------------------------------------------

    If char_length(_path) < 1 Then
        _msg := 'path was blank';
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If char_length(_instrumentName) < 1 Then
        _msg := 'instrumentName was blank';
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not _storFunction::citext In ('inbox', 'old-storage', 'raw-storage') Then
        _msg := 'Function "' || _storFunction || '" is not recognized';
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If Not _mode::citext In ('add', 'update') Then
        _msg := 'Function "' || _mode || '" is not recognized';
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _urlDomain := Coalesce(_urlDomain, '');

    ---------------------------------------------------
    -- Resolve machine name
    ---------------------------------------------------

    If _storFunction = 'inbox' Then
        _machineName := replace(_volNameServer, '\', '');
    Else
        _machineName := replace(_volNameClient, '\', '');
    End If;

    ---------------------------------------------------
    -- Verify instrument name
    ---------------------------------------------------

    If NOT Exists (SELECT * FROM t_instrument_name WHERE instrument = _instrumentName) Then
        _msg := 'Unknown instrument "' || _instrumentName || '"';
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Only one input path allowed for given instrument
    ---------------------------------------------------

    SELECT COUNT(storage_path_id)
    INTO _num
    FROM t_storage_path
    WHERE
        (instrument = _instrumentName) AND
        (storage_path_function = _storFunction);

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    _oldFunction := '';
    _spID := _id::int;

    -- Cannot update a non-existent entry
    --
    If _mode = 'update' Then
        SELECT
            storage_path_id,
            storage_path_function
        INTO _tmpID, _oldFunction
        FROM t_storage_path
        WHERE storage_path_id = _spID;
        --
        If Not FOUND Then
            _msg := 'Cannot update:  Storage path "' || _id || '" is not in database ';
            RAISE EXCEPTION '%', _msg;

            _message := 'message';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        -- Check for an existing row to avoid adding a duplicate

        SELECT storage_path_id
        INTO _existingID
        FROM t_storage_path
        WHERE storage_path = _path AND
              vol_name_client = _volNameClient AND
              vol_name_server = _volNameServer AND
              storage_path_function = _storFunction AND
              machine_name = _machineName

        If FOUND Then
            -- Do not add a duplicate row
            _storagePathID := _existingID;
            _message := 'Storage path already exists; ID ' || cast(_existingID as text);
        Else
            BEGIN

                ---------------------------------------------------
                -- Save existing state of instrument and storage tables
                ---------------------------------------------------
                --
                Call backup_storage_state (_message => _msg, _returnCode => _returnCode);
                --
                If _returnCode <> '' Then
                    ROLLBACK;

                    _msg := 'Backup failed: ' || _msg;
                    RAISE EXCEPTION '%', _msg;

                    _message := 'message';
                    RAISE WARNING '%', _message;

                    _returnCode := 'U5201';
                    RETURN;
                End If;

                ---------------------------------------------------
                -- Clean up any existing raw-storage assignments
                -- for instrument
                ---------------------------------------------------
                --
                If _storFunction = 'raw-storage' Then

                    -- Build list of paths that will be changed
                    --
                    SELECT string_agg(storage_path_id::text, ', ' )
                    INTO _pathList
                    FROM t_storage_path
                    WHERE (storage_path_function = 'raw-storage') AND
                          (instrument = _instrumentName);

                    -- Set any existing raw-storage paths for instrument
                    -- already in storage table to old-storage
                    --
                    UPDATE t_storage_path
                    SET storage_path_function = 'old-storage'
                    WHERE
                        (storage_path_function = 'raw-storage') AND
                        (instrument = _instrumentName);
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    _message := format('%s %s were changed from raw-storage to old-storage (%s)',
                                        _myRowCount, public.check_plural(_myRowCount, 'path', 'paths'), _pathList);

                End If;

                ---------------------------------------------------
                -- Validate against any existing inbox assignments
                ---------------------------------------------------

                If _storFunction = 'inbox' Then
                    _tmpID := 0;
                    --
                    SELECT storage_path_id
                    INTO _tmpID
                    FROM t_storage_path
                    WHERE
                        (storage_path_function = 'inbox') AND
                        (instrument = _instrumentName)

                    If FOUND Then
                        ROLLBACK;

                        _msg := 'Cannot add new inbox path if one (' || cast(_tmpID as text)|| ') already exists for instrument';
                        RAISE EXCEPTION '%', _msg;

                        _message := 'message';
                        RAISE WARNING '%', _message;

                        _returnCode := 'U5201';
                        RETURN;
                    End If;
                End If;

                ---------------------------------------------------
                -- Add the new entry
                ---------------------------------------------------
                --
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
                );

                COMMIT;
            END;

            _storagePathID := _newID;
        End If;

        ---------------------------------------------------
        -- Update the assigned storage for the instrument
        ---------------------------------------------------
        --
        If _storFunction = 'raw-storage' Then
            UPDATE t_instrument_name
            SET storage_path_id = _storagePathID
            WHERE (instrument = _instrumentName)

        End If;

        If _storFunction = 'inbox' Then
            UPDATE t_instrument_name
            SET source_path_id = _storagePathID
            WHERE (instrument = _instrumentName)

        End If;

        -- Return storage path ID as text
        --
        _id := cast(_storagePathID as text);

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        ---------------------------------------------------
        -- Begin transaction
        ---------------------------------------------------
        --
        _transName := 'AddUpdateStoragePath';
        Begin transaction _transName

        ---------------------------------------------------
        -- Save existing state of instrument and storage tables
        ---------------------------------------------------
        --
        Call backup_storage_state (_message => _msg, _returnCode => _returnCode);
        --
        If _returnCode <> '' Then
            ROLLBACK;

            _msg := 'Backup failed: ' || _msg;
            RAISE EXCEPTION '%', _msg;

            _message := 'message';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Clean up any existing raw-storage assignments
        -- for instrument when changing to new raw-storage path
        ---------------------------------------------------
        --
        If _storFunction = 'raw-storage' and _oldFunction <> 'raw-storage' Then

            -- Build list of paths that will be changed
            --
            SELECT string_agg(storage_path_id::text, ', ' )
            INTO _message
            FROM t_storage_path
            WHERE storage_path_function = 'raw-storage' AND
                  instrument = _instrumentName;

            -- Set any existing raw-storage paths for instrument
            -- already in storage table to old-storage
            --
            UPDATE t_storage_path
            SET storage_path_function = 'old-storage'
            WHERE storage_path_function = 'raw-storage' AND
                  instrument = _instrumentName;

            ---------------------------------------------------
            -- Update the assigned storage for the instrument
            ---------------------------------------------------
            --
            UPDATE t_instrument_name
            SET storage_path_id = _tmpID
            WHERE (instrument = _instrumentName)

            _message := cast(_myRowCount as text) || ' path(s) (' || _message || ') were changed from raw-storage to old-storage';
        End If;

        ---------------------------------------------------
        -- Validate against changing current raw-storage path
        -- to old-storage
        ---------------------------------------------------
        --
        If _storFunction <> 'raw-storage' and _oldFunction = 'raw-storage' Then
            ROLLBACK;

            _msg := 'Cannot change existing raw-storage path to old-storage';
            RAISE EXCEPTION '%', _msg;

             _message := 'message';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate against any existing inbox assignments
        ---------------------------------------------------

        If _storFunction <> 'inbox' and _oldFunction = 'inbox' Then
            ROLLBACK;

            _msg := 'Cannot change existing inbox path to another function';
            RAISE EXCEPTION '%', _msg;

             _message := 'message';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Update storage path info
        ---------------------------------------------------
        --
        UPDATE t_storage_path
        SET
            storage_path =_path,
            vol_name_client =_volNameClient,
            vol_name_server =_volNameServer,
            storage_path_function =_storFunction,
            instrument =_instrumentName,
            description =_description,
            machine_name = _machineName
        WHERE (storage_path_id = _spID)

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_storage IS 'AddUpdateStorage';
