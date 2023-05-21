--
CREATE OR REPLACE PROCEDURE public.refresh_cached_mts_peak_matching_tasks
(
    _jobMinimum int = 0,
    _jobMaximum int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the data in T_MTS_Peak_Matching_Tasks_Cached using MTS
**
**  Arguments:
**    _jobMinimum   Set to a positive value to limit the jobs examined; when non-zero, jobs outside the range _jobMinimum to _jobMaximum are ignored
**
**  Auth:   mem
**  Date:   02/05/2010 mem - Initial Version
**          04/21/2010 mem - Updated to use the most recent entry for a given peak matching task (to avoid duplicates if a task is rerun)
**          10/13/2010 mem - Now updating AMT_Count_1pct_FDR through AMT_Count_50pct_FDR
**          12/14/2011 mem - Added columns MD_ID and QID
**          03/16/2012 mem - Added columns Ini_File_Name, Comparison_Mass_Tag_Count, and MD_State
**          05/24/2013 mem - Added column Refine_Mass_Cal_PPMShift
**          08/09/2013 mem - Now populating MassErrorPPM_VIPER and AMTs_10pct_FDR in T_Dataset_QC using Refine_Mass_Cal_PPMShift
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/12/2007 mem - Populate AMTs_25pct_FDR to T_Dataset_QC
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _maxInt int;
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _mergeDeleteCount int;
    _fullRefreshPerformed boolean;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    _maxint := 2147483647;

    _mergeInsertCount := 0;
    _mergeUpdateCount := 0;
    _mergeDeleteCount := 0;

    BEGIN
        _currentLocation := 'Validate the inputs';

        -- Validate the inputs
        _jobMinimum := Coalesce(_jobMinimum, 0);
        _jobMaximum := Coalesce(_jobMaximum, 0);

        If _jobMinimum <= 0 AND _jobMaximum <= 0 Then
            _fullRefreshPerformed := true;
            _jobMinimum := -_maxInt;
            _jobMaximum := _maxInt;
        Else
            _fullRefreshPerformed := false;
            If _jobMinimum > _jobMaximum Then
                _jobMaximum := _maxInt;
            End If;
        End If;

        _currentLocation := 'Update t_mts_cached_data_status';
        --
        CALL update_mts_cached_data_status (
                    't_mts_peak_matching_tasks_cached',
                    _incrementRefreshCount => false,
                    _fullRefreshPerformed => _fullRefreshPerformed,
                    _lastRefreshMinimumID => _jobMinimum);

        -- Use a MERGE Statement to synchronize t_mts_peak_matching_tasks_cached with S_MTS_Peak_Matching_Tasks

        SELECT COUNT(*)
        INTO _countBeforeMerge
        FROM t_mts_peak_matching_tasks_cached;

        MERGE INTO t_mts_peak_matching_tasks_cached AS target
        USING ( SELECT tool_name, mts_job_id, job_start, Job_Finish, Comment,
                       state_id, task_server, task_database, Task_ID,
                       assigned_processor_name, tool_version, dms_job_count,
                       dms_job, output_folder_path, results_url,
                       amt_count_1pct_fdr, amt_count_5pct_fdr,
                       amt_count_10pct_fdr, amt_count_25pct_fdr,
                       amt_count_50pct_fdr, refine_mass_cal_ppm_shift,
                       md_id, qid,
                       ini_file_name, comparison_mass_tag_count, md_state
                FROM ( SELECT tool_name, mts_job_id, job_start, Job_Finish, Comment,
                              state_id, task_server, task_database, Task_ID,
                              assigned_processor_name, tool_version, dms_job_count,
                              dms_job, output_folder_path, results_url,
                              amt_count_1pct_fdr, amt_count_5pct_fdr,
                              amt_count_10pct_fdr, amt_count_25pct_fdr,
                              amt_count_50pct_fdr, refine_mass_cal_ppm_shift,
                              md_id, qid,
                              ini_file_name, comparison_mass_tag_count, md_state,
                              RANK() OVER ( PARTITION BY tool_name, task_server, task_database, task_id
                                            ORDER BY mts_job_id DESC ) AS TaskStartRank
                      FROM S_MTS_Peak_Matching_Tasks AS PMT
                      WHERE mts_job_id >= _jobMinimum AND
                            mts_job_id <= _jobMaximum ) SourceQ
                WHERE TaskStartRank = 1
              ) AS Source
        ON (target.mts_job_id = source.mts_job_id AND target.dms_job = source.dms_job)
        WHEN MATCHED AND
             (Coalesce(target.job_start,'') <> Coalesce(source.job_start,'') OR
              Coalesce(target.job_finish,'') <> Coalesce(source.job_finish,'') OR
              target.state_id <> source.state_id OR
              target.task_server <> source.task_server OR
              target.task_database <> source.task_database OR
              target.task_id <> source.task_id OR
              Coalesce(target.dms_job_count,0) <> Coalesce(source.dms_job_count,0) OR
              Coalesce(target.output_folder_path,'') <> Coalesce(source.output_folder_path,'') OR
              Coalesce(target.results_url,'') <> Coalesce(source.results_url,'') OR
              Coalesce(target.amt_count_1pct_fdr, 0) <> source.amt_count_1pct_fdr OR
              Coalesce(target.amt_count_5pct_fdr, 0) <> source.amt_count_5pct_fdr OR
              Coalesce(target.amt_count_10pct_fdr, 0) <> source.amt_count_10pct_fdr OR
              Coalesce(target.amt_count_25pct_fdr, 0) <> source.amt_count_25pct_fdr OR
              Coalesce(target.amt_count_50pct_fdr, 0) <> source.amt_count_50pct_fdr OR
              Coalesce(target.refine_mass_cal_ppm_shift, -9999) <> source.refine_mass_cal_ppm_shift OR
              Coalesce(target.md_id, -1) <> source.md_id OR
              Coalesce(target.qid, -1) <> source.qid OR
              Coalesce(target.ini_file_name, '') <> source.ini_file_name OR
              Coalesce(target.comparison_mass_tag_count, -1) <> source.comparison_mass_tag_count OR
              Coalesce(target.md_state, 49) <> source.md_state) THEN
            UPDATE SET
                tool_name = source.tool_name,
                job_start = source.job_start,
                job_finish = source.job_finish,
                comment = source.comment,
                state_id = source.state_id,
                task_server = source.task_server,
                task_database = source.task_database,
                task_id = source.task_id,
                assigned_processor_name = source.assigned_processor_name,
                tool_version = source.tool_version,
                dms_job_count = source.dms_job_count,
                output_folder_path = source.output_folder_path,
                results_url = source.results_url,
                amt_count_1pct_fdr = source.amt_count_1pct_fdr,
                amt_count_5pct_fdr = source.amt_count_5pct_fdr,
                amt_count_10pct_fdr = source.amt_count_10pct_fdr,
                amt_count_25pct_fdr = source.amt_count_25pct_fdr,
                amt_count_50pct_fdr = source.amt_count_50pct_fdr,
                refine_mass_cal_ppm_shift = source.refine_mass_cal_ppm_shift,
                md_id = source.md_id,
                qid = source.qid,
                ini_file_name = source.ini_file_name,
                comparison_mass_tag_count = source.comparison_mass_tag_count,
                md_state = source.md_state
        WHEN NOT MATCHED THEN
            INSERT (tool_name,
                    mts_job_id,
                    job_start,
                    job_finish,
                    comment,
                    state_id,
                    task_server,
                    task_database,
                    task_id,
                    assigned_processor_name,
                    tool_version,
                    dms_job_count,
                    dms_job,
                    output_folder_path,
                    results_url,
                    amt_count_1pct_fdr,
                    amt_count_5pct_fdr,
                    amt_count_10pct_fdr,
                    amt_count_25pct_fdr,
                    amt_count_50pct_fdr,
                    refine_mass_cal_ppm_shift,
                    md_id,
                    qid,
                    ini_file_name,
                    comparison_mass_tag_count,
                    md_state)
            VALUES (source.tool_name, source.mts_job_id, source.job_start, source.Job_Finish, source.Comment,
                    source.state_id, source.task_server, source.task_database, source.Task_ID,
                    source.assigned_processor_name, source.tool_version, source.dms_job_count,
                    source.dms_job, source.output_folder_path, source.results_url,
                    source.amt_count_1pct_fdr, source.amt_count_5pct_fdr,
                    source.amt_count_10pct_fdr, source.amt_count_25pct_fdr,
                    source.amt_count_50pct_fdr, source.refine_mass_cal_ppm_shift,
                    source.md_id, source.qid,
                    source.ini_file_name, source.comparison_mass_tag_count, source.md_state);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(*)
        INTO _countAfterMerge
        FROM t_mts_pt_db_jobs_cached;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- If _fullRefreshPerformed is true, delete rows in t_mts_peak_matching_tasks_cached that are not in S_MTS_Analysis_Job_to_MT_DB_Map

        If _fullRefreshPerformed Then

            DELETE FROM t_mts_peak_matching_tasks_cached target
            WHERE NOT EXISTS (SELECT source.mts_job_id
                              FROM (SELECT DISTINCT PMT.mts_job_id, PMT.dms_job
                                    FROM S_MTS_Peak_Matching_Tasks AS PMT
                                   ) AS Source
                              WHERE target.mts_job_id = source.mts_job_id AND
                                    target.dms_job = source.dms_job);

            GET DIAGNOSTICS _mergeDeleteCount = ROW_COUNT;

        End If;

        _currentLocation := 'Copy mass error and match stat values into t_dataset_qc';

        ---------------------------------------------------
        -- Update the cached VIPER stats in t_dataset_qc
        -- The stats used come from the most recent DeconTools job for the datasets
        -- If there are multiple peak matching tasks, results come from the task with the lowest MD_State value and latest Job_Finish value
        ---------------------------------------------------
        --
        UPDATE t_dataset_qc
        SET mass_error_ppm_viper = SourceQ.PPMShift_VIPER,
            amts_10pct_fdr = SourceQ.AMT_Count_10pct_FDR,
            amts_25pct_fdr = SourceQ.AMT_Count_25pct_FDR
        FROM (SELECT J.dataset_id AS Dataset_ID,
                     -PM.refine_mass_cal_ppm_shift AS PPMShift_VIPER,
                     PM.amt_count_10pct_fdr,
                     PM.amt_count_25pct_fdr,
                     Row_Number() OVER ( PARTITION BY J.dataset_id ORDER BY J.job DESC, PM.md_state, PM.job_finish DESC ) AS TaskRank
              FROM t_mts_peak_matching_tasks_cached PM
                  INNER JOIN t_analysis_job J
                      ON PM.dms_job = J.job
              WHERE NOT (PM.refine_mass_cal_ppm_shift IS NULL) AND
                      PM.dms_job >= _jobMinimum AND
                      PM.dms_job <= _jobMaximum
             ) SourceQ
        WHERE DQC.dataset_id = SourceQ.dataset_id AND SourceQ.TaskRank = 1 AND
              (DQC.mass_error_ppm_viper IS DISTINCT FROM SourceQ.PPMShift_VIPER OR
               DQC.AMTs_10pct_FDR       IS DISTINCT FROM SourceQ.amt_count_10pct_fdr OR
               DQC.AMTs_25pct_FDR       IS DISTINCT FROM SourceQ.amt_count_25pct_fdr
              );

        _currentLocation := 'Update stats in t_mts_cached_data_status';

        CALL update_mts_cached_data_status (
                    't_mts_peak_matching_tasks_cached',
                    _incrementRefreshCount => true,
                    _insertCountNew => _mergeInsertCount,
                    _updateCountNew => _mergeUpdateCount,
                    _deleteCountNew => _mergeDeleteCount,
                    _fullRefreshPerformed => _fullRefreshPerformed,
                    _lastRefreshMinimumID => _jobMinimum);

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;

COMMENT ON PROCEDURE public.refresh_cached_mts_peak_matching_tasks IS 'RefreshCachedMTSPeakMatchingTasks';
