--
-- Name: add_new_instrument(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_new_instrument(IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text DEFAULT 'No'::text, IN _sourcemachinename text DEFAULT ''::text, IN _sourcepath text DEFAULT ''::text, IN _sppath text DEFAULT ''::text, IN _spvolclient text DEFAULT ''::text, IN _spvolserver text DEFAULT ''::text, IN _archivepath text DEFAULT ''::text, IN _archiveserver text DEFAULT ''::text, IN _archivenote text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new instrument to the database and new storage paths to the storage paths table
**
**  Arguments:
**    _instrumentName               Name of new instrument
**    _instrumentClass              Instrument class
**    _instrumentGroup              Instrument group
**    _captureMethod                Capture method: 'secfso' for bionet instruments, 'fso' for instruments on the pnl.gov domain
**    _roomNumber                   Room number, e.g. 'BSF 1217', 'EMSL 1526', or 'Offsite'
**    _description                  Instrument description
**    _usage                        Optional description of instrument usage
**    _operationsRole               Operations role: 'Research', 'Production', or 'Offsite'
**    _percentEMSLOwned             Percent of instrument owned by EMSL; number between 0 and 100
**    _autoDefineStoragePath        Set to 'Yes' to enable auto-defining the storage path based on the _spPath and _archivePath related parameters
**    _sourceMachineName            Source machine to capture data from,  e.g. Lumos02.bionet
**    _sourcePath                   Transfer directory on source machine, e.g. ProteomicsData\
**    _spPath                       Storage path (share name) on storage server; treated as _autoSPPathRoot if _autoDefineStoragePath is 'Yes' (e.g. Lumos01\)
**    _spVolClient                  Storage server name,                                     e.g. \\proto-8\
**    _spVolServer                  Drive letter on storage server (local to server itself), e.g. F:\
**    _archivePath                  Storage path on EMSL archive (obsolete),                 e.g. /archive/dmsarch/Lumos01
**    _archiveServer                Archive server name          (obsolete),                 e.g. agate.emsl.pnl.gov
**    _archiveNote                  Note describing archive path
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   grk
**  Date:   01/26/2001
**          07/24/2001 grk - Added archive path setup
**          03/12/2003 grk - Modified to call Add_Update_Storage
**          11/06/2003 grk - Modified to handle new ID for archive path independent of instrument id
**          01/30/2004 grk - Modified to return message (grk)
**          02/24/2004 grk - Fixed problem inserting first entry into empty tables
**          07/01/2004 grk - Modified the function to add records to T_Archive_Path table
**          12/14/2005 grk - Added check for existing instrument
**          04/07/2006 grk - Got rid of CDBurn stuff
**          06/28/2006 grk - Added support for Usage and Operations Role fields
**          12/11/2008 grk - Fixed problem with NULL _usage
**          12/14/2008 grk - Fixed problem with select result being inadvertently returned
**          01/05/2009 grk - Added _archiveNetworkSharePath (http://prismtrac.pnl.gov/trac/ticket/709)
**          01/05/2010 grk - Added _allowedDatasetTypes (http://prismtrac.pnl.gov/trac/ticket/752)
**          02/12/2010 mem - Now calling Update_Instrument_Allowed_Dataset_Type for each dataset type in _allowedDatasetTypes
**          05/25/2010 dac - Updated archive paths for switch from nwfs to aurora
**          08/30/2010 mem - Replaced parameter _allowedDatasetTypes with _instrumentGroup
**          05/12/2011 mem - Added _autoDefineStoragePath
**                         - Expanded _archivePath, _archiveServer, and _archiveNote to larger varchar() variables
**          05/13/2011 mem - Now calling Validate_Auto_Storage_Path_Params
**          11/30/2011 mem - Added parameter _percentEMSLOwned
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov
**          05/03/2019 mem - Add the source machine to T_Storage_Path_Hosts
**          10/27/2020 mem - Populate Auto_SP_URL_Domain and store https:// in T_Storage_Path_Hosts.URL_Prefix
**                           Pass _urlDomain to Add_Update_Storage
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          09/01/2023 mem - Expand _instrumentName to varchar(64), _description to varchar(1024), and _usage to varchar(128)
**          10/05/2023 mem - Archive path is now agate.emsl.pnl.gov
**                         - Ported to PostgreSQL
**          07/12/2024 mem - If _percentEMSLOwned is an empty string, treat it as 0%
**
*****************************************************/
DECLARE
    _spSourcePathID int;
    _spStoragePathID int;
    _percentEMSLOwnedVal int;
    _existingInstrumentID int;
    _archiveNetworkSharePath text;
    _autoDefineStoragePathBool boolean;
    _autoSPVolNameClient text;
    _autoSPVolNameServer text;
    _autoSPPathRoot text;
    _autoSPUrlDomain text := 'pnl.gov';
    _autoSPArchiveServerName text;
    _autoSPArchivePathRoot text;
    _autoSPArchiveSharePathRoot text;
    _instrumentId int;
    _sourceMachineNameToFind text;
    _sourcePathIdText text;
    _storagePathIdText text;
    _hostName text;
    _suffix text;
    _periodLoc Int;
    _logMessage text;
    _archivePathID int;
BEGIN
    _message := '';
    _returnCode := '';

    -- Initially set _spSourcePathID and _spStoragePathID to the storage path ID for '(none)'

    SELECT storage_path_id
    INTO _spSourcePathID            -- This should be id = 2
    FROM t_storage_path
    WHERE storage_path = '(none)'
    ORDER BY storage_path_id;

    If Not FOUND Then
        RAISE EXCEPTION 'Table t_storage_path does not have a storage path named "(none)"';
    End If;

    _spStoragePathID := _spSourcePathID;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _instrumentName        := Trim(Coalesce(_instrumentName, ''));
    _description           := Trim(Coalesce(_description, ''));
    _usage                 := Trim(Coalesce(_usage, ''));
    _autoDefineStoragePath := Trim(Coalesce(_autoDefineStoragePath, 'No'));

    _percentEMSLOwnedVal := Round(public.try_cast(_percentEMSLOwned, 0.0::numeric))::int;

    If _percentEMSLOwnedVal Is Null Or _percentEMSLOwnedVal < 0 Or _percentEMSLOwnedVal > 100 Then
        RAISE EXCEPTION 'Percent EMSL Owned should be a number between 0 and 100';
    End If;

    ---------------------------------------------------
    -- Make sure instrument is not already in instrument table
    ---------------------------------------------------

    SELECT instrument_id
    INTO _existingInstrumentID
    FROM t_instrument_name
    WHERE instrument = _instrumentName::citext;

    If FOUND Then
        RAISE EXCEPTION 'Instrument name "%" is already in use, ID %', _instrumentName, _existingInstrumentID;
    End If;

    ---------------------------------------------------
    -- Derive shared path name
    -- e.g., switch from '/archive/dmsarch/Lumos01' to '\\agate.emsl.pnl.gov\dmsarch\Lumos01'
    ---------------------------------------------------

    _archiveNetworkSharePath := format('\%s', Replace(Replace(_archivePath, 'archive', 'agate.emsl.pnl.gov'), '/', '\'));

    ---------------------------------------------------
    -- _autoDefineStoragePath should be 'Yes' or 'No'; convert to boolean
    ---------------------------------------------------

    -- Option 1, use boolean_text_to_integer()
    -- _autoDefineStoragePathBool = public.boolean_text_to_integer(_autoDefineStoragePath)::boolean

    -- Option 2, use try_cast()
    _autoDefineStoragePathBool = public.try_cast(_autoDefineStoragePath, false);

    ---------------------------------------------------
    -- Define the _autoSP variables
    -- Auto-populate if _autoDefineStoragePathBool is true
    ---------------------------------------------------

    If _autoDefineStoragePathBool Then
        _autoSPVolNameClient        := Trim(_spVolClient);
        _autoSPVolNameServer        := Trim(_spVolServer);
        _autoSPPathRoot             := Trim(_spPath);
        _autoSPArchiveServerName    := Trim(_archiveServer);
        _autoSPArchivePathRoot      := Trim(_archivePath);
        _autoSPArchiveSharePathRoot := Trim(_archiveNetworkSharePath);

        If Coalesce(_autoSPVolNameClient, '') <> '' And _autoSPVolNameClient Not Like '%\\' Then
            -- Auto-add a slash, e.g. change '\\proto-8' to '\\proto-8\'
            _autoSPVolNameClient := format('%s\', _autoSPVolNameClient);
        End If;

        If Coalesce(_autoSPVolNameServer, '') <> '' And _autoSPVolNameServer Not Like '%\\' Then
            -- Auto-add a slash, e.g. change 'F:' to 'F:\'
            _autoSPVolNameServer := format('%s\', _autoSPVolNameServer);
        End If;

        ---------------------------------------------------
        -- Validate the _autoSP parameters
        -- Procedure validate_auto_storage_path_params will raise an exception if there is a problem
        ---------------------------------------------------

        CALL public.validate_auto_storage_path_params (
                        _autoDefineStoragePath      => _autoDefineStoragePathBool,
                        _autoSPVolNameClient        => _autoSPVolNameClient,
                        _autoSPVolNameServer        => _autoSPVolNameServer,
                        _autoSPPathRoot             => _autoSPPathRoot,
                        _autoSPArchiveServerName    => _autoSPArchiveServerName,
                        _autoSPArchivePathRoot      => _autoSPArchivePathRoot,
                        _autoSPArchiveSharePathRoot => _autoSPArchiveSharePathRoot);

    End If;

    ---------------------------------------------------
    -- Add new instrument to instrument table
    ---------------------------------------------------

    -- Get new instrument ID

    SELECT Coalesce(MAX(instrument_id), 0) + 1
    INTO _instrumentId
    FROM t_instrument_name ;

    -- Make entry into instrument table

    INSERT INTO t_instrument_name (
        instrument,
        instrument_id,
        instrument_class,
        instrument_group,
        source_path_id,
        storage_path_id,
        capture_method,
        room_number,
        description,
        usage,
        operations_role,
        percent_emsl_owned,
        auto_define_storage_path,
        auto_sp_vol_name_client,
        auto_sp_vol_name_server,
        auto_sp_path_root,
        auto_sp_url_domain,
        auto_sp_archive_server_name,
        auto_sp_archive_path_root,
        auto_sp_archive_share_path_root
    )
    VALUES (
        _instrumentName,
        _instrumentId,
        _instrumentClass,
        _instrumentGroup,
        _spSourcePathID,
        _spStoragePathID,
        _captureMethod,
        _roomNumber,
        _description,
        Coalesce(_usage, ''),
        _operationsRole,
        _percentEMSLOwnedVal,
        CASE WHEN _autoDefineStoragePathBool THEN 1 ELSE 0 END,
        _autoSPVolNameClient,
        _autoSPVolNameServer,
        _autoSPPathRoot,
        _autoSPUrlDomain,
        _autoSPArchiveServerName,
        _autoSPArchivePathRoot,
        _autoSPArchiveSharePathRoot
    );

    ---------------------------------------------------
    -- Make sure the source machine exists in t_storage_path_hosts
    ---------------------------------------------------

    _sourceMachineNameToFind := Replace(_sourceMachineName, '\', '');

    If Not Exists (SELECT machine_name FROM t_storage_path_hosts WHERE machine_name = _sourceMachineNameToFind::citext) Then
        _periodLoc := Position('.' In _sourceMachineNameToFind);

        If _periodLoc > 1 Then
            _hostName := Substring(_sourceMachineNameToFind, 1, _periodLoc - 1);
            _suffix   := Substring(_sourceMachineNameToFind, _periodLoc, char_length(_sourceMachineNameToFind));
        Else
            _hostName := _sourceMachineNameToFind;
            _suffix   := '.pnl.gov';
        End If;

        INSERT INTO t_storage_path_hosts (machine_name, host_name, dns_suffix, url_prefix)
        VALUES (_sourceMachineNameToFind, _hostName, _suffix, 'https://');

        _logMessage := format('Added machine %s to t_storage_path_hosts with host name %s', _sourceMachineNameToFind, _hostName);

        CALL post_log_entry ('Normal', _logMessage, 'Add_New_Instrument');
    End If;

    If _autoDefineStoragePathBool Then
        _returnCode := '';
    Else
        ---------------------------------------------------
        -- Make new raw storage directory in storage table
        ---------------------------------------------------

        _storagePathIdText := _spStoragePathID::text;

        CALL public.add_update_storage (
                _path           => _spPath,
                _volNameClient  => _spVolClient,
                _volNameServer  => _spVolServer,
                _storFunction   => 'raw-storage',
                _instrumentName => _instrumentName,
                _description    => '(na)',
                _urlDomain      => _autoSPUrlDomain,
                _id             => _storagePathIdText,      -- Input/Output, storage path ID (as text)
                _mode           => 'add',
                _message        => _message,                -- Output
                _returnCode     => _returnCode);            -- Output
    End If;

    If _returnCode <> '' Then
        ROLLBACK;

        RAISE EXCEPTION 'Creating dataset storage path was unsuccessful for new instrument';
    End If;

    ---------------------------------------------------
    -- Make new source (inbox) directory in storage table
    ---------------------------------------------------

    _sourcePathIdText := _spSourcePathID::text;

    CALL public.add_update_storage (
            _path           => _sourcePath,
            _volnameclient  => '(na)',
            _volnameserver  => _sourceMachineName,  -- Note that Add_Update_Storage will remove '\' characters from _sourceMachineName since _storFunction is 'inbox'
            _storfunction   => 'inbox',
            _instrumentname => _instrumentName,
            _description    => '(na)',
            _urldomain      => '',
            _id             => _sourcePathIdText,   -- Input/Output, source path ID (as text)
            _mode           => 'add',
            _message        => _message,            -- Output
            _returnCode     => _returnCode);        -- Output

    If _returnCode <> '' Then
        ROLLBACK;

        RAISE EXCEPTION 'Creating source path was unsuccessful for new instrument';
    End If;

    If Not _autoDefineStoragePathBool Then

        ---------------------------------------------------
        -- Add new archive storage path for new instrument
        ---------------------------------------------------

        INSERT INTO t_archive_path (
            instrument_id,
            archive_path,
            network_share_path,
            note,
            archive_server_name,
            archive_path_function
        ) VALUES (
            _instrumentId,
            _archivePath,
            _archiveNetworkSharePath,
            _archiveNote,
            _archiveServer,
            'Active'
        )
        RETURNING archive_path_id
        INTO _archivePathID;
    End If;

END
$$;


ALTER PROCEDURE public.add_new_instrument(IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text, IN _sourcemachinename text, IN _sourcepath text, IN _sppath text, IN _spvolclient text, IN _spvolserver text, IN _archivepath text, IN _archiveserver text, IN _archivenote text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_new_instrument(IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text, IN _sourcemachinename text, IN _sourcepath text, IN _sppath text, IN _spvolclient text, IN _spvolserver text, IN _archivepath text, IN _archiveserver text, IN _archivenote text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_new_instrument(IN _instrumentname text, IN _instrumentclass text, IN _instrumentgroup text, IN _capturemethod text, IN _roomnumber text, IN _description text, IN _usage text, IN _operationsrole text, IN _percentemslowned text, IN _autodefinestoragepath text, IN _sourcemachinename text, IN _sourcepath text, IN _sppath text, IN _spvolclient text, IN _spvolserver text, IN _archivepath text, IN _archiveserver text, IN _archivenote text, INOUT _message text, INOUT _returncode text) IS 'AddNewInstrument';

