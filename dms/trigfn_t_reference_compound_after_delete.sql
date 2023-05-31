--
-- Name: trigfn_t_reference_compound_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_reference_compound_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the deleted compound
**
**  Auth:   mem
**  Date:   11/27/2017 mem - Initial version
**          08/05/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE DEBUG '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_event_log for each Compound deleted from t_reference_compound
    INSERT INTO t_event_log
        (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered,
            entered_by
        )
    SELECT 13 as target_type,
           compound_id as target_id,
           0 as target_state,
           1 as prev_target_state,
           CURRENT_TIMESTAMP,
           format('%s; %s', SESSION_USER, deleted.compound_name)
    FROM deleted
    ORDER BY compound_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_reference_compound_after_delete() OWNER TO d3l243;

