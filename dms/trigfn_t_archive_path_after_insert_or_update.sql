--
-- Name: trigfn_t_archive_path_after_insert_or_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_archive_path_after_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column archive_url for new or updated archive path entries
**
**  Auth:   mem
**  Date:   08/19/2010
**          08/04/2022 mem - Ported to PostgreSQL
**          08/07/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every new or updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_archive_path
    SET archive_url = CASE WHEN t_archive_path.archive_path LIKE '/archive/dmsarch/%'
                           THEN 'http://dms2.pnl.gov/dmsarch/' || substring(t_archive_path.archive_path, 18, 256) || '/'
                           ELSE NULL
                      END
    WHERE t_archive_path.archive_path_id = NEW.archive_path_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_archive_path_after_insert_or_update() OWNER TO d3l243;

