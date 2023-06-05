--
CREATE OR REPLACE FUNCTION public.get_requested_run_parameters_and_factors
(
    _itemList TEXT,
    _infoOnly boolean = false)
RETURNS TABLE (
    x
    y
    z
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the run parameters and factors associated with the run requests in the input list
**
**      This is used by http://dms2.pnl.gov/requested_run_batch_blocking/grid
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
BEGIN

    -----------------------------------------
    -- Temp tables to hold list of requests and factors
    --
    -- This procedure populates Tmp_Requests
    -- Procedure make_factor_crosstab_sql will populate Tmp_Factors
    -----------------------------------------
    --
    CREATE TEMP TABLE Tmp_Requests (
        Request int
    );

    CREATE TEMP TABLE Tmp_Factors (
        FactorID int,
        FactorName text NULL
    );

    -----------------------------------------
    -- Populate Tmp_Requests with list of requests
    -----------------------------------------
    --
    INSERT INTO Tmp_Requests (Request)
    SELECT Value
    FROM public.parse_delimited_integer_list(_itemList);

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    --
    -- These columns correspond to view V_Requested_Run_Unified_List_Ex
    -----------------------------------------

    _colList := 'request, name, status, batch, experiment, dataset, instrument, cart, lc_col, block, run_order';

    CALL make_factor_crosstab_sql (_itemList, _colList, _sql => _sql, _viewName => 'V_Requested_Run_Unified_List_Ex');


    -----------------------------------------
    -- Return the output table
    --
    -- Either show the dynamic SQL or execute the SQL and return the results
    -----------------------------------------
    --
    If _infoOnly Then

         -- ToDo: update these columns

        RETURN QUERY
        SELECT _sql As sel,
               0 As batch_id,
               '' As experiment,
               '' As dataset,
               '' As name citext
               'Preview SQL' As status,
               0 As request;
    Else
        RETURN QUERY
        EXECUTE _sql;
    End If;

    DROP TABLE Tmp_Requests;
    DROP TABLE Tmp_Factors;
END
$$;

COMMENT ON PROCEDURE public.get_requested_run_parameters_and_factors IS 'GetRequestedRunParametersAndFactors';
