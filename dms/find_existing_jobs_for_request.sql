--
-- Name: find_existing_jobs_for_request(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.find_existing_jobs_for_request(_requestid integer) RETURNS TABLE(job integer, state public.citext, priority integer, request integer, created timestamp without time zone, start timestamp without time zone, finish timestamp without time zone, processor public.citext, dataset public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table of existing analysis jobs created from the given analysis job request
**
**  Arguments:
**    _requestID    Analysis job request ID
**
**  Auth:   grk
**  Date:   12/05/2005 grk - Initial version
**          04/07/2006 grk - Eliminated job to request map table
**          09/10/2007 mem - Now returning columns Processor and Dataset
**          04/09/2008 mem - Now returning associated processor group, if applicable
**          09/03/2008 mem - Fixed bug that returned Entered_By from T_Analysis_Job_Processor_Group instead of from T_Analysis_Job_Processor_Group_Associations
**          05/28/2015 mem - Removed reference to T_Analysis_Job_Processor_Group
**          07/30/2019 mem - After obtaining the actual matching jobs using GetRunRequestExistingJobListTab, compare to the cached values in T_Analysis_Job_Request_Existing_Jobs; call Update_Cached_Job_Request_Existing_Jobs if a mismatch
**          07/31/2019 mem - Use new function name, get_existing_jobs_matching_job_request
**          12/03/2023 mem - Ported to Postgres
**
*****************************************************/
DECLARE
    _existingCount int := 0;
    _cachedCount int := 0;
    _misMatchCount int := 0;
BEGIN

    CREATE TEMP TABLE Tmp_ExistingJobs (
        Job Int Not null
    );

    INSERT INTO Tmp_ExistingJobs( Job )
    SELECT Src.job
    FROM public.get_existing_jobs_matching_job_request(_requestID) Src;
    --
    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    -- See if t_analysis_job_request_existing_jobs needs to be updated

    SELECT COUNT(ExistingJobs.job)
    INTO _cachedCount
    FROM t_analysis_job_request_existing_jobs ExistingJobs
    WHERE ExistingJobs.request_id = _requestID;

    If _cachedCount <> _existingCount Then
        RAISE INFO '%', 'Calling update_cached_job_request_existing_jobs due to differing count';

        CALL public.update_cached_job_request_existing_jobs (
                        _processingMode => 0,
                        _requestID      => _requestID,
                        _infoOnly       => false,
                        _message        => _message,
                        _returnCode     => _returnCode);
    Else
        SELECT COUNT(J.job)
        INTO _misMatchCount
        FROM Tmp_ExistingJobs J
             LEFT OUTER JOIN t_analysis_job_request_existing_jobs AJR
               ON AJR.job = J.job AND
                  AJR.request_id = _requestID
        WHERE AJR.job IS NULL;

        If _misMatchCount > 0 Then
            RAISE INFO '%', 'Calling update_cached_job_request_existing_jobs due to differing jobs';

            CALL public.update_cached_job_request_existing_jobs (
                            _processingMode => 0,
                            _requestID      => _requestID,
                            _infoOnly       => false,
                            _message        => _message,
                            _returnCode     => _returnCode);
        End If;
    End If;

    RETURN QUERY
    SELECT AJ.job AS Job,
           AJS.job_state AS State,
           AJ.priority AS Priority,
           AJ.request_id AS Request,
           AJ.created AS Created,
           AJ.start AS Start,
           AJ.finish AS Finish,
           AJ.assigned_processor_name AS Processor,
           DS.dataset AS Dataset
    FROM t_analysis_job_request_existing_jobs AJR
         INNER JOIN t_analysis_job AJ
           ON AJR.job = AJ.job
         INNER JOIN t_analysis_job_state AJS
           ON AJ.job_state_id = AJS.job_state_id
         INNER JOIN t_dataset DS
           ON AJ.dataset_id = DS.dataset_id
    WHERE AJR.request_id = _requestID
    ORDER BY AJ.job DESC;

    DROP TABLE Tmp_ExistingJobs;
END
$$;


ALTER FUNCTION public.find_existing_jobs_for_request(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION find_existing_jobs_for_request(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.find_existing_jobs_for_request(_requestid integer) IS 'FindExistingJobsForRequest';

