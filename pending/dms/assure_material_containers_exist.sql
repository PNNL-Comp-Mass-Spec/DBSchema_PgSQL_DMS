--
CREATE OR REPLACE PROCEDURE public.assure_material_containers_exist
(
    INOUT _containerList text,
    _comment text,
    _type text = 'Box',
    _researcher text,
    _mode text = 'verify_only',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines the list of containers and/or locations in _containerList
**      For items that are locations, creates a new container by calling add_update_material_container
**      Returns a consolidated list of container names
**
**  Arguments:
**    _containerList        Input / Output: Comma-separated list of locations and containers (can be a mix of both)
**    _comment              Comment
**    _type                 Container type: 'Box', 'Bag', or 'Wellplate'
**    _researcher           Researcher name; supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
**    _mode                 Typically 'add' or 'create'
**                          However, if _mode is 'verify_only', will populate a temporary table with items in _containerList, then will exit the procedure without making any changes
**
**  Returns:
**    Comma-separated list of container names (via argument _containerList)
**
**  Auth:   grk
**  Date:   04/27/2010 grk - Initial release
**          09/23/2011 grk - Accomodate researcher field in AddUpdateMaterialContainer
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/04/2023 mem - Use TOP 1 when retrieving the next item to process
**
*****************************************************/
DECLARE
    _msg text;
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
            Container text NULL,
            Item text,                  -- Either container name or location name
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
        WHERE Not IsLocation AND Not IsContainer;

        If Coalesce(_msg, '') <> '' Then
            RAISE EXCEPTION 'Item(s) "%" is/are not containers or locations', _msg;
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

        WHILE true
        LOOP

            SELECT Item
            INTO _item
            FROM Tmp_ContainerItems
            WHERE IsLocation
            LIMIT 1;

            If Not FOUND Then
                -- Break out of the while loop
                EXIT;
            Else
                _container := '(generate name)';

                CALL public.add_update_material_container (
                                _container   => _container,     -- Output
                                _type        => _type,
                                _location    => _item,
                                _comment     => _comment,
                                _barcode     => '',
                                _researcher  => _researcher,
                                _mode        => 'add',
                                _message     => _msg,           -- Output
                                _returnCode  => _returnCode,    -- Output
                                _callingUser => _callingUser);

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'AddUpdateMaterialContainer: %', _msg;
                End If;

                UPDATE Tmp_ContainerItems
                SET Container = _container,
                    IsContainer = true,
                    IsLocation = false
                WHERE Item = _item;
            End If;
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

COMMENT ON PROCEDURE public.assure_material_containers_exist IS 'AssureMaterialContainersExist';
