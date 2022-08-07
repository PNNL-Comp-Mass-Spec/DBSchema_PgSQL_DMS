--
-- Name: trigfn_t_storage_path_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_storage_path_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates t_cached_dataset_folder_paths for existing datasets
**
**  Auth:   mem
**  Date:   01/22/2015 mem
**          07/25/2017 mem - Now updating t_cached_dataset_links
**          08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> for storage_path since never null
    -- In contrast, machine_name and vol_name_client could be null
    If OLD.storage_path <> NEW.storage_path OR
       OLD.machine_name IS DISTINCT FROM NEW.machine_name OR
       OLD.vol_name_client IS DISTINCT FROM NEW.vol_name_client Then

        UPDATE t_cached_dataset_folder_paths
        SET update_required = 1
        FROM NEW as N
             INNER JOIN t_dataset DS
               ON N.storage_path_id = DS.storage_path_id
        WHERE t_cached_dataset_folder_paths.dataset_id = DS.dataset_id;

        UPDATE t_cached_dataset_links
        SET update_required = 1
        FROM NEW as N
             INNER JOIN t_dataset DS
               ON N.storage_path_id = DS.storage_path_id
        WHERE t_cached_dataset_links.dataset_id = DS.dataset_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_storage_path_after_update() OWNER TO d3l243;

