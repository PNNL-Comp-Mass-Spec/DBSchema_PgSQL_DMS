--
-- Name: trigfn_t_protein_collections_after_delete(); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.trigfn_t_protein_collections_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Raises an exception if all rows in t_protein_collections are deleted
**
**      Otherwise, adds entries to t_event_log for each deleted protein collection
**
**  Auth:   mem
**  Date:   08/01/2022 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(protein_collection_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _newRowCount int;
    _deletedRowCount int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    SELECT COUNT(protein_collection_id)
    INTO _newRowCount
    FROM pc.t_protein_collections;

    SELECT COUNT(*)
    INTO _deletedRowCount
    FROM deleted;

    -- RAISE NOTICE 'New row count: %, deleted rows: %', _newRowCount, _deletedRowCount;

    If _deletedRowCount > 0 And _newRowCount = 0 Then
        _message := format('Cannot delete all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _deletedRowCount, 't_protein_collections', 'trigfn_t_protein_collections_after_delete');

        RAISE EXCEPTION '%', _message;
        RETURN null;
    End If;

    -- Add a new row to pc.t_event_log
    INSERT INTO pc.t_event_log (
        target_type,
        target_id,
        target_state,
        prev_target_state
    )
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

