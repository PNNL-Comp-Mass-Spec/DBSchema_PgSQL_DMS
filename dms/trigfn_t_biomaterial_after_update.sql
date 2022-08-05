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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since biomaterial_name is never null
    If OLD.biomaterial_name <> NEW.biomaterial_name Then

        INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
        SELECT 2, N.biomaterial_id, O.biomaterial_Name, N.biomaterial_Name, CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.biomaterial_ID = N.biomaterial_ID;

        UPDATE t_file_attachment
        SET entity_id = N.biomaterial_Name
        FROM OLD as O INNER JOIN
             NEW as N ON O.biomaterial_ID = N.biomaterial_ID
        WHERE t_file_attachment.Entity_Type = 'cell_culture' AND    -- Use "cell_culture" here for historical reasons
              t_file_attachment.entity_id = O.biomaterial_Name;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_biomaterial_after_update() OWNER TO d3l243;

