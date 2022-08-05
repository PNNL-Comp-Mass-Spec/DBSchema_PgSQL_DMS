--
-- Name: trigfn_t_campaign_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_campaign_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_entity_rename_log if the campaign is renamed
**      Makes an entry in t_event_log if the EMSL funding or Data Release restriction changes
**      Renames entries in t_file_attachment
**
**  Auth:   mem
**  Date:   07/19/2010 mem - Initial version
**          12/01/2011 mem - Now updating t_event_log if fraction_emsl_funded or data_release_restrictions changes
**          03/23/2012 mem - Now updating t_file_attachment
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From NEW) Then
        Return Null;
    End If;

    -- Use <> since campaign is never null
    If OLD.campaign <> NEW.campaign Then

        INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
        SELECT 1, N.campaign_id, O.campaign, N.campaign, CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.campaign_id = N.campaign_id;

        UPDATE t_file_attachment
        SET entity_id = N.campaign
        FROM OLD as O INNER JOIN
             NEW as N ON O.campaign_id = N.campaign_id
        WHERE t_file_attachment.Entity_Type = 'campaign' AND
              t_file_attachment.entity_id = O.campaign;

    End If;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 9, N.campaign_id,
           (N.fraction_emsl_funded * 100)::int,
           (O.fraction_emsl_funded * 100)::int,
           CURRENT_TIMESTAMP
    FROM OLD as O INNER JOIN
         NEW as N ON O.campaign_id = N.campaign_id
    WHERE N.fraction_emsl_funded <> O.fraction_emsl_funded;              -- Use <> since fraction_emsl_funded is never null

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 10, N.campaign_id,
           N.data_release_restrictions,
           O.data_release_restrictions,
           CURRENT_TIMESTAMP
    FROM OLD as O INNER JOIN
         NEW as N ON O.campaign_id = N.campaign_id
    WHERE N.data_release_restrictions <> O.data_release_restrictions;   -- Use <> since data_release_restrictions is never null

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_campaign_after_update() OWNER TO d3l243;

