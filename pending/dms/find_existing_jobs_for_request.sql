--
CREATE OR REPLACE FUNCTION public.find_existing_jobs_for_request
(
    _requestID int
)
RETURNS TABLE
(
    Job int,
    State citext,
    Priority int,
    Request int,
    Created timestamp,
    Start timestamp,
    Finish timestamp,
    Processor citext,
    Dataset citext
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Return a table of existing analysis jobs created from the specified analysis job request
**
**  Auth:   grk
**  Date:   12/05/2005 grk - Initial version
**          04/07/2006 grk - Eliminated job to request map table
**          09/10/2007 mem - Now returning columns Processor and Dataset
**          04/09/2008 mem - Now returning associated processor group, if applicable
**          09/03/2008 mem - Fixed bug that returned Entered_By from T_Analysis_Job_Processor_Group instead of from T_Analysis_Job_Processor_Group_Associations
**          05/28/2015 mem - Removed reference to T_Analysis_Job_Processor_Group
**          07/30/2019 mem - After obtaining the actual matching jobs using GetRunRequestExistingJobListTab, compare to the cached values in T_Analysis_Job_Request_Existing_Jobs; call UpdateCachedJobRequestExistingJobs if a mismatch
**          07/31/2019 mem - Use new function name, get_existing_jobs_matching_job_request
**          11/28/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _cachedCount int := 0;
    _misMatchCount int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

    CREATE TEMP TABLE Tmp_ExistingJobs (
        Job Int Not null
    );

    INSERT INTO Tmp_ExistingJobs( Job )
    SELECT Job
    FROM public.get_existing_jobs_matching_job_request ( _requestID );
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- See if t_analysis_job_request_existing_jobs needs to be updated
    SELECT COUNT(*)
    INTO _cachedCount
    FROM t_analysis_job_request_existing_jobs
    WHERE request_id = _requestID;

    If _cachedCount <> _myRowCount Then
        RAISE INFO '%', 'Calling UpdateCachedJobRequestExistingJobs due to differing count';
        Call update_cached_job_request_existing_jobs (_processingMode => 0, _requestID => _requestID, _infoOnly => false);
    Else
        SELECT COUNT(*)
        INTO _misMatchCount
        FROM Tmp_ExistingJobs J
             LEFT OUTER JOIN t_analysis_job_request_existing_jobs AJR
               ON AJR.job = J.job AND
                  AJR.request_id = _requestID
        WHERE AJR.job IS NULL;

        If _misMatchCount > 0 Then
            RAISE INFO '%', 'Calling UpdateCachedJobRequestExistingJobs due to differing jobs';
            Call update_cached_job_request_existing_jobs (_processingMode => 0, _requestID => _requestID, _infoOnly => false);
        End If;
    End If;

    RETURN QUERY
    SELECT AJ.job AS Job,
           ASN.job_state AS State,
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
         INNER JOIN t_analysis_job_state ASN
           ON AJ.job_state_id = ASN.job_state_id
         INNER JOIN t_dataset DS
           ON AJ.dataset_id = DS.dataset_id
    WHERE AJR.request_id = _requestID
    ORDER BY AJ.job DESC;

    DROP TABLE Tmp_ExistingJobs;
END
$$;

COMMENT ON PROCEDURE public.find_existing_jobs_for_request IS 'FindExistingJobsForRequest';
(
    _requestID int,
    INOUT _results refcursor DEFAULT '_results'::refcursor,
    INOUT _message text DEFAULT ''::text,
    INOUT _returnCode text DEFAULT ''::text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Return list of datasets for given job request
**      showing how many jobs exist for each that
**      match the parameters of the request
**      (regardless of whether or not job is linked to request)
**
**  Auth:   mem
**  Date:   12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _message := '';
    _returnCode := '';

    -- ToDo: Query function find_matching_datasets_for_job_request and return the results using a cursor

    Open _results For
        SELECT '' AS Sel,
               Dataset,
               Jobs,
               New,
               Busy,
               Complete,
               Failed,
               Holding
        FROM find_matching_datasets_for_job_request(_requestID);

END
$$;
