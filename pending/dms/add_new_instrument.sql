--
CREATE OR REPLACE PROCEDURE public.add_new_instrument
(
    _instrumentName text,
    _instrumentClass text,
    _instrumentGroup text,
    _captureMethod text,
    _roomNumber text,
    _description text,
    _usage text,
    _operationsRole text,
    _percentEMSLOwned text,
    _autoDefineStoragePath text = 'No',
    _sourceMachineName text,
    _sourcePath text,
    _spPath text,
    _spVolClient  text,
    _spVolServer  text,
    _archivePath text,
    _archiveServer text,
    _archiveNote text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new instrument to database and new storage paths to storage table
**
**  Arguments:
**    _instrumentName          Name of new instrument
**    _instrumentClass         Class of instrument
**    _captureMethod           Capture method of instrument
**    _roomNumber              Where new instrument is located
**    _description             Description of instrument
**    _sourceMachineName       Source Machine to capture data from
**    _sourcePath              Transfer directory on source machine
**    _spPath                  Storage path on Storage Server; treated as _autoSPPathRoot if _autoDefineStoragePath is yes (e.g. Lumos01\)
**    _spVolClient             Storage server name, e.g. \\proto-8\
**    _spVolServer             Drive letter on storage server (local to server itself), e.g. F:\
**    _archivePath             Storage path on EMSL archive, e.g.
**    _archiveServer           Archive server name
**    _archiveNote             Note describing archive path
**    _usage                   Optional description of instrument usage
**    _operationsRole          Production, QC, Research, or Unused
**    _instrumentGroup         Item in T_Instrument_Group
**    _percentEMSLOwned        % of instrument owned by EMSL; number between 0 and 100
**    _autoDefineStoragePath   Set to Yes to enable auto-defining the storage path based on the _spPath and _archivePath related parameters
**
**  Auth:   grk
**  Date:   01/26/2001
**          07/24/2001 grk - Added Archive Path setup
**          03/12/2003 grk - Modified to call Add_Update_Storage:
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _spSourcePathID int;
    _spStoragePathID int;
    _percentEMSLOwnedVal int;
    _hit int;
    _archiveNetworkSharePath text;
    _autoDefineStoragePathBool boolean := false;
    _autoSPVolNameClient text;
    _autoSPVolNameServer text;
    _autoSPPathRoot text;
    _autoSPUrlDomain text := 'pnl.gov';
    _autoSPArchiveServerName text;
    _autoSPArchivePathRoot text;
    _autoSPArchiveSharePathRoot text;
    _instrumentId int;
    _sourceMachineNameToFind text;
    _hostName text;
    _suffix text;
    _periodLoc Int;
    _logMessage text;
    _aID int;
BEGIN
    _message := '';
    _returnCode := '';

    _spSourcePathID := 2; -- valid reference to 'na' storage path for initial entry
    _spStoragePathID := 2; -- valid reference to 'na' storage path for initial entry

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    _autoDefineStoragePath := Coalesce(_autoDefineStoragePath, 'No');

    _percentEMSLOwnedVal := Round(public.try_cast(_percentEMSLOwned, null::numeric))::int;

    If _percentEMSLOwnedVal Is Null Then
        RAISE EXCEPTION 'Percent EMSL Owned should be a number between 0 and 100';
    End If;

    If _percentEMSLOwnedVal < 0 Or _percentEMSLOwnedVal > 100 Then
        RAISE EXCEPTION 'Percent EMSL Owned should be a number between 0 and 100';
    End If;

    ---------------------------------------------------
    -- Make sure instrument is not already in instrument table
    ---------------------------------------------------

    SELECT instrument_id
    INTO _hit
    FROM t_instrument_name
    WHERE instrument = _instrumentName;

    If FOUND Then
        RAISE EXCEPTION 'Instrument name already in use';
    End If;

    ---------------------------------------------------
    -- Derive shared path name
    ---------------------------------------------------

    _archiveNetworkSharePath := format('\%s', REPLACE(REPLACE(_archivePath, 'archive', 'adms.emsl.pnl.gov'), '/', '\'));

    ---------------------------------------------------
    -- Resolve Yes/No parameters to 0 or 1
    ---------------------------------------------------

    If _autoDefineStoragePath = 'Yes' Or _autoDefineStoragePath = 'Y' OR _autoDefineStoragePath = '1' Then
        _autoDefineStoragePathBool := true;
    Else
        _autoDefineStoragePathBool := false;
    End If;

    ---------------------------------------------------
    -- Define the _autoSP variables
    -- Auto-populate if _autoDefineStoragePathBool is true
    ---------------------------------------------------

    If _autoDefineStoragePathBool Then
        _autoSPVolNameClient := _spVolClient;
        _autoSPVolNameServer := _spVolServer;
        _autoSPPathRoot := _spPath;
        _autoSPArchiveServerName := _archiveServer;
        _autoSPArchivePathRoot := _archivePath;
        _autoSPArchiveSharePathRoot := _archiveNetworkSharePath;

        If Coalesce(_autoSPVolNameClient, '') <> '' AND _autoSPVolNameClient NOT LIKE '%\' Then
            -- Auto-add a slash;
        End If;
            _autoSPVolNameClient := format('%s\', _autoSPVolNameClient);

        If Coalesce(_autoSPVolNameServer, '') <> '' AND _autoSPVolNameServer NOT LIKE '%\' Then
            -- Auto-add a slash;
        End If;
            _autoSPVolNameServer := format('%s\', _autoSPVolNameServer);

        ---------------------------------------------------
        -- Validate the _autoSP parameteres
        ---------------------------------------------------

        CALL validate_auto_storage_path_params (_autoDefineStoragePathBool, _autoSPVolNameClient, _autoSPVolNameServer,
                                                _autoSPPathRoot, _autoSPArchiveServerName,
                                                _autoSPArchivePathRoot, _autoSPArchiveSharePathRoot);

    End If;

    ---------------------------------------------------
    -- Add new instrument to instrument table
    ---------------------------------------------------

    -- Get new instrument ID
    --
    SELECT Coalesce(MAX(instrument_id), 0) + 1
    INTO _instrumentId
    FROM t_instrument_name ;

    -- Make entry into instrument table
    --
    INSERT INTO t_instrument_name(
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
    ) VALUES (
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

    _sourceMachineNameToFind := replace(_sourceMachineName, '\', '');

    If Not Exists (Select * From t_storage_path_hosts Where sp_machine_name = _sourceMachineNameToFind) Then
        _periodLoc := Position('.' In _sourceMachineNameToFind);
        If _periodLoc > 1 Then
            _hostName := Substring(_sourceMachineNameToFind, 1, _periodLoc-1);
            _suffix := Substring(_sourceMachineNameToFind, _periodLoc, char_length(_sourceMachineNameToFind));
        Else
            _hostName := _sourceMachineNameToFind;
            _suffix := '.pnl.gov';
        End If;

        INSERT INTO t_storage_path_hosts ( sp_machine_name, host_name, dns_suffix, URL_Prefix)
        VALUES (_sourceMachineNameToFind, _hostName, _suffix, 'https://')

        _logMessage := format('Added machine %s to t_storage_path_hosts with host name %s', _sourceMachineNameToFind, _hostName);

        CALL post_log_entry ('Normal', _logMessage, 'Add_New_Instrument');
    End If;

    If _valAutoDefineStoragePath Then
        _returnCode := '';
    Else
        ---------------------------------------------------
        -- Make new raw storage directory in storage table
        ---------------------------------------------------

        CALL add_update_storage (
                _spPath,
                _spVolClient,
                _spVolServer,
                'raw-storage',
                _instrumentName,
                '(na)',
                _autoSPUrlDomain,
                _spStoragePathID,               -- Output
                'add',
                _message => _message,           -- Output
                _returnCode => _returnCode);    -- Output
    End If;

    --
    If _returnCode <> '' Then
        ROLLBACK;

        RAISE EXCEPTION 'Creating storage path was unsuccessful for add instrument';
    End If;

    ---------------------------------------------------
    -- Make new source (inbox) directory in storage table
    ---------------------------------------------------

    CALL add_update_storage (
            _sourcePath,
            '(na)',
            _sourceMachineName,     -- Note that Add_Update_Storage will remove '\' characters from _sourceMachineName since _storFunction = 'inbox'
            'inbox',
            _instrumentName,
            '(na)',
            '',
            _spStoragePathID,               -- Output
            'add',
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

    --
    If _returnCode <> '' Then
        ROLLBACK;

        RAISE EXCEPTION 'Creating source path was unsuccessful for add instrument';
    End If;

    If _valAutoDefineStoragePath = 0 Then
    -- <a>
        ---------------------------------------------------
        -- Add new archive storage path for new instrument
        ---------------------------------------------------

        -- Get new archive ID
        --
        --
        -- Insert new archive path
        --
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
        INTO _aID;
    End If; -- </a>

END
$$;

COMMENT ON PROCEDURE public.add_new_instrument IS 'AddNewInstrument';
