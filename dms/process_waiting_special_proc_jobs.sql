--
-- Name: process_waiting_special_proc_jobs(integer, integer, boolean, boolean, integer, text, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.process_waiting_special_proc_jobs(IN _waitthresholdhours integer DEFAULT 96, IN _errormessagepostingintervalhours integer DEFAULT 24, IN _infoonly boolean DEFAULT false, IN _previewsql boolean DEFAULT false, IN _jobstoprocess integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _jobsupdated integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine jobs in t_analysis_job that are in state 19 = 'Special Proc. Waiting'
**      For each, check whether the special processing text now matches an existing job
**      If a match is found, change the job state to 1 = 'New'
**
**  Arguments:
**    _waitThresholdHours                   Hours between when a job is created and when we'll start posting messages to the error log that the job is waiting too long
**    _errorMessagePostingIntervalHours     Hours between posting a message to the error log that a job has been waiting more than _waitThresholdHours; used to prevent duplicate messages from being posted every few minutes
**    _infoOnly                             When true, preview the jobs that would be set to state 'New'; will also display any jobs waiting more than _waitThresholdHours
**    _previewSql                           When true, show the SQL used to look for source jobs
**    _jobsToProcess                        Number of jobs to process
**    _message                              Status message
**    _returnCode                           Return code
**    _jobsUpdated                          Output: Number of jobs whose state was set to 1
**
**  Auth:   mem
**  Date:   05/04/2012 mem - Initial version
**          01/23/2013 mem - Fixed bug that only checked the status of jobs with tag 'SourceJob'
**          05/14/2013 mem - Now auto-deleting jobs for bad datasets
**          07/02/2013 mem - Changed filter for 'bad datasets' to include -1 and -2 (previously included -5 aka Not Released)
**          07/10/2015 mem - Log message now mentions 'Not released dataset' when applicable
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/16/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobsProcessed int := 0;
    _jobInfo record;
    _readyToProcess boolean;
    _datasetIsBad boolean;
    _jobMessage text;
    _hoursSinceStateLastChanged real;
    _hoursSinceLastLogEntry real;
    _sourceJob int;
    _autoQueryUsed boolean;
    _autoQuerySql text;
    _sourceJobState int;
    _warningMessage text;
    _lookForTag boolean;
    _tagName citext;
    _message2 text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _waitThresholdHours               := Coalesce(_waitThresholdHours, 96);
    _errorMessagePostingIntervalHours := Coalesce(_errorMessagePostingIntervalHours, 24);
    _infoOnly                         := Coalesce(_infoOnly, false);
    _previewSql                       := Coalesce(_previewSql, false);
    _jobsToProcess                    := Coalesce(_jobsToProcess, 0);

    _jobsUpdated := 0;

    If _waitThresholdHours < 12 Then
        _waitThresholdHours := 12;
    End If;

    If _errorMessagePostingIntervalHours < 1 Then
        _errorMessagePostingIntervalHours := 1;
    End If;

    ------------------------------------------------
    -- Create a table to track the tag names to look for
    ------------------------------------------------

    CREATE TEMP TABLE Tmp_TagNamesTable (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        TagName text
    );

    INSERT INTO Tmp_TagNamesTable (TagName)
    VALUES ('SourceJob'),
           ('Job2'),
           ('Job3'),
           ('Job4');

    ------------------------------------------------
    -- Create a table to track the jobs to update
    ------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsWaiting (
        Job int NOT NULL,
        Last_Affected timestamp NULL,
        ReadyToProcess boolean NULL,
        Message text NULL
    );

    BEGIN

        FOR _jobInfo IN
            SELECT J.job,
                   DS.dataset,
                   J.special_processing  AS SpecialProcessingText,
                   J.last_affected       AS LastAffected,
                   DS.dataset_rating_id  AS DatasetRating,
                   DS.dataset_state_id   AS DatasetState,
                   J.results_folder_name AS ResultsFolderName
            FROM t_analysis_job J
                 INNER JOIN t_dataset DS
                   ON J.dataset_id = DS.dataset_id
            WHERE J.job_state_id = 19
            ORDER BY J.job
        LOOP
            _jobMessage     := '';
            _readyToProcess := false;
            _datasetIsBad   := false;
            _warningMessage := '';

            -- Process _jobInfo.SpecialProcessingText to look for the tags in Tmp_TagNamesTable
            _lookForTag := true;

            _hoursSinceStateLastChanged := Extract(epoch from CURRENT_TIMESTAMP - _jobInfo.LastAffected) / 3600;

            If _jobInfo.DatasetState = 4 Or _jobInfo.DatasetRating In (-2, -1) Then

                _lookForTag := false;

                If _jobInfo.DatasetState = 4 Then
                    _jobMessage := 'Bad dataset (state=4)';
                Else
                    _jobMessage := format('Dataset rating is %s (%s)',
                                          _jobInfo.DatasetRating,
                                          CASE _jobInfo.DatasetRating
                                               WHEN -2 THEN 'Data Files Missing'
                                               WHEN -1 THEN 'No Data'
                                               ELSE '??'
                                          END);
                End If;

                -- Mark the job as bad
                -- However, if the job actually finished at some point in the past, do not mark the job as bad
                If Coalesce(_jobInfo.ResultsFolderName, '') = '' Then
                    _datasetIsBad := true;
                    _jobMessage := format('%s; job %s will be auto-deleted in %s hours',
                                          _jobMessage,
                                          _jobInfo.Job,
                                          _waitThresholdHours - _hoursSinceStateLastChanged);
                End If;

            End If;

            If _lookForTag Then
                FOR _tagName IN
                    SELECT TagName
                    FROM Tmp_TagNamesTable
                    ORDER BY Entry_ID
                LOOP
                    If Position(format('%s:', _tagName) In _jobInfo.SpecialProcessingText) = 0 Then
                        CONTINUE;
                    End If;

                    _sourceJob      := 0;
                    _warningMessage := '';
                    _readyToProcess := false;

                    CALL sw.lookup_source_job_from_special_processing_text (
                                _job                   => _jobInfo.Job,
                                _dataset               => _jobInfo.Dataset::text,
                                _specialProcessingText => _jobInfo.SpecialProcessingText::text,
                                _tagName               => _tagName::text,
                                _sourceJob             => _sourceJob,       -- Output
                                _autoQueryUsed         => _autoQueryUsed,   -- Output
                                _warningMessage        => _warningMessage,  -- Output
                                _returnCode            => _returnCode,      -- Output
                                _previewSql            => _previewSql,
                                _autoQuerySql          => _autoQuerySql);   -- Output; the auto-query SQL that was used

                    _warningMessage := Coalesce(_warningMessage, '');

                    If _warningMessage = '' And Coalesce(_sourceJob, 0) > 0 Then
                        _readyToProcess := true;
                    Else
                        _jobMessage := _warningMessage;
                    End If;

                    If _readyToProcess Then

                        SELECT job_state_id
                        INTO _sourceJobState
                        FROM t_analysis_job
                        WHERE job = _sourceJob;

                        If Not FOUND Then
                            _readyToProcess := false;
                            _jobMessage := format('Source job %s not found in t_analysis_job', _sourceJob);
                        Else
                            If _sourceJobState In (4, 14) Then
                                _jobMessage := 'Ready';
                            Else
                                _readyToProcess := false;
                                _jobMessage := format('Source job %s exists but has state = %s, instead of 4 or 14', _sourceJob, _sourceJobState);
                            End If;
                        End If;
                    End If;

                    If Not _readyToProcess Then
                        -- Break out of the TagName for loop
                        EXIT;
                    End If;

                END LOOP;
            End If;

            If Not _readyToProcess Then

                If _hoursSinceStateLastChanged > _waitThresholdHours And Not _previewSql Then

                    _message2 := format('Waiting for %s hours', _hoursSinceStateLastChanged);

                    If _jobMessage = '' Then
                        _jobMessage := _message2;
                    Else
                        _jobMessage := format('%s; %s', _jobMessage, _message2);
                    End If;

                    If Not _infoOnly Then
                        -- Log an error message
                        _message := format('Job %s has been in state "Special Proc. Waiting" for over %s hours', _jobInfo.Job, _waitThresholdHours);

                        If _datasetIsBad Then
                            CALL public.delete_analysis_job (
                                            _job         => _jobInfo.Job,
                                            _infoOnly    => false,
                                            _message     => _message2,   -- Output
                                            _returnCode  => _returnCode, -- Output
                                            _callingUser => '');

                            If _returnCode = '' Then
                                _message := format('%s; job deleted since dataset is bad', _message);
                            Else
                                _message := format('%s; call to delete_analysis_job returned error code %s (%s)', _message, _returnCode, _message2);
                            End If;

                            CALL post_log_entry ('Warning', _message, 'Process_Waiting_Special_Proc_Jobs', _duplicateEntryHoldoffHours => 0);
                        Else
                            If _jobInfo.DatasetRating = -5 Then
                                _message := format('Not released dataset: %s', _message);
                            End If;

                            CALL post_log_entry ('Error', _message, 'Process_Waiting_Special_Proc_Jobs', _duplicateEntryHoldoffHours => _errorMessagePostingIntervalHours);
                        End If;
                    End If;

                End If;

            End If;

            INSERT INTO Tmp_JobsWaiting (Job, Last_Affected, ReadyToProcess, Message)
            VALUES (_jobInfo.Job, _jobInfo.LastAffected, _readyToProcess, _jobMessage);

            _jobsProcessed := _jobsProcessed + 1;

            If _jobsToProcess > 0 And _jobsProcessed >= _jobsToProcess Then
                -- Break out of the for loop
                EXIT;
            End If;

        END LOOP;

        If _infoOnly Or _previewSql Then
            ------------------------------------------------
            -- Preview the jobs
            ------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-9s %-20s %-16s %-75s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Last_Affected',
                                'Ready_To_Process',
                                'Message'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------',
                                         '--------------------',
                                         '----------------',
                                         '---------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       public.timestamp_text(Last_Affected) AS Last_Affected,
                       ReadyToProcess,
                       Message
                FROM Tmp_JobsWaiting
                ORDER BY Job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Last_Affected,
                                    _previewData.ReadyToProcess,
                                    _previewData.Message
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;


        Else
            ------------------------------------------------
            -- Update the jobs
            ------------------------------------------------

            UPDATE t_analysis_job
            SET job_state_id = 1
            FROM Tmp_JobsWaiting
            WHERE Tmp_JobsWaiting.job = t_analysis_job.job AND
                  Tmp_JobsWaiting.ReadyToProcess;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_JobsWaiting;
    DROP TABLE IF EXISTS Tmp_TagNamesTable;
END
$$;


ALTER PROCEDURE public.process_waiting_special_proc_jobs(IN _waitthresholdhours integer, IN _errormessagepostingintervalhours integer, IN _infoonly boolean, IN _previewsql boolean, IN _jobstoprocess integer, INOUT _message text, INOUT _returncode text, INOUT _jobsupdated integer) OWNER TO d3l243;

--
-- Name: PROCEDURE process_waiting_special_proc_jobs(IN _waitthresholdhours integer, IN _errormessagepostingintervalhours integer, IN _infoonly boolean, IN _previewsql boolean, IN _jobstoprocess integer, INOUT _message text, INOUT _returncode text, INOUT _jobsupdated integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.process_waiting_special_proc_jobs(IN _waitthresholdhours integer, IN _errormessagepostingintervalhours integer, IN _infoonly boolean, IN _previewsql boolean, IN _jobstoprocess integer, INOUT _message text, INOUT _returncode text, INOUT _jobsupdated integer) IS 'ProcessWaitingSpecialProcJobs';

