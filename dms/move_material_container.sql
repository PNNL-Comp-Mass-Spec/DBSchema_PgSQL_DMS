--
-- Name: move_material_container(text, text, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.move_material_container(IN _container text, IN _oldlocation text DEFAULT ''::text, IN _newlocation text DEFAULT ''::text, IN _newresearcher text DEFAULT ''::text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Moves a container to a new location
**
**      Optionally provide the old location to assure that the container is only moved
**      if the old location matches what is currently defined in DMS
**
**      Optionally also change the researcher associated with the container
**
**  Arguments:
**    _container        Material container name
**    _oldLocation      Existing location (optional)
**    _newLocation      New location
**    _newResearcher    New researcher (optional); supports 'Zink, Erika M', 'Zink, Erika M (D3P704)', or 'D3P704'
**    _infoOnly         When true, preview updates
**    _message          Output message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   12/19/2018 mem - Initial release
**          12/20/2018 mem - Include container name in warnings
**          03/02/2022 mem - Compare current container location to _newLocation before validating _oldLocation
**          11/22/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
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
    -- Make sure the inputs are not null
    -- Additional validation occurs later
    ---------------------------------------------------

    _container     := Trim(Coalesce(_container, ''));
    _oldLocation   := Trim(Coalesce(_oldLocation, ''));
    _newLocation   := Trim(Coalesce(_newLocation, ''));
    _newResearcher := Trim(Coalesce(_newResearcher, ''));
    _infoOnly      := Coalesce(_infoOnly, true);

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

    SELECT MC.container_id AS ContainerID,
           ML.location AS CurrentLocation,
           MC.type AS ContainerType,
           MC.comment AS ContainerComment,
           C.campaign AS CampaignName,
           MC.researcher AS Researcher
    INTO _containerInfo
    FROM t_material_containers AS MC
         INNER JOIN t_material_locations AS ML
           ON MC.location_id = ML.location_id
         LEFT OUTER JOIN t_campaign AS C
           ON MC.campaign_id = C.campaign_id
    WHERE MC.container = _container;

    If Not FOUND Then
        _message := format('Container not found: %s', _container);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _newLocation::citext = _containerInfo.CurrentLocation And (char_length(_newResearcher) = 0 Or _containerInfo.Researcher = _newResearcher::citext) Then
        _message := format('Container is already at %s (and not changing the researcher name): %s', _newLocation, _container);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    If char_length(_oldLocation) > 0 And _oldLocation::citext <> _containerInfo.CurrentLocation Then
        _message := format('Current container location does not match the expected location: %s vs. expected %s for %s',
                           _containerInfo.CurrentLocation, _oldLocation, _container);

        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    If char_length(_newResearcher) > 0 Then
        _containerInfo.Researcher := _newResearcher;
    End If;

    If _infoOnly Then
        _mode := 'preview';
    Else
        _mode := 'update';
    End If;

    CALL public.add_update_material_container (
                _container    => _container,                     -- Input/Output
                _type         => _containerInfo.ContainerType,
                _location     => _newLocation,
                _comment      => _containerInfo.ContainerComment,
                _campaignName => _containerInfo.CampaignName,
                _researcher   => _containerInfo.Researcher,
                _mode         => _mode,
                _message      => _message,       -- Output
                _returnCode   => _returnCode,    -- Output
                _callingUser  => _callingUser);

    If _returnCode <> '' Then
        RAISE WARNING '%', _message;
    Else
        If _containerInfo.CurrentLocation = _newLocation::citext Then
            If _infoOnly Then
                _message := format('Preview setting container %s to be at %s, with researcher %s', _container, _newLocation, _containerInfo.Researcher);
            Else
                _message := format('Container %s is now at %s, with researcher %s', _container, _newLocation, _containerInfo.Researcher);
            End If;
        Else
            If _infoOnly Then
                _message := format('Container %s can be moved from %s to %s', _container, _containerInfo.CurrentLocation, _newLocation);
            Else
                _message := format('Moved container %s from %s to %s', _container, _containerInfo.CurrentLocation, _newLocation);
            End If;
        End If;

        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.move_material_container(IN _container text, IN _oldlocation text, IN _newlocation text, IN _newresearcher text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE move_material_container(IN _container text, IN _oldlocation text, IN _newlocation text, IN _newresearcher text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.move_material_container(IN _container text, IN _oldlocation text, IN _newlocation text, IN _newresearcher text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'MoveMaterialContainer';

