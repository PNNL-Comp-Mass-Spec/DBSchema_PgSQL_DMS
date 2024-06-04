--
-- Name: trigfn_t_organisms_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_organisms_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Appends the inserted row to the organism change history table
**
**  Auth:   mem
**  Date:   08/05/2022 mem - Ported to PostgreSQL
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
    SELECT organism_id, organism, description, short_name,
           domain, kingdom, phylum, class, "order",
           family, genus, species, strain,
           newt_id_list, ncbi_taxonomy_id,
           active, CURRENT_TIMESTAMP, SESSION_USER
    FROM inserted
    ORDER BY organism_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_organisms_after_insert() OWNER TO d3l243;

