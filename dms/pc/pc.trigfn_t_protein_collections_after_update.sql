--
-- Name: trigfn_t_protein_collections_after_update(); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.trigfn_t_protein_collections_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_event_log when the collection state changes for a protein collection
**
**  Auth:   mem
**  Date:   08/01/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the OLD and NEW variables directly instead of using transition tables (which contain every updated row, not just the current row)
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
           NEW.protein_collection_id,
           NEW.collection_state_id AS target_state,
           OLD.collection_state_id AS prev_target_state;

    RETURN null;
END
$$;


ALTER FUNCTION pc.trigfn_t_protein_collections_after_update() OWNER TO d3l243;

