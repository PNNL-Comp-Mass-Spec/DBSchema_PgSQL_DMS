--
-- Name: add_update_osm_package(integer, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.add_update_osm_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _keywords text, IN _comment text, IN _owner text, IN _state text, IN _samplepreprequestlist text, IN _userfolderpath text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing item in sw.t_osm_package
**
**  Arguments:
**    _id                       OSM package ID
**    _name                     OSM package name
**    _packageType              OSM package type ('General' or 'Software Testing')
**    _description              OSM package description
**    _keywords                 Keywords
**    _comment                  Comment
**    _owner                    Owner username
**    _state                    State ('Active', 'Complete', 'Inactive', or 'Future')
**    _samplePrepRequestList    Comma-separated list of sample prep request IDs
**    _userFolderPath           Network share path, e.g. \\protoapps\UserData\Zink\PrepRequest_Summaries\EMSL_Projects\Martin_EUP-47558
**    _mode                     Mode: 'add' or 'update'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
**
**  Auth:   grk
**  Date:   10/22/2012 grk - Initial Release
**          10/26/2012 grk - Now setting "last affected" date
**          11/02/2012 grk - Removed _requester
**          05/20/2013 grk - Added _noteFilesLink
**          07/06/2013 grk - Added _samplePrepRequestList
**          08/20/2013 grk - Added handling for onenote file path
**          08/21/2013 grk - Removed _noteFilesLink
**          08/21/2013 grk - Added call to create onenote folder
**          11/04/2013 grk - Added _userFolderPath
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          06/19/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**                         - Validate _state
**          08/15/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Update warning messages
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**          01/03/2024 mem - Update warning message
**          01/11/2024 mem - Show a custom message when _state is an empty string
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchingValue text;
    _rootPath int;
    _badIDs text := '';
    _goodIDs text := '';
    _logErrors boolean := false;
    _wikiLink text := '';
    _msg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _state                 := Trim(Coalesce(_state, ''));
        _packageType           := Trim(Coalesce(_packageType, ''));
        _description           := Trim(Coalesce(_description, ''));
        _comment               := Trim(Coalesce(_comment, ''));
        _samplePrepRequestList := Trim(Coalesce(_samplePrepRequestList, ''));
        _mode                  := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode In ('add', 'update') Then
            _message := 'Mode must be "add" or "update"';
            _returnCode := 'U5103';
            RETURN;
        End If;

        If _mode = 'update' And Coalesce(_id, 0) = 0 Then
            _message := 'OSM package ID cannot be null or 0 when mode is "update"';
            _returnCode := 'U5104';
            RETURN;
        End If;

        If _state = '' Then
            _message := 'OSM package state must be specified';
            _returnCode := 'U5105';
            RETURN;
        End If;

        If _packageType = '' Then
            _message := 'OSM package type must be specified';
            _returnCode := 'U5106';
            RETURN;
        End If;

        -- Make sure the OSM package type is valid (and capitalize it, if necessary)
        SELECT package_type
        INTO _matchingValue
        FROM dpkg.t_osm_package_type
        WHERE package_type = _packageType::citext;

        If Not Found Then
            _message := format('Invalid OSM package type: %s', _packageType);
            _returnCode := 'U5107';
            RETURN;
        Else
            _packageType := _matchingValue;
        End If;

        ---------------------------------------------------
        -- Get active path
        ---------------------------------------------------

        SELECT path_id
        INTO _rootPath
        FROM dpkg.t_osm_package_storage
        WHERE state = 'Active';

        If Not Found Then
            _message := 'Table dpkg.t_osm_package_storage does not have an active storage path';
            _returnCode := 'U5108';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate sample prep request list
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_PrepRequestItems (
            Item int,
            Valid boolean not null
        );

        -- Populate table from sample prep request list
        INSERT INTO Tmp_PrepRequestItems (Item, Valid)
        SELECT Value, false
        FROM public.parse_delimited_integer_list(_samplePrepRequestList);

        -- Mark sample prep requests that exist in the database
        UPDATE Tmp_PrepRequestItems
        SET Valid = true
        WHERE Item IN (SELECT prep_request_id FROM t_sample_prep_request);

        -- Get list of any list items that weren't in the database
        SELECT string_agg(item::text, ', ' ORDER BY item)
        INTO _badIDs
        FROM Tmp_PrepRequestItems
        WHERE NOT Valid;

        If _badIDs <> '' Then
            If Position(',' In _badIDs) > 0 Then
                _message := format('Sample prep request IDs do not exist: "%s"', _badIDs);
            Else
                _message := format('Sample prep request ID "%s" does not exist', _badIDs);
            End If;

            _returnCode := 'U5109';

            DROP TABLE Tmp_PrepRequestItems;
            RETURN;
        End If;

        SELECT string_agg(Item::text, ', ' ORDER BY item)
        INTO _goodIDs
        FROM Tmp_PrepRequestItems;

        ---------------------------------------------------
        -- Validate the state
        ---------------------------------------------------

        SELECT state_name
        INTO _matchingValue
        FROM dpkg.t_osm_package_state
        WHERE state_name = _state::citext;

        If Not Found Then
            _message := format('Invalid state: %s', _state);
            _returnCode := 'U5110';

            DROP TABLE Tmp_PrepRequestItems;
            RETURN;
        Else
            _state := _matchingValue;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry

            If Not Exists (SELECT osm_pkg_id FROM dpkg.t_osm_package WHERE osm_pkg_id = _id) Then
                _message := format('OSM package ID %s does not exist; cannot update', _id);
                _returnCode := 'U5111';

                DROP TABLE Tmp_PrepRequestItems;
                RETURN;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            -- Make sure the data package name doesn't already exist
            If Exists (SELECT osm_package_name FROM dpkg.t_osm_package WHERE osm_package_name = _name) Then
                _message := format('OSM package "%s" already exists; cannot create an identically named package', _name);
                _returnCode := 'U5112';

                DROP TABLE Tmp_PrepRequestItems;
                RETURN;
            End If;

            -- Create the wiki page link
            If Not _name Is Null Then
                _wikiLink := format('https://prismwiki.pnl.gov/wiki/OSMPackages:%s', Replace(_name, ' ', '_'));
            End If;

            INSERT INTO dpkg.t_osm_package (
                osm_package_name,
                package_type,
                description,
                keywords,
                comment,
                owner_username,
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
            SET osm_package_name = _name,
                package_type = _packageType,
                description = _description,
                keywords = _keywords,
                comment = _comment,
                owner_username = _owner,
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
            CALL dpkg.make_osm_package_storage_folder (
                        _id,
                        _infoOnly   => false,
                        _message    => _msg,            -- Output
                        _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := public.append_to_text(_message, _msg);
            End If;

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
            If Coalesce(_id, 0) > 0 And Position(format('ID %s', _id) In _exceptionMessage) = 0 Then
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
    END;

END
$$;


ALTER PROCEDURE dpkg.add_update_osm_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _keywords text, IN _comment text, IN _owner text, IN _state text, IN _samplepreprequestlist text, IN _userfolderpath text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_osm_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _keywords text, IN _comment text, IN _owner text, IN _state text, IN _samplepreprequestlist text, IN _userfolderpath text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.add_update_osm_package(INOUT _id integer, IN _name text, IN _packagetype text, IN _description text, IN _keywords text, IN _comment text, IN _owner text, IN _state text, IN _samplepreprequestlist text, IN _userfolderpath text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateOSMPackage';

