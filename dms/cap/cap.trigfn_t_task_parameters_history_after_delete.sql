--
-- Name: trigfn_t_task_parameters_history_after_delete(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_task_parameters_history_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column most_recent_entry for the deleted capture task parameters
**
**  Auth:   mem
**  Date:   01/25/2011
**          07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If Not Exists (Select * From deleted) Then
        -- RAISE NOTICE '  no affected rows; exiting';
        Return Null;
    End If;

    UPDATE cap.t_task_parameters_history
    SET most_recent_entry = CASE WHEN LookupQ.SaveRank = 1 THEN 1 ELSE 0 END
    FROM ( SELECT H.job,
                  H.saved,
                  Row_Number() OVER ( PARTITION BY H.job ORDER BY H.saved DESC ) AS SaveRank
           FROM cap.t_task_parameters_history H
                INNER JOIN deleted as deletedRows on H.job = deletedRows.job
         ) LookupQ
    WHERE LookupQ.job = cap.t_task_parameters_history.job AND
          LookupQ.saved = cap.t_task_parameters_history.saved;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_task_parameters_history_after_delete() OWNER TO d3l243;

