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
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
    SELECT 13, NEW.compound_id,
           format('%s (modifications %s, Gene %s)', OLD.compound_name, COALESCE(OLD.modifications, ''), COALESCE(OLD.gene_name, '')),
           format('%s (modifications %s, Gene %s)', NEW.compound_name, COALESCE(NEW.modifications, ''), COALESCE(NEW.gene_name, '')),
           CURRENT_TIMESTAMP
    WHERE format('%s_%s_%s', OLD.compound_name, COALESCE(OLD.modifications, ''), COALESCE(OLD.gene_name, '')) <>
          format('%s_%s_%s', NEW.compound_name, COALESCE(NEW.modifications, ''), COALESCE(NEW.gene_name, ''));

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_reference_compound_after_update() OWNER TO d3l243;

