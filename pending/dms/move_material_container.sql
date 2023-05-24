--
CREATE OR REPLACE PROCEDURE public.move_material_container
(
    _container text,
    _oldLocation text = '',
    _newLocation text = '',
    _newResearcher text = '',
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Moves a container to a new location
**
**      Optionally provide the old location to assure that
**      the container is only moved if the old location matches
**      what is currently defined in DMS
**
**      Optionally also change the researcher associated with the container
**
**  Arguments:
**    _newResearcher   Supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
**
**  Auth:   mem
**  Date:   12/19/2018 mem - Initial release
**          12/20/2018 mem - Include container name in warnings
**          03/02/2022 mem - Compare current container location to _newLocation before validating _oldLocation
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _callingUser text;
    _slashLoc int;
    _containerInfo record;
    _mode text;
BEGIN
    _message := '';
    _returnCode := '';

    _callingUser := session_user;
    _slashLoc := Position('\' In _callingUser);

    If _slashLoc > 0 Then
        _callingUser := Substring(_callingUser, _slashLoc + 1, 100);
    End If;

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

    ---------------------------------------------------
    -- Make sure the inputs are not null
    -- Additional validation occurs later
    ---------------------------------------------------

    _container := Trim(Coalesce(_container, ''));
    _oldLocation := Trim(Coalesce(_oldLocation, ''));
    _newLocation := Trim(Coalesce(_newLocation, ''));
    _newResearcher := Trim(Coalesce(_newResearcher, ''));
    _infoOnly := Coalesce(_infoOnly, true);

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If char_length(_container) = 0 Then
        _message := 'Container name cannot be empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If char_length(_newLocation) = 0 Then
        _message := 'NewLocation cannot be empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the container's information
    ---------------------------------------------------

    --
    SELECT MC.container_id AS ContainerID
           ML.location As CurrentLocation,
           MC.type As ContainerType,
           MC.comment As containerComment,
           MC.barcode As Barcode,
           MC.researcher As Researcher
    INTO _containerInfo
    FROM t_material_containers AS MC
         INNER JOIN t_material_locations AS ML
           ON MC.location_id = ML.container_id
    WHERE MC.container = _container;

    If Not FOUND Then
        _message := format('Container not found: %s', _container);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _newLocation = _curLocation And (char_length(_newResearcher) = 0 Or _researcher = _newResearcher) Then
        _message := format('Container is already at %s (and not changing the researcher name): %s', _newLocation, _container);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    If char_length(_oldLocation) > 0 And _oldLocation <> _curLocation Then
        _message := format('Current container location does not match the expected location: %s vs. expected %s for %s',
                            _curLocation, _oldLocation, _container);
        RAISE WARNING '%', _message;
        _returnCode := 'U5205';
        RETURN;
    End If;

    If char_length(_newResearcher) > 0 Then
        _researcher := _newResearcher;
    End If;

    If _infoOnly Then
        _mode := 'preview';
    Else
        _mode := 'update';
    End If;

    CALL add_update_material_container (
                _container => _container,
                _type => _containerType,
                _location => _newLocation,
                _comment => _containerComment,
                _barcode => _barcode,
                _researcher => _researcher,
                _mode => _mode,
                _message => _message,           -- Output
                _returnCode => _returnCode,     -- Output
                _callingUser => _callingUser);

    If _returnCode <> '' Then
        RAISE WARNING '%', _message;
    Else
        If _infoOnly Then
            _message := format('Container %s can be moved from %s to %s', _container, _curLocation, _newLocation);
        Else
            _message := format('Moved container %s from %s  to %s', _container, _curLocation, _newLocation);
        End If;

        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.move_material_container IS 'MoveMaterialContainer';
