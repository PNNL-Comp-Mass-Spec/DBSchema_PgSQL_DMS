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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> for these columns because they can never be null
    If OLD.residue_symbol    <> NEW.residue_symbol OR
       OLD.average_mass      <> NEW.average_mass OR
       OLD.monoisotopic_mass <> NEW.monoisotopic_mass OR
       OLD.num_c             <> NEW.num_c OR
       OLD.num_h             <> NEW.num_h OR
       OLD.num_n             <> NEW.num_n OR
       OLD.num_o             <> NEW.num_o OR
       OLD.num_s             <> NEW.num_s Then

        INSERT INTO t_residues_change_history (
                    residue_id, residue_symbol, description, average_mass,
                    monoisotopic_mass, num_c, num_h, num_n, num_o, num_s,
                    monoisotopic_mass_change,
                    average_mass_change,
                    entered, entered_by)
        SELECT N.residue_id, N.residue_symbol, N.description, N.average_mass,
               N.monoisotopic_mass, N.num_c, N.num_h, N.num_n, N.num_o, N.num_s,
               ROUND((N.monoisotopic_mass - O.monoisotopic_mass)::numeric, 10),
               ROUND((N.average_mass - O.average_mass)::numeric, 10),
               CURRENT_TIMESTAMP, SESSION_USER
        FROM OLD as O INNER JOIN
             NEW as N ON O.residue_id = N.residue_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_residues_after_update() OWNER TO d3l243;

