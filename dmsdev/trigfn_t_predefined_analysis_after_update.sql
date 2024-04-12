--
-- Name: trigfn_t_predefined_analysis_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_predefined_analysis_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the last_affected column in t_predefined_analysis
**
**  Auth:   mem
**  Date:   08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_predefined_analysis
    SET last_affected = CURRENT_TIMESTAMP
    WHERE t_predefined_analysis.predefine_id = NEW.predefine_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_predefined_analysis_after_update() OWNER TO d3l243;

