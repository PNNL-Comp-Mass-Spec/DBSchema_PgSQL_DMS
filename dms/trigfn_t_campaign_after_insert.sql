--
-- Name: trigfn_t_campaign_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_campaign_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the new Campaign
**
**  Auth:   mem
**  Date:   10/02/2007 mem - Initial version (Ticket #543)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          12/01/2011 mem - Now updating t_event_log if fraction_emsl_funded > 0 or data_release_restrictions > 0
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 1, inserted.campaign_id, 1, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.campaign_id;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 9, inserted.campaign_id, (inserted.fraction_emsl_funded * 100)::int, 0, CURRENT_TIMESTAMP
    FROM inserted
    WHERE inserted.fraction_emsl_funded > 0
    ORDER BY inserted.campaign_id;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 10, inserted.campaign_id, inserted.data_release_restrictions, 0, CURRENT_TIMESTAMP
    FROM inserted
    WHERE inserted.data_release_restrictions > 0
    ORDER BY inserted.campaign_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_campaign_after_insert() OWNER TO d3l243;

