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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> with mass_correction_tag, monoisotopic_mass, and affected_atom since they are never null
    -- In contrast, average_mass could be null
    If OLD.mass_correction_tag <> NEW.mass_correction_tag OR
       OLD.monoisotopic_mass   <> NEW.monoisotopic_mass OR
       OLD.affected_atom       <> NEW.affected_atom OR
       OLD.average_mass IS DISTINCT FROM NEW.average_mass Then

        INSERT INTO t_mass_correction_factors_change_history (
                    mass_correction_id, mass_correction_tag, description,
                    monoisotopic_mass, average_mass,
                    affected_atom, original_source, original_source_name,
                    alternative_name, empirical_formula,
                    monoisotopic_mass_change,
                    average_mass_change,
                    entered, entered_by)
        SELECT  N.mass_correction_id, N.mass_correction_tag, N.description,
                N.monoisotopic_mass, N.average_mass,
                N.affected_atom, N.original_source, N.original_source_name,
                N.alternative_name, N.empirical_formula,
                ROUND((N.monoisotopic_mass - O.monoisotopic_mass)::numeric, 10),
                ROUND((N.average_mass - O.average_mass)::numeric, 10),
                CURRENT_TIMESTAMP, SESSION_USER
        FROM OLD as O INNER JOIN
             NEW as N ON O.mass_correction_id = N.mass_correction_id;       -- mass_correction_id is never null

    End If;
    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_mass_correction_factors_after_update() OWNER TO d3l243;

