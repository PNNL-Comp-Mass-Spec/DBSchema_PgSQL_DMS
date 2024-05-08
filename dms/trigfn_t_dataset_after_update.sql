--
-- Name: trigfn_t_dataset_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_dataset_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the updated dataset
**
**      Also looks for renamed datasets and updates t_cached_dataset_folder_paths and t_cached_dataset_links if necessary
**
**  Auth:   grk
**  Date:   01/01/2003
**          05/16/2007 mem - Update last_affected when dataset_state_id changes (Ticket #478)
**          08/15/2007 mem - Update to use an Insert query and to make an entry if dataset_rating_id is changed (Ticket #519)
**          11/01/2007 mem - Update to make entries in t_event_log only if the state actually changes (Ticket #569)
**          07/19/2010 mem - Update t_entity_rename_log if the dataset is renamed
**          11/15/2013 mem - Update t_cached_dataset_folder_paths
**          11/22/2013 mem - Update date_sort_key
**          07/25/2017 mem - Update t_cached_dataset_links
**          08/05/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the OLD and NEW variables directly instead of using transition tables (which contain every updated row, not just the current row)
**          09/08/2023 mem - Adjust capitalization of keywords
**          05/03/2024 mem - Set update_required to 1 in t_cached_experiment_stats
**
*****************************************************/

BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since dataset_state_id is never null
    If OLD.dataset_state_id <> NEW.dataset_state_id Then

        INSERT INTO t_event_log (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered
        )
        SELECT 4, NEW.dataset_id, NEW.dataset_state_id, OLD.dataset_state_id, CURRENT_TIMESTAMP;

        UPDATE t_dataset
        SET last_affected = CURRENT_TIMESTAMP
        WHERE t_dataset.dataset_id = NEW.dataset_id;

    End If;

    -- Use <> since dataset_rating_id is never null
    If OLD.dataset_rating_id <> NEW.dataset_rating_id Then

        INSERT INTO t_event_log (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered
        )
        SELECT 8, NEW.dataset_id, NEW.dataset_rating_id, OLD.dataset_rating_id, CURRENT_TIMESTAMP;

    End If;

    -- Use <> since dataset name is never null
    If OLD.dataset <> NEW.dataset Then

        INSERT INTO t_entity_rename_log (
            target_type,
            target_id,
            old_name,
            new_name,
            entered
        )
        SELECT 4, NEW.dataset_id, OLD.dataset, NEW.dataset, CURRENT_TIMESTAMP;

    End If;

    -- Use <> with dataset name since never null
    -- In contrast, folder_name could be null
    If OLD.dataset <> NEW.dataset Or
       OLD.folder_name IS DISTINCT FROM NEW.folder_name Then

        UPDATE t_cached_dataset_folder_paths
        SET update_required = 1
        WHERE t_cached_dataset_folder_paths.dataset_id = NEW.dataset_id;

        UPDATE t_cached_dataset_links
        SET update_required = 1
        WHERE t_cached_dataset_links.dataset_id = NEW.dataset_id;

    End If;

    -- Use <> with exp_id and created since never null
    -- In contrast, acq_time_start could be null
    If OLD.exp_id <> NEW.exp_id Or
       OLD.created <> NEW.created Or
       OLD.acq_time_start IS DISTINCT FROM NEW.acq_time_start Then

        -- This query must stay sync'd with the Update query in trigger trigfn_t_dataset_after_insert
        UPDATE t_dataset
        SET date_sort_key = CASE WHEN E.experiment = 'Tracking' THEN t_dataset.created
                                 ELSE COALESCE(t_dataset.acq_time_start, t_dataset.created)
                            END
        FROM t_experiments E
        WHERE t_dataset.dataset_id = NEW.dataset_id AND
              E.exp_id = NEW.exp_id;
    End If;

    If OLD.exp_id <> NEW.exp_id Then
        UPDATE t_cached_experiment_stats
        SET update_required = 1, Last_Affected = CURRENT_TIMESTAMP
        WHERE exp_id IN (NEW.exp_id, OLD.exp_id);
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_dataset_after_update() OWNER TO d3l243;

