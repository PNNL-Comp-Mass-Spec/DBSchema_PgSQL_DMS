--
-- Name: trigfn_t_cached_dataset_folder_paths_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_cached_dataset_folder_paths_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates update_required in t_cached_dataset_links
**
**  Auth:   mem
**  Date:   07/25/2017
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Compare using IS DISTINCT FROM since each of these columns could be null
    If OLD.dataset_row_version      IS DISTINCT FROM NEW.dataset_row_version OR
       OLD.storage_path_row_version IS DISTINCT FROM NEW.storage_path_row_version OR
       OLD.dataset_folder_path      IS DISTINCT FROM NEW.dataset_folder_path OR
       OLD.archive_folder_path      IS DISTINCT FROM NEW.archive_folder_path OR
       OLD.myemsl_path_flag         IS DISTINCT FROM NEW.myemsl_path_flag OR
       OLD.dataset_url              IS DISTINCT FROM NEW.dataset_url Then

        UPDATE t_cached_dataset_links
        SET update_required = 1
        FROM NEW as N
        WHERE t_cached_dataset_links.dataset_id = N.dataset_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_cached_dataset_folder_paths_after_update() OWNER TO d3l243;

