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
    _mode text default 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in T_OSM_Package
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
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          06/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**                         - Validate _state
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _logErrors int := 0;
    _authorized boolean := false;
    _rootPath int;
    _badIDs text := '';
    _goodIDs text := '';
    _wikiLink text := '';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

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

    BEGIN

        ---------------------------------------------------
        -- Get active path
        ---------------------------------------------------
        --
        SELECT path_id
        INTO _rootPath
        FROM dpkg.t_osm_package_storage
        WHERE state = 'Active';

        ---------------------------------------------------
        -- Validate sample prep request list
        ---------------------------------------------------

        -- Table variable to hold items from sample prep request list
        CREATE TEMP TABLE Tmp_PrepRequestItems
            Item int,
            Valid boolean not null
        );

        -- Populate table from sample prep request list
        INSERT INTO Tmp_PrepRequestItems ( Item, Valid)
        SELECT Item, false
        FROM public.parse_delimited_integer_list(_samplePrepRequestList);

        -- Mark sample prep requests that exist in the database
        UPDATE Tmp_PrepRequestItems
        SET Valid = true
        WHERE Item in (SELECT prep_request_id FROM T_Sample_Prep_Request);

        -- Get list of any list items that weren't in the database
        SELECT string_agg(item::text, ', ' ORDER BY item)
        INTO _badIDs
        FROM Tmp_PrepRequestItems
        WHERE Not Valid;

        If _badIDs <> '' Then
            _message := format('Sample prep request IDs "%s" do not exist', _badIDs);
            RAISE EXCEPTION '%', message;
        End If;

        SELECT string_agg(Item::text, ', ' ORDER BY item)
        INTO _goodIDs
        FROM Tmp_PrepRequestItems;

        ---------------------------------------------------
        -- Validate the state
        ---------------------------------------------------

        If Not Exists (SELECT * FROM dpkg.t_osm_package_state WHERE state_name = _state) Then
            _message := format('Invalid state: %s', _state);
            RAISE EXCEPTION '%', message;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- cannot update a non-existent entry
            --
            If Not Exists (SELECT osm_pkg_id FROM dpkg.t_osm_package WHERE osm_pkg_id = _id) Then
                _message := format('OSM package ID %s does not exist; cannot update', _id);
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        _logErrors := 1;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            -- Make sure the data package name doesn't already exist
            If Exists (SELECT * FROM dpkg.t_osm_package WHERE osm_package_name = _name) Then
                _message := format('OSM package "%s" already exists; cannot create an identically named package', _name);
                RAISE EXCEPTION '%', _message;
            End If;

            -- create wiki page link
            If NOT _name IS NULL Then
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
            RETURNING osm_pkg_id
            INTO _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

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
            WHERE osm_pkg_id = _id;

        End If;

        ---------------------------------------------------
        -- Create the OSM package folder when adding a new OSM package
        ---------------------------------------------------

        If _mode = 'add' Then
            CALL Make_OSM_Package_Storage_Folder (
                        _id,
                        _mode,
                        _message => _message,           -- Output
                        _returnCode => returnCode,      -- Output
                        _callingUser => _callingUser);
        End If;

        DROP TABLE Tmp_PrepRequestItems;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If Coalesce(_id, 0) > 0 And Position(format('ID %s', _id) IN _exceptionMessage) = 0 Then
                _exceptionMessage := format('%s; OSM Package ID %s', _exceptionMessage, _id);
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

        DROP TABLE IF EXISTS Tmp_PrepRequestItems;
    END CATCH

END
$$;

COMMENT ON PROCEDURE dpkg.add_update_osm_package IS 'AddUpdateOSMPackage';
