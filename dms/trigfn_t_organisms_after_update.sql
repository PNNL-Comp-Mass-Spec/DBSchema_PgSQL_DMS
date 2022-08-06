--
-- Name: trigfn_t_organisms_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_organisms_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Appends the updated row to the organism change history table
**
**  Auth:   mem
**  Date:   08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> with organism since never null
    -- The remaining columns could each be null
    If OLD.organism <> NEW.organism OR
       OLD.short_name       IS DISTINCT FROM NEW.short_name OR
       OLD.domain           IS DISTINCT FROM NEW.domain OR
       OLD.kingdom          IS DISTINCT FROM NEW.kingdom OR
       OLD.phylum           IS DISTINCT FROM NEW.phylum OR
       OLD.class            IS DISTINCT FROM NEW.class OR
       OLD."order"          IS DISTINCT FROM NEW."order" OR
       OLD.family           IS DISTINCT FROM NEW.family OR
       OLD.genus            IS DISTINCT FROM NEW.genus OR
       OLD.species          IS DISTINCT FROM NEW.species OR
       OLD.strain           IS DISTINCT FROM NEW.strain OR
       OLD.newt_id_list     IS DISTINCT FROM NEW.newt_id_list OR
       OLD.ncbi_taxonomy_id IS DISTINCT FROM NEW.ncbi_taxonomy_id OR
       OLD.active           IS DISTINCT FROM NEW.active Then

        INSERT INTO t_organisms_change_history
            (
                organism_id, organism, description, short_name,
                domain, kingdom, phylum, class, "order",
                family, genus, species, strain,
                newt_id_list, ncbi_taxonomy_id,
                active, entered, entered_by
            )
        SELECT  N.organism_id, N.organism, N.description, N.short_name,
                N.domain, N.kingdom, N.phylum, N.class, N."order",
                N.family, N.genus, N.species, N.strain,
                N.newt_id_list, N.ncbi_taxonomy_id,
                N.active, CURRENT_TIMESTAMP, SESSION_USER
        FROM OLD as O INNER JOIN
             NEW as N ON O.organism_id = N.organism_id;         -- organism_id is never null

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_organisms_after_update() OWNER TO d3l243;

