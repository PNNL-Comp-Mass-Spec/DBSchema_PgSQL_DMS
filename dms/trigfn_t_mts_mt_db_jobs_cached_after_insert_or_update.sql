--
-- Name: trigfn_t_mts_mt_db_jobs_cached_after_insert_or_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_mts_mt_db_jobs_cached_after_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the sort_key column
**
**  Auth:   mem
**  Date:   11/21/2012 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
DECLARE
    _sortKey int;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Exists (SELECT job FROM t_analysis_job WHERE job = NEW.job) Then
        _sortKey := NEW.job;
    Else
        _sortKey := -NEW.job;
    End If;

    UPDATE t_mts_mt_db_jobs_cached
    SET sort_key = _sortKey
    WHERE t_mts_mt_db_jobs_cached.job = NEW.job;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_mts_mt_db_jobs_cached_after_insert_or_update() OWNER TO d3l243;

