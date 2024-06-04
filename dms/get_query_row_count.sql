--
-- Name: get_query_row_count(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_query_row_count(_objectname text, _whereclause text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the number of rows in the given table or view that match the given where clause (use an empty string if no where clause)
**
**      The row count is obtained from table t_query_row_counts if it contains a recent query result
**      If the row count info is out-of-date, the table or view is re-queried and the cached value in t_query_row_counts is updated
**
**  Arguments:
**    _objectName       Table or view to query
**    _whereClause      Where clause for filtering data; use an empty string if no filters are in use
**
**  Example usage:
**      SELECT *
**      FROM public.get_query_row_count('v_dataset_list_report_2', '');
**
**      SELECT *
**      FROM public.get_query_row_count('v_analysis_job_list_report_2', 'dataset like ''qc_mam_23%''');
**
**  Auth:   mem
**  Date:   05/22/2024 mem - Initial version
**          05/24/2024 mem - Change the object name to lowercase
**          05/25/2024 mem - Increment column Usage in t_query_row_counts
**
*****************************************************/
DECLARE
    _queryID int;
    _rowCount int8;
    _lastRefresh timestamp with time zone;
    _usage int;
    _refreshIntervalHours numeric;
    _rowCountAgeHours numeric;
    _sql text;
BEGIN
    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _objectName  := Lower(Trim(Coalesce(_objectName, '')));
    _whereClause := Trim(Coalesce(_whereClause, ''));

    If _objectName = '' Then
        RAISE WARNING 'Object name is an empty string';

        RETURN 0;
    End If;

    If _whereClause::citext LIKE 'WHERE %' Then
        -- Remove the WHERE keyword
        _whereClause := trim(substring(_whereClause, 6));
    End If;

    ------------------------------------------------
    -- Look for a cached row count
    ------------------------------------------------

    SELECT query_id, row_count, last_refresh, usage, refresh_interval_hours
    INTO _queryID, _rowCount, _lastRefresh, _usage, _refreshIntervalHours
    FROM t_query_row_counts
    WHERE object_name  = _objectName AND
          where_clause = _whereClause;

    If FOUND Then
        _rowCountAgeHours := extract(epoch FROM
                                     CURRENT_TIMESTAMP -
                                     _lastRefresh) / 3600.0;

        If _rowCountAgeHours < _refreshIntervalHours Then
            -- Use the cached row count value, but first update columns last_used and usage
            UPDATE t_query_row_counts
            SET last_used = CURRENT_TIMESTAMP,
                usage = _usage + 1
            WHERE query_id = _queryID;

            RAISE INFO 'Using row count obtained % hours ago (will refresh after %)',
                       Round(_rowCountAgeHours, 2),
                       Left((_lastRefresh + make_interval(secs => (_refreshIntervalHours * 60 * 60)::int)
                            )::text, 19);

            RETURN _rowCount;
        End If;
    Else
        _queryID := -1;
        _usage   := 0;
    End If;

    ------------------------------------------------
    -- Query the table or view to count the number of matching rows
    ------------------------------------------------

    If _whereClause = '' Then
        _sql := format('SELECT COUNT(*) FROM %I', _objectName);
    Else
        _sql := format('SELECT COUNT(*) FROM %I WHERE %s', _objectName, _whereClause);
    End If;

    RAISE INFO 'Query: %', _sql;

    EXECUTE _sql
    INTO _rowCount;

    If _queryID <= 0 Then
        INSERT INTO t_query_row_counts (
            object_name,
            where_clause,
            row_count,
            usage
        )
        VALUES (_objectName, _whereClause, _rowCount, 1);

        RETURN _rowCount;
    End If;

    UPDATE t_query_row_counts
    SET row_count = _rowCount,
        last_used = CURRENT_TIMESTAMP,
        last_refresh = CURRENT_TIMESTAMP,
        usage = _usage + 1
    WHERE query_id = _queryID;

    RETURN _rowCount;
END
$$;


ALTER FUNCTION public.get_query_row_count(_objectname text, _whereclause text) OWNER TO d3l243;

