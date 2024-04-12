--
-- Name: trigfn_t_mass_correction_factors_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_mass_correction_factors_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Stores the updated information in t_mass_correction_factors_change_history
**
**  Auth:   grk
**  Date:   08/23/2006
**          11/30/2018 mem - Renamed the monoisotopic_mass and average_mass columns
**          04/02/2020 mem - Add columns Alternative_Name and Empirical_Formula
**          08/05/2022 mem - Ported to PostgreSQL
**          08/07/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW and OLD variables directly instead of using transition tables
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_mass_correction_factors_change_history (
        mass_correction_id, mass_correction_tag, description,
        monoisotopic_mass, average_mass,
        affected_atom, original_source, original_source_name,
        alternative_name, empirical_formula,
        monoisotopic_mass_change,
        average_mass_change,
        entered, entered_by
    )
    SELECT NEW.mass_correction_id, NEW.mass_correction_tag, NEW.description,
           NEW.monoisotopic_mass, NEW.average_mass,
           NEW.affected_atom, NEW.original_source, NEW.original_source_name,
           NEW.alternative_name, NEW.empirical_formula,
           ROUND((NEW.monoisotopic_mass - OLD.monoisotopic_mass)::numeric, 10),
           ROUND((NEW.average_mass - OLD.average_mass)::numeric, 10),
           CURRENT_TIMESTAMP, SESSION_USER;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_mass_correction_factors_after_update() OWNER TO d3l243;

