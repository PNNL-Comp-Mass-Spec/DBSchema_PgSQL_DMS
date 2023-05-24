--
CREATE OR REPLACE PROCEDURE public.move_material_containers
(
    _freezerTagOld text,
    _shelfOld int,
    _rackOld int,
    _freezerTagNew text,
    _shelfNew int,
    _rackNew int,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Moves containers from one location to another
**      Allows for moving between freezers, shelves, and racks, but requires that Row and Col remain unchanged
**      Created in August 2016 to migrate samples from old freezer 1206A to new freezer 1206A, which  has more shelves but fewer racks
**
**  Auth:   mem
**  Date:   08/03/2016
**          08/27/2018 mem - Rename the view Material Location list report view
**          06/21/2022 mem - Use new column name Container_Limit in view V_Material_Location_List_Report
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _containerInfo record;
    _locationTagNew text;
    _locationIDNew int;
    _numContainers int;
    _containterCount int;
    _containterCountLimit int;
    _locStatus text;
    _moveStatus text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the Inputs
    ---------------------------------------------------

    _freezerTagOld := Coalesce(_freezerTagOld, '');
    _shelfOld := Coalesce(_shelfOld, -1);
    _rackOld := Coalesce(_rackOld, -1);

    _freezerTagNew := Coalesce(_freezerTagNew, '');
    _shelfNew := Coalesce(_shelfNew, -1);
    _rackNew := Coalesce(_rackNew, -1);
    _infoOnly := Coalesce(_infoOnly, true);
    _callingUser := Coalesce(_callingUser, '');

    If _freezerTagOld = '' Then
        _message := '_freezerTagOld cannot be empty';
        RETURN;
    End If;

    If _freezerTagNew = '' Then
        _message := '_freezerTagNew cannot be empty';
        RETURN;
    End If;

    If _shelfOld <= 0 or _rackOld <= 0 Then
        _message := '_shelfOld and _rackOld must be positive integers';
        RETURN;
    End If;

    If _shelfNew <= 0 or _rackNew <= 0 Then
        _message := '_shelfNew and _rackNew must be positive integers';
        RETURN;
    End If;

    If _callingUser = '' Then
        _callingUser := session_user;
    End If;

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_ContainersToProcess (
        Entry_ID     int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1)
        MC_ID        int NOT NULL,
        Container    text NOT NULL,
        Type       text NOT NULL,
        Location_ID  int NOT NULL,
        Location_Tag text NOT NULL,
        Shelf        text NOT NULL,
        Rack         text NOT NULL,
        Row          text NOT NULL,
        Col          text NOT NULL
    )

    CREATE TEMP TABLE Tmp_Move_Status (
        Container_ID     int NOT NULL,
        Container        text NOT NULL,
        Type           text NOT NULL,
        Location_Old     text NOT NULL,
        Location_Current text NOT NULL,
        Location_New     text NOT NULL,
        LocationIDNew    int NOT NULL,
        Status           text NULL
    )

    ---------------------------------------------------
    -- Populate the table
    ---------------------------------------------------
    --
    INSERT INTO Tmp_ContainersToProcess (MC_ID, container, type, location_id, Location_Tag, Shelf, Rack, Row, Col )
    SELECT MC.container_id AS MC_ID,
           MC.container AS Container,
           MC.type,
           MC.location_id,
           ML.location AS Location_Tag,
           ML.shelf,
           ML.rack,
           ML.row,
           ML.col
    FROM t_material_containers MC
         INNER JOIN t_material_locations ML
           ON MC.location_id = ML.container_id
    WHERE ML.freezer_tag = _freezerTagOld AND
          ML.shelf = CAST(_shelfOld AS text) AND
          ML.rack = CAST(_rackOld AS text)
    ORDER BY ML.location;

    If Not Exists (SELECT * FROM Tmp_ContainersToProcess) Then
        _message := format('No containers found in freezer %s, shelf %s, rack %s',
                            _freezerTagOld, _shelfOld, _rackOld);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Show the matching containers
    ---------------------------------------------------

    -- ToDo: Show this info using RAISE INFO

    SELECT *
    FROM Tmp_ContainersToProcess

    ---------------------------------------------------
    -- Step through the containers and update their location
    ---------------------------------------------------
    --

    _continue := true;

    FOR _containerInfo In
        SELECT Entry_ID AS EntryID
               MC_ID As ContainerID,
               Container As ContainerName,
               Location_ID As LocationIDOld,
               Location_Tag As LocationTagOld,
               Shelf As ShelfOldText,
               Rack As RackOldText,
               Row,
               Col
        FROM Tmp_ContainersToProcess
        ORDER BY Entry_ID

    LOOP
        _locationTagNew := _freezerTagNew || '.' || CAST(_shelfNew as text) || '.' || CAST(_rackNew as text) || '.' || _row || '.' || _col;
        _numContainers := 1;

        SELECT ml.location_id,
               ml.status,
               ml.container_limit,
               COUNT(mc.location_id) AS containers
        INTO _locationIDNew, _locStatus, _containterCountLimit, _containterCount
        FROM public.t_material_locations ml
             INNER JOIN public.t_material_freezers f
               ON ml.freezer_tag = f.freezer_tag
             LEFT OUTER JOIN public.t_material_containers mc
               ON ml.location_id = mc.location_id
        WHERE ml.location = _locationTagNew
        GROUP BY ml.location_id, ml.status, ml.container_limit;

        If Not FOUND Then
            _message := format('Destination location "%s" could not be found in database', _locationTagNew);
            ROLLBACK;

            DROP TABLE Tmp_ContainersToProcess;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Is location suitable?
        ---------------------------------------------------

        If _locStatus <> 'Active' Then
            _message := format('Location "%s" is not in the "Active" state', _locationTagNew);
            ROLLBACK;

            DROP TABLE Tmp_ContainersToProcess;
            RETURN;
        End If;

        If _containterCount + _numContainers > _containterCountLimit Then
            _message := format('The maximum container capacity (%s) of location "%s" would be exceeded by the move', _containterCountLimit, _locationTagNew);
            ROLLBACK;

            DROP TABLE Tmp_ContainersToProcess;
            RETURN;
        End If;

        If _infoOnly Then
            _moveStatus := 'Preview';
        Else
            _moveStatus := 'Moved';

            ---------------------------------------------------
            -- Update container to be at new location
            ---------------------------------------------------

            UPDATE t_material_containers
            SET location_id = _locationIDNew
            WHERE container_id = _containerID;

            INSERT INTO t_material_log (
                type,
                item,
                initial_state,
                final_state,
                username,
                comment
            )
            VALUES (
                'move_container',
                _containerName,
                _locationTagOld,
                _locationTagNew,
                'pnl\d3l243',
                'Rearrange after replacing freezer 1206A'
            )

        End If;

        INSERT INTO Tmp_Move_Status (Container_ID, Container, Type, Location_Old, Location_Current, Location_New, LocationIDNew, Status)
        SELECT mc.container_id AS Container_ID,
               mc.container,
               mc.type,
               _locationTagOld AS Location_Old,
               ml.location AS Location_Current,
               _locationTagNew AS Location_New,
               _locationIDNew AS LocationIDNew,
               _moveStatus
        FROM public.t_material_containers mc
             INNER JOIN public.t_material_locations ml ON mc.location_id = ml.location_id
        WHERE mc.container_id = _containerID;

    END LOOP;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    -- ToDo: Show this info using RAISE INFO

    SELECT * FROM Tmp_Move_Status;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_ContainersToProcess;
    DROP TABLE Tmp_Move_Status;
END
$$;

COMMENT ON PROCEDURE public.move_material_containers IS 'MoveMaterialContainers';
