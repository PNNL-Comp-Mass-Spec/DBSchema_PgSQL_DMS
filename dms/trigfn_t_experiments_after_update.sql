--
-- Name: trigfn_t_experiments_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_experiments_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_entity_rename_log if the experiment is renamed
**      Renames entries in t_file_attachment
**
**  Auth:   mem
**  Date:   07/19/2010 mem - Initial version
**          03/23/2012 mem - Now updating t_file_attachment
**          11/28/2017 mem - Check for unchanged experiment name
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the OLD and NEW variables directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
    SELECT 3, NEW.exp_id, OLD.experiment, NEW.experiment, CURRENT_TIMESTAMP
    WHERE OLD.experiment <> NEW.experiment;   -- Use <> since experiment name is never null

    UPDATE t_file_attachment
    SET entity_id = NEW.experiment
    WHERE Entity_Type = 'experiment' AND
          t_file_attachment.entity_id = OLD.experiment;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiments_after_update() OWNER TO d3l243;

