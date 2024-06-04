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
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_organisms_change_history (
        organism_id, organism, description, short_name,
        domain, kingdom, phylum, class, "order",
        family, genus, species, strain,
        newt_id_list, ncbi_taxonomy_id,
        active, entered, entered_by
    )
    SELECT NEW.organism_id, NEW.organism, NEW.description, NEW.short_name,
           NEW.domain, NEW.kingdom, NEW.phylum, NEW.class, NEW."order",
           NEW.family, NEW.genus, NEW.species, NEW.strain,
           NEW.newt_id_list, NEW.ncbi_taxonomy_id,
           NEW.active, CURRENT_TIMESTAMP, SESSION_USER;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_organisms_after_update() OWNER TO d3l243;

