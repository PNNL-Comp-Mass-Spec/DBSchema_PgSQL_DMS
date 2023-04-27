--
CREATE OR REPLACE PROCEDURE dpkg.add_update_data_package
(
    INOUT _id int,
    _name text,
    _packageType text,
    _description text,
    _comment text,
    _owner text,
    _requester text,
    _state text,
    _team text,
    _massTagDatabase text,
    _dataDOI text,
    _manuscriptDOI text,
    INOUT _prismWikiLink text,
    INOUT _creationParams text,
    _mode text = 'add',
    INOUT _message text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds new or edits existing T_Data_Package
**
**  Arguments:
**    _id     Data Package ID
**    _mode   or 'update'
**
**  Auth:   grk
**  Date:   05/21/2009 grk
**          05/29/2009 mem - Updated to support Package_File_Folder not allowing null values
**          06/04/2009 grk - Added parameter _creationParams
**                         - Updated to call MakeDataPackageStorageFolder
**          06/05/2009 grk - Added parameter _prismWikiLink, which is used to populate the Wiki_Page_Link field
**          06/08/2009 mem - Now validating _team and _packageType
**          06/09/2009 mem - Now warning user if the team name is changed
**          06/11/2009 mem - Now warning user if the data package name already exists
**          06/11/2009 grk - Added Requester field
**          07/01/2009 mem - Expanced _massTagDatabase to varchar(1024)
**          10/23/2009 mem - Expanded _prismWikiLink to varchar(1024)
**          03/17/2011 mem - Removed extra, unused parameter from MakeDataPackageStorageFolder
**                         - Now only calling MakeDataPackageStorageFolder when _mode = 'add'
**          08/31/2015 mem - Now replacing the symbol & with 'and' in the name when _mode = 'add'
**          02/19/2016 mem - Now replacing a semicolon with a comma when _mode = 'add'
**          10/18/2016 mem - Call UpdateDataPackageEUSInfo
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          06/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**                         - Validate _state
**          11/19/2020 mem - Add _dataDOI and _manuscriptDOI
**          07/05/2022 mem - Include the data package ID when logging errors
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _currentID int;
    _teamCurrent text;
    _teamChangeWarning text;
    _pkgFileFolder text;
    _logErrors int := 0;
    _authorized int := 0;
    _rootPath int;
    _msgForLog text := ERROR_MESSAGE();
BEGIN
    _teamChangeWarning := '';
    _message := '';

    BEGIN TRY

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Call _authorized => verify_sp_authorized 'AddUpdateDataPackage', _raiseError => 1
    If _authorized = 0 Then
        RAISERROR ('Access denied', 11, 3)
    End If;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _team := Coalesce(_team, '');
    _packageType := Coalesce(_packageType, '');
    _description := Coalesce(_description, '');
    _comment := Coalesce(_comment, '');

    If _team = '' Then
        _message := 'Data package team cannot be blank';
        RAISERROR (_message, 10, 1)
        return 51005
    End If;

    If _packageType = '' Then
        _message := 'Data package type cannot be blank';
        RAISERROR (_message, 10, 1)
        return 51006
    End If;

    -- Make sure the team name is valid
    If Not Exists (SELECT * FROM dpkg.t_data_package_teams WHERE team_name = _team) Then
        _message := 'Teams "' || _team || '" is not a valid data package team';
        RAISERROR (_message, 10, 1)
        return 51007
    End If;

    -- Make sure the data package type is valid
    If Not Exists (SELECT * FROM dpkg.t_data_package_type WHERE package_type = _packageType) Then
        _message := 'Type "' || _packageType || '" is not a valid data package type';
        RAISERROR (_message, 10, 1)
        return 51008
    End If;

    ---------------------------------------------------
    -- Get active path
    ---------------------------------------------------
    --
    --
    SELECT path_id INTO _rootPath
    FROM dpkg.t_data_package_storage
    WHERE state = 'Active'

    ---------------------------------------------------
    -- Validate the state
    ---------------------------------------------------

    If Not Exists (SELECT * FROM dpkg.t_data_package_state WHERE "state_name" = _state) Then
        _message := 'Invalid state: ' || _state;
        RAISERROR (_message, 11, 32)
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if _mode = 'update' Then
        -- cannot update a non-existent entry
        --
        _currentID := 0;
        --
        SELECT data_pkg_id, INTO _currentID
               _teamCurrent = path_team
        FROM dpkg.t_data_package
        WHERE (data_pkg_id = _id)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 OR _currentID = 0 Then
            _message := 'No entry could be found in database for update';
            RAISERROR (_message, 10, 1)
            return 51009
        End If;

        -- Warn if the user is changing the team
        If Coalesce(_teamCurrent, '') <> '' Then
            If _teamCurrent <> _team Then
                _teamChangeWarning := 'Warning: Team changed from "' || _teamCurrent || '" to "' || _team || '"; the data package files will need to be moved from the old location to the new one';
            End If;
        End If;

    End If; -- mode update

    _logErrors := 1;

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If _mode = 'add' Then

        If _name Like '%&%' Then
            -- Replace & with 'and'

            If _name SIMILAR TO '%[a-z0-9]&[a-z0-9]%' Then
                If _name Like '% %' Then
                    _name := Replace(_name, '&', ' and ');
                Else
                    _name := Replace(_name, '&', '_and_');
                End If;
            End If;

            _name := Replace(_name, '&', 'and');
        End If;

        If _name Like '%;%' Then
            -- Replace each semicolon with a comma
            _name := Replace(_name, ';', ',');
        End If;

        -- Make sure the data package name doesn't already exist
        If Exists (SELECT * FROM dpkg.t_data_package WHERE package_name = _name) Then
            _message := 'Data package package_name "' || _name || '" already exists; cannot create an identically named data package';
            RAISERROR (_message, 10, 1)
            return 51010
        End If;

        INSERT INTO dpkg.t_data_package (
            package_name,
            package_type,
            description,
            comment,
            owner,
            requester,
            created,
            state,
            package_directory,
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
            Convert(text, NewID()),        -- package_directory cannot be null and must be unique; this guarantees both.  Also, we'll rename it below using dbo.MakePackageFolderName
            _rootPath,
            _team,
            _massTagDatabase,
            Coalesce(_prismWikiLink, ''),
            _dataDOI,
            _manuscriptDOI
        )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            _message := 'Insert operation failed';
            RAISERROR (_message, 10, 1)
            return 51011
        End If;

        -- return ID of newly created entry
        --
        _id := IDENT_CURRENT('dpkg.t_data_package');

        ---------------------------------------------------
        -- data package folder and wiki page auto naming
        ---------------------------------------------------
        --
        _pkgFileFolder := dbo.MakePackageFolderName(_id, _name);
        _prismWikiLink := dbo.MakePRISMWikiPageLink(_id, _name);
        --
        UPDATE dpkg.t_data_package
        SET
            package_directory = _pkgFileFolder,
            wiki_page_link = _prismWikiLink
        WHERE data_pkg_id = _id
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            _message := 'Updating package folder name failed';
            RAISERROR (_message, 10, 1)
            return 51012
        End If;

    End If; -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if _mode = 'update'  Then
        --
        UPDATE dpkg.t_data_package
        SET
            package_name = _name,
            package_type = _packageType,
            description = _description,
            comment = _comment,
            owner = _owner,
            requester = _requester,
            last_modified = CURRENT_TIMESTAMP,
            state = _state,
            path_team = _team,
            mass_tag_database = _massTagDatabase,
            wiki_page_link = _prismWikiLink,
            data_doi = _dataDOI,
            manuscript_doi = _manuscriptDOI
        WHERE data_pkg_id = _id
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            _message := 'Update operation failed for ID "' || _id::text || '"';
            RAISERROR (_message, 10, 1)
            return 51013
        End If;

    End If; -- update mode

    ---------------------------------------------------
    -- Create the data package folder when adding a new data package
    ---------------------------------------------------
    if _mode = 'add' Then
        Call _my_error => MakeDataPackageStorageFolder _id, _mode, _message => _message output, _callingUser => _callingUser;
    End If;

    If _teamChangeWarning <> '' Then
        If Coalesce(_message, '') <> '' Then
            _message := _message || '; ';
        Else
            _message := ': ';
        End If;

        _message := _message + _teamChangeWarning;
    End If;

    ---------------------------------------------------
    -- Update EUS_Person_ID and EUS_Proposal_ID
    ---------------------------------------------------
    --
    Call update_data_package_eus_info _id

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        If _logErrors > 0 Then
            If Not _id Is Null Then
                _msgForLog := _msgForLog || '; Data Package ID ' || Cast(_id As text);
            End If;

            Call post_log_entry 'Error', _msgForLog, 'AddUpdateDataPackage'
        End If;

    END CATCH

    return _myError
END
$$;

COMMENT ON PROCEDURE dpkg.add_update_data_package IS 'AddUpdateDataPackage';
