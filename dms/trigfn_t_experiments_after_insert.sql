--
-- Name: trigfn_t_experiments_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_experiments_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the new Experiments
**
**  Auth:   mem
**  Date:   10/02/2007 mem - Initial version (Ticket #543)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 3, inserted.exp_id, 1, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.exp_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiments_after_insert() OWNER TO d3l243;

