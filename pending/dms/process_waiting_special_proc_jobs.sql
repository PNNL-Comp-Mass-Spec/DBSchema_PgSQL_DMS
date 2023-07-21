--
CREATE OR REPLACE PROCEDURE public.process_waiting_special_proc_jobs
(
    _waitThresholdHours int = 96,
    _errorMessagePostingIntervalHours int = 24,
    _infoOnly boolean = false,
    _previewSql boolean = false,
    _jobsToProcess int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _jobsUpdated int = 0 output
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines jobs in T_Analysis_Job that are in state 19="Special Proc. Waiting"
**      For each, checks whether the Special Processing text now matches an existing job
**      If a match is found, changes the job state to 1 = 'New'
**
**  Arguments:
**    _waitThresholdHours                 Hours between when a job is created and when we'll start posting messages to the error log that the job is waiting too long
**    _errorMessagePostingIntervalHours   Hours between posting a message to the error log that a job has been waiting more than _waitThresholdHours; used to prevent duplicate messages from being posted every few minutes
**    _infoOnly                           True to preview the jobs that would be set to state 'New'; will also display any jobs waiting more than _waitThresholdHours
**    _message                            Status message
**    _jobsUpdated                        Number of jobs whose state was set to 1
**
**  Auth:   mem
**  Date:   05/04/2012 mem - Initial version
**          01/23/2013 mem - Fixed bug that only checked the status of jobs with tag 'SourceJob'
**          05/14/2013 mem - Now auto-deleting jobs for bad datasets
**          07/02/2013 mem - Changed filter for 'bad datasets' to include -1 and -2 (previously included -5 aka Not Released)
**          07/10/2015 mem - Log message now mentions 'Not released dataset' when applicable
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _continue boolean;
    _jobsProcessed int := 0;
    _jobInfo record;
    _readyToProcess boolean;
    _datasetIsBad boolean;
    _jobMessage text;
    _hoursSinceStateLastChanged real;
    _hoursSinceLastLogEntry real;
    _sourceJob int;
    _autoQueryUsed int;
    _sourceJobState int;
    _warningMessage text;
    _tagAvailable boolean;
    _tagName text;
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

    _waitThresholdHours := Coalesce(_waitThresholdHours, 72);
    _errorMessagePostingIntervalHours := Coalesce(_errorMessagePostingIntervalHours, 24);
    _previewSql := Coalesce(_previewSql, false);
    _infoOnly := Coalesce(_infoOnly, false);
    _jobsToProcess := Coalesce(_jobsToProcess, 0);

    _jobsUpdated := 0;

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

    INSERT INTO Tmp_TagNamesTable(TagName)
    Values ('SourceJob'),
           ('Job2'),
           ('Job3'),
           ('Job4');

    ------------------------------------------------
    -- Create a table to track the jobs to update
    ------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsWaiting (
        Job int not null,
        Last_Affected timestamp null,
        ReadyToProcess boolean null,
        Message text null,
    )

    BEGIN

        FOR _jobInfo IN
            SELECT J.job,
                   DS.dataset,
                   J.special_processing As SpecialProcessingText,
                   J.last_affected As LastAffected,
                   DS.dataset_rating_id As DatasetRating,
                   DS.dataset_state_id As DatasetState,
                   J.results_folder_name As ResultsFolderName
            FROM t_analysis_job J
                 INNER JOIN t_dataset DS
                   ON J.dataset_id = DS.dataset_id
            WHERE J.job_state_id = 19
            ORDER BY J.job
        LOOP -- <a>

            _jobMessage := '';
            _readyToProcess := false;
            _datasetIsBad := false;

            _warningMessage := '';

            -- Process _jobInfo.SpecialProcessingText to look for the tags in Tmp_TagNamesTable
            _tagAvailable := true;

            _hoursSinceStateLastChanged := extract(epoch FROM CURRENT_TIMESTAMP - _jobInfo.LastAffected) / 3600.0;

            If _jobInfo.DatasetState = 4 Or _jobInfoatasetRating IN (-2, -1) Then

                _tagAvailable := false;

                If _jobInfo.DatasetState = 4 Then
                    _jobMessage := 'Bad dataset (state=4)';
                Else
                    _jobMessage := format('Dataset rating is %s', _jobInfo.DatasetRating);
                End If;

                -- Mark the job as bad
                -- However, if the job actually finished at some point in the past, do not mark the job as bad
                If Coalesce(_jobInfo.ResultsFolderName, '') = '' Then
                    _datasetIsBad := true;
                    _jobMessage := format('%s; job %s will be auto-deleted in %s hours', _jobMessage, _jobInfo.Job, _waitThresholdHours - _hoursSinceStateLastChanged);
                End If;

            End If;

            If _tagAvailable Then
                FOR _tagName IN
                    SELECT TagName
                    FROM Tmp_TagNamesTable
                    ORDER BY Entry_ID
                LOOP -- <b>

                    If Position(format('%s:', _tagName) In _jobInfo.SpecialProcessingText) = 0 Then
                        CONTINUE;
                    End If;

                    _tagName := _tagName;
                    _sourceJob := 0;
                    _warningMessage := '';
                    _readyToProcess := false;

                    CALL sw.lookup_source_job_from_special_processing_text (
                                _jobInfo.Job,
                                _jobInfo.Dataset,
                                _jobInfo.SpecialProcessingText,
                                _tagName,
                                _sourceJob => _sourceJob,           -- Output
                                _autoQueryUsed => _autoQueryUsed,   -- Output
                                _warningMessage => _warningMessage, -- Output
                                _previewSql => _previewSql);

                    _warningMessage := Coalesce(_warningMessage, '');

                    If _warningMessage = '' And Coalesce(_sourceJob, 0) > 0 Then
                        _readyToProcess := true;
                    Else
                        _jobMessage := _warningMessage;
                    End If;

                    If _readyToProcess Then
                        _sourceJobState := 0;

                        SELECT job_state_id
                        INTO _sourceJobState
                        FROM t_analysis_job
                        WHERE job = _sourceJob

                        If Not FOUND Then
                            _readyToProcess := false;
                            _jobMessage := format('Source job %s not found in t_analysis_job', _sourceJob);
                        Else
                            If _sourceJobState IN (4, 14) Then
                                _jobMessage := 'Ready';
                            Else
                                _readyToProcess := false;
                                _jobMessage := format('Source job %s exists but has state = %s', _sourceJob, _sourceJobState);
                            End If;
                        End If;
                    End If;

                    If Not _readyToProcess Then
                        -- Break out of the TagName for loop
                        EXIT;
                    End If;

                END LOOP; -- </b>
            End If;

            If Not _readyToProcess Then
            -- <c>

                If _hoursSinceStateLastChanged > _waitThresholdHours And Not _previewSql Then
                -- <d>
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
                            CALL delete_analysis_job (_jobInfo.Job);

                            _message := format('%s; job deleted since dataset is bad', _message);
                            CALL post_log_entry ('Warning', _message, 'Process_Waiting_Special_Proc_Jobs', _duplicateEntryHoldoffHours => 0);
                        Else
                            If _jobInfo.DatasetRating = -5 Then
                                _message := format('Not released dataset: %s', _message);
                            End If;

                            CALL post_log_entry ('Error', _message, 'Process_Waiting_Special_Proc_Jobs', _duplicateEntryHoldoffHours => _errorMessagePostingIntervalHours);
                        End If;
                    End If;

                End If; -- </d>

            End If; -- </c>

            INSERT INTO Tmp_JobsWaiting (Job, Last_Affected, ReadyToProcess, Message)
            Values (_jobInfo.Job, _jobInfo.LastAffected, _readyToProcess, _jobMessage)

            _jobsProcessed := _jobsProcessed + 1;

            If _jobsToProcess > 0 And _jobsProcessed >= _jobsToProcess Then
                -- Break out of the for loop
                EXIT;
            End If;

        END LOOP; -- </a>

        If _infoOnly Or _previewSql Then
            ------------------------------------------------
            -- Preview the jobs
            ------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-9s %-20s %-16s %-30s';

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
                                         '------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       public.timestamp_text(Last_Affected),
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
            WHERE Tmp_JobsWaiting.job = t_analysis_job.job And Tmp_JobsWaiting.ReadyToProcess;

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

COMMENT ON PROCEDURE public.process_waiting_special_proc_jobs IS 'ProcessWaitingSpecialProcJobs';
