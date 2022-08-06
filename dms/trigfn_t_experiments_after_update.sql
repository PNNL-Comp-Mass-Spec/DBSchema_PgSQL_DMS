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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since experiment is never null
    If OLD.experiment <> NEW.experiment Then

        INSERT INTO t_entity_rename_log (target_type, target_id, old_name, new_name, entered)
        SELECT 3, N.exp_id, O.experiment, N.experiment, CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.exp_id = N.exp_id
        WHERE O.experiment <> N.experiment;   -- Use <> since experiment name is never null

        UPDATE t_file_attachment
        SET entity_id = N.experiment
        FROM OLD as O INNER JOIN
             NEW as N ON O.exp_id = N.exp_id
        WHERE Entity_Type = 'experiment' AND
              t_file_attachment.entity_id = O.experiment;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_experiments_after_update() OWNER TO d3l243;

