--
CREATE OR REPLACE PROCEDURE public.get_requested_run_factors_for_export
(
    _itemList TEXT,
    _itemType text = 'Batch_ID',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the factors associated with the
**      run requests given by the itemList
**
**  Auth:   grk
**  Date:   03/22/2010
**          03/22/2010 grk - initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _sql text;
    _factorNameList text;
    _colList text;
BEGIN
    _message := '';
    _returnCode := '';

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
    SELECT request_id
    FROM public.get_requested_runs_from_item_list (_itemList, _itemType);

/*
    -----------------------------------------
    -- Filter by request name
    -----------------------------------------
    --
    DELETE FROM
        Tmp_Requests
    WHERE
        NOT EXISTS (
            SELECT request_id
            FROM t_requested_run
            WHERE
                request_id = Request AND
                request_name LIKE '%' || _nameContains || '%'
        )
*/
    -----------------------------------------
    -- Build the Sql for obtaining the factors
    -- for the requests
    -----------------------------------------

    SELECT string_agg(Request::text, ',')
    INTO _requestIdList
    FROM Tmp_Requests;

    DROP TABLE Tmp_Requests;

    _colList := 'BatchID, Name,  Status,  Request,  Dataset_ID,  Dataset,  Experiment,  Experiment_ID,  Block,  [Run Order] ';

    CALL make_factor_crosstab_sql (_colList, _sql => _sql);

    -----------------------------------------
    -- Return the output table
    -----------------------------------------
    --

    -- ToDo: Convert this procedure to a function

    RETURN QUERY
    EXECUTE _sql;

    --
    DROP TABLE Tmp_Requests;
    DROP TABLE Tmp_Factors;

END
$$;

COMMENT ON PROCEDURE public.get_requested_run_factors_for_export IS 'GetRequestedRunFactorsForExport';
