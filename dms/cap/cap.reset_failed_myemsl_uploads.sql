--
-- Name: reset_failed_myemsl_uploads(boolean, integer, text, integer, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.reset_failed_myemsl_uploads(IN _infoonly boolean DEFAULT false, IN _maxjobstoreset integer DEFAULT 0, IN _joblistoverride text DEFAULT ''::text, IN _resetholdoffminutes integer DEFAULT 15, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for failed Dataset Archive or Archive Update tasks with known error messages
**      Resets the capture tasks to try again if _infoOnly is false
**
**  Arguments:
**    _infoOnly             True to preview the changes
**    _maxJobsToReset       Maximum number of capture task jobs to reset
**    _jobListOverride      Comma-separated list of jobs to reset; capture task jobs must have a failed step in t_task_steps
**    _resetHoldoffMinutes  Holdoff time to apply to column Finish
**
**  Auth:   mem
**  Date:   08/01/2016 mem - Initial version
**          01/26/2017 mem - Add parameters _maxJobsToReset and _jobListOverride
**                         - Check for Completion_Message 'Exception checking archive status'
**                         - Expand _message to varchar(4000)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          07/13/2017 mem - Add parameter _resetHoldoffMinutes
**                           Change exception messages to reflect the new MyEMSL API
**          07/20/2017 mem - Store the upload error message in T_MyEMSL_Upload_Resets
**                         - Reset steps with message 'Connection aborted.', BadStatusLine("''",)
**          08/01/2017 mem - Reset steps with message 'Connection aborted.', error(32, 'Broken pipe')
**          12/15/2017 mem - Reset steps with message 'ingest/backend/tasks.py'
**          03/07/2018 mem - Do not reset the same job/subfolder ingest task more than once
**          04/29/2020 bcg - Reset steps with message 'ingest/backend/tasks.py'
**          06/25/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(entry_id) and COUNT(job) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _jobInfo record;
    _logMessage text;
    _jobCountAtStart int;
    _verb text;
    _jobList text := null;
    _jobCount int;

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

    BEGIN
        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _infoOnly            := Coalesce(_infoOnly, false);
        _maxJobsToReset      := Coalesce(_maxJobsToReset, 0);
        _jobListOverride     := Trim(Coalesce(_jobListOverride, ''));
        _resetHoldoffMinutes := Coalesce(_resetHoldoffMinutes, 15);

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_FailedJobs (
            Job int,
            Dataset_ID int,
            Subfolder text NULL,
            Error_Message text NULL,
            SkipResetMode int Null,
            SkipReason text NULL
        );

        -----------------------------------------------------------
        -- Look for failed capture task jobs
        -----------------------------------------------------------

        INSERT INTO Tmp_FailedJobs( Job,
                                    Dataset_ID,
                                    Subfolder,
                                    Error_Message,
                                    SkipResetMode )
        SELECT Job,
               Dataset_ID,
               Coalesce(Output_Folder, Input_Folder),
               MAX(Completion_Message),
               0 AS SkipResetMode
        FROM cap.v_task_steps
        WHERE Tool = 'ArchiveVerify' AND
              State = 6 AND
              (Completion_Message LIKE '%ConnectionTimeout%' OR
               Completion_Message LIKE '%Connection reset by peer%' OR
               Completion_Message LIKE '%Internal Server Error%' OR
               Completion_Message LIKE '%Connection aborted%BadStatusLine%' OR
               Completion_Message LIKE '%Connection aborted%Broken pipe%' OR
               Completion_Message LIKE '%ingest/backend/tasks.py%' OR
               Completion_Message LIKE '%pacifica/ingest/tasks.py%') AND
              Job_State = 5 AND
              Finish < CURRENT_TIMESTAMP - make_interval(mins => _resetHoldoffMinutes)
        GROUP BY Job, Dataset_ID, Output_Folder, Input_Folder;

        If _jobListOverride <> '' Then
            INSERT INTO Tmp_FailedJobs( Job,
                                        Dataset_ID,
                                        Subfolder,
                                        Error_Message,
                                        SkipResetMode )
            SELECT DISTINCT SrcJobs.Value,
                            TS.Dataset_ID,
                            TS.Output_Folder,
                            TS.Completion_Message,
                            0 AS SkipResetMode
            FROM public.parse_delimited_integer_list(_jobListOverride) SrcJobs
                 INNER JOIN cap.v_task_steps TS
                   ON SrcJobs.Value = TS.Job
                 LEFT OUTER JOIN Tmp_FailedJobs Target
                   ON TS.Job = Target.Job
            WHERE TS.Tool LIKE '%Archive%' AND
                  TS.State = 6 AND
                  Target.Job IS NULL;
        End If;

        If Not Exists (SELECT * FROM Tmp_FailedJobs) Then
            If _infoOnly Then
                _message := 'No failed capture task jobs were found';
                RAISE INFO '%', _message;
            End If;

            DROP TABLE Tmp_FailedJobs;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Flag any capture task jobs that have failed twice for the same subfolder
        -- pushing the same number of files each time
        -----------------------------------------------------------

        UPDATE Tmp_FailedJobs Target
        SET SkipResetMode = 1,
            SkipReason = 'Upload has failed two or more times'
        FROM ( SELECT U.job,
                      U.subfolder,
                      U.file_count_new,
                      U.file_count_updated,
                      COUNT(entry_id) AS Attempts
               FROM cap.t_myemsl_uploads AS U
                    INNER JOIN Tmp_FailedJobs
                      ON U.job = Tmp_FailedJobs.job AND
                         U.subfolder = Tmp_FailedJobs.subfolder
               WHERE U.verified = 0
               GROUP BY U.job, U.subfolder, U.file_count_new, U.file_count_updated
             ) AttemptQ
        WHERE Target.job = AttemptQ.job AND
              Target.subfolder = AttemptQ.subfolder AND
              AttemptQ.Attempts > 1;

        If Exists (SELECT Job FROM Tmp_FailedJobs WHERE SkipResetMode = 1) Then
            -- Post a log entry about capture task jobs that we are not resetting
            -- Limit the logging to once every 24 hours

            FOR _jobInfo IN
                SELECT Job, Subfolder
                FROM Tmp_FailedJobs
                WHERE SkipResetMode = 1
                ORDER BY Job
            LOOP
                _logMessage := format('Skipping auto-reset of MyEMSL upload for capture task job %s', _jobInfo.Job);

                If char_length(_jobInfo.Subfolder) > 0 Then
                    _logMessage := format('%s, subfolder %s', _logMessage, _jobInfo.Subfolder);
                End If;

                _logMessage := format('%s since the upload has already failed 2 or more times', _logMessage);

                If Not _infoOnly Then
                    CALL public.post_log_entry ('Error', _logMessage, 'Reset_Failed_MyEMSL_Uploads', 'cap', _duplicateEntryHoldoffHours => 24);
                Else
                    RAISE INFO '%', _logMessage;
                End If;

            END LOOP;

        End If;

        -----------------------------------------------------------
        -- Flag any capture task jobs that have a DatasetArchive or ArchiveUpdate step in state 7 (Holding)
        -----------------------------------------------------------

        UPDATE Tmp_FailedJobs Target
        SET SkipResetMode = 2,
            SkipReason = format('%s tool is in state 7 (holding)', TS.Tool)
        FROM cap.t_task_steps TS
        WHERE Target.Job = TS.Job AND
              Target.Subfolder = TS.Output_Folder_Name AND
              TS.Tool IN ('ArchiveUpdate', 'DatasetArchive') AND
              TS.State = 7;

        -----------------------------------------------------------
        -- Possibly limit the number of capture task jobs to reset
        -----------------------------------------------------------

        SELECT COUNT(job)
        INTO _jobCountAtStart
        FROM Tmp_FailedJobs
        WHERE SkipResetMode = 0;

        If _maxJobsToReset > 0 And _jobCountAtStart > _maxJobsToReset Then

            DELETE FROM Tmp_FailedJobs
            WHERE SkipResetMode = 0 AND
                  NOT Job IN ( SELECT Job
                               FROM Tmp_FailedJobs
                               WHERE SkipResetMode = 0
                               ORDER BY Job
                               LIMIT _maxJobsToReset);

            If Not _infoOnly Then
                _verb := 'Resetting ';
            Else
                _verb := 'Would reset ';
            End If;

            RAISE INFO '% % out of % candidate capture task jobs', _verb, _maxJobsToReset, _jobCountAtStart;
        End If;

        If Exists (SELECT Job FROM Tmp_FailedJobs WHERE SkipResetMode = 0) Then
            -----------------------------------------------------------
            -- Construct a comma-separated list of capture task jobs, then call retry_myemsl_upload
            -----------------------------------------------------------

            SELECT string_agg(Job::text, ',' ORDER BY Job)
            INTO _jobList
            FROM Tmp_FailedJobs
            WHERE SkipResetMode = 0;

            CALL cap.retry_myemsl_upload (
                        _jobs       => _jobList,
                        _infoOnly   => _infoOnly,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

            -----------------------------------------------------------
            -- Post a log entry if any capture task jobs were reset
            -- Posting as an error so that it shows up in the daily error log
            -----------------------------------------------------------

            If Not _infoOnly Then

                SELECT COUNT(job)
                INTO  _jobCount
                FROM Tmp_FailedJobs
                WHERE SkipResetMode = 0;

                _message := format('Warning: Retrying MyEMSL upload for %s %s; for details, see cap.t_myemsl_upload_resets',
                                    public.check_plural(_jobCount, 'capture task job', 'capture task jobs'),
                                   _jobList);

                CALL public.post_log_entry ('Error', _message, 'Reset_Failed_MyEMSL_Uploads', 'cap');

                RAISE INFO '%', _message;

                INSERT INTO cap.t_myemsl_upload_resets (Job, Dataset_ID, Subfolder, Error_Message)
                SELECT Job, Dataset_ID, Subfolder, Error_Message
                FROM Tmp_FailedJobs
                WHERE SkipResetMode = 0;

            End If;
        End If;

        If _infoOnly Then

            -- Preview the capture task jobs in Tmp_FailedJobs

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-30s %-80s %-10s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Dataset_ID',
                                'Subfolder',
                                'Error_Message',
                                'Skip_Reset',
                                'Skip_Reason'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '----------',
                                         '------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '----------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job, Dataset_ID, Subfolder, Error_Message, SkipResetMode, SkipReason
                FROM Tmp_FailedJobs
                ORDER BY Job, Subfolder
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Dataset_ID,
                                    _previewData.Subfolder,
                                    _previewData.Error_Message,
                                    _previewData.SkipResetMode,
                                    _previewData.SkipReason
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        DROP TABLE Tmp_FailedJobs;

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

        DROP TABLE IF EXISTS Tmp_FailedJobs;
    END;

END
$$;


ALTER PROCEDURE cap.reset_failed_myemsl_uploads(IN _infoonly boolean, IN _maxjobstoreset integer, IN _joblistoverride text, IN _resetholdoffminutes integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_failed_myemsl_uploads(IN _infoonly boolean, IN _maxjobstoreset integer, IN _joblistoverride text, IN _resetholdoffminutes integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.reset_failed_myemsl_uploads(IN _infoonly boolean, IN _maxjobstoreset integer, IN _joblistoverride text, IN _resetholdoffminutes integer, INOUT _message text, INOUT _returncode text) IS 'ResetFailedMyEMSLUploads';

