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
**    _job                  Job number
**    _newBrokerJobState    New state of the job in sw.t_jobs
**    _jobStart             Job start time
**    _updateCode           Safety feature to prevent unauthorized job updates
**    _infoOnly             When true, preview updates
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

        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---',
                                     '---',
                                     '---',
                                     '---',
                                     '---'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN

            SELECT Job,
                   Job_State_ID,
                   2 AS Job_State_ID_New,
                   Start,
                   CASE WHEN _newBrokerJobState >= 2
                        THEN Coalesce(_jobStart, CURRENT_TIMESTAMP)
                        ELSE start
                   END AS Start_New
            FROM t_analysis_job
            WHERE job = _job;
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Job_State_ID,
                                _previewData.Job_State_ID_New,
                                _previewData.Start,
                                _previewData.Start_New
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;

    End If;

    -- Perform the update
    UPDATE t_analysis_job
    SET job_state_id = 2,
        start = CASE WHEN _newBrokerJobState >= 2
                     THEN Coalesce(_jobStart, CURRENT_TIMESTAMP)
                     ELSE start
                END,
        assigned_processor_name = 'Job_Broker'
    WHERE job = _job;

END
$$;

COMMENT ON PROCEDURE public.update_failed_job_now_in_progress IS 'UpdateFailedJobNowInProgress';
