--
-- Name: update_cached_secondary_sep_usage(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_secondary_sep_usage(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update data in t_secondary_sep_usage
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   11/18/2015 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/10/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;

    _addOrUpdateCount int;
    _rowsAdded int;
    _rowsUpdated int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        SELECT COUNT(*)
        INTO _countBeforeMerge
        FROM t_secondary_sep_usage;

        MERGE INTO t_secondary_sep_usage AS t
        USING (SELECT SS.separation_type_id,
                      SUM(CASE WHEN public.months_between(DS.Created, CURRENT_TIMESTAMP) <= 12 THEN 1
                               ELSE 0
                          END) AS usage_last12months,
                      SUM(CASE WHEN DS.Dataset_ID IS NULL THEN 0
                               ELSE 1
                          END) AS usage_all_years,
                      MAX(DS.created) AS most_recent_use
               FROM t_secondary_sep SS
                    LEFT OUTER JOIN t_dataset DS
                      ON DS.separation_type = SS.separation_type
               GROUP BY SS.separation_type_id, SS.separation_type
              ) AS s
        ON (t.separation_type_id = s.separation_type_id)
        WHEN MATCHED AND
             (t.usage_last12months IS DISTINCT FROM s.usage_last12months OR
              t.usage_all_years    IS DISTINCT FROM s.usage_all_years OR
              t.most_recent_use    IS DISTINCT FROM s.most_recent_use) THEN
            UPDATE SET
                usage_last12months = s.usage_last12months,
                usage_all_years    = s.usage_all_years,
                most_recent_use    = s.most_recent_use
        WHEN NOT MATCHED THEN
            INSERT (separation_type_id, usage_last12months, usage_all_years, most_recent_use)
            VALUES (s.separation_type_id, s.usage_last12months, s.usage_all_years, s.most_recent_use);

        GET DIAGNOSTICS _addOrUpdateCount = ROW_COUNT;

        SELECT COUNT(*)
        INTO _countAfterMerge
        FROM t_secondary_sep_usage;

        _rowsAdded    := _countAfterMerge - _countBeforeMerge;
        _rowsUpdated := _addOrUpdateCount - _rowsAdded;

        If _rowsAdded > 0 Then
            _message := format('Added %s %s', _rowsAdded, public.check_plural(_rowsAdded, 'row', 'rows'));
        End If;

        If _rowsUpdated > 0 Then
            _message := public.append_to_text(
                                _message,
                                format('Updated %s %s', _rowsUpdated, public.check_plural(_rowsUpdated, 'row', 'rows')));
        End If;

        -- Delete rows in t_secondary_sep_usage that are not in t_secondary_sep

        DELETE FROM t_secondary_sep_usage target
        WHERE NOT EXISTS (SELECT SS.separation_type_id
                          FROM t_secondary_sep SS
                          WHERE target.separation_type_id = SS.separation_type_id);

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


ALTER PROCEDURE public.update_cached_secondary_sep_usage(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_secondary_sep_usage(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_secondary_sep_usage(INOUT _message text, INOUT _returncode text) IS 'UpdateCachedSecondarySepUsage';

