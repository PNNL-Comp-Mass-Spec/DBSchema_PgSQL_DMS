--
-- Name: get_requested_runs_for_grid(text, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_requested_runs_for_grid(IN _itemlist text, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the info for the requested run IDs in itemList
**
**  Arguments:
**    _itemList          Comma-separated list of requested run IDs
**    _results           Cursor for retrieving the results
**    _message           Output: message (if an error)
**    _returnCode        Output: return code (if an error)
**                       supports the % wildcard
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL public.get_requested_runs_for_grid (
**              _itemList => '123456,123457,323457,823457,229733,225708'
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   10/25/2022 mem - Initial version
**          03/28/2023 mem - Use new function name
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------

    _itemList := Coalesce(_itemList, '');

    RAISE INFO '%', _message;

    Open _results For
        SELECT request,
            name,
            status,
            batchID,
            instrument,
            separation_Type,
            experiment,
            cart,
            "column",
            block,
            run_order
        FROM public.get_requested_run_table_for_grid(_itemList);

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

END
$$;


ALTER PROCEDURE public.get_requested_runs_for_grid(IN _itemlist text, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_requested_runs_for_grid(IN _itemlist text, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_requested_runs_for_grid(IN _itemlist text, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'get_requested_runs_for_grid returns results from function get_requested_run_table_for_grid';

