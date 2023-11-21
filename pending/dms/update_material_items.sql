--
CREATE OR REPLACE PROCEDURE public.update_material_items
(
    _mode text,
    _itemList text,
    _itemType text,
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
**      Makes changes for specified list of material items
**
**  Arguments:
**    _mode       'move_material', 'retire_items'
**    _itemList   Either list of material IDs with type tag prefixes (e.g. E:8432,E:8434,E:9786), or list of container IDs (integers)
**    _itemType   'mixed_material' or 'containers'
**
**  Auth:   grk
**  Date:   03/27/2008 grk - Initial release (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          07/24/2008 grk - Added retirement mode
**          09/14/2016 mem - When retiring a single experiment, will abort and update _message if the experiment is already retired
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/28/2017 mem - Add support for Reference_Compound
**                         - Only update Container_ID if _mode is 'move_material'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _container text := 'na';
    _contID int;
    _contStatus text;
    _mixedMaterialCount int;
    _experimentCount int;
    _retiredExperiment text := '';
    _moveType text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Default container to null container
    ---------------------------------------------------

    _contID := 1;

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

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Resolve container name to actual ID (if applicable)
    ---------------------------------------------------

    If _mode = 'move_material' And _newValue = '' Then
        _message := 'No destination container was provided';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _mode = 'move_material' Then

        SELECT
            _contID = container_id,
            _contStatus = status
        FROM t_material_containers
        WHERE container = _container;

        If Not FOUND Then
            _message := format('Destination container "%s" could not be found in database', _container);
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Is container a valid target?
        ---------------------------------------------------

        If _contStatus <> 'Active' Then
            _message := format('Container "%s" must be in "Active" state to receive material', _container);
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Temporary table to hold material items
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Material_Items (
        ID int,
        itemType text,            -- B for Biomaterial, E for Experiment, R for RefCompound
        itemName text NULL,
        itemContainer text NULL
    );

    If _itemType::citext = 'mixed_material' Then

        ---------------------------------------------------
        -- Populate temporary table from type-tagged list
        -- of material items, if applicable
        ---------------------------------------------------

        -- _itemList is a comma-separated list of items of the form Type:ID, for example 'E:8432,E:8434,E:9786'
        -- This is a list of three experiments, IDs 8432, 8434, and 9786

        INSERT INTO Tmp_Material_Items ( ID, itemType )
        SELECT Substring(Value, 3, 300) AS ID,
               Upper(Substring(Value, 1, 1)) AS itemType        -- B for Biomaterial, E for Experiment, R for RefCompound
        FROM public.parse_delimited_list(_itemList)
        --
        GET DIAGNOSTICS _mixedMaterialCount = ROW_COUNT;

        ---------------------------------------------------
        -- Update temporary table with information from
        -- biomaterial entities (if any)
        -- They have itemType = 'B'
        ---------------------------------------------------

        UPDATE Tmp_Material_Items
        SET itemName = V.Name,
            itemContainer = V.Container
        FROM V_Biomaterial_List_Report_2 V
        WHERE Tmp_Material_Items.itemType = 'B' AND
              V.ID = Tmp_Material_Items.ID;

        ---------------------------------------------------
        -- Update temporary table with information from
        -- experiment entities (if any)
        -- They have itemType = 'E'
        ---------------------------------------------------

        UPDATE Tmp_Material_Items
        SET itemName = V.Experiment,
            itemContainer = V.Container
        FROM V_Experiment_List_Report_2 V
        WHERE Tmp_Material_Items.itemType = 'E' AND
              V.ID = Tmp_Material_Items.ID;
        --
        GET DIAGNOSTICS _experimentCount = ROW_COUNT;

        ---------------------------------------------------
        -- Update temporary table with information from
        -- reference compound entities (if any)
        -- They have itemType = 'R'
        ---------------------------------------------------

        UPDATE Tmp_Material_Items
        SET itemName = V.Name,
            itemContainer = V.Container
        FROM V_Reference_Compound_List_Report V
        WHERE Tmp_Material_Items.itemType = 'R' AND
              V.ID = Tmp_Material_Items.ID;

        If _mode = 'retire_items' And _mixedMaterialCount = 1 And _experimentCount = 1 Then
            -- Retiring a single experiment
            -- Check whether the item being updated is already retired

            SELECT experiment
            INTO _retiredExperiment
            FROM t_experiments
            WHERE exp_id IN ( SELECT ID
                              FROM Tmp_Material_Items
                              WHERE itemType = 'E' ) AND
                  container_id = _contID AND
                  material_active = 'Inactive'

            If Coalesce(_retiredExperiment, '') <> '' Then
                -- Yes, the experiment is already retired

                _message := format('Experiment is already retired (inactive and no container): %s', _retiredExperiment);
                RAISE WARNING '%', _message;

                _returnCode := 'U5205';
                DROP TABLE Tmp_Material_Items;

                RETURN;
            End If;
        End If;

    End If;

    If _itemType::citext = 'containers' Then

        ---------------------------------------------------
        -- Populate material item list with items contained
        -- by containers given in input list, if applicable
        ---------------------------------------------------

        INSERT INTO Tmp_Material_Items
            (container_id, itemType, itemName, itemContainer)
        SELECT
            T.Item_ID,
            T.Item_Type,    -- B for Biomaterial, E for experiment, R for RefCompound
            T.Item,
            t_material_containers.container
        FROM
            t_material_containers INNER JOIN
            (
                SELECT Biomaterial_Name AS Item,
                       'B' AS Item_Type,            -- Biomaterial
                       Container_ID
                       Biomaterial_ID AS Item_ID
                FROM t_biomaterial
                UNION
                SELECT experiment AS Item,
                       'E' AS Item_Type,            -- Experiment
                       container_id
                       exp_id AS Item_ID
                FROM t_experiments
                UNION
                SELECT compound_name AS Item,
                       'R' AS Item_Type,            -- Reference Compound
                       container_id AS container_id,
                       compound_id AS Item_ID
                FROM t_reference_compound
            ) AS T ON T.container_id = t_material_containers.container_id
        WHERE T.container_id in (SELECT Value FROM public.parse_delimited_integer_list(_itemList));

    End If;

    ---------------------------------------------------
    -- Update container reference to destination container
    -- and update material status (if retiring)
    -- for biomaterial items (if any)
    ---------------------------------------------------

    UPDATE t_biomaterial
    SET Container_ID = CASE
                       WHEN _mode = 'move_material' THEN _contID
                       ELSE Container_ID
                       END,
        Material_Active = CASE
                          WHEN _mode = 'retire_items' THEN 'Inactive'
                          ELSE Material_Active
                          END
    WHERE Biomaterial_ID IN ( SELECT ID FROM Tmp_Material_Items WHERE itemType = 'B' );

    ---------------------------------------------------
    -- Update container reference to destination container
    -- and update material status (if retiring)
    -- for experiment items (if any)
    ---------------------------------------------------

    UPDATE t_experiments
    SET container_id = CASE
                       WHEN _mode = 'move_material' THEN _contID
                       ELSE container_id
                       END,
        material_active = CASE
                          WHEN _mode = 'retire_items' THEN 'Inactive'
                          ELSE material_active
                          END
    WHERE Exp_ID IN (SELECT ID FROM Tmp_Material_Items WHERE itemType = 'E')

    ---------------------------------------------------
    -- Update container reference to destination container
    -- for reference compounds (if any)
    ---------------------------------------------------

    UPDATE t_reference_compound
    SET container_id = CASE
                       WHEN _mode = 'move_material' THEN _contID
                       ELSE Container_ID
                       END,
        Active = CASE
                 WHEN _mode = 'retire_items' THEN 0
                 ELSE Active
                 END
    WHERE Compound_ID IN (SELECT ID FROM Tmp_Material_Items WHERE itemType = 'R')

    ---------------------------------------------------
    -- Set up appropriate label for log
    ---------------------------------------------------

    If _mode = 'retire_items' Then
        _moveType := 'Material Retirement';
    ElsIf _mode = 'move_material' Then
        _moveType := 'Material Move';
    Else
        _moveType := '??';
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
    SELECT
        format('%s %s', itemType, _moveType),
        itemName,
        itemContainer,
        _container,
        _callingUser,
        _comment
    FROM Tmp_Material_Items

    DROP TABLE Tmp_Material_Items;

END
$$;

COMMENT ON PROCEDURE public.update_material_items IS 'UpdateMaterialItems';
