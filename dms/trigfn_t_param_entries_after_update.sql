--
-- Name: trigfn_t_param_entries_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_param_entries_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the entered_by field if any of the fields are changed
**      Also updates date_modified in t_param_files
**
**  Auth:   mem
**  Date:   10/12/2007 (Ticket:557)
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
DECLARE
    _sepChar text;
    _userInfo text;
    _matchLoc int;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');


    -- Update date_modified in t_param_files for the param_file_id
    -- values in the changed rows
    UPDATE t_param_files
    SET date_modified = CURRENT_TIMESTAMP
    WHERE t_param_files.param_file_id = NEW.param_file_id;

    If OLD.param_file_id <> NEW.param_file_id Then
        -- param_file_id was changed; update date_modified in t_param_files
        -- for the old param_file_id associated with the changed entries

        UPDATE t_param_files
        SET date_modified = CURRENT_TIMESTAMP
        WHERE t_param_files.param_file_id = OLD.param_file_id;

    End If;

    -- Append the current time and username to the entered_by field
    -- Note that public.timestamp_text() returns a timestamp
    -- in the form: 2006-09-01 09:05:03

    _sepChar := ' (';
    _matchLoc := Position(_sepChar in COALESCE(NEW.entered_by, ''));

    _userInfo := COALESCE(public.timestamp_text(CURRENT_TIMESTAMP) || '; ' || LEFT(SESSION_USER, 75), '');

    UPDATE t_param_entries
    SET entered_by = CASE WHEN _matchLoc > 0 THEN Left(t_param_entries.entered_by, _matchLoc - 1) || _sepChar || _userInfo || ')'
                          WHEN t_param_entries.entered_by IS NULL Then SESSION_USER
                          ELSE COALESCE(t_param_entries.entered_by, '??') || _sepChar || _userInfo || ')'
                     END
    WHERE t_param_entries.param_entry_id = NEW.param_entry_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_param_entries_after_update() OWNER TO d3l243;

