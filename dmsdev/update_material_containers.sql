--
-- Name: update_material_containers(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_material_containers(IN _mode text, IN _containerlist text, IN _newvalue text, IN _comment text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update specified list of containers
**
**  Arguments:
**    _mode             Mode: 'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
**    _containerList    Comma-separated list of container IDs, e.g. '6314, 9750'
**    _newValue         When mode is 'move_container', this is the new location for the container
**    _comment          Comment to store in t_material_log; if null or an empty string and _mode is 'retire_container_and_contents', the comment will be auto-defined
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/26/2008     - (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Add mode 'unretire_container'
**                         - Do not allow updating containers of type 'na'
**          08/27/2018 mem - Rename the view Material Location list report view
**          06/21/2022 mem - Use new column name Container_Limit in view V_Material_Location_List_Report
**          07/07/2022 mem - Include container name in 'container not empty' message
**          02/12/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _numContainers int;
    _containerName text;
    _location citext;
    _locationID int;
    _containterCount int;
    _containerLimit int;
    _locStatus citext;
    _nonEmptyContainerCount int := 1;
    _nonEmptyContainers text;
    _moveType text := '??';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mode          := Trim(Lower(Coalesce(_mode, '')));
    _containerList := Trim(Coalesce(_containerList, ''));
    _newValue      := Trim(Coalesce(_newValue, ''));
    _comment       := Trim(Coalesce(_comment, ''));

    If _containerList = '' Then
        _message := 'Container ID(s) must be specified';
        _returnCode := 'U5110';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Temporary table to hold containers
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Material_Container_List (
        ID int,
        Name text,
        Location text,
        ItemCount int,
        Status citext,
        Type citext
    );

    ---------------------------------------------------
    -- Populate temporary table from container list
    ---------------------------------------------------

    INSERT INTO Tmp_Material_Container_List (ID, Name, Location, ItemCount, Status, Type)
    SELECT Container_ID,
           Container,
           Location,
           Items,
           Status,
           Type
    FROM V_Material_Container_Item_Stats
    WHERE container_id IN ( SELECT Value
                            FROM public.parse_delimited_integer_list(_containerList) );
    --
    GET DIAGNOSTICS _numContainers = ROW_COUNT;

    If _numContainers = 0 Then
        If Position(',' In _containerList) > 1 Then
            _message := format('Invalid Container IDs: %s', _containerList);
        Else
            _message := format('Invalid Container ID: %s', _containerList);
        End If;

        _returnCode := 'U5111';

        DROP TABLE Tmp_Material_Container_List;
        RETURN;
    End If;

    If Exists (SELECT ID FROM Tmp_Material_Container_List WHERE Type = 'na') Then
        If Position(',' In _containerList) > 1 Then
            _message := 'Containers of type "na" cannot be updated by the website; contact a DMS admin (see Update_Material_Containers)';
        Else

            SELECT Name
            INTO _containerName
            FROM Tmp_Material_Container_List;

            _message := format('Container "%s" cannot be updated by the website; contact a DMS admin (see Update_Material_Containers)', Coalesce(_containerName, _containerList));
        End If;

        _returnCode := 'U5112';

        DROP TABLE Tmp_Material_Container_List;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve location to ID (according to mode)
    ---------------------------------------------------

    _location   := 'None';  -- The 'container not in a freezer' location
    _locationID := 1;       -- The ID of the 'None' location;

    If _mode = 'move_container' Then
        _location := _newValue;

        If _newValue = '' Then
            _message := 'Cannot move the container(s): destination location not specified';
            _returnCode := 'U5120';

            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;

        SELECT location_id
        INTO _locationID
        FROM t_material_locations
        WHERE location = _location::citext;

        If Not FOUND Then
            _message := format('Cannot move the container(s): destination location does not exist: %s', _location);
            _returnCode := 'U5121';

            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;

        SELECT COUNT(MC.location_id) AS containers,
               ML.container_limit,
               ML.status
        INTO _containterCount, _containerLimit, _locStatus
        FROM t_material_locations ML
             INNER JOIN t_material_freezers F
               ON ML.freezer_tag = F.freezer_tag
             LEFT OUTER JOIN t_material_containers MC
               ON ML.location_id = MC.location_id
        WHERE ML.location_id = _locationID
        GROUP BY ML.location_id, ML.container_limit, ML.status;

        ---------------------------------------------------
        -- Is location suitable?
        ---------------------------------------------------

        If _locStatus <> 'Active' Then
            _message := format('Cannot move the container(s): location "%s" must have state "Active", not "%s"', _location, _locStatus);
            _returnCode := 'U5122';

            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;

        If _containterCount + _numContainers > _containerLimit Then
            _message := format('Cannot move the container(s): the maximum container capacity of location "%s" would exceed the limit (%s)', _location, _containerLimit);
            _returnCode := 'U5123';

            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Determine whether any containers have contents
    ---------------------------------------------------

    SELECT COUNT(ID)
    INTO _nonEmptyContainerCount
    FROM Tmp_Material_Container_List
    WHERE ItemCount > 0;

    ---------------------------------------------------
    -- For 'plain' container retirement, container must be empty
    ---------------------------------------------------

    If _mode = 'retire_container' And _nonEmptyContainerCount > 0 Then
        If _numContainers = 1 Then
            _message := format('Container %s is not empty; cannot retire it', _containerList);
        Else
            SELECT string_agg(Name, ', ' ORDER BY Name)
            INTO _nonEmptyContainers
            FROM Tmp_Material_Container_List
            WHERE ItemCount > 0;

            _message := format('All containers must be empty in order to retire them; see %s', _nonEmptyContainers);
        End If;

        _returnCode := 'U5124';

        DROP TABLE Tmp_Material_Container_List;
        RETURN;
    End If;

    ---------------------------------------------------
    -- For 'contents' container retirement, also retire contents
    ---------------------------------------------------

    -- Arrange for containers and their contents to have a common comment, e.g.
    -- CR-2024.02.12_15:07:58

    If _mode = 'retire_container_and_contents' And _comment = '' Then
        _comment := format('CR-%s', to_char(CURRENT_TIMESTAMP, 'yyyy.mm.dd_hh24:mi:ss'));
    End If;

    -- Retire the contents
    If _mode = 'retire_container_and_contents' And _nonEmptyContainerCount > 0 Then

        CALL public.update_material_items (
                        _mode        => 'retire_items',
                        _itemList    => containerList,
                        _itemType    => 'containers',
                        _newValue    => '',
                        _comment     => _comment,
                        _message     => _message,       -- Output
                        _returnCode  => _returnCode,    -- Output
                        _callingUser => _callingUser);

        If _returnCode <> '' Then
            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;
    End If;

    If _mode = 'unretire_container' Then
        -- Make sure the container(s) are all inactive
        If Exists (SELECT ID FROM Tmp_Material_Container_List WHERE Status <> 'Inactive') Then
            If _numContainers = 1 Then
                _message := format('Container is already active; cannot unretire %s', _containerList);
            Else
                _message := format('All containers must be inactive in order to unretire them: %s', _containerList);
            End If;

            _returnCode := 'U5125';

            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;
     End If;

    ---------------------------------------------------
    -- Update containers to be at new location
    ---------------------------------------------------

    UPDATE t_material_containers
    SET location_id = _locationID,
        status = CASE _mode
                    WHEN 'retire_container'              THEN 'Inactive'
                    WHEN 'retire_container_and_contents' THEN 'Inactive'
                    WHEN 'unretire_container'            THEN 'Active'
                    ELSE status
                 END
    WHERE t_material_containers.container_id IN (SELECT ID FROM Tmp_Material_Container_List);

    ---------------------------------------------------
    -- Set up appropriate label for log
    ---------------------------------------------------

    If _mode = 'retire_container' Then
        _moveType := 'Container Retirement';
    ElsIf _mode = 'retire_container_and_contents' Then
        _moveType := 'Container Retirement';
    ElsIf _mode = 'unretire_container' Then
        _moveType := 'Container Unretirement';
    ElsIf _mode = 'move_container' Then
        _moveType := 'Container Move';
    Else
      _message := format('Invalid material container update mode: %s', _mode);
      _returnCode := 'U5126';

      DROP TABLE Tmp_Material_Container_List;
      RETURN;
    End If;

    ---------------------------------------------------
    -- Make log entries
    ---------------------------------------------------

    INSERT INTO t_material_log (
        type,
        item,
        initial_state,
        final_state,
        username,
        comment
    )
    SELECT _moveType,
           Name,
           Location,
           _location,
           _callingUser,
           _comment
    FROM Tmp_Material_Container_List
    WHERE Location <> _location OR
          _mode <> 'move_container';

    DROP TABLE Tmp_Material_Container_List;

END
$$;


ALTER PROCEDURE public.update_material_containers(IN _mode text, IN _containerlist text, IN _newvalue text, IN _comment text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_material_containers(IN _mode text, IN _containerlist text, IN _newvalue text, IN _comment text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_material_containers(IN _mode text, IN _containerlist text, IN _newvalue text, IN _comment text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateMaterialContainers';

