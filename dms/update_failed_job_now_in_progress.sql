--
-- Name: update_failed_job_now_in_progress(integer, integer, timestamp without time zone, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_failed_job_now_in_progress(IN _job integer, IN _newbrokerjobstate integer, IN _jobstart timestamp without time zone, IN _updatecode integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update job state to 2 for an analysis job that is now in-progress in sw.t_jobs
**
**      Typically used to update jobs listed as Failed in public.t_analysis_job, but occasionally used to update jobs listed as New
**
**  Arguments:
**    _job                  Job number
**    _newBrokerJobState    New state of the job in sw.t_jobs
**    _jobStart             Job start time
**    _updateCode           Safety feature to prevent unauthorized job updates
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   02/21/2013 mem - Initial version
**          08/03/2023 mem - Ported to PostgreSQL
**          11/20/2023 mem - Add missing semicolon before Return statement
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
        _returnCode := 'U5202';
        RETURN;
    End If;

    If _infoOnly Then

        -- Display the old and new values

        RAISE INFO '';

        _formatSpecifier := '%-9s %-12s %-16s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Job_State_ID',
                            'Job_State_ID_New',
                            'Start',
                            'Start_New'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '------------',
                                     '----------------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job,
                   Job_State_ID,
                   2 AS Job_State_ID_New,
                   public.timestamp_text(Start) AS Start,
                   CASE WHEN _newBrokerJobState >= 2
                        THEN public.timestamp_text(Coalesce(_jobStart, CURRENT_TIMESTAMP))
                        ELSE public.timestamp_text(start)
                   END AS Start_New
            FROM t_analysis_job
            WHERE job = _job
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


ALTER PROCEDURE public.update_failed_job_now_in_progress(IN _job integer, IN _newbrokerjobstate integer, IN _jobstart timestamp without time zone, IN _updatecode integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_failed_job_now_in_progress(IN _job integer, IN _newbrokerjobstate integer, IN _jobstart timestamp without time zone, IN _updatecode integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_failed_job_now_in_progress(IN _job integer, IN _newbrokerjobstate integer, IN _jobstart timestamp without time zone, IN _updatecode integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateFailedJobNowInProgress';

