--
CREATE OR REPLACE PROCEDURE dpkg.auto_import_osm_package_items (  )
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Calls auto import function for all currently active OSM packages
**
**  Auth:   grk
**  Date:   03/20/2013 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentId int := 0;
    _prevId int := 0;
    _continue boolean := true;

    _itemType text := '';
    _itemList text := '';
    _comment text := '';
    _mode text := 'auto-import';
    _callingUser text;

    _message text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';

    BEGIN

        ---------------------------------------------------
        -- Create and populate table to hold active package IDs
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_OSM_Pkgs (
            ID INT
            -- FUTURE: details about auto-update
        )

        INSERT INTO Tmp_OSM_Pkgs ( ID )
        SELECT ID
        FROM t_osm_package
        WHERE State = 'Active';

        _callingUser := session_user;

        ---------------------------------------------------
        -- Cycle through active packages and do auto import
        -- for each one
        ---------------------------------------------------

        WHILE _continue
        LOOP
            SELECT ID
            INTO _currentId
            FROM Tmp_OSM_Pkgs
            WHERE ID > _prevId
            ORDER BY ID
            LIMIT 1;

            If Not Found Then
                -- Break out of the while loop
                EXIT;
            End If;

            _prevId := _currentId;
            -- SELECT '->' + CONVERT(text, _currentId)

            CALL Update_OSM_Package_Items (
                    _currentId,
                    _itemType,
                    _itemList,
                    _comment,
                    _mode,
                    _message => _message,      -- Output
                    _returnCode => _returnCode,      -- Output
                    _callingUser => _callingUser);

        END LOOP;

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

    DROP TABLE IF EXISTS Tmp_OSM_Pkgs;
END
$$;

COMMENT ON PROCEDURE dpkg.auto_import_osm_package_items IS 'AutoImportOSMPackageItems';
