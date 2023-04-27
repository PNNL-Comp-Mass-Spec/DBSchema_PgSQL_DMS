--
CREATE OR REPLACE PROCEDURE dpkg.add_update_osm_package
(
    INOUT _id int,
    _name text,
    _packageType text,
    _description text,
    _keywords text,
    _comment text,
    _owner text,
    _state text,
    _samplePrepRequestList text,
    _userFolderPath text,
    _mode text = 'add',
    INOUT _message text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in
**    T_OSM_Package
**
**  Arguments:
**    _mode   or 'update'
**
**  Auth:   grk
**  Date:
**          10/26/2012 grk - now setting "last affected" date
**          11/02/2012 grk - removed _requester
**          05/20/2013 grk - added _noteFilesLink
**          07/06/2013 grk - added _samplePrepRequestList
**          08/20/2013 grk - added handling for onenote file path
**          08/21/2013 grk - removed _noteFilesLink
**          08/21/2013 grk - added call to create onenote folder
**          11/04/2013 grk - added _userFolderPath
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          06/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**                         - Validate _state
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _logErrors int := 0;
    _authorized int := 0;
    _rootPath int;
    _iTM TABLE (;
    _badIDs text := '';
    _goodIDs text := '';
    _tmp int := 0;
    _wikiLink text := '';
    _msgForLog text := ERROR_MESSAGE();
BEGIN

    _message := '';

    BEGIN TRY

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Call _authorized => verify_sp_authorized 'AddUpdateOSMPackage', _raiseError => 1
    If _authorized = 0 Then
        RAISERROR ('Access denied', 11, 3)
    End If;

    ---------------------------------------------------
    -- Get active path
    ---------------------------------------------------
    --
    --
    SELECT path_id INTO _rootPath
    FROM dpkg.t_osm_package_storage
    WHERE state = 'Active'

    ---------------------------------------------------
    -- Validate sample prep request list
    ---------------------------------------------------

    -- Table variable to hold items from sample prep request list
        Item INT,
        Valid CHAR(1) null
    )
    -- populate table from sample prep request list
    INSERT INTO _iTM ( Item, Valid)
    SELECT Item, 'N' FROM public.parse_delimited_list(_samplePrepRequestList)

    -- mark sample prep requests that exist in the database
    UPDATE TX
    SET Valid = 'Y'
    FROM _iTM TX INNER JOIN dbo.S_Sample_Prep_Request_List SPL ON TX.Item = SPL.ID

    -- get list of any list items that weren't in the database
    SELECT @badIDs + CASE WHEN @badIDs <> '' THEN ', ' + CONVERT(VARCHAR(12), Item) ELSE CONVERT(VARCHAR(12), Item) END INTO _badIDs
    FROM _iTM
    WHERE Valid = 'N'

    IF _badIDs <> '' Then
        _message := 'Sample prep request IDs "' || _badIDs || '" do not exist';
        RAISERROR (_message, 11, 31)
    End If;

    SELECT @goodIDs + CASE WHEN @goodIDs <> '' THEN ', ' + CONVERT(VARCHAR(12), Item) ELSE CONVERT(VARCHAR(12), Item) END INTO _goodIDs
    FROM _iTM
    ORDER BY Item

    ---------------------------------------------------
    -- Validate the state
    ---------------------------------------------------

    If Not Exists (SELECT * FROM dpkg.t_osm_package_state WHERE "state_name" = _state) Then
        _message := 'Invalid state: ' || _state;
        RAISERROR (_message, 11, 32)
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if _mode = 'update' Then
        -- cannot update a non-existent entry
        --
        --
        SELECT osm_pkg_id INTO _tmp
        FROM  dpkg.t_osm_package
        WHERE (osm_pkg_id = _id)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 OR _tmp = 0 Then
            RAISERROR ('No entry could be found in database for update', 11, 16);
        End If;
    End If;

    _logErrors := 1;

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if _mode = 'add' Then

    -- Make sure the data package name doesn't already exist
    If Exists (SELECT * FROM dpkg.t_osm_package WHERE osm_package_name = _name) Then
        _message := 'OSM package osm_package_name "' || _name || '" already exists; cannot create an identically named package';
        RAISERROR (_message, 11, 1)
    End If;

    -- create wiki page link
    if NOT _name IS NULL Then
        _wikiLink := 'http://prismwiki.pnl.gov/wiki/OSMPackages:' || REPLACE(_name, ' ', '_');
    End If;

    INSERT INTO dpkg.t_osm_package (
        osm_package_name,
        package_type,
        description,
        keywords,
        comment,
        owner,
        state,
        wiki_page_link,
        path_root,
        sample_prep_requests,
        user_folder_path
    ) VALUES (
        _name,
        _packageType,
        _description,
        _keywords,
        _comment,
        _owner,
        _state,
        _wikiLink,
        _rootPath,
        _goodIDs,
        _userFolderPath
    )
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        RAISERROR ('Insert operation failed', 11, 7);
    End If;

    -- return ID of newly created entry
    --
    _id := IDENT_CURRENT('dpkg.t_osm_package');

    End If; -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if _mode = 'update' Then
        --
        UPDATE dpkg.t_osm_package
        SET
            osm_package_name = _name,
            package_type = _packageType,
            description = _description,
            keywords = _keywords,
            comment = _comment,
            owner = _owner,
            state = _state,
            last_modified = CURRENT_TIMESTAMP,
            sample_prep_requests = _goodIDs,
            user_folder_path = _userFolderPath
        WHERE (osm_pkg_id = _id)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            RAISERROR ('Update operation failed: "%s"', 11, 4, _id);
        End If;

    End If; -- update mode

    ---------------------------------------------------
    -- Create the OSM package folder when adding a new OSM package
    ---------------------------------------------------
    if _mode = 'add' Then
        Call _my_error => MakeOSMPackageStorageFolder _id, _mode, _message => _message output, _callingUser => _callingUser;
    End If;

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        If _logErrors > 0 Then
            Call post_log_entry 'Error', _msgForLog, 'AddUpdateOSMPackage'
        End If;

    END CATCH

    return _myError
END
$$;

COMMENT ON PROCEDURE dpkg.add_update_osm_package IS 'AddUpdateOSMPackage';
