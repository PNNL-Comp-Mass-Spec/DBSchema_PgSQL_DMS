--
-- Name: set_max_active_jobs_for_request(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_max_active_jobs_for_request(IN _requestid integer, IN _jobcount integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the value for max_active_jobs in t_analysis_job_request
**
**      When creating new analysis jobs for an analysis job request, call this procedure with _jobCount set to the number of jobs to be created
**
**      If this procedure is called for an analysis job request that has existing jobs and has max_active_jobs = 0,
**      this procedure will determine the number of jobs and update max_active_jobs if necessary
**      (either if there are too many jobs or if the settings file has a split FASTA search enabled)
**
**  Arguments:
**    _requestID            Analysis job request id
**    _jobCount             Number of jobs associated with the given analysis job request
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   10/29/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _maxInProgressJobs int := 175;
    _settingsFileName text;
    _maxActiveJobs int := 0;
    _splitFastaEnabled boolean := false;
    _numberOfClonedSteps int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _requestID           := Coalesce(_requestID, 0);
    _jobCount            := Coalesce(_jobCount, 0);
    _infoOnly            := Coalesce(_infoOnly, false);

    ------------------------------------------------
    -- Validate the request ID and determine the settings file name
    ------------------------------------------------

    SELECT settings_file_name, max_active_jobs
    INTO _settingsFileName, _maxActiveJobs
    FROM t_analysis_job_request
    WHERE request_id = _requestID;

    If Not FOUND Then
        _message    := format('Invalid job request ID: %s', _requestID);
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ------------------------------------------------
    -- If _jobCount is 0, lookup the current value for max_active_jobs
    ------------------------------------------------

    If _jobCount <= 0 Then
        If _maxActiveJobs > 0 Then
            _message    := format('Max_active_jobs is already set to %s for request ID %s; leaving unchanged', _maxActiveJobs, _requestID);
            _returnCode := 'U5202';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        -- Determine the number of jobs associated with the given analysis job request
        SELECT COUNT(*)
        INTO _jobCount
        FROM t_analysis_job
        WHERE request_id = _requestID;

        If Not FOUND Then
            _message    := format('There are no analysis jobs associated with request ID %s; cannot define max_active_jobs since the job count was not specified', _requestID);
            _returnCode := 'U5203';

            RAISE WARNING '%', _message;
            RETURN;
        End If;
    End If;

    -- Check whether the job request has a settings file with SplitFasta='True'

    SELECT split_fasta_enabled, number_of_cloned_steps, message
    INTO _splitFastaEnabled, _numberOfClonedSteps, _message
    FROM get_split_fasta_settings(_settingsFileName);

    If Not FOUND Then
        _message    := format('Function get_split_fasta_settings() did not return any rows for settings file %s for job request %s', _settingsFileName, _requestID);
        _returnCode := 'U5204';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _splitFastaEnabled Then
        If _numberOfClonedSteps < 1 Then
            _message    := format('Settings file %s for job request %s does not have a positive value defined for "NumberOfClonedSteps"', _settingsFileName, _requestID);
            _returnCode := 'U5205';

            RAISE WARNING '%', _message;
        End If;
    End If;

    If _splitFastaEnabled Then
        If _jobCount * _numberOfClonedSteps > _maxInProgressJobs Then
            _maxActiveJobs := Floor(_maxInProgressJobs / _numberOfClonedSteps::float);
        Else
            _maxActiveJobs := 0;
        End If;
    Else
        If _jobCount > _maxInProgressJobs Then
            _maxActiveJobs := _maxInProgressJobs;
        Else
            _maxActiveJobs := 0;
        End If;
    End If;

    If _maxActiveJobs = 0 Then
        _message := Format('%s max_active_jobs unchanged for analysis job request %s',
                           CASE WHEN _infoOnly THEN 'Would leave' ELSE 'Left' END,
                           _requestID);
    ElsIf _splitFastaEnabled Then
        _message := Format('%s max_active_jobs to %s for analysis job request %s since running a split FASTA search with %s cloned steps for each job',
                           CASE WHEN _infoOnly THEN 'Would set' ELSE 'Set' END,
                           _maxActiveJobs, _requestID, _numberOfClonedSteps);
    Else
        _message := Format('%s max_active_jobs to %s for analysis job request %s since the job count is over the max job count threshold',
                           CASE WHEN _infoOnly THEN 'Would set' ELSE 'Set' END,
                           _maxActiveJobs, _requestID);
    End If;

    If _infoOnly Then
        RAISE INFO '%', _message;
        RETURN;
    End If;

    If _maxActiveJobs > 0 Then
        UPDATE t_analysis_job_request
        SET max_active_jobs = _maxActiveJobs
        WHERE request_id = _requestID;

        RAISE INFO '%', _message;
    End If;
END
$$;


ALTER PROCEDURE public.set_max_active_jobs_for_request(IN _requestid integer, IN _jobcount integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_max_active_jobs_for_request(IN _requestid integer, IN _jobcount integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_max_active_jobs_for_request(IN _requestid integer, IN _jobcount integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SetMaxActiveJobsForRequest';

