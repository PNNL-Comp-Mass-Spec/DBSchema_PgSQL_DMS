--
-- Name: trigfn_t_task_steps_history_after_insert(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_task_steps_history_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column most_recent_entry for the new capture task step history items
**
**  Auth:   mem
**  Date:   01/25/2011
**          07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    UPDATE cap.t_task_steps_history
    SET most_recent_entry = CASE WHEN LookupQ.SaveRank = 1 THEN 1 ELSE 0 END
    FROM ( SELECT H.job,
                  H.step,
                  H.saved,
                  Row_Number() OVER ( PARTITION BY H.job, H.step ORDER BY H.saved DESC ) AS SaveRank
           FROM cap.t_task_steps_history H
                INNER JOIN inserted on H.job = inserted.job and H.step = inserted.step
         ) LookupQ
    WHERE LookupQ.job = cap.t_task_Steps_History.job AND
          LookupQ.step = cap.t_task_Steps_History.step AND
          LookupQ.saved = cap.t_task_Steps_History.saved;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_task_steps_history_after_insert() OWNER TO d3l243;

