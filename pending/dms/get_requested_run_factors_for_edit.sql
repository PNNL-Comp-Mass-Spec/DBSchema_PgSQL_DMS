--
CREATE OR REPLACE FUNCTION public.get_requested_run_factors_for_edit
(
    _itemList TEXT,
    _itemType text = 'Batch_ID',
    _infoOnly boolean = false)
RETURNS TABLE (
    sel citext,
    batch_id int,
    experiment citext,
    dataset citext,
    name citext
    status citext,
    request int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the factors associated with the
**      requested runs associated with the items
**      specified by _itemList
**
**  Arguments:
**    _itemList     Comma-separated list of item IDs
**    _itemType     Item type: Batch_ID, Requested_Run_ID, Dataset_Name, Dataset_ID, Experiment_Name, Experiment_ID, or Data_Package_ID
**    _infoOnly     When true, show the SQL
**
**  Auth:   grk
**  Date:   02/20/2010
**          03/02/2010 grk - Added status field to requested run
**          03/08/2010 grk - Improved field validation
**          03/18/2010 grk - Eliminated call to Get_Factor_Crosstab_By_Factor_ID
**          01/23/2023 mem - Use lowercase column names when querying V_Requested_Run_Unified_List
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sql text;
    _factorNameList text;
    _colList text;
BEGIN

    -----------------------------------------
    -- Temp tables to hold list of requests and factors
    --
    -- This procedure populates Tmp_Requests
    -- Procedure make_factor_crosstab_sql will populate Tmp_Factors
    -----------------------------------------

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

    INSERT INTO Tmp_Requests (Request)
    SELECT request_id
    FROM public.get_requested_runs_from_item_list (_itemList, _itemType);

    -----------------------------------------
    -- Build the Sql for obtaining the factors
    -- for the requests
    -----------------------------------------

    _colList := ' ''x'' As sel, batch_id, experiment, dataset, name, status, request'

    CALL make_factor_crosstab_sql (_colList, _sql => _sql);

    -----------------------------------------
    -- Return the output table
    --
    -- Either show the dynamic SQL or execute the SQL and return the results
    -----------------------------------------

    If _infoOnly Then
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

    --
    DROP TABLE Tmp_Requests;
    DROP TABLE Tmp_Factors;
END
$$;

COMMENT ON FUNCTION public.get_requested_run_factors_for_edit IS 'GetRequestedRunFactorsForEdit';
