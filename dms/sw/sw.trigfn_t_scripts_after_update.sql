--
-- Name: trigfn_t_scripts_after_update(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_scripts_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores the contents of the updated scripts in t_scripts_history,
**      though only if the script name, results_tag, or contents changes
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO sw.t_scripts_history
        (script_id, script, results_tag, contents, parameters, backfill_to_dms)
    SELECT NEW.script_id, NEW.script, NEW.results_tag, NEW.contents, NEW.parameters, NEW.backfill_to_dms;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_scripts_after_update() OWNER TO d3l243;

