--
-- Name: trigfn_t_job_parameters_history_after_insert(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_job_parameters_history_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column most_recent_entry for the affected jobs
**
**  Auth:   mem
**  Date:   01/25/2011
**          07/31/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    UPDATE sw.t_job_parameters_history
    SET most_recent_entry = CASE WHEN LookupQ.SaveRank = 1 THEN 1 ELSE 0 END
    FROM ( SELECT H.job,
                  H.saved,
                  Row_Number() OVER ( PARTITION BY H.job ORDER BY H.saved DESC ) AS SaveRank
           FROM sw.t_job_parameters_history H
                INNER JOIN inserted on H.job = inserted.job
         ) LookupQ
    WHERE LookupQ.job = sw.t_job_parameters_history.job AND
          LookupQ.saved = sw.t_job_parameters_history.saved;

    RETURN null;
    End
$$;


ALTER FUNCTION sw.trigfn_t_job_parameters_history_after_insert() OWNER TO d3l243;

