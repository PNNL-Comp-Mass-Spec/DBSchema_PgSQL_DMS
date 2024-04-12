--
-- Name: trigfn_t_scripts_after_delete(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_scripts_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores the contents of the deleted scripts in t_scripts_history
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          06/10/2023 mem - Fix syntax error calling format()
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO cap.t_scripts_history
        (script_id, script, results_tag, contents)
    SELECT script_id, format('Deleted: %s', script), results_tag, contents
    FROM deleted
    ORDER BY deleted.script_id;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_scripts_after_delete() OWNER TO d3l243;

