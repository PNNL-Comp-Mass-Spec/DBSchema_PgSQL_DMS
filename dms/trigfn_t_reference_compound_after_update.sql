--
-- Name: trigfn_t_reference_compound_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_reference_compound_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_entity_rename_log if the compound is renamed
**
**  Auth:   mem
**  Date:   11/28/2017 mem - Initial version
**          01/03/2018 mem - Store compound name, gene name, and modifications in the old_name and new_name fields
**
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> with compound_name since never null
    -- The other columns could be null
    If OLD.compound_name <> NEW.compound_name OR
       OLD.modifications IS DISTINCT FROM NEW.modifications OR
       OLD.gene_name IS DISTINCT FROM NEW.gene_name Then

        INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
        SELECT 13, N.compound_id,
               O.compound_name || ' (modifications ' || COALESCE(O.modifications, '') || ', Gene ' || COALESCE(O.gene_name, '') || ')',
               N.compound_name || ' (modifications ' || COALESCE(N.modifications, '') || ', Gene ' || COALESCE(N.gene_name, '') || ')',
               CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.compound_id = N.compound_id
        WHERE O.compound_name || '_' || COALESCE(O.modifications, '') || '_' ||  COALESCE(O.gene_name, '') <>
              N.compound_name || '_' || COALESCE(N.modifications, '') || '_' ||  COALESCE(N.gene_name, '')
        ORDER BY N.compound_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_reference_compound_after_update() OWNER TO d3l243;

