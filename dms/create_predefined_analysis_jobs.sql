--
-- Name: create_predefined_analysis_jobs(text, text, text, boolean, boolean, boolean, boolean, text, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.create_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text DEFAULT ''::text, IN _analysistoolnamefilter text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _preventduplicatejobs boolean DEFAULT true, IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _jobscreated integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Schedule analysis jobs for dataset according to defaults
**
**  Arguments:
**    _datasetName                  Dataset name
**    _callingUser                  Username of the calling user
**    _analysisToolNameFilter       Optional: if not blank, only considers predefines that match the given tool name (can contain % as a wildcard)
**    _excludeDatasetsNotReleased   When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _preventDuplicateJobs         When true, will not create new jobs that duplicate old jobs
**    _infoOnly                     When true, preview jobs that would be created
**    _showDebug                    When true, show debug messages
**    _message                      Status message
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
**          12/08/2023 mem - Ported to PostgreSQL
**          12/09/2023 mem - Add parameter _showDebug
**                         - Use append_to_text() to append messages
**          12/13/2023 mem - Do not log an error for return codes 'U6251', 'U6253', and 'U6254' from add_update_analysis_job
**          08/07/2024 mem - Include current location in the exception message
**          08/14/2024 mem - When counting jobs in Tmp_JobsToCreate, ignore rows with an empty dataset name
**                         - Check for empty dataset name when looping through jobs in Tmp_JobsToCreate
**                         - Show additional values when debugging
**
*****************************************************/
DECLARE
    _errorMessage text;
    _newMessage text;
    _logMessage text;
    _jobCount int;
    _createJob boolean;
    _jobFailCount int;
    _jobFailErrorCode text;
    _instrumentClass text;

    _jobInfo record;
    _job text;
    _propagationModeText text;

    _currentLocation text;
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _jobsCreated := 0;
    _jobFailCount := 0;
    _jobFailErrorCode := '';

    _analysisToolNameFilter     := Trim(Coalesce(_analysisToolNameFilter, ''));
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _preventDuplicateJobs       := Coalesce(_preventDuplicateJobs, true);
    _infoOnly                   := Coalesce(_infoOnly, false);
    _showDebug                  := Coalesce(_showDebug, false);

    BEGIN
        _currentLocation := 'Create and populate temp table';

        ---------------------------------------------------
        -- Temporary job holding table for jobs to create
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_JobsToCreate (
            DatasetName text,
            Priority int,
            AnalysisToolName text,
            ParamFileName text,
            SettingsFileName text,
            OrganismName text,
            ProteinCollectionList text,
            ProteinOptionsList text,
            OrganismDBName text,
            OwnerUsername text,
            Comment text,
            PropagationMode smallint,
            SpecialProcessing text,
            ExistingJobCount int,
            Message text,
            ReturnCode text,
            ID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY
        );

        ---------------------------------------------------
        -- Populate the job holding table
        ---------------------------------------------------

        INSERT INTO Tmp_JobsToCreate (
            DatasetName, Priority, AnalysisToolName, ParamFileName, SettingsFileName,
            OrganismName, ProteinCollectionList, ProteinOptionsList, OrganismDBName,
            OwnerUsername, Comment, PropagationMode, SpecialProcessing,
            ExistingJobCount, Message, ReturnCode
        )
        SELECT Trim(Coalesce(dataset, '')), priority, analysis_tool_name, param_file_name, settings_file_name,
               organism_name, protein_collection_list, protein_options_list, organism_db_name,
               owner_username, comment, propagation_mode, special_processing,
               existing_job_count, message, returncode
        FROM public.predefined_analysis_jobs (
                    _datasetName,
                    _raiseErrorMessages => false,
                    _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                    _createJobsForUnreviewedDatasets => true,
                    _analysisToolNameFilter => '');

        _currentLocation := 'Examine ReturnCode in Tmp_JobsToCreate';

        SELECT message, ReturnCode
        INTO _message, _returnCode
        FROM Tmp_JobsToCreate
        WHERE _returnCode <> ''
        LIMIT 1;

        If FOUND Then
            _currentLocation := format('Handle return code %s', _returnCode);

            _errorMessage := format('predefined_analysis_jobs returned error code %s', _returnCode);

            If Not Coalesce(_message, '') = '' Then
                _errorMessage := format('%s; %s', _errorMessage, _message);
            End If;

            If _showDebug Then
                RAISE WARNING '%', _errorMessage;
            End If;

            _message := _errorMessage;
            RAISE EXCEPTION '%', _message;
        End If;

        If _showDebug Then
            SELECT COUNT(*)
            INTO _jobCount
            FROM Tmp_JobsToCreate
            WHERE DatasetName <> '';

            RAISE INFO 'Table Tmp_JobsToCreate has % % for dataset %', _jobCount, check_plural(_jobCount, 'job', 'jobs'), _datasetName;
        End If;

        ---------------------------------------------------
        -- Cycle through the job holding table and make jobs for each entry
        ---------------------------------------------------

        _currentLocation := 'Create pending jobs';

        FOR _jobInfo IN
            SELECT DatasetName,
                   Priority,
                   AnalysisToolName,
                   ParamFileName,
                   SettingsFileName,
                   OrganismName,
                   ProteinCollectionList,
                   ProteinOptionsList,
                   OrganismDBName,
                   OwnerUsername,
                   Comment,
                   PropagationMode,
                   SpecialProcessing,
                   Message,
                   ID
            FROM Tmp_JobsToCreate
            ORDER BY ID
        LOOP
            If _jobInfo.DatasetName = '' Then
                -- No predefined rules were found for this dataset
                -- The Message column will have the details, e.g. No rules found (dataset is unreviewed): Dataset_Name

                If _infoOnly Or _showDebug Then
                    RAISE INFO '%', _jobInfo.Message;
                End If;

                CONTINUE;
            End If;

            If _analysisToolNameFilter = '' Then
                _createJob := true;
            ElsIf _jobInfo.AnalysisToolName ILike _analysisToolNameFilter Then
                _createJob := true;
            Else
                If _showDebug Then
                    RAISE INFO 'Not creating % job because it does not match tool name filter "%"', _jobInfo.AnalysisToolName, _analysisToolNameFilter;
                End If;

                _createJob := false;
            End If;

            If Coalesce(_jobInfo.PropagationMode, 0) = 0 Then
                _propagationModeText := 'Export';
            Else
                _propagationModeText := 'No Export';
            End If;

            If Not _createJob Then
                CONTINUE;
            End If;

            If _infoOnly Or _showDebug Then
                RAISE INFO '';
                RAISE INFO 'Call add_update_analysis_job for';
                RAISE INFO '  dataset:            %', _datasetName;
                RAISE INFO '  tool:               %', _jobInfo.AnalysisToolName;
                RAISE INFO '  param file:         %', _jobInfo.ParamFileName;
                RAISE INFO '  settings file:      %', _jobInfo.SettingsFileName;
                RAISE INFO '  organism:           %', _jobInfo.OrganismName;
                RAISE INFO '  protein collection: %', _jobInfo.ProteinCollectionList;
                RAISE INFO '  protein options:    %', _jobInfo.ProteinOptionsList;
                RAISE INFO '  organism DB:        %', _jobInfo.OrganismDBName;
                RAISE INFO '  owner username:     %', _jobInfo.OwnerUsername;
            End If;

            ---------------------------------------------------
            -- Create the job
            ---------------------------------------------------

            _currentLocation := 'Call add_update_analysis_job';

            CALL public.add_update_analysis_job (
                            _datasetName                      => _datasetName,
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
                            _specialProcessing                => _jobInfo.SpecialProcessing,
                            _associatedProcessorGroup         => '',                        -- Empty string, since processor groups were deprecated in 2015
                            _propagationMode                  => _propagationModeText,
                            _stateName                        => 'new',
                            _job                              => _job,                      -- Output: new job number, as text
                            _mode                             => 'add',
                            _message                          => _newMessage,               -- Output
                            _returnCode                       => _returnCode,               -- Output
                            _callingUser                      => _callingUser,
                            _preventDuplicateJobs             => _preventDuplicateJobs,
                            _preventDuplicatesIgnoresNoExport => false,
                            _specialProcessingWaitUntilReady  => true,
                            _infoOnly                         => _infoOnly,
                            _showDebug                        => _showDebug);

            -- If there was an error creating the job, store it in _message;
            -- otherwise bump the job count

            If _returnCode = '' Then
                If Not _infoOnly Then
                    _jobsCreated := _jobsCreated + 1;
                End If;

                CONTINUE;
            End If;

            _currentLocation := 'Update _message';

            If _message = '' Then
                _message := _newMessage;
            Else
                _message := append_to_text(_message, _newMessage, _delimiter => '; ');
            End If;

            -- Return code 'U5250' means a duplicate job exists; that error can be ignored
            If _returnCode <> 'U5250' Then

                _currentLocation := 'Prepare duplicate job message';

                -- Increment _jobFailCount, but keep trying to create the other predefined jobs for this dataset
                _jobFailCount := _jobFailCount + 1;

                If _jobFailErrorCode = '' Then
                    _jobFailErrorCode := _returnCode;
                End If;

                If Position(_returnCode In _message) = 0 Then
                    -- Append _returnCode to _message
                    _message := format('%s [%s]', _message, _returnCode);
                End If;

                _logMessage := _newMessage;

                If Position(_datasetName In _logMessage) = 0 Then
                    _logMessage := format('%s; Dataset %s,', _logMessage, _datasetName);
                Else
                    _logMessage := format('%s', _logMessage);
                End If;

                _logMessage := format('%s %s', _logMessage, _jobInfo.AnalysisToolName);

                -- Return codes 'U6251', 'U6253', and 'U6254' are warnings from validate_analysis_job_request_datasets and are non-critical errors

                If Not _returnCode In ('U6251', 'U6253', 'U6254') Then
                    _currentLocation := 'Call post_log_entry with duplicate job message';
                    CALL post_log_entry ('Error', _logMessage, 'Create_Predefined_Analysis_Jobs');
                End If;

                If _showDebug Then
                    RAISE WARNING '%', _logMessage;
                End If;
            End If;

        END LOOP;

        ---------------------------------------------------
        -- Construct the summary message
        ---------------------------------------------------

        _currentLocation := 'Construct the summary message';

        _newMessage := format('Created %s %s', _jobsCreated, public.check_plural(_jobsCreated, 'job', 'jobs'));

        If _message <> '' Then
            -- _message might look like this: Dataset rating (-10) does not allow creation of jobs: 47538_Pls_FF_IGT_23_25Aug10_Andromeda_10-07-10
            -- If it does, update _message to remove the dataset name

            _message := Replace(_message, format('does not allow creation of jobs: %s', _datasetName), 'does not allow creation of jobs');

            _newMessage := append_to_text(_newMessage, _message, _delimiter => '; ');
        End If;

        _message := _newMessage;

        If _jobFailCount > 0 Then
            If _jobFailErrorCode <> '' Then
                _returnCode := _jobFailErrorCode;
            Else
                _returnCode := 'U5225';
            End If;
        End If;

        If _showDebug Then
            RAISE INFO '%', _message;
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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_JobsToCreate;
END
$$;


ALTER PROCEDURE public.create_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text, INOUT _jobscreated integer) OWNER TO d3l243;

--
-- Name: PROCEDURE create_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text, INOUT _jobscreated integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.create_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text, INOUT _jobscreated integer) IS 'CreatePredefinedAnalysisJobs';

