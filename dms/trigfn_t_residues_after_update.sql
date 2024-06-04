--
-- Name: trigfn_t_residues_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_residues_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_residues_change_history for each updated residue
**
**  Auth:   mem
**  Date:   08/06/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_residues_change_history (
        residue_id, residue_symbol, description, average_mass,
        monoisotopic_mass, num_c, num_h, num_n, num_o, num_s,
        monoisotopic_mass_change,
        average_mass_change,
        entered, entered_by
    )
    SELECT NEW.residue_id, NEW.residue_symbol, NEW.description, NEW.average_mass,
           NEW.monoisotopic_mass, NEW.num_c, NEW.num_h, NEW.num_n, NEW.num_o, NEW.num_s,
           ROUND((NEW.monoisotopic_mass - OLD.monoisotopic_mass)::numeric, 10),
           ROUND((NEW.average_mass - OLD.average_mass)::numeric, 10),
           CURRENT_TIMESTAMP, SESSION_USER;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_residues_after_update() OWNER TO d3l243;

