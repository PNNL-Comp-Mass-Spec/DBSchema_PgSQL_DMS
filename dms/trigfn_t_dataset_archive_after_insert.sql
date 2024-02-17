--
-- Name: trigfn_t_dataset_archive_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_dataset_archive_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the new dataset archive task
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          10/31/2007 mem - Updated to track changes to archive_update_state_id (Ticket #569)
**          12/12/2007 mem - Now updating state_name_cached in t_analysis_job (Ticket #585)
**          11/14/2013 mem - Now updating t_cached_dataset_folder_paths
**          07/25/2017 mem - Now updating t_cached_dataset_links
**          08/05/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (SELECT * FROM inserted) Then
        RETURN Null;
    End If;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 6, inserted.dataset_id, inserted.archive_state_id, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.dataset_id;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 7, inserted.dataset_id, inserted.archive_update_state_id, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.dataset_id;

    UPDATE t_analysis_job
    SET state_name_cached = COALESCE(AJDAS.job_state, '')
    FROM inserted INNER JOIN
         V_Analysis_Job_and_Dataset_Archive_State AJDAS
           ON AJDAS.dataset_id = inserted.dataset_ID
    WHERE t_analysis_job.dataset_id = inserted.dataset_id AND
          t_analysis_job.state_name_cached <> COALESCE(AJDAS.job_state, '');

    UPDATE t_cached_dataset_folder_paths
    SET update_required = 1
    FROM inserted
    WHERE t_cached_dataset_folder_paths.dataset_id = inserted.dataset_id;

    UPDATE t_cached_dataset_links
    SET update_required = 1
    FROM inserted
    WHERE t_cached_dataset_links.dataset_id = inserted.dataset_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_dataset_archive_after_insert() OWNER TO d3l243;

