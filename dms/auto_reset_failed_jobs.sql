--
-- Name: auto_reset_failed_jobs(integer, boolean, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_reset_failed_jobs(IN _windowhours integer DEFAULT 12, IN _infoonly boolean DEFAULT true, IN _steptoolfilter text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for recently failed jobs (with job_state_id = 5 in public.t_analysis_job)
**      Look for failed job steps in sw.t_job_steps and possibly reset the jobs
**
**      Also look for and reset jobs that are in progress (job step state is 4), but for which the processor has state 'Stopped Error'
**
**  Arguments:
**    _windowHours      Look for jobs that failed within this many hours of the present time
**    _infoOnly         When true, preview updates
**    _stepToolFilter   Optional step tool to filter on (must be an exact match to a tool name in t_job_steps)
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user (unused by this procedure)
**
**  Auth:   mem
**  Date:   09/30/2010 mem - Initial Version
**          10/01/2010 mem - Added call to post_log_entry when changing ManagerErrorCleanupMode for a processor
**          02/16/2012 mem - Fixed major bug that reset the state for all steps of a job to state 2, rather than only resetting the state for the running step
**                         - Fixed bug finding jobs that are running, but started over 60 minutes ago and for which the processor is reporting Stopped_Error in T_Processor_Status
**          07/25/2013 mem - Now auto-updating the settings file for MSGF+ jobs that report a comment similar to "MSGF+ skipped 99.2% of the spectra because they did not appear centroided"
**                         - Now auto-resetting MSGF+ jobs that report 'Not enough free memory'
**          07/31/2013 mem - Now auto-updating the settings file for MSGF+ jobs that contain the text "None of the spectra are centroided; unable to process with MSGF+" in the comment
**                         - Now auto-resetting jobs that report 'Exception generating OrgDb file'
**          04/17/2014 mem - Updated check for 'None of the spectra are centroided' to be more generic
**          09/09/2014 mem - Changed DataExtractor and MSGF retries to 2
**                         - Now auto-resetting MSAlign jobs that report 'Not enough free memory'
**          10/27/2014 mem - Now watching for 'None of the spectra are centroided' from DTA_Refinery
**          03/27/2015 mem - Now auto-resetting ICR2LS jobs up to 15 times
**                         - Added parameter _stepToolFilter
**          11/19/2015 mem - Preventing retry of jobs with a failed DataExtractor job with a message like "7.7% of the peptides have a mass error over 6.0 Da"
**          11/19/2015 mem - Now auto-resetting jobs with a DataExtractor step reporting 'Not enough free memory'
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/12/2016 mem - Now using a synonym when calling S_SetManagerErrorCleanupMode in the Manager_Control database
**          09/02/2016 mem - Switch the archive server path from \\a2 to \\adms
**          01/18/2017 mem - Auto-reset Bruker_DA_Export jobs up to 2 times
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add check for 'An unexpected network error occurred'
**          09/05/2017 mem - Check for Mz_Refinery reporting Not enough free memory
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          10/05/2023 mem - Switch the archive server path from \\adms to \\agate
**          01/27/2024 mem - Ported to PostgreSQL
**          06/13/2025 mem - Use new parameter name when calling procedure mc.set_manager_error_cleanup_mode()
**                         - Reset failed jobs with error 'cyclic redundancy check'
**
*****************************************************/
DECLARE
    _jobInfo record;
    _newJobState int;
    _newComment citext;
    _newSettingsFile citext;
    _skipInfo citext;
    _retryJob boolean;
    _setProcessorAutoRecover boolean;
    _settingsFileChanged boolean;
    _retryCount int;
    _matchPos int;
    _matchPosLast int;
    _poundPos int;
    _retryText citext;
    _retryCountText citext;
    _resetReason citext;
    _logMessage text;

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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _windowHours    := Coalesce(_windowHours, 12);
        _infoOnly       := Coalesce(_infoOnly, false);
        _stepToolFilter := Trim(Coalesce(_stepToolFilter, ''));

        If _windowHours < 2 Then
            _windowHours := 2;
        End If;

        CREATE TEMP TABLE Tmp_FailedJobs (
            Job int NOT NULL,
            Step int NOT NULL,
            Step_Tool text NOT NULL,
            Job_State int NOT NULL,
            Step_State int NOT NULL,
            Processor text NOT NULL,
            Comment text NOT NULL,
            Job_Finish timestamp NULL,
            Settings_File text NOT NULL,
            Analysis_Tool text NOT NULL,
            New_Job_State int NULL,
            New_Step_State int NULL,
            New_Comment text NULL,
            New_Settings_File text NULL,
            Reset_Job boolean NOT NULL DEFAULT false,
            Rerun_All_Job_Steps boolean NOT NULL DEFAULT false
        );

        ---------------------------------------------------
        -- Populate a temporary table with jobs that failed within the last _windowHours hours
        ---------------------------------------------------

        INSERT INTO Tmp_FailedJobs (
            Job, Step, Step_Tool, Job_State, Step_State,
            Processor, Comment, Job_Finish, Settings_File, Analysis_Tool
        )
        SELECT J.job,
               JS.step,
               JS.tool,
               J.job_state_id AS Job_State,
               JS.state AS Step_State,
               Coalesce(JS.processor, '') AS Processor,
               Coalesce(J.comment, '') AS Comment,
               Coalesce(J.finish, J.start) AS Job_Finish,
               J.settings_file_name,
               Tool.analysis_tool
        FROM t_analysis_job J
             INNER JOIN sw.t_job_steps JS
               ON J.job = JS.job
             INNER JOIN t_analysis_tool Tool
               ON J.analysis_tool_id = Tool.analysis_tool_id
        WHERE J.job_state_id = 5 AND
              Coalesce(J.finish, J.start) >= CURRENT_TIMESTAMP - make_interval(hours => _windowHours) AND
              JS.state = 6 AND
              (_stepToolFilter = '' OR JS.Tool = _stepToolFilter::citext);

        ---------------------------------------------------
        -- Next look for job steps that are running, but started over 60 minutes ago and for which
        -- the processor is reporting Stopped_Error in T_Processor_Status
        ---------------------------------------------------

        INSERT INTO Tmp_FailedJobs (
            Job, Step, Step_Tool, Job_State, Step_State,
            Processor, comment, Job_Finish, Settings_File, Analysis_Tool
        )
        SELECT J.job,
               JS.step,
               JS.tool,
               J.job_state_id AS Job_State,
               JS.state AS Step_State,
               Coalesce(JS.processor, '') AS Processor,
               Coalesce(J.comment, '') AS Comment,
               Coalesce(J.finish, J.start) AS Job_Finish,
               J.settings_file_name,
               Tool.analysis_tool
        FROM t_analysis_job J
             INNER JOIN sw.t_job_steps JS
               ON J.job = JS.job
             INNER JOIN sw.t_processor_status ProcStatus
               ON JS.Processor = ProcStatus.Processor_Name
             INNER JOIN t_analysis_tool Tool
               ON J.analysis_tool_id = Tool.analysis_tool_id
        WHERE J.job_state_id = 2 AND
              JS.state = 4 AND
              ProcStatus.Mgr_Status = 'Stopped Error' AND
              JS.start <= CURRENT_TIMESTAMP - INTERVAL '1 hour' AND
              ProcStatus.Status_Date > CURRENT_TIMESTAMP - INTERVAL '30 minutes';

        If Not Exists (SELECT * FROM Tmp_FailedJobs) Then
            DROP TABLE Tmp_FailedJobs;
            RETURN;
        End If;

        -- Step through the jobs and reset them if appropriate

        FOR _jobInfo IN
            SELECT Job,
                   Step,
                   Step_Tool AS StepTool,           -- Step tool name
                   Job_State AS JobState,
                   Step_State AS StepState,
                   Processor,
                   Comment,
                   Settings_File AS SettingsFile,
                   Analysis_Tool AS AnalysisTool    -- Overall Job Analysis Tool Name
            FROM Tmp_FailedJobs
            ORDER BY Job
        LOOP

            _retryJob                := false;
            _retryCount              := 0;
            _setProcessorAutoRecover := false;
            _settingsFileChanged     := false;
            _newSettingsFile         := '';
            _skipInfo                := '';

            -- Examine the comment to determine if we've retried this job before
            -- Need to find the last instance of '(retry'

            _matchPosLast := 0;
            _matchPos := 1;

            WHILE _matchPos > 0
            LOOP
                _matchPos := Position('(retry' In Substring(_jobInfo.Comment, _matchPosLast + 1));

                If _matchPos > 0 Then
                    _matchPosLast := _matchPos + _matchPosLast;
                End If;
            END LOOP;

            _matchPos := _matchPosLast;

            If _matchPos = 0 Then
                -- Comment does not contain '(retry'
                _newComment := _jobInfo.Comment;

                If _newComment Like '%;%' Then
                    -- Comment contains a semicolon
                    -- Remove the text after the semicolon
                    _matchPos := Position(';' In _newComment);

                    If _matchPos > 1 Then
                        _newComment := Substring(_newComment, 1, _matchPos - 1);
                    Else
                        _newComment := '';
                    End If;
                End If;
            Else
                -- Comment contains '(retry'

                If _matchPos > 1 Then
                    _newComment := Substring(_jobInfo.Comment, 1, _matchPos - 1);
                Else
                    _newComment := '';
                End If;

                -- Determine the number of times the job has been retried
                _retryCount := 1;
                _retryText := Substring(_jobInfo.Comment, _matchPos, char_length(_jobInfo.Comment));

                -- Find the closing parenthesis
                _matchPos := Position(')' In _retryText);

                If _matchPos > 0 Then
                    _poundPos := Position('#' In _retryText);

                    If _poundPos > 0 Then
                        If _matchPos - _poundPos - 1 > 0 Then
                            _retryCountText := Substring(_retryText, _poundPos + 1, _matchPos - _poundPos - 1);
                            _retryCount := Coalesce(public.try_cast(_retryCountText, null::int), _retryCount);
                        End If;
                    End If;
                End If;
            End If;

            If _jobInfo.StepState = 6 Then
                -- Job step is failed (in sw.t_job_steps) and overall job is failed (in public.t_analysis_job)

                If Not _retryJob And _jobInfo.StepTool In ('Decon2LS', 'MSGF', 'Bruker_DA_Export') And _retryCount < 2 Then
                    _retryJob := true;
                End If;

                If Not _retryJob And _jobInfo.StepTool = 'ICR2LS' And _retryCount < 15 Then
                    _retryJob := true;
                End If;

                If Not _retryJob And _jobInfo.StepTool = 'DataExtractor' And Not _jobInfo.Comment ILike '%have a mass error over%' And _retryCount < 2 Then
                    _retryJob := true;
                End If;

                If Not _retryJob And _jobInfo.StepTool In ('Sequest', 'MSGFPlus', 'XTandem', 'MSAlign', 'Mz_Refinery') And _jobInfo.Comment ILike '%Exception generating OrgDb file%' And _retryCount < 2 Then
                    _retryJob := true;
                End If;

                If Not _retryJob And _jobInfo.StepTool In ('Sequest', 'MSGFPlus', 'XTandem', 'MSAlign', 'Mz_Refinery') And _jobInfo.Comment ILike '%cyclic redundancy check%' And _retryCount < 2 Then
                    _retryJob := true;
                End If;

                If Not _retryJob And
                   (_jobInfo.StepTool ILike 'MSGFPlus%' Or _jobInfo.StepTool = 'DTA_Refinery') And
                   (_jobInfo.Comment  ILike '%None of the spectra are centroided; unable to process%' Or
                    _jobInfo.Comment  ILike '%skipped % of the spectra because they did not appear centroided%' Or
                    _jobInfo.Comment  ILike '%skip % of the spectra because they do not appear centroided%'
                   ) Then

                    -- MSGF+ job that failed due to too many profile-mode spectra
                    -- Auto-change the SettingsFile to a MSConvert version if possible.

                    _newSettingsFile := '';

                    SELECT msgfplus_auto_centroid
                    INTO _newSettingsFile
                    FROM t_settings_files
                    WHERE analysis_tool = _jobInfo.AnalysisTool AND
                          file_name     = _jobInfo.SettingsFile AND
                          Coalesce(msgfplus_auto_centroid, '') <> '';

                    If FOUND Then

                        _retryJob := true;
                        _settingsFileChanged := true;

                        If _jobInfo.Comment ILike '%None of the spectra are centroided; unable to process%' Then
                            _skipInfo := 'None of the spectra are centroided';
                        Else
                            _matchPos := Position('MSGF+ skipped' In _jobInfo.Comment);

                            If _matchPos > 0 Then
                                _skipInfo := Substring(_jobInfo.Comment, _matchPos, char_length(_jobInfo.Comment));
                            Else

                                _matchPos := Position('MSGF+ will likely skip' In _jobInfo.Comment);

                                If _matchPos > 0 Then
                                    _skipInfo := Substring(_jobInfo.Comment, _matchPos, char_length(_jobInfo.Comment));
                                Else
                                    _skipInfo := 'MSGF+ skipped ??% of the spectra because they did not appear centroided';
                                End If;

                            End If;
                        End If;
                    End If;
                End If;

                If Not _retryJob And
                   _jobInfo.StepTool In ('MSGFPlus', 'MSGFPlus_IMS', 'MSAlign', 'MSAlign_Histone', 'DataExtractor', 'Mz_Refinery') And
                   _jobInfo.Comment ILike '%Not enough free memory%' And
                   _retryCount < 10 Then

                    RAISE INFO 'Reset %', _jobInfo.Job;
                    _retryJob := true;
                End If;

                If Not _retryJob And _retryCount < 5 Then
                    -- Check for file copy errors from the Archive
                    If _jobInfo.Comment ILike '%Error copying file \\\\agate%' Or
                       _jobInfo.Comment ILike '%Error copying file \\\\adms%' Or
                       _jobInfo.Comment ILike '%File not found: \\\\agate%' Or
                       _jobInfo.Comment ILike '%File not found: \\\\adms%' Or
                       _jobInfo.Comment ILike '%Error copying %dta.zip%' Or
                       _jobInfo.Comment ILike '%Source dataset file file not found%' Then

                        _retryJob := true;

                    End If;

                End If;

                If Not _retryJob And _retryCount < 5 Then
                    -- Check for network errors
                    If _jobInfo.Comment ILike '%unexpected network error occurred%' Then
                        _retryJob := true;
                    End If;

                End If;
            End If;

            If _jobInfo.StepState = 4 Then
                -- Job is still running, but processor has an error (typically a flagfile)
                -- This likely indicates an out-of-memory error

                If _jobInfo.StepTool In ('DataExtractor', 'MSGF') And _retryCount < 5 Then
                    _retryJob := true;
                End If;

                If _retryJob Then
                    _setProcessorAutoRecover := true;
                End If;
            End If;

            If Not _retryJob Then
                CONTINUE;
            End If;

            _newComment := RTrim(_newComment);

            If _settingsFileChanged Then
                -- Note: do not append a semicolon because, if the job fails again in the future, the text after the semicolon may get auto-removed
                If _newComment <> '' Then
                    _newComment := format('%s, ', _newComment);
                End If;

                _newComment := format('%sAuto-switched settings file from %s (%s)', _newComment, _jobInfo.SettingsFile, _skipInfo);
            Else
                If _newComment <> '' Then
                    _newComment := format('%s ', _newComment);
                End If;

                _newComment := format('%s(retry %s', _newComment, _jobInfo.StepTool);

                _retryCount := _retryCount + 1;

                If _retryCount = 1 Then
                    _newComment := format('%s)', _newComment);
                Else
                    _newComment := format('%s #%s)', _newComment, _retryCount);
                End If;
            End If;

            If _jobInfo.StepState = 6 Then
                _newJobState := 1;

                UPDATE Tmp_FailedJobs
                SET New_Job_State       = _newJobState,
                    New_Step_State      = _jobInfo.StepState,
                    New_Comment         = _newComment,
                    Reset_Job           = true,
                    New_Settings_File   = _newSettingsFile,
                    Rerun_All_Job_Steps = _settingsFileChanged
                WHERE Job = _jobInfo.Job;

                _resetReason := format('job step failed in the last %s hours', _windowHours);
            End If;

            If _jobInfo.StepState = 4 Then
                _newJobState := _jobInfo.JobState;

                UPDATE Tmp_FailedJobs
                SET New_Job_State  = _newJobState,
                    New_Step_State = 2,
                    New_Comment    = _newComment,
                    Reset_Job      = true
                WHERE Job = _jobInfo.Job;

                If Not _infoOnly Then
                    -- Reset the step back to state 2=Enabled
                    UPDATE sw.t_job_steps
                    SET state = 2
                    WHERE job = _jobInfo.Job AND step = _jobInfo.Step;
                End If;

                _resetReason := 'job step in progress but manager reports "Stopped Error"';
            End If;

            If Not _infoOnly Then

                If _settingsFileChanged Then
                    -- The settings file for this job has changed, thus we must re-generate the job in the sw schema tables
                    -- Note that deletes auto-cascade from sw.T_Jobs to sw.T_Job_Steps, sw.T_Job_Parameters, and sw.T_Job_Step_Dependencies

                    DELETE FROM sw.t_jobs
                    WHERE Job = _jobInfo.Job;

                    UPDATE t_analysis_job
                    SET settings_file_name = _newSettingsFile
                    WHERE job = _jobInfo.Job;

                End If;

                -- Update the JobState and comment in t_analysis_job
                UPDATE t_analysis_job
                SET job_state_id = _newJobState,
                    comment      = _newComment
                WHERE job = _jobInfo.Job;

                _logMessage := format('Auto-reset job %s; %s; %s', _jobInfo.Job, _resetReason, _newComment);

                CALL post_log_entry ('Warning', _logMessage, 'Auto_Reset_Failed_Jobs');
            End If;

            If _setProcessorAutoRecover Then
                If Not _infoOnly Then
                    _logMessage := format('%s reports "Stopped Error"; setting ManagerErrorCleanupMode to 1 in the Manager_Control DB', _jobInfo.Processor);

                    CALL post_log_entry ('Warning', _logMessage, 'Auto_Reset_Failed_Jobs');

                    CALL mc.set_manager_error_cleanup_mode (_mgrlist => _jobInfo.Processor, _cleanupMode => 1);
                Else
                    RAISE INFO 'Call mc.set_manager_error_cleanup_mode (_mgrlist => %, _cleanupMode => 1)', _jobInfo.Processor;
                End If;
            End If;

        END LOOP;

        If Not _infoOnly Then
            DROP TABLE Tmp_FailedJobs;
            RETURN;
        End If;

        RAISE INFO '';

        _formatSpecifier := '%-10s %-4s %-25s %-9s %-10s %-20s %-150s %-20s %-70s %-25s %-30s %-16s %-70s %-70s %-9s %-19s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Step_Tool',
                            'Job_State',
                            'Step_State',
                            'Processor',
                            'Comment',
                            'Job_Finish',
                            'Settings_File',
                            'Analysis_Tool',
                            'New_Job_State',
                            'New_Step_State',
                            'New_Comment',
                            'New_Settings_File',
                            'Reset_Job',
                            'Rerun_All_Job_Steps'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----',
                                     '-------------------------',
                                     '---------',
                                     '----------',
                                     '--------------------',
                                     '------------------------------------------------------------------------------------------------------------------------------------------------------',
                                     '--------------------',
                                     '----------------------------------------------------------------------',
                                     '-------------------------',
                                     '------------------------------',
                                     '----------------',
                                     '----------------------------------------------------------------------',
                                     '----------------------------------------------------------------------',
                                     '---------',
                                     '-------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job,
                   Step,
                   Step_Tool,
                   Job_State,
                   Step_State,
                   Processor,
                   Substring(Comment, 1, 150) AS Comment,
                   public.timestamp_text(Job_Finish) AS Job_Finish,
                   Settings_File,
                   Analysis_Tool,
                   New_Job_State,
                   New_Step_State,
                   New_Comment,
                   New_Settings_File,
                   Reset_Job,
                   Rerun_All_Job_Steps
            FROM Tmp_FailedJobs
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Step,
                                _previewData.Step_Tool,
                                _previewData.Job_State,
                                _previewData.Step_State,
                                _previewData.Processor,
                                _previewData.Comment,
                                _previewData.Job_Finish,
                                _previewData.Settings_File,
                                _previewData.Analysis_Tool,
                                _previewData.New_Job_State,
                                _previewData.New_Step_State,
                                _previewData.New_Comment,
                                _previewData.New_Settings_File,
                                _previewData.Reset_Job,
                                _previewData.Rerun_All_Job_Steps
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_FailedJobs;
        RETURN;

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

    DROP TABLE IF EXISTS Tmp_FailedJobs;
END
$$;


ALTER PROCEDURE public.auto_reset_failed_jobs(IN _windowhours integer, IN _infoonly boolean, IN _steptoolfilter text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_reset_failed_jobs(IN _windowhours integer, IN _infoonly boolean, IN _steptoolfilter text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_reset_failed_jobs(IN _windowhours integer, IN _infoonly boolean, IN _steptoolfilter text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AutoResetFailedJobs';

