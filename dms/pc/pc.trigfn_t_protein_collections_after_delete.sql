--
-- Name: trigfn_t_protein_collections_after_delete(); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.trigfn_t_protein_collections_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_event_log for each deleted protein collection
**
**  Auth:   mem
**  Date:   08/01/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    -- Add a new row to t_event_log
    INSERT INTO pc.t_event_log( target_type,
                                target_id,
                                target_state,
                                prev_target_state )
    SELECT 1 AS target_type,
           deleted.protein_collection_id,
           0 AS target_state,
           deleted.collection_state_id AS prev_target_state
    FROM deleted
    ORDER BY deleted.protein_collection_id;

    RETURN null;
END
$$;


ALTER FUNCTION pc.trigfn_t_protein_collections_after_delete() OWNER TO d3l243;

