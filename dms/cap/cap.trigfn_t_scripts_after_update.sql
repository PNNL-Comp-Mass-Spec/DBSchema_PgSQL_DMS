--
-- Name: trigfn_t_scripts_after_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_scripts_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores the contents of the updated scripts in T_Scripts_History
**
**  Auth:   mem
**  Date:   07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If NEW.script = OLD.script AND
       Coalesce(NEW.results_tag, '') = Coalesce(OLD.results_tag, '') AND
       Coalesce(NEW.contents, '') = Coalesce(OLD.contents, '') THEN
        RETURN null;
    End If;

    INSERT INTO cap.T_Scripts_History
        (id, script, results_tag, contents)
    SELECT id, script, results_tag, contents
    FROM NEW
    ORDER BY NEW.id;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_scripts_after_update() OWNER TO d3l243;

