--
-- Name: update_all_sample_prep_request_items(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_all_sample_prep_request_items(IN _dayspriortoupdateclosedrequests integer DEFAULT 365, IN _preprequestidfilterlist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Call update_sample_prep_request_items() for all active sample prep requests, updating table T_Sample_Prep_Request_Items
**      Also update items for closed sample prep requests where the state was changed within the last year (customizable using _daysPriorToUpdateClosedRequests)
**
**  Arguments:
**    _daysPriorToUpdateClosedRequests  Update prep requests whose state changed within this number of days before today
**    _prepRequestIDFilterList          Optional commma-separated list of prep request IDs to update; if defined, _daysPriorToUpdateClosedRequests is ignored
**    _message                          Status message
**    _returnCode                       Return code
**
**  Auth:   grk
**  Date:   07/05/2013 grk - Initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/15/2021 mem - Also update counts for prep requests whose state changed within the last year
**          10/19/2023 mem - Also update counts for prep requests with state 1 (New)
**                         - Ported to PostgreSQL, adding parameter _prepRequestIDFilterList
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _itemType text := '';
    _callingUser text := SESSION_USER;
    _currentId int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _daysPriorToUpdateClosedRequests := Abs(Coalesce(_daysPriorToUpdateClosedRequests, 365));
    _prepRequestIDFilterList := Trim(Coalesce(_prepRequestIDFilterList, ''));

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
        -- Create and populate table to hold prep request IDs to process
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_PrepRequests (
            prep_request_id int
        );

        If _prepRequestIDFilterList = '' Then

            -- Update counts for new and active prep requests
            INSERT INTO Tmp_PrepRequests (prep_request_id)
            SELECT prep_request_id
            FROM t_sample_prep_request
            WHERE state_id IN (1, 2, 3, 4);

            -- Also update counts for closed prep requests where the state changed within the last year
            INSERT INTO Tmp_PrepRequests (prep_request_id)
            SELECT prep_request_id
            FROM t_sample_prep_request
            WHERE state_id = 5 AND
                  state_changed >= CURRENT_TIMESTAMP - make_interval(days => _daysPriorToUpdateClosedRequests);
        Else
            INSERT INTO Tmp_PrepRequests (prep_request_id)
            SELECT DISTINCT Value
            FROM public.parse_delimited_integer_list(_prepRequestIDFilterList);

            If Not Exists (SELECT * FROM Tmp_PrepRequests) Then
                RAISE WARNING 'Did not find any integers in _prepRequestIDFilterList';
                DROP TABLE Tmp_PrepRequests;
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Process the sample prep requests in Tmp_PrepRequests
        ---------------------------------------------------

        FOR _currentId IN
            SELECT prep_request_id
            FROM Tmp_PrepRequests
            ORDER BY prep_request_id
        LOOP
            CALL public.update_sample_prep_request_items (
                            _currentId,
                            _mode        => 'update',
                            _message     => _message,      -- Output
                            _returnCode  => _returncode,   -- Output
                            _callingUser => _callingUser);
        END LOOP;

        DROP TABLE Tmp_PrepRequests;
        RETURN;

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

    DROP TABLE IF EXISTS Tmp_PrepRequests;
END
$$;


ALTER PROCEDURE public.update_all_sample_prep_request_items(IN _dayspriortoupdateclosedrequests integer, IN _preprequestidfilterlist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_all_sample_prep_request_items(IN _dayspriortoupdateclosedrequests integer, IN _preprequestidfilterlist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_all_sample_prep_request_items(IN _dayspriortoupdateclosedrequests integer, IN _preprequestidfilterlist text, INOUT _message text, INOUT _returncode text) IS 'UpdateAllSamplePrepRequestItems';

