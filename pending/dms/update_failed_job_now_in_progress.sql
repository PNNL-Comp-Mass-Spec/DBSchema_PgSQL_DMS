--
CREATE OR REPLACE PROCEDURE public.update_failed_job_now_in_progress
(
    _job int,
    _newBrokerJobState int,
    _jobStart timestamp,
    _updateCode int,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates job state to 2 for an analysis job that is now in-progress in sw.t_jobs database
**
**      Typically used to update jobs listed as Failed in public.t_analysis_job,
**      but occasionally updates jobs listed as New
**
**  Arguments:
**    _updateCode   Safety feature to prevent unauthorized job updates
**
**  Auth:   mem
**  Date:   02/21/2013 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetName text;
    _updateCodeExpected int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _datasetName := '';

       ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _job Is Null Then
        _message := 'Invalid job';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -- Confirm that _updateCode is valid for this job
    If _job % 2 = 0 Then
        _updateCodeExpected := (_job % 220) + 14;
    Else
        _updateCodeExpected := (_job % 125) + 11;
    End If;

    If Coalesce(_updateCode, 0) <> _updateCodeExpected Then
        _message := 'Invalid Update Code';
        _returnCode := 'U5202'
        RETURN;
    End If;

    If _infoOnly Then
        -- Display the old and new values

        -- ToDo: Show this data using RAISE INFO

        SELECT job,
               job_state_id,
               2 AS job_state_id_New,
               AJ_Start,
               CASE
                   WHEN _newBrokerJobState >= 2 THEN Coalesce(_jobStart, CURRENT_TIMESTAMP)
                   ELSE AJ_start
               END AS AJ_Start_New
        FROM t_analysis_job
        WHERE job = _job

    Else

        -- Perform the update
        UPDATE t_analysis_job
        SET job_state_id = 2,
            start = CASE WHEN _newBrokerJobState >= 2
                            THEN Coalesce(_jobStart, CURRENT_TIMESTAMP)
                            ELSE AJ_start
                       END,
            AJ_AssignedProcessorName = 'Job_Broker'
        WHERE job = _job;

    End If;

END
$$;

COMMENT ON PROCEDURE public.update_failed_job_now_in_progress IS 'UpdateFailedJobNowInProgress';
