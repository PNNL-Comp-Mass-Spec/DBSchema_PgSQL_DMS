--
-- Name: trigfn_t_dataset_archive_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_dataset_archive_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the updated dataset archive task
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          09/04/2007 mem - Now updating archive_state_last_affected when the state changes (Ticket #527)
**          10/31/2007 mem - Updated to track changes to archive_update_state_id (Ticket #569)
**                         - Updated to make entries in t_event_log only if the state actually changes (Ticket #569)
**          12/12/2007 mem - Now updating state_name_cached in t_analysis_job (Ticket #585)
**          08/04/2008 mem - Now updating instrument_data_purged if archive_state_id changes to 4 (Ticket #683)
**          06/06/2012 mem - Now updating archive_state_last_affected and archive_update_state_last_affected only if the state actually changes
**          06/11/2012 mem - Now updating qc_data_purged to 1 if archive_state_id changes to 4
**          06/12/2012 mem - Now updating instrument_data_purged if archive_state_id changes to 4 or 14
**          11/14/2013 mem - Now updating t_cached_dataset_folder_paths
**          07/25/2017 mem - Now updating t_cached_dataset_links
**          08/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From NEW) Then
        Return Null;
    End If;

    -- Use <> since archive_state_id is never null
    If OLD.archive_state_id <> NEW.archive_state_id Then

        INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
        SELECT 6, N.dataset_id, N.archive_state_id, O.archive_state_id, CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.dataset_id = N.dataset_id;

        UPDATE t_dataset_archive
        SET archive_state_last_affected = CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.dataset_id = N.dataset_id
        WHERE t_dataset_archive.dataset_id = N.dataset_id;

        UPDATE t_dataset_archive
        SET instrument_data_purged = 1
        FROM OLD as O INNER JOIN
             NEW as N ON O.dataset_id = N.dataset_id
        WHERE t_dataset_archive.dataset_id = N.dataset_id AND
              t_dataset_archive.archive_state_id in (4, 14) AND
              t_dataset_archive.instrument_data_purged <> 1;        -- instrument_data_purged is never null

        UPDATE t_dataset_archive
        SET qc_data_purged = 1
        FROM OLD as O INNER JOIN
             NEW as N ON O.dataset_id = N.dataset_id
        WHERE t_dataset_archive.dataset_id = N.dataset_id AND
              t_dataset_archive.archive_state_id = 4 AND
              t_dataset_archive.qc_data_purged <> 1;                -- qc_data_purged is never null
    End If;

    -- Use IS DISTINCT FROM since archive_update_state_id can be null
    If OLD.archive_update_state_id IS DISTINCT FROM NEW.archive_update_state_id Then

        INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
        SELECT 7, N.dataset_id, N.archive_update_state_id, O.archive_update_state_id, CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.dataset_id = N.dataset_id;

        UPDATE t_dataset_archive
        SET archive_update_state_last_affected = CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.dataset_id = N.dataset_id
        WHERE t_dataset_archive.dataset_id = N.dataset_id;
    End If;

    -- Use <> with archive_state_id since never null
    -- In contrast, archive_update_state_id could be null
    If OLD.archive_state_id <> NEW.archive_state_id OR
       OLD.archive_update_state_id IS DISTINCT FROM NEW.archive_update_state_id Then

        UPDATE t_analysis_job
        SET state_name_cached = COALESCE(AJDAS.job_state, '')
        FROM NEW as N INNER JOIN
             V_Analysis_Job_and_Dataset_Archive_State AJDAS
               ON AJDAS.dataset_id = N.dataset_ID
        WHERE t_analysis_job.dataset_id = N.dataset_id AND
              t_analysis_job.state_name_cached <> COALESCE(AJDAS.job_state, '');

    End If;

    -- Use <> since storage_path_id is never null
    If OLD.storage_path_id <> NEW.storage_path_id Then

        UPDATE t_cached_dataset_folder_paths
        SET update_required = 1
        FROM NEW as N
        WHERE t_cached_dataset_folder_paths.dataset_id = N.dataset_id;

    End If;

    -- Use <> since these columns are never null
    If OLD.archive_state_id <> NEW.archive_state_id OR
       OLD.storage_path_id <> NEW.storage_path_id OR
       OLD.instrument_data_purged <> NEW.instrument_data_purged OR
       OLD.qc_data_purged <> NEW.qc_data_purged OR
       OLD.myemsl_state <> NEW.myemsl_state Then

        UPDATE t_cached_dataset_links
        SET update_required = 1
        FROM NEW as N
        WHERE t_cached_dataset_links.dataset_id = N.dataset_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_dataset_archive_after_update() OWNER TO d3l243;

