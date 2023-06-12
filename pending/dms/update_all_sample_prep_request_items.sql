--
CREATE OR REPLACE PROCEDURE public.update_all_sample_prep_request_items
(
    _daysPriorToUpdateClosedRequests int = 365,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Calls update sample prep request items for all active sample prep requests
**
**  Auth:   grk
**  Date:   07/05/2013 grk - Initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/15/2021 mem - Also update counts for prep requests whose state changed within the last year
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _itemType text := '';
    _callingUser text := session_user;
    _currentId int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _daysPriorToUpdateClosedRequests := Abs(Coalesce(_daysPriorToUpdateClosedRequests, 365));

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

    BEGIN

        ---------------------------------------------------
        -- Create and populate table to hold active package IDs
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_PrepRequestItems (
            ID int
        );

        -- Update counts for active prep requests
        INSERT INTO Tmp_PrepRequestItems ( prep_request_id )
        SELECT prep_request_id
        FROM t_sample_prep_request
        WHERE state_id IN (2, 3, 4);

        -- Also update counts for closed prep requests where the state changed within the last year
        INSERT INTO Tmp_PrepRequestItems ( prep_request_id )
        SELECT prep_request_id
        FROM t_sample_prep_request
        WHERE state_id = 5 And state_changed >= CURRENT_TIMESTAMP - make_interval(days => _daysPriorToUpdateClosedRequests);

        ---------------------------------------------------
        -- Cycle through active packages and do auto import
        -- for each one
        ---------------------------------------------------

        FOR _currentId IN
            SELECT ID
            FROM Tmp_PrepRequestItems
            ORDER BY ID
        LOOP
            CALL update_sample_prep_request_items (
                    _currentId,
                    _mode => 'update',
                    _message => _message,           -- Output
                    _returnCode => _returncode,     -- Output
                    _callingUser) => _callingUser;
/*
            CALL update_osm_package_items
                                _currentId,
                                _itemType,
                                _itemList,
                                _comment,
                                _mode,
                                _message output,
                                _callingUser
*/
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

    DROP TABLE IF EXISTS Tmp_PrepRequestItems;
END
$$;

COMMENT ON PROCEDURE public.update_all_sample_prep_request_items IS 'UpdateAllSamplePrepRequestItems';
