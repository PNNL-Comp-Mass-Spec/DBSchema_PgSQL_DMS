--
CREATE OR REPLACE PROCEDURE public.add_update_material_container
(
    INOUT _container text,
    _type text,
    _location text,
    _comment text,
    _barcode text,
    _researcher text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits an existing material container
**
**  Arguments:
**    _type         Box, Bag, or Wellplate
**    _researcher   Supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
**    _mode         'add', 'update', or 'preview'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _status text := 'Active';
    _nextContainerID int := 0;
    _matchCount int;
    _researcherUsername text;
    _userID Int;
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
        -- Make sure the inputs are not null
        -- Additional validation occurs later
        ---------------------------------------------------

        _container := Trim(Coalesce(_container, ''));
        _type := Trim(Coalesce(_type, 'Box'));
        _location := Trim(Coalesce(_location, ''));
        _comment := Trim(Coalesce(_comment, ''));
        _barcode := Trim(Coalesce(_barcode, ''));
        _researcher := Trim(Coalesce(_researcher, ''));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Optionally generate a container name
        ---------------------------------------------------

        If _container = '(generate name)' OR _mode = 'add' Then
            --
            SELECT MAX(container_id) + 1
            INTO _nextContainerID
            FROM  t_material_containers;

            _container := format('MC-%s', _nextContainerID);
        End If;

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If char_length(_container) = 0 Then
            _message := 'Container name cannot be empty';
            _returnCode := 'U5202';
            RETURN;
        End If;

        If _container::citext In ('na', 'Staging', '-80_Staging', 'Met_Staging') Then
            _message := 'The "' || _container || '" container cannot be updated via the website; contact a DMS admin (see AddUpdateMaterialContainer)';
            _returnCode := 'U5203';
            RETURN;
        End If;

        If _mode = 'add' And Not _type::citext In ('Box', 'Bag', 'Wellplate') Then
            _type := 'Box';
        End If;

        If Not _type::citext In ('Box', 'Bag', 'Wellplate') Then
            _message := 'Container type must be Box, Bag, or Wellplate, not ' || _type;
            _returnCode := 'U5204';
            RETURN;
        End If;

        If _type = 'na' Then
            _message := 'Containers of type "na" cannot be updated via the website; contact a DMS admin';
            _returnCode := 'U5205';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate the researcher name
        ---------------------------------------------------

        If _researcher::citext In ('', 'na', 'none') Then
            _message := 'Researcher must be a valid DMS user';
            _returnCode := 'U5206';
            RETURN;
        End If;

        CALL auto_resolve_name_to_username (_researcher, _matchCount => _matchCount, _matchingUsername => _researcherUsername, _matchingUserID => _userID);

        If _matchCount = 1 Then
            -- Single match found; update _researcher to be in the form 'Zink, Erika M (D3P704)'

            SELECT name_with_username
            INTO _researcher
            FROM t_users
            WHERE username = _researcherUsername

        Else
            -- Single match not found

            _message := 'Researcher must be a valid DMS user';

            If _matchCount = 0 Then
                _message := _message || '; ' || _researcher || ' is an unknown person';
            Else
                _message := _message || '; ' || _researcher || ' is an ambiguous match to multiple people';
            End If;

            _returnCode := 'U5207';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        --
        SELECT container_id,
               location_id,
               type,
               status
        INTO _containerID, _curLocationID, _curType, _curStatus
        FROM  t_material_containers
        WHERE container = _container;

        If _mode = 'add' and _containerID <> 0 Then
            _message := 'Cannot add container with same name as existing container: ' || _container;
            _returnCode := 'U5208';
            RETURN;
        End If;

        If _mode::citext In ('update', 'preview') and _containerID = 0 Then
            _message := 'No entry could be found in database for updating ' || _container;
            _returnCode := 'U5209';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Resolve input location name to ID and get limit
        ---------------------------------------------------

        --
        SELECT location_id,
               container_limit
        INTO _locationID, _limit
        FROM t_material_locations
        WHERE location = _location;

        If Not FOUND Then
            _message := 'Invalid location: ' || _location || ' (for container ' || _container || ')';
            _returnCode := 'U5210';
            RETURN;
        End If;

        ---------------------------------------------------
        -- If moving a container, verify that there is room in destination location
        ---------------------------------------------------

        If _curLocationID <> _locationID Then
            --
            SELECT COUNT(*)
            INTO _cnt
            FROM t_material_containers
            WHERE location_id = _locationID;

            If _limit <= _cnt Then
                _message := 'Destination location does not have room for another container (moving ' || _container || ' to ' || _location || ')';
                _returnCode := 'U5211';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve current Location id to name
        ---------------------------------------------------

        --
        SELECT location
        INTO _curLocationName
        FROM t_material_locations
        WHERE location_id = _curLocationID

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        --
        If _mode = 'add' Then

            -- future: accept '<next bag>' or '<next box> and generate container name

            INSERT INTO t_material_containers( container,
                                               type,
                                               comment,
                                               barcode,
                                               location_id,
                                               status,
                                               researcher )
            VALUES (_container, _type, _comment, _barcode, _locationID, _status, _researcher);

            -- Material movement logging
            --
            CALL post_material_log_entry
                 'Container Creation',
                 _container,
                 'na',
                 _location,
                 _callingUser,
                 ''

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            UPDATE t_material_containers
            SET type = _type,
                comment = _comment,
                barcode = _barcode,
                location_id = _locationID,
                status = _status,
                researcher = _researcher
            WHERE container = _container;

            -- Material movement logging
            --
            If _curLocationName <> _location Then
                CALL post_material_log_entry
                     'Container Move',
                     _container,
                     _curLocationName,
                     _location,
                     _callingUser,
                     ''
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

COMMENT ON PROCEDURE public.add_update_material_container IS 'AddUpdateMaterialContainer';
