--
-- Name: trigfn_t_tasks_history_after_insert(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_tasks_history_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column most_recent_entry for the new capture task history items
**
**  Auth:   mem
**  Date:   01/25/2011
**          07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    UPDATE cap.t_tasks_history
    SET most_recent_entry = CASE WHEN LookupQ.SaveRank = 1 THEN 1 ELSE 0 END
    FROM ( SELECT H.job,
                  H.saved,
                  Row_Number() OVER (PARTITION BY H.job ORDER BY H.saved DESC) AS SaveRank
           FROM cap.t_tasks_history H
                INNER JOIN inserted on H.Job = inserted.job
         ) LookupQ
    WHERE LookupQ.job = cap.t_tasks_history.job AND
          LookupQ.saved = cap.t_tasks_history.saved;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_tasks_history_after_insert() OWNER TO d3l243;

