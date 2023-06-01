--
CREATE OR REPLACE PROCEDURE sw.sync_job_info
(
    _bypassDMS boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Synchronizes job info with DMS, including
**      updating priorities and assigned processor groups
**
**  Auth:   mem
**  Date:   01/17/2009 mem - Initial version (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          06/01/2009 mem - Added index to Tmp_JobProcessorInfo (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/27/2009 mem - Now only filtering out complete jobs when populating Tmp_JobProcessorInfo (previously, we were also excluding failed jobs)
**          09/17/2009 mem - Now using a MERGE statement to update T_Local_Job_Processors
**          07/01/2010 mem - Removed old code that was replaced by the MERGE statement in 9/17/2009
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          05/28/2015 mem - No longer updating T_Local_Job_Processors since we have deprecated processor groups
**          02/15/2016 mem - Re-enabled use of T_Local_Job_Processors
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobUpdateCount int;
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _mergeDeleteCount int;
BEGIN
    _message := '';
    _returnCode := '';

    If _bypassDMS Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update archive busy flag for active jobs according to state in DMS
    --
    -- Use public.v_get_analysis_jobs_for_archive_busy
    -- to look for jobs that have dataset archive state:
    --  1=New, 2=Archive In Progress, 6=Operation Failed, 7=Purge In Progress, or 12=Verification In Progress
    -- Jobs matching this criterion are deemed 'busy' and thus will get archive_busy set to 1 in sw.t_jobs
    --
    -- However, if the dataset has been in state 'Archive In Progress' for over 90 minutes, we do not set archive_busy to true
    -- This is required because MyEMSL can be quite slow at verifying that the uploaded data has been copied to tape
    -- This logic is defined in view V_GetAnalysisJobsForArchiveBusy
    --
    -- For QC_Shew datasets, we only exclude jobs if the dataset archive state is 7=Purge In Progress
    --
    -- Prior to May 2012 we also excluded datasets with archive update state: 3=Update In Progress
    -- However, we now allow jobs to run if a dataset has an archive update job running
    --
    ---------------------------------------------------
    --
    UPDATE sw.t_jobs
    SET archive_busy = 0
    WHERE archive_busy = 1 AND
          NOT EXISTS ( SELECT AB.Job
                       FROM public.v_get_analysis_jobs_for_archive_busy AB
                       WHERE AB.Job = sw.t_jobs.job );

    UPDATE sw.t_jobs target
    SET archive_busy = 1
    FROM ( SELECT AB.Job
           FROM public.v_get_analysis_jobs_for_archive_busy AB ) BusyQ
    WHERE target.job = BusyQ.Job And archive_busy = 0;

    ---------------------------------------------------
    -- Update priorities for jobs and job steps based on
    -- the priority defined in DMS
    ---------------------------------------------------

    UPDATE sw.t_jobs J
    SET priority = PJP.priority
    FROM public.V_Get_Pipeline_Job_Priority PJP
    WHERE J.Job = PJP.Job AND
          PJP.Priority <> J.Priority
    --
    GET DIAGNOSTICS _jobUpdateCount = ROW_COUNT;

    If _jobUpdateCount > 0 Then
        _message := format('Job priorities changed: updated %s %s in sw.t_jobs', _jobUpdateCount, public.check_plural('job', 'jobs'));
        CALL public.post_log_entry ('Normal', _message, 'Sync_Job_Info', 'sw');
        _message := '';
    End If;

    ---------------------------------------------------
    -- Deprecated in May 2015, then re-enabled in February 2016
    --
    -- Update the processor groups that jobs belong to,
    -- based on the group membership defined in DMS
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _countBeforeMerge
    FROM sw.t_local_job_processors;

    -- Use a MERGE Statement to synchronize sw.t_local_job_processors with v_get_pipeline_job_processors
    --
    MERGE INTO sw.t_local_job_processors AS target
    USING ( SELECT job, processor, general_processing
            FROM public.v_get_pipeline_job_processors AS VGP
            WHERE job IN ( SELECT job
                           FROM sw.t_jobs
                           WHERE state NOT IN (4)
                         )
          ) AS Source
    ON (target.job = source.job And
        target.processor = source.processor)
    WHEN MATCHED AND target.general_processing <> source.general_processing THEN
        UPDATE SET general_processing = source.general_processing
    WHEN NOT MATCHED THEN
        INSERT (job, processor, general_processing)
        VALUES (source.job, source.processor, source.general_processing)
    ;

    GET DIAGNOSTICS _mergeCount = ROW_COUNT;

    SELECT COUNT(*)
    INTO _countAfterMerge
    FROM sw.t_local_job_processors;

    _mergeInsertCount := _countAfterMerge - _countBeforeMerge;
    _mergeUpdateCount := _mergeCount - _mergeInsertCount;

    -- Delete rows in t_local_job_processors that are not in v_get_pipeline_job_processors

    DELETE FROM sw.t_local_job_processors target
    WHERE NOT EXISTS (  SELECT source.job
                        FROM ( SELECT job, processor
                               FROM public.v_get_pipeline_job_processors AS VGP
                               WHERE job IN ( SELECT job
                                              FROM sw.t_jobs
                                              WHERE state NOT IN (4)
                                            )
                              ) AS Source
                        WHERE target.job = source.job And
                              target.processor = source.processor
                     );

--    GET DIAGNOSTICS _mergeDeleteCount = ROW_COUNT;
--
--    If _mergeCount > 0 Or _mergeDeleteCount > 0 Then
--        Set _message = format('Added/updated sw.t_local_job_processors; UpdateCount = %s; InsertCount = %s, DeleteCount = %s', _mergeUpdateCount, _mergeInsertCount, _mergeDeleteCount);
--        Call public.post_log_entry ('Normal', _message, 'Sync_Job_Info', 'sw');
--        Set _message = ''
--    End If;

    DROP TABLE Tmp_UpdateSummary;
END
$$;

COMMENT ON PROCEDURE sw.sync_job_info IS 'SyncJobInfo';
