--
-- Name: trigfn_t_campaign_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_campaign_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the deleted Campaign
**
**  Auth:   mem
**  Date:   10/02/2007 mem - Initial version (Ticket #543)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Add entries to t_event_log for each Campaign deleted from t_campaign
    INSERT INTO t_event_log
        (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered,
            entered_by
        )
    SELECT  1 AS target_type,
            campaign_id AS target_id,
            0 AS target_state,
            1 AS prev_target_state,
            CURRENT_TIMESTAMP,
            SESSION_USER || '; ' || deleted.campaign
    FROM deleted
    ORDER BY campaign_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_campaign_after_delete() OWNER TO d3l243;

