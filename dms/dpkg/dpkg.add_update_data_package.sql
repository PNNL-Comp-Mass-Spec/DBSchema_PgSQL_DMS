--
-- Name: add_update_data_package(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.add_update_data_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _comment text, IN _owner text, IN _requester text, IN _state text, IN _team text, IN _masstagdatabase text, IN _datadoi text, IN _manuscriptdoi text, INOUT _prismwikilink text, INOUT _creationparams text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing item in dpkg.t_data_package
**
**  Arguments:
**    _id               Data package ID
**    _name             Data package name
**    _packageType      Data package type ('General' or 'Software Testing')
**    _description      Data package description
**    _comment          Comment
**    _owner            Owner username
**    _requester        Requester username
**    _state            State ('Active', 'Complete', 'Inactive', or 'Future')
**    _team             Team ('Public', 'NIH_Section', etc.)
**    _massTagDatabase  AMT tag database
**    _dataDOI          Digital Object Identifier for the data
**    _manuscriptDOI    Digital Object Identifier for the manuscript
**    _prismWikiLink    PRISMWiki page URL
**    _creationParams   Creation parameters (unused)
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   05/21/2009 grk
**          05/29/2009 mem - Updated to support Package_File_Folder not allowing null values
**          06/04/2009 grk - Added parameter _creationParams
**                         - Updated to call Make_Data_Package_Storage_Folder
**          06/05/2009 grk - Added parameter _prismWikiLink, which is used to populate the Wiki_Page_Link field
**          06/08/2009 mem - Now validating _team and _packageType
**          06/09/2009 mem - Now warning user if the team name is changed
**          06/11/2009 mem - Now warning user if the data package name already exists
**          06/11/2009 grk - Added Requester field
**          07/01/2009 mem - Expanced _massTagDatabase to varchar(1024)
**          10/23/2009 mem - Expanded _prismWikiLink to varchar(1024)
**          03/17/2011 mem - Removed extra, unused parameter from Make_Data_Package_Storage_Folder
**                         - Now only calling Make_Data_Package_Storage_Folder when _mode is 'add'
**          08/31/2015 mem - Now replacing the symbol & with 'and' in the name when _mode is 'add'
**          02/19/2016 mem - Now replacing a semicolon with a comma when _mode is 'add'
**          10/18/2016 mem - Call update_data_package_eus_info
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          06/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**                         - Validate _state
**          11/19/2020 mem - Add _dataDOI and _manuscriptDOI
**          07/05/2022 mem - Include the data package ID when logging errors
**          05/10/2023 mem - Update warning messages
**          08/15/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Update warning messages
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchingValue text;
    _currentID int;
    _currentTeam text;
    _teamChangeWarning text;
    _pkgFileFolder text;
    _logErrors boolean := false;
    _storagePathID int;
    _msg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _teamChangeWarning := '';

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

        _team        := Trim(Coalesce(_team, ''));
        _packageType := Trim(Coalesce(_packageType, ''));
        _description := Trim(Coalesce(_description, ''));
        _comment     := Trim(Coalesce(_comment, ''));
        _mode        := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode In ('add', 'update') Then
            _message := 'Mode must be "add" or "update"';
            _returnCode := 'U5103';
            RETURN;
        End If;

        If _mode = 'update' And Coalesce(_id, 0) = 0 Then
            _message := 'Data package ID cannot be null or 0 when mode is "update"';
            _returnCode := 'U5104';
            RETURN;
        End If;

        If _team = '' Then
            _message := 'Data package team must be specified';
            _returnCode := 'U5105';
            RETURN;
        End If;

        If _packageType = '' Then
            _message := 'Data package type must be specified';
            _returnCode := 'U5106';
            RETURN;
        End If;

        -- Make sure the team name is valid (and capitalize it, if necessary)
        SELECT team_name
        INTO _matchingValue
        FROM dpkg.t_data_package_teams
        WHERE team_name = _team::citext;

        If Not Found Then
            _message := format('Invalid data package team: %s', _team);
            _returnCode := 'U5107';
            RETURN;
        Else
            _team := _matchingValue;
        End If;

        -- Make sure the data package type is valid (and capitalize it, if necessary)
        SELECT package_type
        INTO _matchingValue
        FROM dpkg.t_data_package_type
        WHERE package_type = _packageType::citext;

        If Not Found Then
            _message := format('Invalid data package type: %s', _packageType);
            _returnCode := 'U5108';
            RETURN;
        Else
            _packageType := _matchingValue;
        End If;

        ---------------------------------------------------
        -- Get active path
        ---------------------------------------------------

        SELECT path_id
        INTO _storagePathID
        FROM dpkg.t_data_package_storage
        WHERE state = 'Active';

        If Not Found Then
            _message := 'Table dpkg.t_data_package_storage does not have an active storage path';
            _returnCode := 'U5109';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate the state
        ---------------------------------------------------

        SELECT state_name
        INTO _matchingValue
        FROM dpkg.t_data_package_state
        WHERE state_name = _state::citext;

        If Not Found Then
            _message := format('Invalid state: %s', _state);
            _returnCode := 'U5110';
            RETURN;
        Else
            _state := _matchingValue;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            SELECT data_pkg_id,
                   path_team
            INTO _currentID, _currentTeam
            FROM dpkg.t_data_package
            WHERE data_pkg_id = _id;

            If Not FOUND Then
                _message := format('Data package ID %s does not exist; cannot update', _id);
                _returnCode := 'U5111';
                RETURN;
            End If;

            -- Warn if the user is changing the team
            If Coalesce(_currentTeam, '') <> '' And _currentTeam <> _team Then
                _teamChangeWarning := format('Warning: Team changed from "%s" to "%s"; the data package files will need to be moved from the old location to the new one', _currentTeam, _team);
            End If;

        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            If _name Like '%&%' Then
                -- Replace & with 'and'

                If _name::citext SIMILAR TO '%[a-z0-9]&[a-z0-9]%' Then
                    If _name Like '% %' Then
                        _name := Replace(_name, '&', ' and ');
                    Else
                        _name := Replace(_name, '&', '_and_');
                    End If;
                Else
                    _name := Replace(_name, '&', 'and');
                End If;
            End If;

            If _name Like '%;%' Then
                -- Replace each semicolon with a comma
                _name := Replace(_name, ';', ',');
            End If;

            -- Make sure the data package name doesn't already exist
            If Exists (SELECT package_name FROM dpkg.t_data_package WHERE package_name = _name::citext) Then
                _message := format('Data package "%s" already exists; cannot create an identically named data package', _name);
                _returnCode := 'U5112';
                RETURN;
            End If;

            INSERT INTO dpkg.t_data_package (
                package_name,
                package_type,
                description,
                comment,
                owner_username,
                requester,
                created,
                state,
                package_folder,
                storage_path_id,
                path_team,
                mass_tag_database,
                wiki_page_link,
                data_doi,
                manuscript_doi
            ) VALUES (
                _name,
                _packageType,
                _description,
                _comment,
                _owner,
                _requester,
                CURRENT_TIMESTAMP,
                _state,
                gen_random_uuid()::text,        -- package_folder cannot be null and must be unique; this guarantees both. Also, we'll rename it below using dpkg.make_package_folder_name()
                _storagePathID,
                _team,
                _massTagDatabase,
                Coalesce(_prismWikiLink, ''),
                _dataDOI,
                _manuscriptDOI
            )
            RETURNING data_pkg_id
            INTO _id;

            ---------------------------------------------------
            -- Data package folder and wiki page auto naming
            ---------------------------------------------------

            _pkgFileFolder := dpkg.make_package_folder_name(_id, _name);
            _prismWikiLink := dpkg.make_prismwiki_page_link(_name);

            UPDATE dpkg.t_data_package
            SET package_folder = _pkgFileFolder,
                wiki_page_link = _prismWikiLink
            WHERE data_pkg_id = _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE dpkg.t_data_package
            SET package_name = _name,
                package_type = _packageType,
                description = _description,
                comment = _comment,
                owner_username = _owner,
                requester = _requester,
                last_modified = CURRENT_TIMESTAMP,
                state = _state,
                path_team = _team,
                mass_tag_database = _massTagDatabase,
                wiki_page_link = _prismWikiLink,
                data_doi = _dataDOI,
                manuscript_doi = _manuscriptDOI
            WHERE data_pkg_id = _id;

        End If;

        ---------------------------------------------------
        -- Create the data package folder when adding a new data package
        ---------------------------------------------------

        If _mode = 'add' Then
            CALL dpkg.make_data_package_storage_folder (
                        _id,
                        _infoOnly   => false,
                        _message    => _msg,            -- Output
                        _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := public.append_to_text(_message, _msg);
            End If;
        End If;

        If _teamChangeWarning <> '' Then
            _message := public.append_to_text(_message, _teamChangeWarning);
        End If;

        ---------------------------------------------------
        -- Update EUS_Person_ID and EUS_Proposal_ID
        ---------------------------------------------------

        CALL dpkg.update_data_package_eus_info (
                    _id::text,                      -- _dataPackageList
                    _message    => _msg,            -- Output
                    _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            _message := public.append_to_text(_message, _msg);
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If Coalesce(_id, 0) > 0 And Position(format('ID %s', _id) In _exceptionMessage) = 0 Then
                _exceptionMessage := format('%s; Data Package ID %s', _exceptionMessage, _id);
            End If;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
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


ALTER PROCEDURE dpkg.add_update_data_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _comment text, IN _owner text, IN _requester text, IN _state text, IN _team text, IN _masstagdatabase text, IN _datadoi text, IN _manuscriptdoi text, INOUT _prismwikilink text, INOUT _creationparams text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_data_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _comment text, IN _owner text, IN _requester text, IN _state text, IN _team text, IN _masstagdatabase text, IN _datadoi text, IN _manuscriptdoi text, INOUT _prismwikilink text, INOUT _creationparams text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.add_update_data_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _comment text, IN _owner text, IN _requester text, IN _state text, IN _team text, IN _masstagdatabase text, IN _datadoi text, IN _manuscriptdoi text, INOUT _prismwikilink text, INOUT _creationparams text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateDataPackage';

