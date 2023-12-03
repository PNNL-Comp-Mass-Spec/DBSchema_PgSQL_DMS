--
CREATE OR REPLACE PROCEDURE public.create_predefined_analysis_jobs
(
    _datasetName text,
    _callingUser text = '',
    _analysisToolNameFilter text = '',
    _excludeDatasetsNotReleased boolean = true,
    _preventDuplicateJobs boolean = true,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    INOUT _jobsCreated int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Schedules analysis jobs for dataset according to defaults
**
**  Arguments:
**    _datasetName                  Dataset name
**    _callingUser                  Calling user username
**    _analysisToolNameFilter       Optional: if not blank, only considers predefines that match the given tool name (can contain % as a wildcard)
**    _excludeDatasetsNotReleased   When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _preventDuplicateJobs         When true, will not create new jobs that duplicate old jobs
**    _infoOnly                     When true, preview jobs that would be created
**    _message                      Output message
**    _returnCode                   Return code
**    _jobsCreated                  Output: number of jobs created
**
**  Auth:   grk
**  Date:   06/29/2005 grk - Supersedes procedure ScheduleDefaultAnalyses
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          06/01/2006 grk - Fixed calling sequence to Add_Update_Analysis_Job
**          03/15/2007 mem - Updated call to Add_Update_Analysis_Job (Ticket #394)
**                         - Replaced processor name with associated processor group (Ticket #388)
**          02/29/2008 mem - Added optional parameter _callingUser; If provided, will call alter_event_log_entry_user (Ticket #644)
**          04/11/2008 mem - Now passing _raiseErrorMessages to evaluate_predefined_analysis_rules (predefined_analysis_jobs)
**          05/14/2009 mem - Added parameters _analysisToolNameFilter, _excludeDatasetsNotReleased, and _infoOnly
**          07/22/2009 mem - Improved error reporting for non-zero return values from evaluate_predefined_analysis_rules
**          07/12/2010 mem - Expanded protein Collection fields and variables to varchar(4000)
**          08/26/2010 grk - This was cloned from schedule_predefined_analysis_jobs; added try-catch error handling
**          08/26/2010 mem - Added output parameter _jobsCreated
**          02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**          04/11/2011 mem - Updated call to Add_Update_Analysis_Job
**          04/26/2011 mem - Now sending _preventDuplicatesIgnoresNoExport = 0 to Add_Update_Analysis_Job
**          05/03/2012 mem - Added support for the Special Processing field
**          08/02/2013 mem - Removed extra semicolon in status message
**          06/24/2015 mem - Now passing _infoOnly to Add_Update_Analysis_Job
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/21/2016 mem - Log errors in post_log_entry
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          08/29/2018 mem - Tabs to spaces
**          03/31/2021 mem - Expand _organismName and _organismDBName to varchar(128)
**          06/14/2022 mem - Send procedure name to post_log_entry
**          06/30/2022 mem - Rename parameter file column
**          06/30/2022 mem - Rename parameter file argument
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _errorMessage text;
    _newMessage text;
    _logMessage text;
    _createJob boolean;
    _jobFailCount int := 0;
    _jobFailErrorCode text := '';
    _result int;
    _instrumentClass text;

    _jobInfo record;
    _job text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';
    _jobsCreated := 0;

    _analysisToolNameFilter     := Trim(Coalesce(_analysisToolNameFilter, ''));
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _preventDuplicateJobs       := Coalesce(_preventDuplicateJobs, true);
    _infoOnly                   := Coalesce(_infoOnly, false);

    BEGIN

        ---------------------------------------------------
        -- Temporary job holding table for jobs to create
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_JobsToCreate (
            datasetName text,
            priority text,
            analysisToolName text,
            paramFileName text,
            settingsFileName text,
            organismDBName text,
            organismName text,
            proteinCollectionList text,
            proteinOptionsList text,
            ownerUsername text,
            comment text,
            associatedProcessorGroup text,
            numJobs int,
            propagationMode int,
            specialProcessing text,
            ID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY
        );

        ---------------------------------------------------
        -- Populate the job holding table
        ---------------------------------------------------

        INSERT INTO Tmp_JobsToCreate (
                datasetName, priority, analysisToolName, paramFileName, settingsFileName,
                organismDBName, organismName, proteinCollectionList, proteinOptionsList,
                ownerUsername, comment, associatedProcessorGroup,
                numJobs, propagationMode, specialProcessing)
        SELECT datasetName, priority, analysisToolName, paramFileName, settingsFileName,
               organismDBName, organismName, proteinCollectionList, proteinOptionsList,
               ownerUsername, comment, associatedProcessorGroup,
               numJobs, propagationMode, specialProcessing
        FROM predefined_analysis_jobs (
                    _datasetName,
                    _raiseErrorMessages => false,
                    _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                    _createJobsForUnreviewedDatasets => true,
                    _analysisToolNameFilter => '');

        SELECT message, returncode
        INTO _message, _returnCode
        FROM Tmp_JobsToCreate
        WHERE _returnCode <> '';

        If FOUND Then
            _errorMessage := format('predefined_analysis_jobs returned error code %s', _returnCode);

            If Not Coalesce(_message, '') = '' Then
                _errorMessage := format('%s; %s', _errorMessage, _message);
            End If;

            _message := _errorMessage;
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Cycle through the job holding table and
        -- make jobs for each entry
        ---------------------------------------------------

        _associatedProcessorGroup := '';

        -- Keep track of how many jobs have been scheduled
        --
        _jobsCreated := 0;

        _currID := 0;

        FOR _jobInfo IN
            SELECT priority,
                   analysisToolName,
                   paramFileName,
                   settingsFileName,
                   organismDBName,
                   organismName,
                   proteinCollectionList,
                   proteinOptionsList,
                   ownerUsername
                   comment,
                   associatedProcessorGroup,
                   propagationMode,
                   specialProcessing,
                   ID
            FROM Tmp_JobsToCreate
            ORDER BY ID
        LOOP

            If _analysisToolNameFilter = '' Then
                _createJob := true;
            ElsIf _analysisToolName Like _analysisToolNameFilter Then
                _createJob := true;
            Else
                _createJob := false;
            End If;

            If Coalesce(_propagationMode, 0) = 0 Then
                _propagationModeText := 'Export';
            Else
                _propagationModeText := 'No Export';
            End If;

            If Not _createJob Then
                CONTINUE;
            End If;

            If _infoOnly Then
                RAISE INFO '';
                RAISE INFO 'Call add_update_analysis_job for dataset % and tool %; param file: %; settings file: %'
                            _datasetName, _analysisToolName, Coalesce(_paramFileName, ''), Coalesce(_settingsFileName, '');
            End If;

            ---------------------------------------------------
            -- Create the job
            ---------------------------------------------------

            CALL public.add_update_analysis_job (
                            _datasetName                      => _jobInfo.DatasetName,
                            _priority                         => _jobInfo.Priority,
                            _toolName                         => _jobInfo.AnalysisToolName,
                            _paramFileName                    => _jobInfo.ParamFileName,
                            _settingsFileName                 => _jobInfo.SettingsFileName,
                            _organismName                     => _jobInfo.OrganismName,
                            _protCollNameList                 => _jobInfo.ProteinCollectionList,
                            _protCollOptionsList              => _jobInfo.ProteinOptionsList,
                            _organismDBName                   => _jobInfo.OrganismDBName,
                            _ownerUsername                    => _jobInfo.OwnerUsername,
                            _comment                          => _jobInfo.Comment,
                            _associatedProcessorGroup         => _jobInfo.AssociatedProcessorGroup,
                            _propagationMode                  => _propagationModeText,
                            _stateName                        => 'new',
                            _job                              => _job,              -- Output
                            _mode                             => 'add',
                            _message                          => _newMessage,       -- Output
                            _returnCode                       => _returnCode,       -- Output
                            _callingUser                      => _callingUser,
                            _preventDuplicateJobs             => _preventDuplicateJobs,
                            _preventDuplicatesIgnoresNoExport => false,
                            _specialProcessing                => _jobInfo.SpecialProcessing,
                            _specialProcessingWaitUntilReady  => true,
                            _infoOnly                         => _infoOnly);

            -- If there was an error creating the job, store it in _message
            -- otherwise bump the job count
            --
            If _returnCode = '' Then
                If Not _infoOnly Then
                    _jobsCreated := _jobsCreated + 1;
                End If;

                CONTINUE;
            End If;

            If _message = '' Then
                _message := _newMessage;
            Else
                _message := format('%s; %s', _message, _newMessage);
            End If;

            -- ResultCode U5250 means a duplicate job exists; that error can be ignored
            If _returnCode <> 'U5250' Then

                -- Append the _result ID to _message
                -- Increment _jobFailCount, but keep trying to create the other predefined jobs for this dataset
                _jobFailCount := _jobFailCount + 1;
                If _jobFailErrorCode = '' Then
                    _jobFailErrorCode := _returnCode;
                End If;

                _message := format('%s [%s]', _message, _returnCode);

                _logMessage := _newMessage;

                If Position(_datasetName In _logMessage) = 0 Then
                    _logMessage := format('%s; Dataset %s,', _logMessage, _datasetName)
                Else
                    _logMessage := format('%s;', _logMessage);
                End If;

                _logMessage := format('%s %s', _logMessage, _analysisToolName);

                CALL post_log_entry ('Error', _logMessage, 'Create_Predefined_Analysis_Jobs');

            End If;

        END LOOP;

        ---------------------------------------------------
        -- Construct the summary message
        ---------------------------------------------------

        _newMessage := format('Created %s %s', _jobsCreated, public.check_plural(_jobsCreated, 'job', 'jobs');

        If _message <> '' Then
            -- _message might look like this: Dataset rating (-10) does not allow creation of jobs: 47538_Pls_FF_IGT_23_25Aug10_Andromeda_10-07-10
            -- If it does, update _message to remove the dataset name

            _message := Replace(_message, format('does not allow creation of jobs: %s', _datasetName), 'does not allow creation of jobs');

            _newMessage := format('%s; %s', _newMessage, _message);
        End If;

        _message := _newMessage;

        If _jobFailCount > 0 Then
            If _jobFailErrorCode <> '' Then
                _returnCode := _jobFailErrorCode;
            Else
                _returnCode := 'U5225';
            End If;
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

    DROP TABLE IF EXISTS Tmp_JobsToCreate;
END
$$;

COMMENT ON PROCEDURE public.create_predefined_analysis_jobs IS 'CreatePredefinedAnalysisJobs';
