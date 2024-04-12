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
**          08/07/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_cached_dataset_links
    SET update_required = 1
    WHERE t_cached_dataset_links.dataset_id = NEW.dataset_id AND
          t_cached_dataset_links.update_required = 0;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_cached_dataset_folder_paths_after_update() OWNER TO d3l243;

