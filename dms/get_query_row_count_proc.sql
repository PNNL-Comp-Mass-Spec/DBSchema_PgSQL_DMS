--
-- Name: get_query_row_count_proc(text, text, bigint, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_query_row_count_proc(IN _objectname text, IN _whereclause text, INOUT _rowcount bigint DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Use function get_query_row_count() to determine the number of rows in the given table or view
***     that match the given where clause (use an empty string if no where clause)
**
**      The row count is obtained from table t_query_row_counts if it contains a recent query result
**      If the row count info is out-of-date, the table or view is re-queried and the cached value in t_query_row_counts is updated
**
**  Arguments:
**    _objectName       Table or view to query
**    _whereClause      Where clause for filtering data; use an empty string if no filters are in use
**    _rowCount         Output: number of matching rows
**    _message          Status message
**    _returnCode       Return code
**
**  Example usage:
**      CALL public.get_query_row_count_proc('v_dataset_list_report_2', '');
**
**      CALL public.get_query_row_count_proc('v_analysis_job_list_report_2', 'dataset like ''qc_mam_23%''');
**
**
**  Auth:   mem
**  Date:   05/22/2024 mem - Initial version
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

    BEGIN
        ------------------------------------------------
        -- Validate the inputs
        ------------------------------------------------

        _objectName  := Trim(Coalesce(_objectName, ''));
        _whereClause := Trim(Coalesce(_whereClause, ''));

        ------------------------------------------------
        -- Use the function to determine the number of matching rows
        ------------------------------------------------

        _rowCount := public.get_query_row_count(_objectName, _whereClause);

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

END
$$;


ALTER PROCEDURE public.get_query_row_count_proc(IN _objectname text, IN _whereclause text, INOUT _rowcount bigint, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

