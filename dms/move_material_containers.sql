--
-- Name: move_material_containers(text, integer, integer, text, integer, integer, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.move_material_containers(IN _freezertagold text, IN _shelfold integer, IN _rackold integer, IN _freezertagnew text, IN _shelfnew integer, IN _racknew integer, IN _materiallogcomment text DEFAULT 'Rearrange after replacing freezer 1206A'::text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move containers from one location to another
**      Allows for moving between freezers, shelves, and racks, but requires that Row and Col remain unchanged
**      Created in August 2016 to migrate samples from old freezer 1206A to new freezer 1206A, which has more shelves but fewer racks
**
**  Arguments:
**    _freezerTagOld        Old freezer tag
**    _shelfOld             Old shelf
**    _rackOld              Old rack
**    _freezerTagNew        New freezer tag
**    _shelfNew             New shelf
**    _rackNew              New rack
**    _materialLogComment   Comment to store in t_material_log
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Example usage:
**      CALL move_material_containers (
**               _freezerTagOld => '1206A',
**               _shelfOld      => 1,
**               _rackOld       => 1,
**               _freezerTagNew => '1206D',
**               _shelfNew      => 2,
**               _rackNew       => 2,
**               _materialLogComment => 'Move containers from 1206A to 1206D',
**               _infoOnly           => true
**           );
**
**  Auth:   mem
**  Date:   08/03/2016 mem - Initial version
**          08/27/2018 mem - Rename the view Material Location list report view
**          06/21/2022 mem - Use new column name Container_Limit in view V_Material_Location_List_Report
**          02/15/2024 mem - Ported to PostgreSQL
**          04/02/2025 mem - Prevent moving a container to an inactive freezer
**
*****************************************************/
DECLARE
    _containerInfo record;
    _locationTagNew text;
    _locationIDNew int;
    _numContainers int;
    _containterCount int;
    _containterCountLimit int;
    _locationStatus citext;
    _freezerStatus citext;
    _moveStatus citext;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _freezerTagOld := Trim(Coalesce(_freezerTagOld, ''));
    _shelfOld      := Coalesce(_shelfOld, -1);
    _rackOld       := Coalesce(_rackOld, -1);

    _freezerTagNew := Trim(Coalesce(_freezerTagNew, ''));
    _shelfNew      := Coalesce(_shelfNew, -1);
    _rackNew       := Coalesce(_rackNew, -1);

    _materialLogComment := Trim(Coalesce(_materialLogComment, ''));

    _infoOnly      := Coalesce(_infoOnly, true);
    _callingUser   := Trim(Coalesce(_callingUser, ''));

    If _freezerTagOld = '' Then
        _message := 'Old freezer tag must be specified';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _freezerTagNew = '' Then
        _message := 'New freezer tag must be specified';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _shelfOld <= 0 Then
        _message := 'Old shelf must be a positive integer';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _rackOld <= 0 Then
        _message := 'Old rack must be a positive integer';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _shelfNew <= 0 Then
        _message := 'New shelf must be a positive integer';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _rackNew <= 0 Then
        _message := 'New rack must be a positive integer';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _materialLogComment = '' Then
        _materialLogComment := 'Moved container using move_material_containers';
    End If;

    If _callingUser = '' Then
        _callingUser := SESSION_USER;
    End If;

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ContainersToProcess (
        Entry_ID     int  PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1 INCREMENT BY 1),
        Container_ID int  NOT NULL,
        Container    text NOT NULL,
        Type         text NOT NULL,
        Location_ID  int  NOT NULL,
        Location_Tag text NOT NULL,
        Shelf        text NOT NULL,
        Rack         text NOT NULL,
        Row          text NOT NULL,
        Col          text NOT NULL
    );

    CREATE TEMP TABLE Tmp_Move_Status (
        Container_ID     int  NOT NULL,
        Container        text NOT NULL,
        Type             text NOT NULL,
        Location_Old     text NOT NULL,
        Location_Current text NOT NULL,
        Location_New     text NOT NULL,
        LocationIDNew    int  NOT NULL,
        Status           text NULL
    );

    ---------------------------------------------------
    -- Populate the table
    ---------------------------------------------------

    INSERT INTO Tmp_ContainersToProcess (
        Container_ID,
        Container,
        Type,
        Location_ID,
        Location_Tag,
        Shelf,
        Rack,
        Row,
        Col
    )
    SELECT MC.container_id,
           MC.container,
           MC.type,
           MC.location_id,
           ML.location AS Location_Tag,
           ML.shelf,
           ML.rack,
           ML.row,
           ML.col
    FROM t_material_containers MC
         INNER JOIN t_material_locations ML
           ON MC.location_id = ML.location_id
    WHERE ML.freezer_tag = _freezerTagOld AND
          ML.shelf = _shelfOld::text AND
          ML.rack = _rackOld::text
    ORDER BY ML.location, MC.container_ID;

    If Not Exists (SELECT Entry_ID FROM Tmp_ContainersToProcess) Then
        _message := format('No containers found in freezer %s, shelf %s, rack %s',
                           _freezerTagOld, _shelfOld, _rackOld);

        RAISE INFO '';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_ContainersToProcess;
        DROP TABLE Tmp_Move_Status;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Show the matching containers
    ---------------------------------------------------

    RAISE INFO '';

    _formatSpecifier := '%-8s %-12s %-20s %-10s %-11s %-25s';

    _infoHead := format(_formatSpecifier,
                        'Entry_ID',
                        'Container_ID',
                        'Container',
                        'Type',
                        'Location_ID',
                        'Location_Tag'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '--------',
                                 '------------',
                                 '--------------------',
                                 '----------',
                                 '-----------',
                                 '-------------------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT Entry_ID,
               Container_ID,
               Container,
               Type,
               Location_ID,
               Location_Tag
        FROM Tmp_ContainersToProcess
        ORDER BY Entry_ID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.Entry_ID,
                            _previewData.Container_ID,
                            _previewData.Container,
                            _previewData.Type,
                            _previewData.Location_ID,
                            _previewData.Location_Tag
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    ---------------------------------------------------
    -- Step through the containers and update their location
    ---------------------------------------------------

    FOR _containerInfo In
        SELECT Container_ID AS ContainerID,
               Container AS ContainerName,
               -- Location_ID AS LocationIDOld,
               Location_Tag AS LocationTagOld,
               -- Shelf AS ShelfOldText,
               -- Rack AS RackOldText,
               Row,
               Col
        FROM Tmp_ContainersToProcess
        ORDER BY Entry_ID
    LOOP
        _locationTagNew := format('%s.%s.%s.%s.%s', _freezerTagNew, _shelfNew, _rackNew, _containerInfo.Row, _containerInfo.Col);
        _numContainers  := 1;

        SELECT ML.location_id,
               ML.status,
               F.status,
               ML.container_limit,
               COUNT(MC.location_id) AS containers
        INTO _locationIDNew, _locationStatus, _freezerStatus, _containterCountLimit, _containterCount
        FROM public.t_material_locations ML
             INNER JOIN public.t_material_freezers F
               ON ML.freezer_tag = F.freezer_tag
             LEFT OUTER JOIN public.t_material_containers MC
               ON ML.location_id = MC.location_id
        WHERE ML.location = _locationTagNew
        GROUP BY ML.location_id, ML.status, F.status, ML.container_limit;

        If Not FOUND Then
            _message := format('Destination location "%s" does not exist in t_material_locations', _locationTagNew);
            RAISE WARNING '%', _message;
            ROLLBACK;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Is location suitable?
        ---------------------------------------------------

        If _locationStatus <> 'Active' Then
            _message := format('Location "%s" is not in the "Active" state; see t_material_locations', _locationTagNew);
            RAISE WARNING '%', _message;
            ROLLBACK;
            RETURN;
        End If;

        If _freezerStatus <> 'Active' Then
            _message := format('Freezer "%s" is not in the "Active" state; see t_material_freezers', _freezerTagNew);
            RAISE WARNING '%', _message;
            ROLLBACK;
            RETURN;
        End If;

        If _containterCount + _numContainers > _containterCountLimit Then
            _message := format('The maximum container capacity (%s) of location "%s" would be exceeded by the move; see t_material_locations', _containterCountLimit, _locationTagNew);
            RAISE WARNING '%', _message;
            ROLLBACK;
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
            WHERE container_id = _containerInfo.ContainerID;

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
                _containerInfo.ContainerName,
                _containerInfo.LocationTagOld,
                _locationTagNew,
                'pnl\d3l243',
                _materialLogComment
            );

        End If;

        INSERT INTO Tmp_Move_Status (Container_ID, Container, Type, Location_Old, Location_Current, Location_New, LocationIDNew, Status)
        SELECT MC.container_id AS Container_ID,
               MC.container,
               MC.type,
               _containerInfo.LocationTagOld AS Location_Old,
               ML.location AS Location_Current,
               _locationTagNew AS Location_New,
               _locationIDNew AS LocationIDNew,
               _moveStatus
        FROM public.t_material_containers MC
             INNER JOIN public.t_material_locations ML
               ON MC.location_id = ML.location_id
        WHERE MC.container_id = _containerInfo.ContainerID;

    END LOOP;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    RAISE INFO '';

    If Not Exists (SELECT Container_ID FROM Tmp_Move_Status) Then
        RAISE INFO 'No containers were moved';
    Else
        _formatSpecifier := '%-12s %-20s %-10s %-25s %-25s %-25s %-15s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Container_ID',
                            'Container',
                            'Type',
                            'Location_Old',
                            'Location_Current',
                            'Location_New',
                            'Location_ID_New',
                            'Status'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '--------------------',
                                     '----------',
                                     '-------------------------',
                                     '-------------------------',
                                     '-------------------------',
                                     '---------------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Container_ID,
                   Container,
                   Type,
                   Location_Old,
                   Location_Current,
                   Location_New,
                   LocationIDNew,
                   Status
            FROM Tmp_Move_Status
            ORDER BY Container_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Container_ID,
                                _previewData.Container,
                                _previewData.Type,
                                _previewData.Location_Old,
                                _previewData.Location_Current,
                                _previewData.Location_New,
                                _previewData.LocationIDNew,
                                _previewData.Status
                               );

            RAISE INFO '%', _infoData;
        END LOOP;
    End If;

    DROP TABLE Tmp_ContainersToProcess;
    DROP TABLE Tmp_Move_Status;
END
$$;


ALTER PROCEDURE public.move_material_containers(IN _freezertagold text, IN _shelfold integer, IN _rackold integer, IN _freezertagnew text, IN _shelfnew integer, IN _racknew integer, IN _materiallogcomment text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE move_material_containers(IN _freezertagold text, IN _shelfold integer, IN _rackold integer, IN _freezertagnew text, IN _shelfnew integer, IN _racknew integer, IN _materiallogcomment text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.move_material_containers(IN _freezertagold text, IN _shelfold integer, IN _rackold integer, IN _freezertagnew text, IN _shelfnew integer, IN _racknew integer, IN _materiallogcomment text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'MoveMaterialContainers';

