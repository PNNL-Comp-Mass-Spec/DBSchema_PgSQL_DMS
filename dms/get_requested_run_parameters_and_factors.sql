--
-- Name: get_requested_run_parameters_and_factors(text, boolean, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_requested_run_parameters_and_factors(IN _itemlist text, IN _infoonly boolean DEFAULT false, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the run parameters and factors associated with the requested runs in the input list
**
**      This is used by http://dms2.pnl.gov/requested_run_batch_blocking/grid
**
**  Arguments:
**    _itemList     Comma-separated list of request IDs
**    _infoOnly     When true, show the SQL used to display the factors associated with the requested runs in _itemList
**    _results      Cursor for obtaining results
**    _message      Status message
**    _returnCode   Return code
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.get_requested_run_parameters_and_factors (
**              _itemList => '1123361, 1123374, 1147991',
**              _infoOnly => false
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**  For an example, see procedure public.get_factor_crosstab_by_batch()
**
**  Auth:   grk
**  Date:   03/28/2013
**          03/28/2013 grk - Cloned from GetFactorCrosstabByBatch
**          01/24/2023 bcg - Use lowercase column names in _colList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _colList text;
    _sql text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    If _itemList Is Null Then
        RAISE WARNING '_itemList is null';
        RETURN;
    End If;

    -----------------------------------------
    -- Temp tables to hold list of requests and factors
    --
    -- This procedure populates Tmp_RequestIDs
    -- Procedure make_factor_crosstab_sql will populate Tmp_Factors
    -----------------------------------------

    DROP TABLE IF EXISTS Tmp_RequestIDs;
    DROP TABLE IF EXISTS Tmp_Factors;

    CREATE TEMP TABLE Tmp_RequestIDs (
        Request int
    );

    CREATE TEMP TABLE Tmp_Factors (
        FactorID int,
        FactorName citext NULL
    );

    -----------------------------------------
    -- Populate Tmp_RequestIDs with requested run IDs
    -----------------------------------------

    INSERT INTO Tmp_RequestIDs (Request)
    SELECT Value
    FROM public.parse_delimited_integer_list(_itemList);

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    -- If the batch has additional factors, they will be shown after the run_order column
    -----------------------------------------

    _colList := 'request, name, status, batch, experiment, dataset, instrument, cart, lc_col, block, run_order';

    SELECT make_factor_crosstab_sql (_colList, _viewName => 'V_Requested_Run_Unified_List_Ex')
    INTO _sql;

    -----------------------------------------
    -- Return the output table
    -- Either show the dynamic SQL or execute the SQL and return the results
    -----------------------------------------

    If _infoOnly Then
        RAISE INFO '%', _sql;
    Else
        Open _results For
            EXECUTE _sql;
    End If;

    -- Do not drop Tmp_RequestIDs or Tmp_Factors, since the cursor accesses them

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
END
$$;


ALTER PROCEDURE public.get_requested_run_parameters_and_factors(IN _itemlist text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_requested_run_parameters_and_factors(IN _itemlist text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_requested_run_parameters_and_factors(IN _itemlist text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'GetRequestedRunParametersAndFactors';

