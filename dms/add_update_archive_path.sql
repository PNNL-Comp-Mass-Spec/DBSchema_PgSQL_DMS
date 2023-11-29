--
-- Name: add_update_archive_path(text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_archive_path(INOUT _archivepathid text, IN _archivepath text, IN _archiveserver text, IN _instrumentname text, IN _networksharepath text, IN _archivenote text, IN _archivefunction text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing archive paths in database
**
**  Arguments:
**    _archivePathID    ID value (as a string)
**    _mode             'add' or 'update'
**
**  Auth:   jds
**  Date:   06/24/2004 jds - Initial release
**          12/29/2008 grk - Added _networkSharePath (http://prismtrac.pnl.gov/trac/ticket/708)
**          05/11/2011 mem - Expanded _archivePath, _archiveServer, _networkSharePath, and _archiveNote to larger varchar() variables
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/16/2022 mem - Change RAISERROR severity to 11 (required so that the web page shows the error message)
**          04/24/2023 mem - Ported to PostgreSQL
**          05/11/2023 mem - Update return code
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/07/2023 mem - Align assignment statements
**                         - Update warning messages
**          09/08/2023 mem - Adjust capitalization of keywords
**                         - Include schema name when calling function verify_sp_authorized()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _archivePathIDValue int;
    _archiveIdCheck int;
    _instrumentID int;
    _tempArchiveID int;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _instrumentName  := Trim(Coalesce(_instrumentName, ''));
    _archivePath     := Trim(Coalesce(_archivePath, ''));
    _archiveFunction := Trim(Coalesce(_archiveFunction, ''));

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _instrumentName = '' Then
        _returnCode := 'U5201';
        RAISE EXCEPTION 'Instrument Name must be specified';
    End If;

    If _archivePath = '' Then
        RAISE EXCEPTION 'Archive Path must be specified';
    End If;

    If _archiveFunction = '' Then
        RAISE EXCEPTION 'Archive Function must be specified';
    End If;

    _archivePathIDValue := public.try_cast(_archivePathID, 0);

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT archive_path_id
    INTO _archiveIdCheck
    FROM t_archive_path
    WHERE archive_path = _archivePath;

    -- Cannot create an entry that already exists
    --
    If FOUND And _mode = 'add' Then
        RAISE EXCEPTION 'Cannot add: Archive Path "%" already in database ', _archivePath;
    End If;

    ---------------------------------------------------
    -- Resolve instrument ID
    ---------------------------------------------------

    _instrumentID := public.get_instrument_id(_instrumentName);

    If _instrumentID = 0 Then
        RAISE EXCEPTION 'Could not find entry in database for instrument "%"', _instrumentName;
    End If;

    ---------------------------------------------------
    -- Resolve Archive function
    ---------------------------------------------------

    -- Do not allow changing 'Active' to non active
    --
    If _archiveFunction::citext <> 'Active' Then

        If Exists ( SELECT archive_path_id
                    FROM t_archive_path
                    WHERE archive_path_id = _archivePathIDValue AND archive_path_function = 'Active'
                  ) Then

            RAISE EXCEPTION 'Cannot set archive path to non Active for instrument "%"', _instrumentName;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for active instrument
    ---------------------------------------------------

    -- Check for active instrument to prevent multiple Active paths for an instrument
    --
    If _archiveFunction::citext = 'Active' And Exists (
            SELECT InstName.instrument_id
            FROM t_instrument_name InstName
                 INNER JOIN t_archive_path ArchPath
                   ON InstName.instrument_id = ArchPath.instrument_id AND
                      InstName.instrument = _instrumentName AND
                      ArchPath.archive_path_function = 'Active') Then

        UPDATE t_archive_path
        SET archive_path_function = 'Old'
        WHERE archive_path_id In (
                SELECT ArchPath.archive_path_id
                FROM t_instrument_name InstName
                     INNER JOIN t_archive_path ArchPath
                       ON InstName.instrument_id = ArchPath.instrument_id AND
                          InstName.instrument = _instrumentName AND
                          archive_path_function = 'Active');
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    -- Insert new archive path
    --
    If _mode = 'add' Then

        INSERT INTO t_archive_path (
            archive_path,
            archive_server_name,
            instrument_id,
            network_share_path,
            note,
            archive_path_function
        ) VALUES (
            _archivePath,
            _archiveServer,
            _instrumentID,
            _networkSharePath,
            _archiveNote,
            _archiveFunction
        )
        RETURNING archive_path_id
        INTO _archivePathID;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_archive_path
        SET
            archive_path = _archivePath,
            archive_server_name = _archiveServer,
            instrument_id = _instrumentID,
            network_share_path = _networkSharePath,
            note = _archiveNote,
            archive_path_function = _archiveFunction
        WHERE archive_path_id = _archivePathIDValue;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_archive_path(INOUT _archivepathid text, IN _archivepath text, IN _archiveserver text, IN _instrumentname text, IN _networksharepath text, IN _archivenote text, IN _archivefunction text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_archive_path(INOUT _archivepathid text, IN _archivepath text, IN _archiveserver text, IN _instrumentname text, IN _networksharepath text, IN _archivenote text, IN _archivefunction text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_archive_path(INOUT _archivepathid text, IN _archivepath text, IN _archiveserver text, IN _instrumentname text, IN _networksharepath text, IN _archivenote text, IN _archivefunction text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateArchivePath';

