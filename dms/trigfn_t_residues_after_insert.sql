--
-- Name: trigfn_t_residues_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_residues_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_residues_change_history for each new residue
**
**  Auth:   mem
**  Date:   08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_residues_change_history (
        residue_id, residue_symbol, description, average_mass,
        monoisotopic_mass, num_c, num_h, num_n, num_o, num_s,
        monoisotopic_mass_change, average_mass_change,
        entered, entered_by
    )
    SELECT residue_id, residue_symbol, description, average_mass,
           monoisotopic_mass, num_c, num_h, num_n, num_o, num_s,
           0 as monoisotopic_mass_change, 0 as average_mass_change,
           CURRENT_TIMESTAMP, SESSION_USER
    FROM inserted;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_residues_after_insert() OWNER TO d3l243;

