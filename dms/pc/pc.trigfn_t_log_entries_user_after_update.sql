--
-- Name: trigfn_t_log_entries_user_after_update(); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.trigfn_t_log_entries_user_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the entered_by field in t_log_entries
**
**  Auth:   mem
**  Date:   08/17/2006
**          09/01/2006 mem - Updated to use public.timestamp_text()
**          08/01/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _userInfo text;
    _sepChar text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    _userInfo := Coalesce(timestamp_text(localtimestamp) || '; ' || SESSION_USER, '');

    _sepChar := ' (';

    UPDATE pc.t_log_entries
    SET entered_by = CASE WHEN strpos(Coalesce(entered_by, ''), ' (') > 0 THEN
                               Left(pc.t_log_entries.entered_by, strpos(Coalesce(entered_by, ''), ' (') - 1) || _sepChar || _userInfo || ')'
                          WHEN pc.t_log_entries.entered_by IS NULL THEN SESSION_USER
                          ELSE Coalesce(pc.t_log_entries.entered_by, '??') || _sepChar || _userInfo || ')'
                     END
    WHERE entry_id = NEW.entry_id;

    RETURN null;
END
$$;


ALTER FUNCTION pc.trigfn_t_log_entries_user_after_update() OWNER TO d3l243;

