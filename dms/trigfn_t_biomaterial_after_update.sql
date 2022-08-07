--
-- Name: trigfn_t_biomaterial_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_biomaterial_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_entity_rename_log if the biomaterial is renamed
**      Also Renames entries in t_file_attachment
**
**  Auth:   mem
**  Date:   07/19/2010 mem - Initial version
**          03/27/2022 mem - Now updating t_file_attachment
**          08/04/2022 mem - Ported to PostgreSQL
**          08/06/2022 mem - Convert to statement-level trigger
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
    SELECT 2, inserted.biomaterial_id, deleted.biomaterial_Name, inserted.biomaterial_Name, CURRENT_TIMESTAMP
    FROM deleted INNER JOIN
         inserted ON deleted.biomaterial_ID = inserted.biomaterial_ID
    WHERE deleted.biomaterial_name <> inserted.biomaterial_name;        -- Use <> since biomaterial_name is never null

    UPDATE t_file_attachment
    SET entity_id = inserted.biomaterial_Name
    FROM deleted INNER JOIN
         inserted ON deleted.biomaterial_ID = inserted.biomaterial_ID
    WHERE deleted.biomaterial_name <> inserted.biomaterial_name AND     -- Use <> since biomaterial_name is never null
          t_file_attachment.Entity_Type = 'cell_culture' AND            -- Use "cell_culture" here for historical reasons
          t_file_attachment.entity_id = deleted.biomaterial_Name;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_biomaterial_after_update() OWNER TO d3l243;

