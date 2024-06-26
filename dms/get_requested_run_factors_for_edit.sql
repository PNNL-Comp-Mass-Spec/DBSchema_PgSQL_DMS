--
-- Name: get_requested_run_factors_for_edit(text, text, boolean, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_requested_run_factors_for_edit(IN _itemlist text, IN _itemtype text DEFAULT 'Batch_ID'::text, IN _infoonly boolean DEFAULT false, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the factors associated with the requested runs associated with the items specified by _itemList
**
**  Arguments:
**    _itemList     Comma-separated list of item IDs
**    _itemType     Item type: Batch_ID, Requested_Run_ID, Dataset_Name, Dataset_ID, Experiment_Name, Experiment_ID, or Data_Package_ID
**    _infoOnly     When true, show the SQL used to display the factors associated with the matching requested runs
**    _results      Cursor for obtaining results
**    _message      Status message
**    _returnCode   Return code
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.get_requested_run_factors_for_edit (
**              _itemList => '8603, 9066',
**              _itemType => 'Batch_ID',
**              _infoOnly => false
**          );
**          FETCH ALL FROM _results;
**      END;
**
**      BEGIN;
**          CALL public.get_requested_run_factors_for_edit (
**              _itemList => '1123361, 1123374, 1147991',
**              _itemType =>  'Requested_Run_ID',
**              _infoOnly => false
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**  For an example, see procedure public.get_factor_crosstab_by_batch()
**
**  Auth:   grk
**  Date:   02/20/2010
**          03/02/2010 grk - Added status field to requested run
**          03/08/2010 grk - Improved field validation
**          03/18/2010 grk - Eliminated call to Get_Factor_Crosstab_By_Factor_ID
**          01/23/2023 mem - Use lowercase column names when querying V_Requested_Run_Unified_List
**          07/14/2023 mem - Ported to PostgreSQL
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

    If _itemType Is Null Then
        RAISE WARNING '_itemType is null';
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
    -- Populate Tmp_RequestIDs with the requests that correspond to the items in _itemList
    -----------------------------------------

    INSERT INTO Tmp_RequestIDs (Request)
    SELECT request_id
    FROM public.get_requested_runs_from_item_list(_itemList, _itemType);

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    -- If the batch has additional factors, they will be shown after the request column
    -----------------------------------------

    _colList := ' ''x'' AS sel, batch_id, experiment, dataset, name, status, request';

    SELECT make_factor_crosstab_sql (_colList)
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


ALTER PROCEDURE public.get_requested_run_factors_for_edit(IN _itemlist text, IN _itemtype text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_requested_run_factors_for_edit(IN _itemlist text, IN _itemtype text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_requested_run_factors_for_edit(IN _itemlist text, IN _itemtype text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'GetRequestedRunFactorsForEdit';

