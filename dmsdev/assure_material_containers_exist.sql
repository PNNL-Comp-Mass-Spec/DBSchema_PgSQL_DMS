--
-- Name: assure_material_containers_exist(text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.assure_material_containers_exist(INOUT _containerlist text, IN _comment text, IN _type text, IN _campaignname text, IN _researcher text, IN _mode text DEFAULT 'verify_only'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine the list of containers and/or locations in _containerList
**
**      For items that are locations, creates a new container by calling add_update_material_container
**
**  Arguments:
**    _containerList        Input/Output: Comma-separated list of locations and containers (can be a mix of both)
**    _comment              Comment
**    _type                 Container type: 'Box', 'Bag', or 'Wellplate'
**    _campaignName         Campaign name
**    _researcher           Researcher name; supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
**    _mode                 If 'verify_only', populates a temporary table with items in _containerList, then exits the procedure without making any changes
**                          Otherwise, creates missing containers (including assuring that each location has a container)
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Returns:
**      Comma-separated list of container names (via argument _containerList)
**
**  Auth:   grk
**  Date:   04/27/2010 grk - Initial release
**          09/23/2011 grk - Accomodate researcher field in add_update_material_container
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/04/2023 mem - Use TOP 1 when retrieving the next item to process
**          11/19/2023 mem - Add procedure argument _campaignName
**          11/20/2023 mem - Ported to PostgreSQL
**          01/08/2024 mem - Remove procedure name from error message
**
*****************************************************/
DECLARE
    _msg text;
    _entryID int;
    _item text;
    _container text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Get container list items into temp table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_ContainerItems (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Container citext NULL,
            Item citext,                  -- Either container name or location name
            IsContainer boolean,
            IsLocation boolean
        );

        INSERT INTO Tmp_ContainerItems (Item, IsContainer, IsLocation)
        SELECT Value, false, false
        FROM public.parse_delimited_list(_containerList);

        ---------------------------------------------------
        -- Mark list items as either container or location
        ---------------------------------------------------

        UPDATE Tmp_ContainerItems
        SET IsContainer = true,
            Container = Item
        FROM t_material_containers
        WHERE Item = t_material_containers.container;

        UPDATE Tmp_ContainerItems
        SET IsLocation = true
        FROM t_material_locations
        WHERE Item = t_material_locations.location;

        ---------------------------------------------------
        -- Quick check of list
        ---------------------------------------------------

        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _msg
        FROM Tmp_ContainerItems
        WHERE NOT IsLocation AND NOT IsContainer;

        If Coalesce(_msg, '') <> '' Then
            If Position(',' IN _msg) > 0 Then
                RAISE EXCEPTION 'Items "%" are not containers or locations', _msg;
            Else
                RAISE EXCEPTION 'Item "%" is not a container or location', _msg;
            End If;
        Else
            _msg := '';
        End If;

        If _mode = 'verify_only' Then
            DROP TABLE Tmp_ContainerItems;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make new containers for locations
        ---------------------------------------------------

        FOR _entryID, _item IN
            SELECT Entry_ID, Item
            FROM Tmp_ContainerItems
            WHERE IsLocation
            ORDER BY Entry_ID
        LOOP
            _container := '(generate name)';

            CALL public.add_update_material_container (
                            _container    => _container,     -- Output
                            _type         => _type,
                            _location     => _item,
                            _comment      => _comment,
                            _campaignName => _campaignName,
                            _researcher   => _researcher,
                            _mode         => 'add',
                            _message      => _msg,           -- Output
                            _returnCode   => _returnCode,    -- Output
                            _callingUser  => _callingUser);

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

            UPDATE Tmp_ContainerItems
            SET Container = _container,
                IsContainer = true,
                IsLocation = false
            WHERE Entry_ID = _entryID;
        END LOOP;

        ---------------------------------------------------
        -- Make consolidated list of containers
        ---------------------------------------------------

        SELECT string_agg(Container, ', ' ORDER BY Container)
        INTO _containerList
        FROM Tmp_ContainerItems
        WHERE NOT Container IS NULL;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_ContainerItems;
END
$$;


ALTER PROCEDURE public.assure_material_containers_exist(INOUT _containerlist text, IN _comment text, IN _type text, IN _campaignname text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE assure_material_containers_exist(INOUT _containerlist text, IN _comment text, IN _type text, IN _campaignname text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.assure_material_containers_exist(INOUT _containerlist text, IN _comment text, IN _type text, IN _campaignname text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AssureMaterialContainersExist';

