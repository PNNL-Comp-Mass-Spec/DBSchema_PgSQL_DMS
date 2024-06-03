--
-- Name: update_cached_job_request_existing_jobs(integer, integer, integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_job_request_existing_jobs(IN _processingmode integer DEFAULT 0, IN _requestid integer DEFAULT 0, IN _jobsearchhours integer DEFAULT 0, IN _modezerosearchdays integer DEFAULT 30, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_analysis_job_request_existing_jobs
**
**  Arguments:
**    _processingMode       0 to only add new job requests created within the last 30 days (customizable using _modeZeroSearchDays)
**                          1 to add new job requests and update existing information
**                          Ignored if _requestID is non-zero or _jobSearchHours is non-zero
**    _requestID            When > 0, a single analysis job request to add / update
**    _jobSearchHours       When > 0, compare jobs created within this many hours to existing job requests (ignored if _requestID is non-zero)
**    _modeZeroSearchDays   Number of days to search when _processingMode is 0 (and _requestID and _jobSearchHours are each zero)
**    _infoOnly             When true, preview changes
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   07/30/2019 mem - Initial version
**          07/31/2019 mem - Add option to find existing job requests that match jobs created within the last _jobSearchHours
**          06/25/2021 mem - Fix bug comparing legacy organism DB name in T_Analysis_Job to T_Analysis_Job_Request_Datasets
**          09/07/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Include schema name when calling function verify_sp_authorized()
**          09/13/2023 mem - Remove unnecessary delimiter argument when calling append_to_text()
**
*****************************************************/
DECLARE
    _matchCount int;
    _currentRequestId int := 0;
    _jobRequestsAdded int := 0;
    _insertCount int;
    _insertCountOverall int;
    _addon text;

    _requestIdMax int;
    _requestIdStart int;
    _requestIdEnd int;
    _batchSize int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _formatSpecifierLoop text;
    _infoHeadLoop text;
    _infoHeadSeparatorLoop text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _processingMode     := Coalesce(_processingMode, 0);
    _requestID          := Coalesce(_requestID, 0);
    _jobSearchHours     := Coalesce(_jobSearchHours, 0);
    _modeZeroSearchDays := Coalesce(_modeZeroSearchDays, 30);
    _infoOnly           := Coalesce(_infoOnly, false);

    If _modeZeroSearchDays < 2 Then
        _modeZeroSearchDays := 2;
    End If;

    If _requestID = 1 Then
        RAISE WARNING '_requestID 1 is a special placeholder request; table t_analysis_job_request_existing_jobs does not track jobs for _requestID 1';
        RETURN;
    End If;

    _formatSpecifier := '%-10s %-90s';

    _infoHead := format(_formatSpecifier,
                        'Request_ID',
                        'Status'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '----------',
                                 '------------------------------------------------------------------------------------------'
                                );

    If _requestID > 0 Then

        If _infoOnly Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DISTINCT AJR.Request_ID,
                       CASE WHEN CachedJobs.request_id IS NULL
                            THEN 'Analysis job request to add to t_analysis_job_request_existing_jobs'
                            ELSE 'Existing Analysis job request to validate against t_analysis_job_request_existing_jobs'
                       END AS Status
                FROM t_analysis_job_request AJR
                     LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                       ON AJR.request_id = CachedJobs.request_id
                WHERE AJR.request_id = _requestID
                ORDER BY AJR.request_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Request_ID,
                                    _previewData.Status
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            RETURN;
        End If;

        MERGE INTO t_analysis_job_request_existing_jobs AS target
        USING (SELECT DISTINCT _requestID AS Request_ID, Job
               FROM public.get_existing_jobs_matching_job_request(_requestID)
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
                                FROM public.get_existing_jobs_matching_job_request(_requestID)
                               ) AS source
                          WHERE target.job = source.job);

        RETURN;
    End If;

    If _jobSearchHours > 0 Then

        ------------------------------------------------
        -- Find jobs created in the last _jobSearchHours that match one or more job requests
        ------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestsAndExistingJobs (
            Request_ID int NOT NULL,
            Job        int NOT NULL
        );

        CREATE INDEX IX_TmpRequestsAndExistingJobs ON Tmp_RequestsAndExistingJobs ( Request_ID, Job );

        INSERT INTO Tmp_RequestsAndExistingJobs (request_id, job)
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
        ORDER BY AJR.request_id, AJ.job;

        If _infoOnly Then

            ------------------------------------------------
            -- Preview updating cached info
            ------------------------------------------------

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DISTINCT RJ.Request_ID,
                       CASE WHEN CachedJobs.request_id IS NULL
                            THEN 'Analysis job request to add to t_analysis_job_request_existing_jobs'
                            ELSE 'Existing Analysis job request to validate against t_analysis_job_request_existing_jobs'
                       END AS Status
                FROM Tmp_RequestsAndExistingJobs RJ
                     LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                       ON RJ.request_id = CachedJobs.request_id
                ORDER BY RJ.request_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Request_ID,
                                    _previewData.Status
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_RequestsAndExistingJobs;
            RETURN;
        End If;

        ------------------------------------------------
        -- Count the new number of job requests that are not yet in Tmp_RequestsAndExistingJobs
        ------------------------------------------------

        SELECT COUNT(DISTINCT Src.request_id)
        INTO _jobRequestsAdded
        FROM Tmp_RequestsAndExistingJobs Src
             LEFT OUTER JOIN t_analysis_job_request_existing_jobs AJRJ
               ON Src.request_id = AJRJ.request_id
        WHERE AJRJ.request_id IS NULL;

        ------------------------------------------------
        -- Use a merge statement to add/remove rows from t_analysis_job_request_existing_jobs
        --
        -- We must process each request_id separately so that we can
        -- delete extra rows in t_analysis_job_request_existing_jobs for each request_id
        ------------------------------------------------

        _insertCountOverall := 0;

        FOR _currentRequestId IN
            SELECT Request_ID
            FROM Tmp_RequestsAndExistingJobs
            ORDER BY Request_ID
        LOOP

            MERGE INTO t_analysis_job_request_existing_jobs AS target
            USING (SELECT DISTINCT _currentRequestId AS Request_ID, Job
                   FROM public.get_existing_jobs_matching_job_request(_currentRequestId)
                  ) AS source
            ON (target.request_id = source.request_id AND target.job = source.job)
            WHEN NOT MATCHED THEN
                INSERT (request_id, job)
                VALUES (source.request_id, source.job);
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            _insertCountOverall := _insertCountOverall + _insertCount;

            -- Delete rows in t_analysis_job_request_existing_jobs that have Request_ID = _currentRequestId
            -- but are not in the job list returned by get_existing_jobs_matching_job_request()

            DELETE FROM t_analysis_job_request_existing_jobs target
            WHERE target.Request_ID = _currentRequestId AND
                  NOT EXISTS (SELECT source.Job
                              FROM (SELECT DISTINCT Job
                                    FROM public.get_existing_jobs_matching_job_request(_currentRequestId)
                                   ) AS source
                              WHERE target.job = source.job);

        END LOOP;

        If _jobRequestsAdded > 0 Then
            _message := format('%s %s to t_analysis_job_request_existing_jobs', _jobRequestsAdded, public.check_plural(_jobRequestsAdded, 'job request was added', 'job requests were added'));
        End If;

        If _insertCountOverall > 0 Then
            _addon := format('%s %s to t_analysis_job_request_existing_jobs', _insertCountOverall, public.check_plural(_insertCountOverall, 'row was added', 'rows were added'));
            _message := public.append_to_text(_message, _addon);
        End If;

        DROP TABLE Tmp_RequestsAndExistingJobs;
        RETURN;
    End If;

    If _processingMode = 0 Then

        ------------------------------------------------
        -- Add new analysis job requests to t_analysis_job_request_existing_jobs
        ------------------------------------------------

        If _infoOnly Then

            ------------------------------------------------
            -- Preview the addition of new analysis job requests
            --
            -- There are a large number of existing job requests that were never used to create jobs
            -- Therefore, this query only examines job requests from the last _modeZeroSearchDays days
            ------------------------------------------------

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            _matchCount := 0;

            FOR _previewData IN
                SELECT AJR.request_id AS Request_ID,
                       'Analysis job request to add to t_analysis_job_request_existing_jobs' AS Status
                FROM t_analysis_job_request AJR
                     LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                       ON AJR.request_id = CachedJobs.request_id
                WHERE AJR.request_id > 1 AND
                      AJR.created > CURRENT_TIMESTAMP - make_interval(days => _modeZeroSearchDays) AND
                      CachedJobs.request_id IS NULL
                ORDER BY AJR.request_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Request_ID,
                                    _previewData.Status
                                   );

                RAISE INFO '%', _infoData;
                _matchCount := _matchCount + 1;
            END LOOP;

            If _matchCount = 0 Then
                RAISE INFO 'No analysis job requests need to be added to t_analysis_job_request_existing_jobs';
            End If;

            RETURN;
        End If;

        ------------------------------------------------
        -- Add missing analysis job requests
        --
        -- There are a large number of existing job requests that were never used to create jobs
        -- Therefore, this query only examines job requests from the last _modeZeroSearchDays days
        ------------------------------------------------

        INSERT INTO t_analysis_job_request_existing_jobs (request_id, job)
        SELECT DISTINCT LookupQ.request_id,
                        RequestJobs.job
        FROM (SELECT AJR.request_id AS Request_ID
              FROM t_analysis_job_request AJR
                   LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                     ON AJR.request_id = CachedJobs.request_id
              WHERE AJR.request_id > 1 AND
                    AJR.created > CURRENT_TIMESTAMP - make_interval(days => _modeZeroSearchDays) AND
                    CachedJobs.request_id IS NULL
             ) LookupQ
             JOIN LATERAL (
                SELECT job
                FROM public.get_existing_jobs_matching_job_request(LookupQ.Request_ID)
               ) AS RequestJobs On true
        ORDER BY LookupQ.request_id, RequestJobs.job;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _matchCount > 0 Then
            _message := format('Added %s new analysis job %s', _matchCount, public.check_plural(_matchCount, 'request', 'requests'));
        End If;

        RETURN;
    End If;

    ------------------------------------------------
    -- Update t_analysis_job_request_existing_jobs using all existing analysis job requests (_processingMode is 1)
    -- The queries are run in batches of 500 job requests at a time, since processing the entire table at once takes too long
    ------------------------------------------------

    _batchSize := 500;

    RAISE INFO '';
    RAISE INFO '% new rows to t_analysis_job_request_existing_jobs, processing % job requests at a time',
                    CASE WHEN _infoOnly
                         THEN 'Preview adding'
                         ELSE 'Adding'
                    END,
                    _batchSize;
    RAISE INFO '';

    If _infoOnly Then

        ------------------------------------------------
        -- Preview each range of request IDs to process
        ------------------------------------------------

        _formatSpecifierLoop := '%-16s %-15s %-15s %-15s';

        _infoHeadLoop := format(_formatSpecifierLoop,
                            'Request_ID_Start',
                            'Request_ID_End',
                            'Request_Count',
                            'New_Jobs_to_Add'
                           );

        _infoHeadSeparatorLoop := format(_formatSpecifierLoop,
                                     '----------------',
                                     '---------------',
                                     '---------------',
                                     '---------------'
                                    );

        RAISE INFO '%', _infoHeadLoop;
        RAISE INFO '%', _infoHeadSeparatorLoop;

    End If;

    SELECT MAX(request_id)
    INTO _requestIdMax
    FROM t_analysis_job_request;

    _requestIdMax := Coalesce(_requestIdMax, 2);
    _requestIdStart := 2;
    _insertCountOverall := 0;

    WHILE true
    LOOP
        If _requestIdStart < _batchSize Then
            _requestIdEnd := _batchSize - 1;
        Else
            _requestIdEnd := _requestIdStart + _batchSize - 1;
        End If;

        If _infoOnly Then

            SELECT COUNT(DISTINCT AJR.request_id) AS Request_Count,
                   SUM(CASE WHEN CachedJobs.request_id IS NULL THEN 1 ELSE 0 END) AS New_Jobs_to_Add
            INTO _previewData
            FROM t_analysis_job_request AJR
                 LEFT OUTER JOIN t_analysis_job_request_existing_jobs CachedJobs
                   ON AJR.request_id = CachedJobs.request_id
            WHERE AJR.request_id BETWEEN _requestIdStart AND _requestIdEnd;

            _infoData := format(_formatSpecifierLoop,
                                _requestIdStart,
                                _requestIdEnd,
                                _previewData.Request_Count,
                                _previewData.New_Jobs_to_Add
                               );

            RAISE INFO '%', _infoData;

        Else

            RAISE INFO 'Processing job requests % to %', _requestIdStart, _requestIdEnd;

            -- Add new rows to t_analysis_job_request_existing_jobs

            MERGE INTO t_analysis_job_request_existing_jobs AS target
            USING (SELECT DISTINCT AJR.request_id AS Request_ID, MatchingJobs.Job
                   FROM t_analysis_job_request AJR
                        JOIN LATERAL (
                           SELECT job
                           FROM public.get_existing_jobs_matching_job_request(AJR.Request_ID)
                          ) AS MatchingJobs On true
                   WHERE AJR.request_id BETWEEN _requestIdStart AND _requestIdEnd
                  ) AS source
            ON (target.request_id = source.request_id AND target.job = source.job)
            WHEN NOT MATCHED THEN
                INSERT (request_id, job)
                VALUES (source.request_id, source.job);
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            _insertCountOverall := _insertCountOverall + _insertCount;

            -- Delete rows in t_analysis_job_request_existing_jobs that are not in
            -- the job list returned by get_existing_jobs_matching_job_request()

            DELETE FROM t_analysis_job_request_existing_jobs target
            WHERE target.request_id BETWEEN _requestIdStart AND _requestIdEnd
                  AND NOT EXISTS (SELECT source.Job
                                  FROM (SELECT DISTINCT AJR.request_id AS Request_ID, MatchingJobs.Job
                                        FROM t_analysis_job_request AJR
                                             JOIN LATERAL (
                                                SELECT job
                                                FROM public.get_existing_jobs_matching_job_request(AJR.Request_ID)
                                               ) AS MatchingJobs On true
                                        WHERE AJR.request_id BETWEEN _requestIdStart AND _requestIdEnd
                                       ) AS source
                                  WHERE target.request_id = source.request_id AND target.job = source.job);
        End If;

        If _requestIdStart < _batchSize Then
            _requestIdStart := _batchSize;
        Else
            _requestIdStart := _requestIdStart + _batchSize;
        End If;

        COMMIT;

        If _requestIdStart > _requestIdMax Then
            -- Break out of the while loop
            EXIT;
        End If;
    END LOOP;

    If _infoOnly Then
        RETURN;
    End If;

    If _insertCountOverall > 0 Then
        _message := format('Processing complete: %s %s to t_analysis_job_request_existing_jobs', _insertCountOverall, public.check_plural(_insertCountOverall, 'row was added', 'rows were added'));
    Else
        _message := 'Processing complete: no rows were added to t_analysis_job_request_existing_jobs';
    End If;

    RAISE INFO '';
    RAISE INFO '%', _message;

    -- CALL post_log_entry ('Debug', _message, 'Update_Cached_Job_Request_Existing_Jobs');
END
$$;


ALTER PROCEDURE public.update_cached_job_request_existing_jobs(IN _processingmode integer, IN _requestid integer, IN _jobsearchhours integer, IN _modezerosearchdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_job_request_existing_jobs(IN _processingmode integer, IN _requestid integer, IN _jobsearchhours integer, IN _modezerosearchdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_job_request_existing_jobs(IN _processingmode integer, IN _requestid integer, IN _jobsearchhours integer, IN _modezerosearchdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedJobRequestExistingJobs';

