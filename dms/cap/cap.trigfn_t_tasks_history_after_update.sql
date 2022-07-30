--
-- Name: trigfn_t_tasks_history_after_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_tasks_history_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column most_recent_entry for the updated capture task history items
**
**  Auth:   mem
**  Date:   01/25/2011
**          07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If Not Exists (Select * From NEW) Then
        -- RAISE NOTICE '  no affected rows; exiting';
        Return Null;
    End If;

    If Old.Saved = New.Saved Then
        -- RAISE NOTICE '  Saved date unchanged; exiting';
        Return null;
    End If;

    -- RAISE NOTICE '  Old saved=%, New saved=%', Old.saved, New.saved;

    WITH RankQ AS (
        SELECT CountQ.job,
               CountQ.saved,
               CASE WHEN CountQ.SaveRank = 1 THEN 1 ELSE 0 END As most_recent_entry
        FROM (
                SELECT H.job,
                       H.saved,
                       Row_Number() OVER ( PARTITION BY H.job ORDER BY H.saved DESC ) AS SaveRank
                FROM cap.t_tasks_history H
                     INNER JOIN NEW as updatedRows on H.Job = updatedRows.job
             ) CountQ
    )
    UPDATE cap.t_tasks_history
    SET most_recent_entry = RankQ.most_recent_entry
    FROM RankQ
    WHERE cap.t_tasks_history.job = RankQ.job AND
          cap.t_tasks_history.saved = RankQ.saved AND
          cap.t_tasks_history.most_recent_entry <> RankQ.most_recent_entry;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_tasks_history_after_update() OWNER TO d3l243;

