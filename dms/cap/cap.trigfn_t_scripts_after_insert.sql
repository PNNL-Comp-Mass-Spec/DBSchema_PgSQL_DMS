--
-- Name: trigfn_t_scripts_after_insert(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_scripts_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores the contents of the new scripts in t_scripts_history
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO cap.T_Scripts_History
        (script_id, script, results_tag, contents)
    SELECT script_id, script, results_tag, contents
    FROM inserted
    ORDER BY inserted.script_id;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_scripts_after_insert() OWNER TO d3l243;

