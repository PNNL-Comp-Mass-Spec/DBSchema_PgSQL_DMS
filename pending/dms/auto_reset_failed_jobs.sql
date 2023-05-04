--
CREATE OR REPLACE PROCEDURE public.auto_reset_failed_jobs
(
    _windowHours int = 12,
    _infoOnly boolean = true,
    _stepToolFilter text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for recently failed jobs
**      Examines the reason for the failure and will auto-reset under certain conditions
**
**  Arguments:
**    _windowHours      Will look for jobs that failed within _windowHours hours of the present time
**    _stepToolFilter   Optional Step Tool to filter on (must be an exact match to a tool name in T_Job_Steps)
**
**  Auth:   mem
**  Date:   09/30/2010 mem - Initial Version
**          10/01/2010 mem - Added call to PostLogEntry when changing ManagerErrorCleanupMode for a processor
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _job int;
    _step int;
    _stepTool citext;
    _jobState int;
    _stepState int;
    _processor citext;
    _comment citext;
    _settingsFile citext;
    _analysisTool citext;
    _newJobState int;
    _newComment citext;
    _newSettingsFile citext;
    _skipInfo citext;
    _continue boolean;
    _retryJob boolean;
    _setProcessorAutoRecover boolean;
    _settingsFileChanged boolean;
    _retryCount int;
    _matchIndex int;
    _matchIndexLast int;
    _poundIndex int;
    _retryText citext;
    _retryCountText citext;
    _resetReason citext;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------
        --

        _windowHours := Coalesce(_windowHours, 12);
        If _windowHours < 2 Then
            _windowHours := 2;
        End If;

        _infoOnly := Coalesce(_infoOnly, false);

        _stepToolFilter := Coalesce(_stepToolFilter, '');

        _message := '';

        CREATE TEMP TABLE Tmp_FailedJobs (
            Job int NOT NULL,
            Step_Number int NOT NULL,
            Step_Tool text NOT NULL,
            Job_State int NOT NULL,
            Step_State int NOT NULL,
            Processor text NOT NULL,
            Comment text NOT NULL,
            Job_Finish timestamp Null,
            Settings_File text NOT NULL,
            AnalysisTool text NOT NULL,
            NewJobState int null,
            NewStepState int null,
            NewComment text null,
            NewSettingsFile text null,
            ResetJob int not null default 0,
            RerunAllJobSteps boolean not null default false
        )

        ---------------------------------------------------
        -- Populate a temporary table with jobs that failed within the last _windowHours hours
        ---------------------------------------------------
        --
        INSERT INTO Tmp_FailedJobs (job, Step_Number, Step_Tool, Job_State, Step_State,
           Processor, comment, Job_Finish, Settings_File, AnalysisTool)
        SELECT J.job AS Job,
               JS.Step_Number,
               JS.Step_Tool,
               J.job_state_id AS Job_State,
               JS.State AS Step_State,
               Coalesce(JS.Processor, '') AS Processor,
               Coalesce(J.comment, '') AS Comment,
               Coalesce(J.finish, J.start) as Job_Finish,
               J.settings_file_name,
               Tool.analysis_tool
        FROM t_analysis_job J
             INNER JOIN sw.T_Job_Steps JS
         ON J.job = JS.job
             INNER JOIN t_analysis_tool Tool
               ON J.analysis_tool_id = Tool.analysis_tool_id
        WHERE J.job_state_id = 5 AND
              Coalesce(J.finish, J.start) >= CURRENT_TIMESTAMP - make_interval(hours => _windowHours) AND
              JS.State = 6 AND
              (_stepToolFilter = '' OR JS.Step_Tool = _stepToolFilter);

        ---------------------------------------------------
        -- Next look for job steps that are running, but started over 60 minutes ago and for which
        -- the processor is reporting Stopped_Error in T_Processor_Status
        ---------------------------------------------------
        --
        INSERT INTO Tmp_FailedJobs (job, Step_Number, Step_Tool, Job_State, Step_State,
                                     Processor, comment, Job_Finish, Settings_File, AnalysisTool)
        SELECT J.job AS Job,
               JS.Step_Number,
               JS.Step_Tool,
               J.job_state_id AS Job_State,
               JS.State AS Step_State,
               Coalesce(JS.Processor, '') AS Processor,
               Coalesce(J.comment, '') AS Comment,
               Coalesce(J.finish, J.start) as Job_Finish,
               J.settings_file_name,
               Tool.analysis_tool
        FROM t_analysis_job J
             INNER JOIN sw.T_Job_Steps JS
               ON J.job = JS.job
             INNER JOIN sw.T_Processor_Status ProcStatus
               ON JS.Processor = ProcStatus.Processor_Name
             INNER JOIN t_analysis_tool Tool
               ON J.analysis_tool_id = Tool.analysis_tool_id
        WHERE J.job_state_id = 2 AND
              JS.State = 4 AND
              ProcStatus.Mgr_Status = 'Stopped Error' AND
              JS.start <= CURRENT_TIMESTAMP - INTERVAL '1 hour' AND
              ProcStatus.Status_Date > CURRENT_TIMESTAMP - INTERVAL '30 minutes';

        If Exists (SELECT * FROM Tmp_FailedJobs) Then

            -- Step through the jobs and reset them if appropriate

            FOR _jobInfo IN
                SELECT Job,
                       Step_Number,
                       Step_Tool,                -- Step tool name
                       Job_State,
                       Step_State,
                       Processor,
                       Comment,
                       Settings_File,
                       AnalysisTool        -- Overall Job Analysis Tool Name
                FROM Tmp_FailedJobs
                ORDER BY Job
            LOOP

                _retryJob := false;
                _retryCount := ;
                _setProcessorAutoRecover := false;
                _settingsFileChanged := false;
                _newSettingsFile := '';
                _skipInfo := '';

                -- Examine the comment to determine if we've retried this job before
                -- Need to find the last instance of '(retry'

                _matchIndexLast := 0;
                _matchIndex := 999;
                WHILE _matchIndex > 0
                LOOP
                    _matchIndex := Position('(retry', _comment In _matchIndexLast+1);
                    If _matchIndex > 0 Then
                        _matchIndexLast := _matchIndex;
                    End If;
                END LOOP;
                _matchIndex := _matchIndexLast;

                If _matchIndex = 0 Then
                    -- Comment does not contain '(retry'
                    _newComment := _comment;

                    If _newComment LIKE '%;%' Then
                        -- Comment contains a semicolon
                        -- Remove the text after the semicolon
                        _matchIndex := Position(';' In _newComment);
                        If _matchIndex > 1 Then
                            _newComment := SubString(_newComment, 1, _matchIndex-1);
                        Else
                            _newComment := '';
                        End If;
                    End If;
                Else
                    -- Comment contains '(retry'

                    If _matchIndex > 1 Then
                        _newComment := SubString(_comment, 1, _matchIndex-1);
                    Else
                        _newComment := '';
                    End If;

                    -- Determine the number of times the job has been retried
                    _retryCount := 1;
                    _retryText := SubString(_comment, _matchIndex, char_length(_comment));

                    -- Find the closing parenthesis
                    _matchIndex := Position(')' In _retryText);
                    If _matchIndex > 0 Then
                        _poundIndex := Position('#' In _retryText);

                        If _poundIndex > 0 Then
                            If _matchIndex - _poundIndex - 1 > 0 Then
                                _retryCountText := SubString(_retryText, _poundIndex+1, _matchIndex - _poundIndex - 1);
                                _retryCount := Coalesce(public.try_cast(_retryCountText, null::int), _retryCount);
                            End If;
                        End If;
                    End If;
                End If;

                If _stepState = 6 Then
                -- <failedJob>
                    -- Job step is failed and overall job is failed

                    If Not _retryJob And _stepTool IN ('Decon2LS', 'MSGF', 'Bruker_DA_Export') And _retryCount < 2 Then
                        _retryJob := true;
                    End If;

                    If Not _retryJob And _stepTool = 'ICR2LS' And _retryCount < 15 Then
                        _retryJob := true;
                    End If;

                    If Not _retryJob And _stepTool = 'DataExtractor' And Not _comment Like '%have a mass error over%' And _retryCount < 2 Then
                        _retryJob := true;
                    End If;

                    If Not _retryJob And _stepTool IN ('Sequest', 'MSGFPlus', 'XTandem', 'MSAlign') And _comment Like '%Exception generating OrgDb file%' And _retryCount < 2 Then
                        _retryJob := true;
                    End If;

                    If Not _retryJob And
                       (_stepTool LIKE 'MSGFPlus%' OR _stepTool = 'DTA_Refinery') And
                       (_comment Like '%None of the spectra are centroided; unable to process%' OR
                        _comment Like '%skipped % of the spectra because they did not appear centroided%' OR
                        _comment Like '%skip % of the spectra because they do not appear centroided%'
                       ) Then -- <nonCentroided>

                        -- MSGF+ job that failed due to too many profile-mode spectra
                        -- Auto-change the SettingsFile to a MSConvert version if possible.

                        _newSettingsFile := '';

                        SELECT msgfplus_auto_centroid
                        INTO _newSettingsFile
                        FROM t_settings_files
                        WHERE analysis_tool = _analysisTool AND
                              file_name = _settingsFile AND
                              Coalesce(msgfplus_auto_centroid, '') <> ''

                        If FOUND Then

                            _retryJob := true;
                            _settingsFileChanged := true;

                            If _comment Like '%None of the spectra are centroided; unable to process%' Then
                                _skipInfo := 'None of the spectra are centroided';
                            Else
                                _matchIndex := Position('MSGF+ skipped' In _comment);
                                If _matchIndex > 0 Then
                                    _skipInfo := SubString(_comment, _matchIndex, char_length(_comment));
                                Else

                                    _matchIndex := Position('MSGF+ will likely skip' In _comment);
                                    If _matchIndex > 0 Then
                                        _skipInfo := SubString(_comment, _matchIndex, char_length(_comment));
                                    Else
                                        _skipInfo := 'MSGF+ skipped ??% of the spectra because they did not appear centroided';
                                    End If;

                                End If;
                            End If;
                        End If;
                    End If; -- </nonCentroided>

                    If Not _retryJob And
                       _stepTool IN ('MSGFPlus', 'MSGFPlus_IMS', 'MSAlign', 'MSAlign_Histone', 'DataExtractor', 'Mz_Refinery') And
                       _comment Like '%Not enough free memory%' And
                       _retryCount < 10 Then

                        RAISE INFO 'Reset %', _job;
                        _retryJob := true;
                    End If;

                    If Not _retryJob And _retryCount < 5 Then
                        -- Check for file copy errors from the Archive
                        If _comment Like '%Error copying file \\adms%' Or Then
                           _comment Like '%File not found: \\adms%' Or;
                        End If;
                           _comment Like '%Error copying %dta.zip%' Or
                           _comment Like '%Source dataset file file not found%'
                            _retryJob := true;

                    End If;

                    If Not _retryJob And _retryCount < 5 Then
                        -- Check for network errors
                        If _comment Like '%unexpected network error occurred%' Then
                            _retryJob := true;
                        End If;

                    End If;
                End If; -- </failedJob>

                If _stepState = 4 Then
                    -- Job is still running, but processor has an error (likely a flagfile)
                    -- This likely indicates an out-of-memory error

                    If _stepTool In ('DataExtractor', 'MSGF') And _retryCount < 5 Then
                        _retryJob := true;
                    End If;

                    If _retryJob Then
                        _setProcessorAutoRecover := true;
                    End If;
                End If;

                If _retryJob Then   -- <retryJob>
                    _newComment := RTrim(_newComment);

                    If _settingsFileChanged Then
                        -- Note: do not append a semicolon because if the job fails again in the future, the text after the semicolon may get auto-removed
                        If char_length(_newComment) > 0 Then
                            _newComment := _newComment || ', ';
                        End If;

                        _newComment := _newComment || 'Auto-switched settings file from ' || _settingsFile || ' (' || _skipInfo || ')';
                    Else
                        If char_length(_newComment) > 0 Then
                            _newComment := _newComment || ' ';
                        End If;

                        _newComment := _newComment || '(retry ' || _stepTool;

                        _retryCount := _retryCount + 1;
                        If _retryCount = 1 Then
                            _newComment := _newComment || ')';
                        Else
                            _newComment := format('%s #%s)', _newComment, _retryCount);
                        End If;
                    End If;

                    If _stepState = 6 Then
                        _newJobState := 1;

                        UPDATE Tmp_FailedJobs
                        SET NewJobState = _newJobState,
                            NewStepState = _stepState,
                            NewComment = _newComment,
                            ResetJob = 1,
                            NewSettingsFile = _newSettingsFile,
                            RerunAllJobSteps = _settingsFileChanged
                        WHERE Job = _job

                        _resetReason := 'job step failed in the last ' || _windowHours::text || ' hours';
                    End If;

                    If _stepState = 4 Then
                        _newJobState := _jobState;

                        UPDATE Tmp_FailedJobs
                        SET NewJobState = _newJobState,
                            NewStepState = 2,
                            NewComment = _newComment,
                           ResetJob = 1
                        WHERE Job = _job

                        If Not _infoOnly Then
                            -- Reset the step back to state 2=Enabled
                            UPDATE sw.T_Job_Steps
                            SET State = 2
                            WHERE Job = _job And Step_Number = _step
                        End If;

                        _resetReason := 'job step in progress but manager reports "Stopped Error"';
                    End If;

                    If Not _infoOnly Then

                        If _settingsFileChanged Then
                            -- The settings file for this job has changed, thus we must re-generate the job in the pipeline DB
                            -- Note that deletes auto-cascade from T_Jobs to T_Job_Steps, T_Job_Parameters, and T_Job_Step_Dependencies
                            --
                            DELETE FROM sw.T_Jobs
                            WHERE Job = _job

                            UPDATE t_analysis_job
                            SET settings_file_name = _newSettingsFile
                            WHERE job = _job

                        End If;

                        -- Update the JobState and comment in t_analysis_job
                        UPDATE t_analysis_job
                        SET job_state_id = _newJobState,
                            comment = _newComment
                        WHERE job = _job

                        _logMessage := format('Auto-reset job %s; %s; %s', _job, _resetReason, _newComment);

                        Call post_log_entry ('Warning', _logMessage, 'AutoResetFailedJobs');
                    End If;

                    If _setProcessorAutoRecover Then
                        If Not _infoOnly Then
                            _logMessage := format('%s reports "Stopped Error"; setting ManagerErrorCleanupMode to 1 in the Manager_Control DB', _processor);

                            Call post_log_entry ('Warning', _logMessage, 'AutoResetFailedJobs');

                            Call mc.set_manager_error_cleanup_mode ( _managerList => _processor, _cleanupMode => 1);
                        Else
                            RAISE INFO '%', 'Call mc.set_manager_error_cleanup_mode (_managerList = _processor, _cleanupMode = 1)';
                        End If;
                    End If;

                End If;     -- </retryJob>
            END LOOP; -- </c>

            If _infoOnly Then

                -- ToDo: Update this to use RAISE INFO
                --
                SELECT *;
                FROM Tmp_FailedJobs
                ORDER BY Job
            End If;

        End If; -- </a>

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

COMMENT ON PROCEDURE public.auto_reset_failed_jobs IS 'AutoResetFailedJobs';