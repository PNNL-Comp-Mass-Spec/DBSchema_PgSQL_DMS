--
CREATE OR REPLACE PROCEDURE public.update_cached_job_request_existing_jobs
(
    _processingMode int = 0,
    _requestID int = 0,
    _jobSearchHours int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates T_Analysis_Job_Request_Existing_Jobs
**
**  Arguments:
**    _processingMode   0 to only add new job requests, 1 to add new job requests and update existing information; ignored if _requestID or _jobSearchHours is non-zero
**    _requestID        When non-zero, a single request ID to add / update
**    _jobSearchHours   When non-zero, compare jobs created within this many hours to existing job requests
**
**  Auth:   mem
**  Date:   07/30/2019 mem - Initial version
**          07/31/2019 mem - Add option to find existing job requests that match jobs created within the last _jobSearchHours
**          06/25/2021 mem - Fix bug comparing legacy organism DB name in T_Analysis_Job to T_Analysis_Job_Request_Datasets
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _currentRequestId int := 0;
    _jobRequestsAdded int := 0;
    _jobRequestsUpdated int := 0;
    _addon text;
BEGIN
    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    _processingMode := Coalesce(_processingMode, 0);
    _requestID := Coalesce(_requestID, 0);
    _jobSearchHours := Coalesce(_jobSearchHours, 0);
    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode:= '';

    If _requestID = 1 Then
        Select '_requestID 1 is a special placeholder request; table t_analysis_job_request_existing_jobs does not track jobs for _requestID 1' As Warning
        RETURN;
    End If;

    If _requestID > 0 Then

        If _infoOnly Then

            -- ToDo: Show this data using RAISE INFO

            SELECT DISTINCT AJR.AJR_requestID AS Request_ID,
                   CASE
                       WHEN CachedJobs.request_id IS NULL
                       THEN 'Analysis job request to add to t_analysis_job_request_existing_jobs'
                       ELSE 'Existing Analysis job request to validate against t_analysis_job_request_existing_jobs'
                   END AS Status
            FROM t_analysis_job_request AJR
                 LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                   ON AJR.request_id = CachedJobs.request_id
            WHERE AJR.request_id = _requestID
            ORDER BY AJR.request_id
        Else
            MERGE INTO t_analysis_job_request_existing_jobs AS target
            USING ( SELECT DISTINCT _requestID As Request_ID, Job
                    FROM get_existing_jobs_matching_job_request(_requestID)
                  ) AS source
            ON (target.request_id = source.request_id AND target.job = source.job)
            -- Note: all of the columns in table t_analysis_job_request_existing_jobs are primary keys or identity columns; there are no updatable columns
            WHEN NOT MATCHED THEN
                INSERT (Request_ID, Job)
                VALUES (source.Request_ID, source.Job);

            -- Delete rows in t_analysis_job_request_existing_jobs that have Request_ID = _requestID
            -- but are not in the job list returned by get_existing_jobs_matching_job_request()

            DELETE FROM t_analysis_job_request_existing_jobs target
            WHERE target.Request_ID = _requestID AND
                  NOT EXISTS (SELECT source.Job
                              FROM (SELECT DISTINCT Job
                                    FROM get_existing_jobs_matching_job_request(_requestID)
                                   ) AS source
                              WHERE target.job = source.job);

        End If;

        RETURN;
    End If;

    If _jobSearchHours > 0 Then

        ------------------------------------------------
        -- Find jobs created in the last _jobSearchHours that match one or more job requests
        ------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_RequestsAndExistingJobs (
            Request_ID int NOT NULL,
            Job        int NOT NULL
        )

        CREATE INDEX IX_TmpRequestsAndExistingJobs ON Tmp_RequestsAndExistingJobs ( Request_ID, Job );

        INSERT INTO Tmp_RequestsAndExistingJobs( request_id, job )
        SELECT AJR.request_id,
               AJ.job
        FROM t_analysis_job AJ
             INNER JOIN t_analysis_tool AJT
               ON AJ.analysis_tool_id = AJT.analysis_tool_id
             INNER JOIN t_analysis_job_request AJR
               ON AJT.analysis_tool = AJR.analysis_tool AND
                  AJ.param_file_name = AJR.param_file_name AND
                  AJ.settings_file_name = AJR.settings_file_name AND
                  Coalesce(AJ.special_processing, '') = Coalesce(AJR.special_processing, '')
             INNER JOIN t_analysis_job_request_datasets AJRD
               ON AJR.request_id = AJRD.request_id AND
                  AJRD.dataset_id = AJ.dataset_id
        WHERE AJR.request_id > 1 AND
              AJ.created >= CURRENT_TIMESTAMP - make_interval(hours => _jobSearchHours) AND
              (AJT.result_type NOT LIKE '%Peptide_Hit%' OR
               AJT.result_type LIKE '%Peptide_Hit%' AND
               ((AJ.protein_collection_list <> 'na' AND
                 AJ.protein_collection_list = AJR.protein_collection_list AND
                 AJ.protein_options_list = AJR.protein_options_list
                ) OR
                (AJ.protein_collection_list = 'na' AND
                 AJ.protein_collection_list = AJR.protein_collection_list AND
                 AJ.organism_db_name = AJR.organism_db_name AND
                 AJ.organism_id = AJR.organism_id
                )
               )
              )
        GROUP BY AJR.request_id, AJ.job
        ORDER BY AJR.request_id, AJ.job

        If _infoOnly Then
            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------
            --

            -- ToDo: Show this data using RAISE INFO

            SELECT DISTINCT RJ.request_id AS Request_ID,
                   CASE
                       WHEN CachedJobs.request_id IS NULL
                       THEN 'Analysis job request to add to t_analysis_job_request_existing_jobs'
                       ELSE 'Existing Analysis job request to validate against t_analysis_job_request_existing_jobs'
                   END AS Status
            FROM Tmp_RequestsAndExistingJobs RJ
                 LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                   ON RJ.request_id = CachedJobs.request_id
            ORDER BY RJ.request_id;

        Else
        -- <b>

            ------------------------------------------------
            -- Count the new number of job requests that are not yet in Tmp_RequestsAndExistingJobs
            ------------------------------------------------
            --
            SELECT COUNT(DISTINCT Src.request_id) INTO _jobRequestsAdded
            FROM Tmp_RequestsAndExistingJobs Src
                 LEFT OUTER JOIN t_analysis_job_request_existing_jobs AJRJ
                   ON Src.request_id = AJRJ.request_id
            WHERE AJRJ.request_id IS NULL;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            ------------------------------------------------
            -- Use a merge statement to add/remove rows from t_analysis_job_request_existing_jobs
            --
            -- We must process each request_id separately so that we can
            -- delete extra rows in t_analysis_job_request_existing_jobs for each request_id
            ------------------------------------------------
            --

            FOR _currentRequestId IN
                SELECT Request_ID
                FROM Tmp_RequestsAndExistingJobs
                ORDER BY Request_ID
            LOOP

                MERGE INTO t_analysis_job_request_existing_jobs AS target
                USING ( SELECT DISTINCT _currentRequestId As Request_ID, Job
                        FROM get_existing_jobs_matching_job_request(_currentRequestId)
                      ) AS source
                ON (target.request_id = source.request_id AND target.job = source.job)
                WHEN NOT MATCHED THEN
                    INSERT (request_id, job)
                    VALUES (source.request_id, source.job);

                If FOUND Then
                    _jobRequestsUpdated := _jobRequestsUpdated + 1;
                End If;

                -- Delete rows in t_analysis_job_request_existing_jobs that have Request_ID = _currentRequestId
                -- but are not in the job list returned by get_existing_jobs_matching_job_request()

                DELETE FROM t_analysis_job_request_existing_jobs target
                WHERE target.Request_ID = _currentRequestId AND
                      NOT EXISTS (SELECT source.Job
                                  FROM (SELECT DISTINCT Job
                                        FROM get_existing_jobs_matching_job_request(_currentRequestId)
                                       ) AS source
                                  WHERE target.job = source.job);

            END LOOP; -- </c>

            If _jobRequestsAdded > 0 Then
                _message := format('%s %s', _jobRequestsAdded, public.check_plural(_jobRequestsAdded, 'job request was added', 'job requests were added'));
            End If;

            If _jobRequestsUpdated > 0 Then
                _addon := format('%s %s via a merge', _jobRequestsUpdated, public.check_plural(_jobRequestsUpdated, 'job request was updated', 'job requests were updated'));
                _message := public.append_to_text(_message, _addon, 0, '; ', 512)
            End If;
        End If; -- </b>

        RETURN;
    End If;

    If _processingMode = 0 Then

        ------------------------------------------------
        -- Add new analysis job requests to t_analysis_job_request_existing_jobs
        ------------------------------------------------
        --
        If _infoOnly Then
            ------------------------------------------------
            -- Preview the addition of new analysis job requests
            ------------------------------------------------

            SELECT AJR.request_id AS Request_ID,
                   'Analysis job request to add to t_analysis_job_request_existing_jobs' AS Status
            FROM t_analysis_job_request AJR
                 LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                   ON AJR.request_id = CachedJobs.request_id
            WHERE AJR.request_id > 1 AND
                  CachedJobs.request_id IS NULL
            ORDER BY AJR.request_id
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                Select 'No analysis job requests need to be added to t_analysis_job_request_existing_jobs' As Status
            End If;
        Else
            ------------------------------------------------
            -- Add missing analysis job requests
            --
            -- There are a large number of existing job requests that were never used to create jobs
            -- Therefore, this query only examines job requests from the last 30 days
            ------------------------------------------------
            --
            INSERT INTO t_analysis_job_request_existing_jobs( request_id, job )
            SELECT DISTINCT LookupQ.request_id,
                            get_existing_jobs_matching_job_request.job
            FROM ( SELECT AJR.request_id AS Request_ID
                   FROM t_analysis_job_request AJR
                        LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                          ON AJR.request_id = CachedJobs.request_id
                   WHERE AJR.request_id > 1 AND
                         AJR.created > CURRENT_TIMESTAMP - INTERVAL '30 days' AND
                         CachedJobs.request_id IS NULL
                 ) LookupQ
                 CROSS APPLY get_existing_jobs_matching_job_request ( LookupQ.request_id )
            ORDER BY LookupQ.request_id, job
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount > 0 Then
                _message := format('Added %s new analysis job %s', _myRowCount, public.check_plural(_myRowCount, 'request', 'requests'));
            End If;
        End If;

    Else

        ------------------------------------------------
        -- Update t_analysis_job_request_existing_jobs using all existing analysis job requests
        ------------------------------------------------
        --
        If _infoOnly Then
            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------
            --
            SELECT DISTINCT AJR.AJR_requestID AS Request_ID,
              CASE
                  WHEN CachedJobs.request_id IS NULL
                  THEN 'Analysis job request to add to t_analysis_job_request_existing_jobs'
                  ELSE 'Existing Analysis job request to validate against t_analysis_job_request_existing_jobs'
              END AS Status
            FROM t_analysis_job_request AJR
                 LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                   ON AJR.request_id = CachedJobs.request_id
            ORDER BY AJR.request_id
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                Select 'No data in t_analysis_job_request_existing_jobs needs to be updated' As Status;
            End If;

        Else
            ------------------------------------------------
            -- Update cached info for all job requests
            -- This will take at least 30 seconds to complete
            ------------------------------------------------
            --
            MERGE INTO t_analysis_job_request_existing_jobs AS target
            USING ( SELECT DISTINCT AJR.request_id As Request_ID, MatchingJobs.Job
                    FROM t_analysis_job_request AJR CROSS APPLY get_existing_jobs_matching_job_request(AJR.request_id) MatchingJobs
                    WHERE AJR.request_id > 1
                  ) AS source
            ON (target.request_id = source.request_id AND target.job = source.job)
            WHEN NOT MATCHED THEN
                INSERT (request_id, job)
                VALUES (source.request_id, source.job);
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount > 0 Then
                _message := format('%s %s via a merge', _myRowCount, public.check_plural(_myRowCount, 'job request was updated', 'job requests were updated'));
            End If;

            -- Delete rows in t_analysis_job_request_existing_jobs that are not in
            -- the job list returned by get_existing_jobs_matching_job_request()

            DELETE FROM t_analysis_job_request_existing_jobs target
            WHERE NOT EXISTS (SELECT source.Job
                              FROM ( SELECT DISTINCT AJR.request_id As Request_ID, MatchingJobs.Job
                                     FROM t_analysis_job_request AJR CROSS APPLY get_existing_jobs_matching_job_request(AJR.request_id) MatchingJobs
                                     WHERE AJR.request_id > 1
                                   ) AS source
                              WHERE target.request_id = source.request_id AND target.job = source.job);

        End If;

    End If;

    -- call PostLogEntry ('Debug', _message, 'UpdateCachedJobRequestExistingJobs');

    DROP TABLE Tmp_RequestsAndExistingJobs;
END
$$;

COMMENT ON PROCEDURE public.update_cached_job_request_existing_jobs IS 'UpdateCachedJobRequestExistingJobs';
