--
-- Name: get_factor_crosstab_by_batch(integer, text, boolean, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_factor_crosstab_by_batch(IN _batchid integer, IN _namecontains text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Returns the factors associated with the requested runs in the specified batch
**
**      This is used by https://dms2.pnl.gov/requested_run_batch_blocking/param
**
**  Arguments:
**    _batchID          Batch ID
**    _nameContains     Requested run name filter
**    _infoOnly         When True, show the SQL used to display the factors associated with the requested runs in the batch
**
**  Use this to view the data returned by the _results cursor
**
**  Note that this will result in an error if the batch is not found,
**  or if none of the requested runs for the batch has a name
**  that includes the text in _nameContains
**
**      BEGIN;
**          CALL public.get_factor_crosstab_by_batch (
**              _batchID      => 9066,
**              _nameContains => '12wk',
**              _infoOnly     => false
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**      DO
**      LANGUAGE plpgsql
**      $block$
**      DECLARE
**          _results refcursor := '_results'::refcursor;
**          _message text;
**          _returnCode text;
**          _currentRow record;
**      BEGIN
**          CALL public.get_factor_crosstab_by_batch (
**                    _batchID      => 9066,
**                    _nameContains => '12wk',
**                    _infoOnly     => false,
**                    _results      => _results,
**                    _message      => _message,
**                    _returnCode   => _returnCode
**                );
**
**          If Exists (SELECT name FROM pg_cursors WHERE name = '_results') Then
**              RAISE INFO 'Cursor has data';
**
**              WHILE true
**              LOOP
**                  FETCH NEXT FROM _results
**                  INTO _currentRow;
**
**                  If Not FOUND Then
**                      EXIT;
**                  End If;
**
**                  RAISE INFO 'Batch %, Request %: %', _currentRow.batch_id, _currentRow.request, _currentRow.name;
**              END LOOP;
**          Else
**              RAISE INFO 'Cursor is not open';
**          End If;
**      END
**      $block$;
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
**          07/13/2023 mem - Ported to PostgreSQL
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

    _nameContains := Trim(Coalesce(_nameContains, ''));
    _infoOnly     := Coalesce(_infoOnly, false);

    If _batchID Is Null Then
        RAISE WARNING '_batchID is null';
        RETURN;
    End If;

    If _batchID <= 0 Then
        RAISE WARNING '_batchID should be a positive integer, not %', _batchID;
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
    -- Populate Tmp_RequestIDs with the requested runs in batch _batchID
    -----------------------------------------

    INSERT INTO Tmp_RequestIDs (Request)
    SELECT request_id
    FROM public.get_requested_runs_from_item_list(_batchID::text, 'Batch_ID');

    If _nameContains <> '' Then
        -----------------------------------------
        -- Filter by request name
        -----------------------------------------

        DELETE FROM Tmp_RequestIDs Target
        WHERE NOT EXISTS (
                SELECT 1
                FROM t_requested_run RR
                WHERE RR.request_id = Target.Request AND
                      RR.request_name LIKE '%' || _nameContains || '%'
            );

    End If;

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    -- If the batch has additional factors, they will be shown after the run_order column
    -----------------------------------------

    _colList := ' ''x'' As sel, batch_id, name, status, dataset_id, request, block, run_order';

    SELECT make_factor_crosstab_sql ( _colList)
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
$_$;


ALTER PROCEDURE public.get_factor_crosstab_by_batch(IN _batchid integer, IN _namecontains text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_factor_crosstab_by_batch(IN _batchid integer, IN _namecontains text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_factor_crosstab_by_batch(IN _batchid integer, IN _namecontains text, IN _infoonly boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'GetFactorCrosstabByBatch';

