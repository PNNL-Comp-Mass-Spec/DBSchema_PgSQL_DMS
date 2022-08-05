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
**
*****************************************************/
DECLARE
    _updateURL bool;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If TG_OP = 'INSERT' Then
        _updateURL := true;
    ElsIf OLD.archive_path <> NEW.archive_path OR               -- Use <> for archive_path since never null
          OLD.archive_url IS DISTINCT FROM NEW.archive_url Then -- In contrast, archive_url could be null
        _updateURL := true;
    Else
        _updateURL := false;
    End If;

    If _updateURL Then
        -- RAISE NOTICE '% trigger, % %, Update archive_url for archive_path_id %', TG_TABLE_NAME, TG_WHEN, TG_OP, NEW.archive_path_id;

        UPDATE t_archive_path
        SET archive_url = CASE WHEN t_archive_path.archive_path LIKE '/archive/dmsarch/%'
                               THEN 'http://dms2.pnl.gov/dmsarch/' || substring(t_archive_path.archive_path, 18, 256) || '/'
                               ELSE NULL
                          END
        FROM NEW as N
        WHERE t_archive_path.archive_path_id = N.archive_path_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_archive_path_after_insert_or_update() OWNER TO d3l243;

