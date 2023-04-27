--
CREATE OR REPLACE FUNCTION public.get_instrument_storage_path_for_new_datasets
(
    _instrumentID int,
    _refDate timestamp = null,
    _autoSwitchActiveStorage boolean = true,
    _infoOnly boolean = false
)
RETURNS int
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the ID for the most appropriate storage path for
**      new data uploaded for the given instrument.
**
**      If the Instrument has Auto_Define_Storage_Path enabled in
**      T_Instrument_Name, then will auto-define the storage path
**      based on the current year and quarter
**
**      If necessary, will call AddUpdateStorage to auto-create an entry in T_Storage_Path
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/11/2011 mem - Initial Version
**          05/12/2011 mem - Added _refDate and _autoSwitchActiveStorage
**          02/23/2016 mem - Add Set XACT_ABORT on
**          10/27/2020 mem - Pass Auto_SP_URL_Domain to AddUpdateStorage
**          12/17/2020 mem - Rollback any open transactions before calling LocalErrorHandler
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _storagePathID int;
    _message text;
    _instrumentInfo record;
    _callingProcName text;
    _currentLocation text;
    _currentYear int;
    _currentQuarter int;
    _storagePathName text;
    _suffix text;
    _storageFunction text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _currentLocation := 'Start';

    Begin

        -----------------------------------------
        -- See if this instrument has Auto_Define_Storage_Path enabled
        -----------------------------------------
        --
        _autoDefineStoragePath := 0;    -- This is stored as an integer in t_instrument_name
        _storagePathID := 0;

        SELECT auto_define_storage_path As AutoDefineStoragePath
               auto_sp_vol_name_client  AS AutoSPVolNameClient
               auto_sp_vol_name_server  AS AutoSPVolNameServer
               auto_sp_path_root        AS AutoSPPathRoot
               auto_sp_url_domain       AS AutoSPUrlDomain
               instrument               AS InstrumentName
        INTO _instrumentInfo
        FROM t_instrument_name
        WHERE instrument_id = _instrumentID;

        If Coalesce(_instrumentInfo.AutoDefineStoragePath, 0) = 0 Then
            -- Using the storage path defined in t_instrument_name

            SELECT storage_path_id
            INTO _storagePathID
            FROM t_instrument_name
            WHERE instrument_id = _instrumentID;
        Else
        -- <a>

            _currentLocation := 'Auto-defining storage path';

            -- Validate the _autoSP variables
            If Coalesce(_instrumentInfo.AutoSPVolNameClient, '') = '' OR
               Coalesce(_instrumentInfo.autoSPVolNameServer, '') = '' OR
               Coalesce(_instrumentInfo.AutoSPPathRoot, '') = '' Then

                _message := format('One or more Auto_SP fields are empty or null for instrument %s; unable to auto-define the storage path', _instrumentInfo.InstrumentName);

                If _infoOnly Then
                    RAISE INFO '%', _message;
                Else
                    Call post_log_entry ('Error', _message, 'GetInstrumentStoragePathForNewDatasets');
                End If;
            Else
            -- <b>
                -----------------------------------------
                -- Define the StoragePath
                -- It will look like VOrbiETD01\2011_2\
                -----------------------------------------

                _refDate := Coalesce(_refDate, CURRENT_TIMESTAMP);

                _currentYear :=    Extract(year    from _refDate),
                _currentQuarter := Extract(quarter from _refDate)

                _suffix := format('%s_%s\', _currentYear, _currentQuarter);

                _storagePathName := _instrumentInfo.AutoSPPathRoot;

                If Right(_storagePathName, 1) <> '\' Then
                        _storagePathName := _storagePathName || '\';
                End If;

                _storagePathName := _storagePathName || _suffix;

                -----------------------------------------
                -- Look for existing entry in t_storage_path
                -----------------------------------------

                SELECT storage_path_id
                INTO _storagePathID
                FROM t_storage_path
                WHERE storage_path = _storagePathName AND
                      vol_name_client = _instrumentInfo.AutoSPVolNameClient AND
                      vol_name_server = _instrumentInfo.AutoSPVolNameServer AND
                      (storage_path_function = 'raw-storage' OR
                       storage_path_function = 'old-storage' AND Not _autoSwitchActiveStorage);

                If Not FOUND Then

                    -- Path not found; add it if _infoOnly is false
                    If _infoOnly Then
                        RAISE INFO '%', 'Auto-defined storage path "' || _storagePathName || '" not found t_storage_path; need to add it';
                    Else
                        _currentLocation := 'Call AddUpdateStorage to add ' || _storagePathName;

                        If _autoSwitchActiveStorage Then
                            _storageFunction := 'raw-storage';
                        Else
                            _storageFunction := 'old-storage';
                        End If;

                        Call add_update_storage (
                                    _storagePathName,
                                    _autoSPVolNameClient => _instrumentInfo.AutoSPVolNameClient,
                                    _autoSPVolNameServer => _instrumentInfo.AutoSPVolNameServer,
                                    _storFunction => _storageFunction,
                                    _instrumentName => _instrumentInfo.InstrumentName,
                                    _description => '',
                                    _urlDomain => _instrumentInfo.AutoSPUrlDomain,
                                    _id >= _storagePathID,          -- Output
                                    _mode => 'add',
                                    _message => _message,           -- Output
                                    _returnCode => _returnCode);    -- Output

                    End If;

                ElsIf _infoOnly Then
                    RAISE INFO '%', 'Auto-defined storage path "' || _storagePathName || '" matched in t_storage_path; ID=' || _storagePathID::text;
                End If;

            End If; -- </b>
        End If; -- </a>

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

    -----------------------------------------
    -- Return the storage path ID
    -----------------------------------------

    RETURN Coalesce(_storagePathID, 0);
END
$$;

COMMENT ON FUNCTION public.get_instrument_storage_path_for_new_datasets IS 'GetInstrumentStoragePathForNewDatasets';
