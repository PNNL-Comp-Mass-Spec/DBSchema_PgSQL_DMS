--
CREATE OR REPLACE PROCEDURE public.update_material_containers
(
    _mode text,
    _containerList text,
    _newValue text,
    _comment text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Makes changes for specified list of containers
**
**  Arguments:
**    _mode             'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
**    _containerList    Container ID list, e.g. 'MC-6314', 'MC-9750'
**    _newValue         When mode is 'move_container', this is the new location for the container
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _numContainers int;
    _containerName text := Null;
    _location text;
    _locID int;
    _containterCount int;
    _locLimit int;
    _locStatus text;
    _nonEmptyContainerCount int := 1;
    _nonEmptyContainers text;
    _transName text := 'UpdateMaterialContainers';
    _moveType text := '??';
BEGIN

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
    -- Validate the inputs
    ---------------------------------------------------

    _mode := Trim(Lower(Coalesce(_mode, '')));
    _containerList := Coalesce(_containerList, '');
    _newValue := Coalesce(_newValue, '');
    _comment := Coalesce(_comment, '');
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Temporary table to hold containers
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Material_Container_List (
        ID int,
        Name text,
        Location text,
        ItemCount int,
        Status text,
        Type text
    )

    ---------------------------------------------------
    -- Populate temporary table from container list
    ---------------------------------------------------

    INSERT INTO Tmp_Material_Container_List
        (ID, Name, Location, ItemCount, Status, Type)
    SELECT Container_ID,
           Container,
           Location,
           Items,
           Status,
           Type
    FROM V_Material_Container_Item_Stats
    WHERE Container_ID IN ( SELECT Value
                   FROM public.parse_delimited_list ( _containerList ) );
    --
    GET DIAGNOSTICS _numContainers = ROW_COUNT;

    If _numContainers = 0 Then
        If Position(',' In _containerList) > 1 Then
            _message := 'Invalid Container IDs: ' || _containerList;
        Else
            _message := 'Invalid Container ID: ' || _containerList;
        End If;

        _returnCode := 'U5110';
        DROP TABLE Tmp_Material_Container_List;

        RETURN;
    End If;

    If Exists (Select * From Tmp_Material_Container_List Where Type = 'na') Then
        If Position(',' In _containerList) > 1 Then
            _message := 'Containers of type "na" cannot be updated by the website; contact a DMS admin (see UpdateMaterialContainers)';
        Else

            SELECT Name
            INTO _containerName
            From Tmp_Material_Container_List

            _message := 'Container "' || Coalesce(_containerName, _containerList) || '" cannot be updated by the website; contact a DMS admin (see UpdateMaterialContainers)';
        End If;

        _returnCode := 'U5111';
        DROP TABLE Tmp_Material_Container_List;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve location to ID (according to mode)
    ---------------------------------------------------
    --
    _location := 'None' -- the null location;
    _locID    := 1      -- the null location;

    If _mode = 'move_container' Then
    -- <c>
        _location := _newValue;

        SELECT ml.location_id,
               COUNT(mc.location_id) AS containers,
               ml.container_limit,
               ml.status
        INTO _locID, _containterCount, _locLimit, _locStatus
        FROM t_material_locations ml
             INNER JOIN t_material_freezers f
               ON ml.freezer_tag = f.freezer_tag
             LEFT OUTER JOIN t_material_containers mc
               ON ml.location_id = mc.location_id
        WHERE ml.location = _location
        GROUP BY ml.location_id, ml.container_limit, ml.status;

        WHERE Location = _location

        If Not FOUND Then
            _message := 'Destination location "' || _location || '" could not be found in database';
            _returnCode := 'U5120';
            DROP TABLE Tmp_Material_Container_List;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Is location suitable?
        ---------------------------------------------------

        If _locStatus <> 'Active' Then
            _message := format('Location "%s" is not in the "Active" state', _location);
            _returnCode := 'U5121';
            DROP TABLE Tmp_Material_Container_List;

            RETURN;
        End If;

        If _containterCount + _numContainers > _locLimit Then
            _message := format('The maximum container capacity (%s) of location "%s" would be exceeded by the move', _locLimit, _location);
            _returnCode := 'U5123';
            DROP TABLE Tmp_Material_Container_List;

            RETURN;
        End If;

    End If; -- </c>

    ---------------------------------------------------
    -- Determine whether or not any containers have contents
    ---------------------------------------------------
    --
    SELECT COUNT(*)
    INTO _nonEmptyContainerCount
    FROM Tmp_Material_Container_List
    WHERE ItemCount > 0;

    ---------------------------------------------------
    -- For 'plain' container retirement
    -- container must be empty
    ---------------------------------------------------
    --
    If _mode = 'retire_container' AND _nonEmptyContainerCount > 0 Then
        If _numContainers = 1 Then
            _message := 'Container ' || _containerList || ' is not empty; cannot retire it';
        Else
            SELECT string_agg(Name, ', ')
            INTO _nonEmptyContainers
            FROM Tmp_Material_Container_List
            WHERE ItemCount > 0
            ORDER BY Name;

            _message := 'All containers must be empty in order to retire them; see ' || _nonEmptyContainers;
        End If;

        _returnCode := 'U5124';
        DROP TABLE Tmp_Material_Container_List;

        RETURN;
    End If;

    ---------------------------------------------------
    -- For 'contents' container retirement
    -- retire contents as well
    ---------------------------------------------------

    -- Arrange for containers and their contents to have common comment
    -- Example comment: CR-2022.08.11_14:23:11

    If _mode = 'retire_container_and_contents' AND _comment = '' Then
        _comment := format('CR-%s', to_char(CURRENT_TIMESTAMP, 'yyyy.mm.dd_hh24:mi:ss'));
    End If;

    -- Retire the contents
    If _mode = 'retire_container_and_contents' AND _nonEmptyContainerCount > 0 Then
        Call update_material_items (
                    'retire_items',
                    containerList,
                    'containers',
                    '',
                    _comment,
                    _message => _message,           -- Output
                    _returnCode => _returnCode,     -- Output
                    _callingUser => _callingUser);

        If _returnCode <> '' Then
            DROP TABLE Tmp_Material_Container_List;
            RETURN;
        End If;
    End If;

    If _mode = 'unretire_container' Then
        -- Make sure the container(s) are all Inactive
        If Exists (SELECT * FROM Tmp_Material_Container_List WHERE Status <> 'Inactive') Then
            If _numContainers = 1 Then
                _message := 'Container is already active; cannot unretire ' || _containerList;
            Else
                _message := 'All containers must be Inactive in order to unretire them: ' || _containerList;
            End If;

            _returnCode := 'U5125';
            DROP TABLE Tmp_Material_Container_List;

            RETURN;
        End If;
     End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    Begin transaction _transName

    ---------------------------------------------------
    -- Update containers to be at new location
    ---------------------------------------------------

    UPDATE t_material_containers
    Set
        location_id = _locID,
        status = CASE _mode
                    WHEN 'retire_container'              THEN 'Inactive'
                    WHEN 'retire_container_and_contents' THEN 'Inactive'
                    WHEN 'unretire_container'            THEN 'Active'
                    ELSE Status
                 End
    WHERE t_material_containers.ID IN (SELECT ID FROM Tmp_Material_Container_List);

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
        _moveType := 'Unknown container operation';
    End If;

    ---------------------------------------------------
    -- Make log entries
    ---------------------------------------------------
    --
    INSERT INTO t_material_log (
        type,
        item,
        initial_state,
        final_state,
        username,
        comment
    )
    SELECT
        _moveType,
        Name,
        Location,
        _location,
        _callingUser,
        _comment
    FROM Tmp_Material_Container_List
    WHERE Location <> _location Or
          _mode <> 'move_container';

    DROP TABLE Tmp_Material_Container_List;

END
$$;

COMMENT ON PROCEDURE public.update_material_containers IS 'UpdateMaterialContainers';
