--
-- Name: trigfn_t_log_entries_user_after_update(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.trigfn_t_log_entries_user_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the entered_by field in mc.t_log_entries
**
**  Auth:   mem
**  Date:   01/09/2020 mem - Initial version
**          04/16/2022 mem - Use new function name
**          07/30/2022 mem - Use schema name when referencing tables
**
*****************************************************/
DECLARE
    _userInfo text;
    _sepChar text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    _userInfo := Coalesce(timestamp_text(localtimestamp) || '; ' || SESSION_USER, '');

    _sepChar := ' (';

    UPDATE mc.t_log_entries
    SET entered_by = CASE WHEN strpos(Coalesce(entered_by, ''), ' (') > 0 THEN
                               Left(mc.t_log_entries.entered_by, strpos(Coalesce(entered_by, ''), ' (') - 1) || _sepChar || _userInfo || ')'
                          WHEN mc.t_log_entries.entered_by IS NULL THEN SESSION_USER
                          ELSE Coalesce(mc.t_log_entries.entered_by, '??') || _sepChar || _userInfo || ')'
                     END
    WHERE entry_id = NEW.entry_id;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_t_log_entries_user_after_update() OWNER TO d3l243;

