--
-- Name: add_update_material_container(text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_material_container(INOUT _container text, IN _type text, IN _location text, IN _comment text, IN _campaignname text, IN _researcher text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing material container
**
**  Arguments:
**    _container        Input/Output: Container name; auto-defined if _mode is 'add'
**    _type             Container type: Box, Bag, Wellplate, or na
**    _location         Storage location name, e.g. '1521A.2.3.4.3' (must exist in table t_material_locations)
**    _comment          Comment
**    _campaignName     Campaign name; if an empty string, will store a null for Campaign_ID
**    _researcher       Researcher name; supports 'Zink, Erika M', 'Zink, Erika M (D3P704)', or 'D3P704'
**    _mode             Mode: 'add', 'update', or 'preview'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/20/2008 grk - Initial release
**          07/18/2008 grk - Added checking for location's container limit
**          11/25/2008 grk - Corrected update not to check for room if location doesn't change
**          07/28/2011 grk - Added owner field
**          08/01/2011 grk - Always create new container if mode is 'add'
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Validate inputs
**          12/19/2018 mem - Standardize the researcher name
**          11/11/2019 mem - If _researcher is 'na' or 'none', store an empty string in the Researcher column of T_Material_Containers
**          07/02/2021 mem - Require that the researcher is a valid DMS user
**          05/23/2023 mem - Use a Like clause to prevent updating Staging containers
**          11/18/2023 mem - Remove procedure argument _barcode and add _campaignName
**          11/20/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := true;
    _currentLocation text := 'Initializing';
    _status text := 'Active';
    _nextContainerID int := 0;
    _matchCount int;
    _researcherUsername text;
    _userID int;
    _campaignID int;
    _containerID int := 0;
    _curLocationID int := 0;
    _curType text := '';
    _curStatus text := '';
    _locationID int := 0;
    _limit int := 0;
    _cnt int := 0;
    _curLocationName text := '';

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

        _currentLocation := 'Validate the inputs';

        _container    := Trim(Coalesce(_container, ''));
        _type         := Trim(Coalesce(_type, 'Box'));
        _location     := Trim(Coalesce(_location, ''));
        _comment      := Trim(Coalesce(_comment, ''));
        _campaignName := Trim(Coalesce(_campaignName, ''));
        _researcher   := Trim(Coalesce(_researcher, ''));
        _mode         := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Generate a new container name if mode is 'add'
        ---------------------------------------------------

        If _mode = 'add' Then

            SELECT MAX(container_id) + 1
            INTO _nextContainerID
            FROM  t_material_containers;

            _container := format('MC-%s', _nextContainerID);
        End If;

        If char_length(_container) = 0 Then
            _message := 'Container name cannot be empty';
            _returnCode := 'U5201';
            RETURN;
        End If;

        If _container::citext = 'na' Or _container ILike '%Staging%' Then
            _message := format('The "%s" container cannot be updated via the website; contact a DMS admin (see AddUpdateMaterialContainer)', _container);
            _returnCode := 'U5202';
            RETURN;
        End If;

        If _mode = 'add' And Not _type::citext In ('Box', 'Bag', 'Wellplate') Then
            _type := 'Box';
        End If;

        If Not _type::citext In ('Box', 'Bag', 'Wellplate') Then
            _message := format('Container type must be Box, Bag, or Wellplate, not %s', _type);
            _returnCode := 'U5203';
            RETURN;
        End If;

        If _type::citext = 'na' Then
            _message := 'Containers of type "na" cannot be updated via the website; contact a DMS admin';
            _returnCode := 'U5204';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate the researcher name
        ---------------------------------------------------

        _currentLocation := 'Validate the researcher name';

        If _researcher::citext In ('', 'na', 'none') Then
            _message := 'Researcher must be a valid DMS user';
            _returnCode := 'U5205';
            RETURN;
        End If;

        CALL public.auto_resolve_name_to_username (
                        _researcher,
                        _matchCount       => _matchCount,           -- Output
                        _matchingUsername => _researcherUsername,   -- Output
                        _matchingUserID   => _userID);              -- Output

        If _matchCount = 1 Then
            -- Single match found; update _researcher to be in the form 'Zink, Erika M (D3P704)'

            SELECT name_with_username
            INTO _researcher
            FROM t_users
            WHERE username = _researcherUsername::citext;

        Else
            -- Single match not found

            _message := 'Researcher must be a valid DMS user';

            If _matchCount = 0 Then
                _message := format('%s; "%s" does not exist', _message, _researcher);
            Else
                _message := format('%s; "%s" matches more than one user', _message, _researcher);
            End If;

            _returnCode := 'U5206';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Resolve campaign name to ID
        ---------------------------------------------------

        _currentLocation := 'Resolve campaign name to ID';

        If _campaignName = '' Then
            _campaignID := null;
        Else
            SELECT Campaign_ID
            INTO _campaignID
            FROM T_Campaign
            WHERE Campaign = _campaignName::citext;

            If Not FOUND Then
                _message := format('Unrecognized campaign name: %s', _campaignName);
                _returnCode := 'U5207';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        _currentLocation := 'Check for existing container';

        SELECT container_id,
               location_id,
               type,
               status
        INTO _containerID, _curLocationID, _curType, _curStatus
        FROM  t_material_containers
        WHERE container = _container::citext;

        If _mode = 'add' And FOUND Then
            -- This code should never be reached since the container name is auto-generated when _mode is 'add'

            _message := format('Cannot add container with same name as existing container: %s', _container);
            _returnCode := 'U5208';
            RETURN;
        End If;

        If _mode In ('update', 'preview') And _containerID = 0 Then
            _message := format('Cannot update: container "%s" does not exist', _container);
            _returnCode := 'U5209';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Resolve input location name to ID and get limit
        ---------------------------------------------------

        _currentLocation := 'Resolve location name to ID';

        SELECT location_id,
               container_limit
        INTO _locationID, _limit
        FROM t_material_locations
        WHERE location = _location::citext;

        If Not FOUND Then
            _message := format('Invalid location: %s (for container %s)', _location, _container);
            _returnCode := 'U5210';
            RETURN;
        End If;

        ---------------------------------------------------
        -- If moving a container, verify that there is room in destination location
        ---------------------------------------------------

        If _curLocationID <> _locationID Then

            _currentLocation := 'Verify that destination location has room for the container';

            SELECT COUNT(container_id)
            INTO _cnt
            FROM t_material_containers
            WHERE location_id = _locationID;

            If _limit <= _cnt Then
                _message := format('Destination location does not have room for another container (moving %s to %s)',
                                   _container, _location);
                _returnCode := 'U5211';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve current Location ID to name
        ---------------------------------------------------

        _currentLocation := 'Resolve location ID to name';

        SELECT location
        INTO _curLocationName
        FROM t_material_locations
        WHERE location_id = _curLocationID;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            _currentLocation := 'Add new row to t_material_containers';

            INSERT INTO t_material_containers( container,
                                               type,
                                               comment,
                                               campaign_id,
                                               location_id,
                                               status,
                                               researcher )
            VALUES (_container, _type, _comment, _campaignID, _locationID, _status, _researcher);

            _currentLocation := 'Call post_material_log_entry';

            -- Log the container creation
            --
            CALL public.post_material_log_entry (
                            _type         => 'Container Creation',
                            _item         => _container,
                            _initialState => 'na',                  -- Initial State: Old location ('na')
                            _finalState   => _location,             -- Final State:   New location
                            _callingUser  => _callingUser,
                            _comment      => '');

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            _currentLocation := 'Update row in t_material_containers';

            UPDATE t_material_containers
            SET type        = _type,
                comment     = _comment,
                campaign_id = _campaignID,
                location_id = _locationID,
                status      = _status,
                researcher  = _researcher
            WHERE container = _container::citext;

            If _curLocationName <> _location Then

                _currentLocation := 'Call post_material_log_entry';

                -- Log the container location change
                --
                CALL public.post_material_log_entry (
                                _type         => 'Container Move',
                                _item         => _container,
                                _initialState => _curLocationName,      -- Initial State: Old location
                                _finalState   => _location,             -- Final State    New location
                                _callingUser  => _callingUser,
                                _comment      => '');
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_material_container(INOUT _container text, IN _type text, IN _location text, IN _comment text, IN _campaignname text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_material_container(INOUT _container text, IN _type text, IN _location text, IN _comment text, IN _campaignname text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_material_container(INOUT _container text, IN _type text, IN _location text, IN _comment text, IN _campaignname text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateMaterialContainer';

