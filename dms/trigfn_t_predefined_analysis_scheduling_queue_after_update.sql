--
-- Name: trigfn_t_predefined_analysis_scheduling_queue_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_predefined_analysis_scheduling_queue_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected in t_predefined_analysis_scheduling_queue
**
**  Auth:   mem
**  Date:   08/26/2010
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Using <> since state can never be null
    If OLD.state <> NEW.state Then

        UPDATE t_predefined_analysis_scheduling_queue
        SET last_affected = CURRENT_TIMESTAMP
        FROM NEW as N
        WHERE t_predefined_analysis_scheduling_queue.item = N.item;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_predefined_analysis_scheduling_queue_after_update() OWNER TO d3l243;

