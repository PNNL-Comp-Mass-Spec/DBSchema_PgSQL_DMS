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
**          08/07/2022 mem - Rename transition tables
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From inserted) Then
        Return Null;
    End If;

    INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
    SELECT 1, inserted.campaign_id, deleted.campaign, inserted.campaign, CURRENT_TIMESTAMP
    FROM deleted INNER JOIN
         inserted ON deleted.campaign_id = inserted.campaign_id
    WHERE deleted.campaign <> inserted.campaign;   -- Use <> since campaign is never null

    UPDATE t_file_attachment
    SET entity_id = inserted.campaign
    FROM deleted INNER JOIN
         inserted ON deleted.campaign_id = inserted.campaign_id
    WHERE deleted.campaign <> inserted.campaign AND
          t_file_attachment.Entity_Type = 'campaign' AND
          t_file_attachment.entity_id = deleted.campaign;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 9, inserted.campaign_id,
           (inserted.fraction_emsl_funded * 100)::int,
           (deleted.fraction_emsl_funded * 100)::int,
           CURRENT_TIMESTAMP
    FROM deleted INNER JOIN
         inserted ON deleted.campaign_id = inserted.campaign_id
    WHERE inserted.fraction_emsl_funded <> deleted.fraction_emsl_funded;              -- Use <> since fraction_emsl_funded is never null

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 10, inserted.campaign_id,
           inserted.data_release_restrictions,
           deleted.data_release_restrictions,
           CURRENT_TIMESTAMP
    FROM deleted INNER JOIN
         inserted ON deleted.campaign_id = inserted.campaign_id
    WHERE inserted.data_release_restrictions <> deleted.data_release_restrictions;   -- Use <> since data_release_restrictions is never null

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_campaign_after_update() OWNER TO d3l243;
