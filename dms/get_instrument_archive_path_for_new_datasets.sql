--
-- Name: get_instrument_archive_path_for_new_datasets(integer, integer, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_archive_path_for_new_datasets(_instrumentid integer, _datasetid integer DEFAULT NULL::integer, _autoswitchactivearchive boolean DEFAULT true, _infoonly boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the ID for the most appropriate archive path for the initial archive of new datasets uploaded for the given instrument
**
**      If the Instrument has Auto_Define_Storage_Path enabled in T_Instrument_Name,
**      will auto-define the archive path based on the current year and quarter
**
**      If _datasetID is defined, uses the Created value of the given dataset rather than the current date
**
**      If necessary, will call add_update_archive_path to auto-create an entry in T_Archive_Path;
**      Optionally set _autoSwitchActiveArchive to false to not auto-update the system to use the
**      archive path determined for future datasets for this instrument
**
**  Arguments:
**    _instrumentID             Instrument ID
**    _datasetID                Dataset ID (optional); if defined, use the Created value of the dataset for the reference date
**    _autoSwitchActiveArchive  When true, if the archive path differs from the instrument's currently assigned archive path, update the assigned path
**    _infoOnly                 When true, preview updates
**
**  Returns:
**      The archive path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/11/2011 mem - Initial Version
**          05/12/2011 mem - Added _datasetID and _autoSwitchActiveArchive
**          05/16/2011 mem - Now filtering T_Archive_Path using only AP_Function IN ('Active', 'Old') when auto-defining the archive path
**          02/23/2016 mem - Add set XACT_ABORT on
**          07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov
**          04/24/2023 mem - Ported to PostgreSQL
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/22/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/05/2023 mem - Archive path is now agate.emsl.pnl.gov
**
*****************************************************/
DECLARE
    _archivePathID int;
    _archivePathIDText text;
    _message text;
    _returnCode text;
    _instrumentInfo record;
    _callingProcName text;
    _currentLocation text;
    _currentYear int;
    _currentQuarter int;
    _archivePathName text;
    _refDate timestamp;
    _suffix text;
    _networkSharePath text;
    _archiveFunction text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _currentLocation := 'Start';

    BEGIN

        _archivePathID := 0;

        -----------------------------------------
        -- See if this instrument has Auto_Define_Storage_Path enabled
        -----------------------------------------

        SELECT auto_define_storage_path             As AutoDefineStoragePath,    -- This is stored as an integer in t_instrument_name
               auto_sp_archive_server_name::text    As AutoSPArchiveServerName,
               auto_sp_archive_path_root            As AutoSPArchivePathRoot,
               auto_sp_archive_share_path_root      As AutoSPArchiveSharePathRoot,
               instrument::text                     As InstrumentName
        INTO _instrumentInfo
        FROM t_instrument_name
        WHERE instrument_id = _instrumentID;

        If FOUND And Coalesce(_instrumentInfo.AutoDefineStoragePath, 0) = 0 Then

            -- Use the archive path defined in t_archive_path for _instrumentID
            --
            SELECT archive_path_id
            INTO _archivePathID
            FROM t_archive_path
            WHERE archive_path_function = 'Active' AND
                  instrument_id = _instrumentID;

            RETURN Coalesce(_archivePathID, 0);
        End If;

        _currentLocation := 'Auto-defining archive path';

        -- Validate the _autoSP variables
        If Coalesce(_instrumentInfo.AutoSPArchiveServerName, '') = '' Or
           Coalesce(_instrumentInfo.AutoSPArchivePathRoot, '') = '' Or
           Coalesce(_instrumentInfo.AutoSPArchiveSharePathRoot, '') = '' Then

            _message := format('One or more Auto_SP fields are empty or null for instrument %s; unable to auto-define the archive path', _instrumentInfo.InstrumentName);

            If _infoOnly Then
                RAISE WARNING '%', _message;
            Else
                CALL post_log_entry ('Error', _message, 'Get_Instrument_Archive_Path_For_New_Datasets');
            End If;

            RETURN 0;
        End If;

        -----------------------------------------
        -- Define the ArchivePath and NetworkSharePath
        -- Archive path will look like /archive/dmsarch/VOrbiETD02/2011_2
        -- NetworkSharePath will look like \\agate.emsl.pnl.gov\dmsarch\VOrbiETD02\2011_2
        -----------------------------------------

        If Coalesce(_datasetID, 0) > 0 Then
            SELECT Coalesce(Created, CURRENT_TIMESTAMP)
            INTO _refDate
            FROM t_dataset
            WHERE dataset_id = _datasetID;
        Else
            _refDate := CURRENT_TIMESTAMP;
        End If;

        _currentYear    := Extract(year    from _refDate);
        _currentQuarter := Extract(quarter from _refDate);

        _suffix := format('%s_%s', _currentYear, _currentQuarter);

        _archivePathName := _instrumentInfo.AutoSPArchivePathRoot;

        If Right(_archivePathName, 1) <> '/' Then
            _archivePathName := format('%s/', _archivePathName);
        End If;

        _archivePathName := format('%s%s', _archivePathName, _suffix);

        _networkSharePath := _instrumentInfo.AutoSPArchiveSharePathRoot;

        If Right(_networkSharePath, 1) <> '\' Then
            _networkSharePath := format('%s\', _networkSharePath);
        End If;

        _networkSharePath := format('%s%s', _networkSharePath, _suffix);

        -----------------------------------------
        -- Look for existing entry in t_archive_path
        -- Limit to Active entries only if _autoSwitchActiveArchive is true
        -----------------------------------------

        SELECT archive_path_id
        INTO _archivePathID
        FROM t_archive_path
        WHERE archive_path = _archivePathName AND
              archive_path_function IN ('Active', 'Old');

        If FOUND Then
            If _infoOnly Then
                RAISE INFO 'Auto-defined archive path "%" matched in t_archive_path; ID=%', _archivePathName, _archivePathID;
            End If;

            RETURN Coalesce(_archivePathID, 0);
        End If;

        -- Path not found; add if _infoOnly is false
        If _infoOnly Then
            RAISE INFO 'Auto-defined archive path "%" not found t_archive_path; need to add it', _archivePathName;
            RETURN 0;
        End If;

        _currentLocation := format('Call add_update_archive_path to add %s', _archivePathName);

        If _autoSwitchActiveArchive Then
            _archiveFunction := 'Active';
        Else
            _archiveFunction := 'Old';
        End If;

        _archivePathIDText := _archivePathID::text;

        CALL public.add_update_archive_path (
                          _archivePathID    => _archivePathIDText,  -- Input/Output
                          _archivePath      => _archivePathName,
                          _archiveServer    => _instrumentInfo.AutoSPArchiveServerName,
                          _instrumentName   => _instrumentInfo.InstrumentName,
                          _networkSharePath => _networkSharePath,
                          _archiveNote      => _instrumentInfo.InstrumentName,
                          _archiveFunction  => _archiveFunction,
                          _mode             => 'add',
                          _message          => _message,            -- Output
                          _returnCode       => _returnCode);        -- Output

        _archivePathID := public.try_cast(_archivePathIDText, 0);

        -----------------------------------------
        -- Return the archive path ID
        -----------------------------------------

        RETURN Coalesce(_archivePathID, 0);

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

        RAISE WARNING '%', _message;
    END;

    RETURN 0;
END
$$;


ALTER FUNCTION public.get_instrument_archive_path_for_new_datasets(_instrumentid integer, _datasetid integer, _autoswitchactivearchive boolean, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_archive_path_for_new_datasets(_instrumentid integer, _datasetid integer, _autoswitchactivearchive boolean, _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_archive_path_for_new_datasets(_instrumentid integer, _datasetid integer, _autoswitchactivearchive boolean, _infoonly boolean) IS 'GetInstrumentArchivePathForNewDatasets';

