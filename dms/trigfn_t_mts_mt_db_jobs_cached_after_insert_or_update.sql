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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since job is never null
    If TG_OP = 'INSERT' Or OLD.job <> NEW.job Then

        UPDATE t_mts_mt_db_jobs_cached
        SET sort_key = CASE WHEN AJ.job IS NULL
                            THEN -t_mts_mt_db_jobs_cached.job
                            ELSE t_mts_mt_db_jobs_cached.job
                       END
        FROM NEW as N
             LEFT OUTER JOIN t_analysis_job AJ
               ON AJ.job = N.job
        WHERE t_mts_mt_db_jobs_cached.job = N.job;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_mts_mt_db_jobs_cached_after_insert_or_update() OWNER TO d3l243;

