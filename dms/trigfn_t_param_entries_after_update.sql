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
**
*****************************************************/
DECLARE
    _sepChar text;
    _userInfo text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> with param_file_id since never null
    -- The remaining columns could be null
    If OLD.entry_sequence_order IS DISTINCT FROM NEW.entry_sequence_order OR
       OLD.entry_type           IS DISTINCT FROM NEW.entry_type OR
       OLD.entry_specifier      IS DISTINCT FROM NEW.entry_specifier OR
       OLD.entry_value          IS DISTINCT FROM NEW.entry_value OR
       OLD.param_file_id <> NEW.param_file_id Then

        -- Update date_modified in t_param_files for the param_file_id
        -- values in the changed rows
        UPDATE t_param_files
        SET date_modified = CURRENT_TIMESTAMP
        FROM NEW as N
        WHERE t_param_files.param_file_id = N.param_file_id;

        If OLD.param_file_id <> NEW.param_file_id Then
            -- param_file_id was changed; update date_modified in t_param_files
            -- for the old param_file_id associated with the changed entries

            UPDATE t_param_files
            SET date_modified = CURRENT_TIMESTAMP
            FROM OLD as O
            WHERE t_param_files.param_file_id = O.param_file_id;

        End If;

        -- Append the current time and username to the entered_by field
        -- Note that public.timestamp_text() returns a timestamp
        -- in the form: 2006-09-01 09:05:03

        _sepChar := ' (';

        _userInfo := COALESCE(public.timestamp_text(CURRENT_TIMESTAMP) || '; ' || LEFT(SESSION_USER, 75), '');

        UPDATE t_param_entries
        SET entered_by = CASE WHEN LookupQ.MatchLoc > 0 THEN Left(t_param_entries.entered_by, LookupQ.MatchLoc - 1) || _sepChar || _userInfo || ')'
                              WHEN t_param_entries.entered_by IS NULL Then SESSION_USER
                              ELSE COALESCE(t_param_entries.entered_by, '??') || _sepChar || _userInfo || ')'
                         END
        FROM ( SELECT param_entry_id,
                      Position(_sepChar in COALESCE(entered_by, '')) AS MatchLoc
               FROM NEW as N
             ) LookupQ
        WHERE t_param_entries.param_entry_id = LookupQ.param_entry_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_param_entries_after_update() OWNER TO d3l243;

