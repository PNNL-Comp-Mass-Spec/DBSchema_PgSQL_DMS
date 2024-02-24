--
-- Name: trigfn_t_dataset_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_dataset_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the deleted dataset
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          10/02/2007 mem - Updated to append the dataset name to the entered_by field (Ticket #543)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          08/04/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_event_log for each dataset deleted from t_dataset
    INSERT INTO t_event_log (
        target_type,
        target_id,
        target_state,
        prev_target_state,
        entered,
        entered_by
    )
    SELECT 4 AS target_type,
           dataset_id AS target_id,
           0 AS target_state,
           dataset_state_id AS prev_target_state,
           CURRENT_TIMESTAMP,
           format('%s; %s', SESSION_USER, dataset)
    FROM deleted
    ORDER BY dataset_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_dataset_after_delete() OWNER TO d3l243;

