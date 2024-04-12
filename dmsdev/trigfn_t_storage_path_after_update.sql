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
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_cached_dataset_folder_paths
    SET update_required = 1
    FROM t_dataset DS
    WHERE DS.storage_path_id = NEW.storage_path_id AND
          t_cached_dataset_folder_paths.dataset_id = DS.dataset_id;

    UPDATE t_cached_dataset_links
    SET update_required = 1
    FROM t_dataset DS
    WHERE DS.storage_path_id = NEW.storage_path_id AND
          t_cached_dataset_links.dataset_id = DS.dataset_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_storage_path_after_update() OWNER TO d3l243;

