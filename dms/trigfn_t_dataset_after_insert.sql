--
-- Name: trigfn_t_dataset_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_dataset_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the new dataset
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query and to make an entry for dataset_rating_id (Ticket #519)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          11/22/2013 mem - Now updating date_sort_key
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From inserted) Then
        Return Null;
    End If;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 4, inserted.dataset_id, inserted.dataset_state_id, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.dataset_id;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 8, inserted.dataset_id, inserted.dataset_rating_id, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.dataset_id;

    -- This query must stay sync'd with the Update query in trigger trigfn_t_dataset_after_update
    UPDATE t_dataset
    SET date_sort_key = CASE WHEN E.experiment = 'Tracking' THEN t_dataset.created
                             ELSE COALESCE(t_dataset.Acq_Time_Start, t_dataset.created)
                        END
    FROM inserted
         INNER JOIN t_experiments E
           ON inserted.exp_id = E.exp_id
    WHERE t_dataset.dataset_id = inserted.dataset_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_dataset_after_insert() OWNER TO d3l243;

