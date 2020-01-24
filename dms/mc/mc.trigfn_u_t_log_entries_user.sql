--
-- Name: trigfn_u_t_log_entries_user(); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.trigfn_u_t_log_entries_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**        Updates the entered_by field in t_log_entries
**
**  Auth:   mem
**  Date:   01/09/2020 mem - Initial version
**
*****************************************************/
DECLARE
    _userInfo text;
    _sepChar text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, %', TG_TABLE_NAME, TG_WHEN, TG_LEVEL, TG_OP;

    _userInfo := Coalesce(udf_timestamp_text(localtimestamp) || '; ' || SESSION_USER, '');

    _sepChar := ' (';

    UPDATE t_log_entries
    SET entered_by = CASE WHEN strpos(Coalesce(entered_by, ''), ' (') > 0 THEN
                               Left(t_log_entries.entered_by, strpos(Coalesce(entered_by, ''), ' (') - 1) || _sepChar || _userInfo || ')'
                          WHEN t_log_entries.entered_by IS NULL THEN SESSION_USER
                          ELSE Coalesce(t_log_entries.entered_by, '??') || _sepChar || _userInfo || ')'
                     END
    WHERE entry_id = NEW.entry_id;

    RETURN null;
END
$$;


ALTER FUNCTION mc.trigfn_u_t_log_entries_user() OWNER TO d3l243;

