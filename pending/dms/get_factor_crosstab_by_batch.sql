--
CREATE OR REPLACE FUNCTION public.get_factor_crosstab_by_batch
(
    _batchID int,
    _nameContains text = '',
    _infoOnly boolean = false
)
RETURNS TABLE (
    x,
    y,
    z
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the factors associated with the run requests in the specified batch
**
**      This is used by https://dms2.pnl.gov/requested_run_batch_blocking/param
**
**  Auth:   mem
**  Date:   02/18/2010
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          03/02/2010 grk - Added status field to requested run
**          03/17/2010 grk - Added filtering for request name contains
**          03/18/2010 grk - Eliminated call to GetFactorCrosstabByFactorID
**          02/17/2012 mem - Updated to delete data from Tmp_Requests only if _nameContains is not blank
**          01/05/2023 mem - Use new column names in V_Requested_Run_Unified_List
**          01/24/2023 mem - Use lowercase column names in _colList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _sql text;
    _factorNameList text;
    _itemList text;
    _colList text;
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

    If Coalesce(_batchID, 0) > 0 Then
        -----------------------------------------
        -- Populate Tmp_Requests with the requests that correspond to batch _batchID
        -----------------------------------------
        --
        _itemList := _batchID::text;

        INSERT INTO Tmp_Requests (Request)
        SELECT request_id
        FROM public.get_requested_runs_from_item_list (_itemList, 'Batch_ID');

    End If;

    If Coalesce(_nameContains, '') <> '' Then
        -----------------------------------------
        -- Filter by request name
        -----------------------------------------
        --
        DELETE FROM Tmp_Requests
        WHERE
            NOT EXISTS (
                SELECT request_id
                FROM t_requested_run
                WHERE
                    request_id = Request AND
                    request_name LIKE '%' || _nameContains || '%';
            )
    End If;

    -----------------------------------------
    -- Build the Sql for obtaining the factors
    -- for the requests
    -----------------------------------------

    _colList := ' ''x'' As sel, batch_id, name, status, dataset_id, request, block, run_order';

    CALL make_factor_crosstab_sql (_colList, _sql => _sql);

    -----------------------------------------
    -- Return the output table
    -- Either show the dynamic SQL or execute the SQL and return the results
    -----------------------------------------
    --

    -- ToDo: Convert this procedure to a function

    If _infoOnly Then
        RETURN QUERY
        SELECT _sql As Sel,

    Else
        RETURN QUERY
        EXECUTE _sql;
    End If;

   DROP TABLE Tmp_Requests;
   DROP TABLE Tmp_Factors;
END
$$;

COMMENT ON PROCEDURE public.get_factor_crosstab_by_batch IS 'GetFactorCrosstabByBatch';
