--
-- Name: add_update_analysis_job(text, integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean, boolean, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_analysis_job(IN _datasetname text, IN _priority integer, IN _toolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _organismdbname text, IN _ownerusername text, IN _comment text, IN _specialprocessing text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _statename text, INOUT _job text DEFAULT '0'::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _preventduplicatejobs boolean DEFAULT false, IN _preventduplicatesignoresnoexport boolean DEFAULT true, IN _specialprocessingwaituntilready boolean DEFAULT false, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an analysis job in t_analysis_job
**
**  Arguments:
**    _datasetName                  Dataset name
**    _priority                     Job priority; suggested default is 3
**    _toolName                     Analysis tool name
**    _paramFileName                Parameter file name
**    _settingsFileName             Settings file name
**    _organismName                 Organism name
**    _protCollNameList             Comma-separated list of protein collection names
**    _protCollOptionsList          Protein collection options list
**    _organismDBName               Organism DB name (legacy FASTA file); should be 'na' if using a protein collection list
**    _ownerUsername                Username of the job owner
**    _comment                      Comment
**    _specialProcessing            Special processing parameters
**    _associatedProcessorGroup     Processor group
**    _propagationMode              Propagation mode, aka export mode; should be 'Export' or 'No Export'
**    _stateName                    Job state when updating or resetting the job. When _mode is 'add', if this is 'hold' or 'holding', the job will be created and placed in state holding; see also T_Analysis_Job_Request_State
**    _job                          Input/Output: New job number if adding a job; existing job number if updating or resetting a job (number as text for compatibility with the web page)
**    _mode                         Mode: typically 'add', 'update', or 'reset'; use 'previewadd' or 'previewupdate' to validate the parameters but not actually make the change (used by the Spreadsheet loader page)
**    _message                      Output: status message
**    _returnCode                   Output: return code
**    _callingUser                  Username of the calling user
**    _preventDuplicateJobs                 Only used if _mode is 'add'; when true, ignores jobs with state 5 (failed), 13 (inactive) or 14 (no export)
**    _preventDuplicatesIgnoresNoExport     When true, ignores jobs with state 5 or 13, but updates jobs with state 14
**    _specialProcessingWaitUntilReady      When true, sets the job state to 19="Special Proc. Waiting" when the _specialProcessing parameter is not empty
**    _infoOnly                             When true, preview updates
**
**  Auth:   grk
**  Date:   01/10/2002
**          01/30/2004 fixed @@identity problem with insert
**          05/06/2004 grk - Allowed analysis processor preset
**          11/05/2004 grk - Added parameter for assigned processor
**                           removed batchID parameter
**          02/10/2005 grk - Fixed update to include assigned processor
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased size of param file name
**          04/07/2006 grk - Revised validation logic to use Validate_Analysis_Job_Parameters
**          04/11/2006 grk - Added state field and reset mode
**          04/21/2006 grk - Reset now allowed even if job not in 'new' state
**          06/01/2006 grk - Added code to handle '(default)' organism
**          11/30/2006 mem - Added column Dataset_Type to Tmp_DatasetInfo (Ticket #335)
**          12/20/2006 mem - Added column dataset_rating_id to Tmp_DatasetInfo (Ticket #339)
**          01/13/2007 grk - Switched to organism ID instead of organism name (Ticket #360)
**          02/07/2007 grk - Eliminated 'Spectra Required' states (Ticket #249)
**          02/15/2007 grk - Added associated processor group (Ticket #383)
**          02/15/2007 grk - Added propagation mode (Ticket #366)
**          02/21/2007 grk - Removed _assignedProcessor (Ticket #383)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to Tmp_DatasetInfo
**          02/22/2008 mem - Updated to allow updating jobs in state 'holding'
**                         - Updated to convert _comment and _associatedProcessorGroup to '' if null (Ticket #648)
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644, http://prismtrac.pnl.gov/trac/ticket/644)
**          04/22/2008 mem - Updated to call Alter_Entered_By_User when updating T_Analysis_Job_Processor_Group_Associations
**          09/12/2008 mem - Now passing _paramFileName and _settingsFileName ByRef to Validate_Analysis_Job_Parameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          02/27/2009 mem - Expanded _comment to varchar(512)
**          04/15/2009 grk - Handles wildcard DTA folder name in comment field (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          08/05/2009 grk - Assign job number from separate table (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          05/05/2010 mem - Now passing _ownerUsername to Validate_Analysis_Job_Parameters as input/output
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          08/18/2010 mem - Now allowing job update if state is Failed, in addition to New or Holding
**          08/19/2010 grk - Use try-catch for error handling
**          08/26/2010 mem - Added parameter _preventDuplicateJobs
**          03/29/2011 grk - Added _specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          04/26/2011 mem - Added parameter _preventDuplicatesIgnoresNoExport
**          05/24/2011 mem - Now populating column dataset_unreviewed when adding new jobs
**          05/03/2012 mem - Added parameter _specialProcessingWaitUntilReady
**          06/12/2012 mem - Removed unused code related to Archive State in Tmp_DatasetInfo
**          09/18/2012 mem - Now clearing _organismDBName if _mode='reset' and we're searching a protein collection
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          01/04/2013 mem - Now ignoring _organismName, _protCollNameList, _protCollOptionsList, and _organismDBName for analysis tools that do not use protein collections (AJT_orgDbReqd = 0)
**          04/02/2013 mem - Now updating _msg if it is blank yet _result is non-zero
**          03/13/2014 mem - Now passing _job to Validate_Analysis_Job_Parameters
**          04/08/2015 mem - Now passing _autoUpdateSettingsFileToCentroided and _warning to Validate_Analysis_Job_Parameters
**          05/28/2015 mem - No longer creating processor group entries (thus _associatedProcessorGroup is ignored)
**          06/24/2015 mem - Added parameter _infoOnly
**          07/21/2015 mem - Now allowing job comment and Export Mode to be changed
**          01/20/2016 mem - Update comments
**          02/15/2016 mem - Re-enabled handling of _associatedProcessorGroup
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Expand error messages
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/09/2017 mem - Add support for state 13 (inactive)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/09/2017 mem - Allow job state to be changed from Complete (state 4) to No Export (state 14) if _propagationMode is 1 (aka 'No Export')
**          12/06/2017 mem - Set _allowNewDatasets to false when calling Validate_Analysis_Job_Parameters
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          09/05/2018 mem - When _mode is 'add', if _state is 'hold' or 'holding', create the job, but put it on hold (state 8)
**          06/30/2022 mem - Rename parameter file argument
**          07/29/2022 mem - Assure that the parameter file and settings file names are not null
**          07/27/2023 mem - Update message sent to get_new_job_id()
**          09/06/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _alterEnteredByRequired boolean := false;
    _msg text;
    _batchID int := 0;
    _logErrors boolean := false;
    _jobID int := 0;
    _currentStateID int := 0;
    _propMode int;
    _currentStateName citext;
    _currentComment citext;
    _currentExportMode int;
    _gid int := 0;
    _userID int;
    _analysisToolID int;
    _organismID int;
    _warning text := '';
    _datasetID int;
    _existingJobCount int := 0;
    _existingMatchingJob int := 0;
    _datasetUnreviewed int := 0;
    _newJobNum int;
    _newStateID int := 1;
    _updateStateID int;
    _pgaAssocID int := 0;
    _logMessage text;
    _alterEnteredByMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _currentLocation text := 'Start';
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _paramFileName                    := Trim(Coalesce(_paramFileName, ''));
    _settingsFileName                 := Trim(Coalesce(_settingsFileName, ''));
    _comment                          := Trim(Coalesce(_comment, ''));
    _associatedProcessorGroup         := Trim(Coalesce(_associatedProcessorGroup, ''));
    _callingUser                      := Trim(Coalesce(_callingUser, ''));
    _preventDuplicateJobs             := Coalesce(_preventDuplicateJobs, false);
    _preventDuplicatesIgnoresNoExport := Coalesce(_preventDuplicatesIgnoresNoExport, true);
    _infoOnly                         := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates and resets)
        ---------------------------------------------------

        If _mode = 'update' Or _mode = 'reset' Then
            _currentLocation := 'Check for non-existent entry';

            -- Cannot update a non-existent entry
            --
            SELECT job,
                   job_state_id
            INTO _jobID, _currentStateID
            FROM t_analysis_job
            WHERE job = public.try_cast(_job, 0);

            If Not FOUND Then
                _msg := format('Cannot update: Analysis Job %s is not in database', _job);

                If _infoOnly Then
                    RAISE WARNING '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;

        End If;

        ---------------------------------------------------
        -- Resolve propagation mode
        ---------------------------------------------------

        _currentLocation := 'Resolve propagation mode';

        _propMode := CASE _propagationMode::citext
                         WHEN 'Export' THEN 0
                         WHEN 'No Export' THEN 1
                         ELSE 0
                     END;

        If _mode = 'update' Then
            _currentLocation := 'Validate settings when _mode is "update"';

            -- Changes are typically only allowed to jobs in 'new', 'failed', or 'holding' state
            -- However, we do allow the job comment or export mode to be updated

            If _currentStateID <> 4 And _stateName::citext = 'Complete' Then
                SELECT AJS.job_state
                INTO _currentStateName
                FROM t_analysis_job J
                     INNER JOIN t_analysis_job_state AJS
                       ON J.job_state_id = AJS.job_state_id
                WHERE J.job = _jobID;

                _msg := format('State for Analysis Job %s cannot be changed from "%s" to "Complete"', _job, _currentStateName);

                If _infoOnly Then
                    RAISE WARNING '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;

            If Not _currentStateID In (1, 5, 8, 19) Then

                -- Allow the job comment and Export Mode to be updated

                SELECT AJS.job_state,
                       Coalesce(J.comment, ''),
                       Coalesce(J.propagation_mode, 0)
                INTO _currentStateName, _currentComment, _currentExportMode
                FROM t_analysis_job J
                     INNER JOIN t_analysis_job_state AJS
                       ON J.job_state_id = AJS.job_state_id
                WHERE J.job = _jobID;

                If _comment::citext IS DISTINCT FROM _currentComment Or
                   _propMode IS DISTINCT FROM _currentExportMode Or
                   _currentStateName::citext = 'Complete' And _stateName::citext = 'No export' Then

                    If Not _infoOnly Then
                        UPDATE t_analysis_job
                        SET comment = _comment,
                            propagation_mode = _propMode
                        WHERE job = _jobID;
                    End If;

                    If _comment::citext IS DISTINCT FROM _currentComment And _propMode IS DISTINCT FROM _currentExportMode Then
                        _message := 'Updated job comment and export mode';
                    End If;

                    If _message = '' And _comment::citext IS DISTINCT FROM _currentComment Then
                        _message := 'Updated job comment';
                    End If;

                    If _message = '' And _propMode <> _currentExportMode Then
                        _message := 'Updated export mode';
                    End If;

                    If _stateName::citext IS DISTINCT FROM _currentStateName Then
                        If _propMode = 1 And _currentStateName = 'Complete' And _stateName::citext = 'No export' Then
                            If Not _infoOnly Then
                                UPDATE t_analysis_job
                                SET job_state_id = 14
                                WHERE job = _jobID;
                            End If;

                            _message := public.append_to_text(_message, 'set job state to "No export"', _delimiter => '; ', _maxlength => 512);
                        Else
                            _msg := format('job state cannot be changed from %s to %s', _currentStateName, _stateName);
                            _message := public.append_to_text(_message, _msg, _delimiter => '; ', _maxlength => 512);

                            If _propagationMode::citext = 'Export' And _stateName::citext = 'No export' Then
                                -- Job propagation mode is Export (0) but user wants to set the state to No export
                                _message := public.append_to_text(_message, 'to make this change, set the Export Mode to "No Export"', _delimiter => '; ', _maxlength => 512);
                            End If;
                        End If;
                    End If;

                    If _infoOnly Then
                        _message := format('Preview: %s', _message);
                    End If;

                    RETURN;
                End If;

                _msg := format('Cannot update: Analysis Job %s is not in "new", "holding", or "failed" state', _job);

                If _infoOnly Then
                    RAISE WARNING '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        If _mode = 'reset' Then
            _currentLocation := 'Validate settings when _mode is "reset"';

            If _organismDBName::citext SIMILAR TO 'ID[_]%' And Not Coalesce(_protCollNameList, '')::citext In ('', 'na') Then
                -- We are resetting a job that used a protein collection; clear _organismDBName
                _organismDBName := '';
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve processor group ID
        ---------------------------------------------------

        _currentLocation := 'Resolve processor group ID';

        If _associatedProcessorGroup <> '' Then
            SELECT group_id
            INTO _gid
            FROM t_analysis_job_processor_group
            WHERE group_name = _associatedProcessorGroup::citext;

            If Not FOUND Then
                RAISE EXCEPTION 'Processor group "%" not found', _associatedProcessorGroup;
            End If;
        End If;

        ---------------------------------------------------
        -- Create temporary table to hold the dataset details
        -- This table will only have one row
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name citext,
            Dataset_ID int NULL,
            Instrument_Class text NULL,
            Dataset_State_ID int NULL,
            Archive_State_ID int NULL,
            Dataset_Type text NULL,
            Dataset_Rating_ID smallint NULL
        );

        ---------------------------------------------------
        -- Add dataset to table
        ---------------------------------------------------

        INSERT INTO Tmp_DatasetInfo ( Dataset_Name )
        VALUES (_datasetName);

        ---------------------------------------------------
        -- Handle '(default)' organism
        ---------------------------------------------------

        If _organismName::citext = '(default)' Then
            SELECT t_organisms.organism
            INTO _organismName
            FROM t_experiments INNER JOIN
                 t_dataset ON t_experiments.exp_id = t_dataset.exp_id INNER JOIN
                 t_organisms ON t_experiments.organism_id = t_organisms.organism_id
            WHERE t_dataset.dataset = _datasetName::citext;

            If Not FOUND Then
                _organismName := '(default)';
            End If;
        End If;

        ---------------------------------------------------
        -- Validate job parameters
        ---------------------------------------------------

        _currentLocation := 'Validate job parameters';

        CALL public.validate_analysis_job_parameters (
                                _toolName => _toolName,
                                _paramFileName => _paramFileName,               -- Output
                                _settingsFileName => _settingsFileName,         -- Output
                                _organismDBName => _organismDBName,             -- Output
                                _organismName => _organismName,
                                _protCollNameList => _protCollNameList,         -- Output
                                _protCollOptionsList => _protCollOptionsList,   -- Output
                                _ownerUsername => _ownerUsername,               -- Output
                                _mode => _mode,
                                _userID => _userID,                             -- Output
                                _analysisToolID => _analysisToolID,             -- Output
                                _organismID => _organismID,                     -- Output
                                _job => _jobID,
                                _autoRemoveNotReleasedDatasets => false,
                                _autoUpdateSettingsFileToCentroided => true,
                                _allowNewDatasets => false,
                                _warning => _warning,                           -- Output
                                _priority => _priority,                         -- Output
                                _showDebugMessages => _infoOnly,
                                _message => _msg,                               -- Output
                                _returnCode => _returnCode);                    -- Output

        If _returnCode <> '' Then
            If Coalesce(_msg, '') = '' Then
                _msg := format('Error code %s returned by validate_analysis_job_parameters', _returnCode);
            End If;

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            RAISE EXCEPTION '%', _msg;
        End If;

        If Coalesce(_warning, '') <> '' Then
            _comment := public.append_to_text(_comment, _warning);

            If _mode Like 'preview%' Then
                _message := _warning;
            End If;

        End If;

        _logErrors := true;

        _formatSpecifier := '%-13s %-10s %-8s %-20s %-16s %-60s %-50s %-50s %-80s %-40s %-11s %-10s %-40s %-10s %-8s %-8s %-20s %-20s %-16s %-18s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Mode',
                            'Job',
                            'Priority',
                            'Created',
                            'Analysis_Tool_ID',
                            'Param_File_Name',
                            'Settings_File_Name',
                            'Organism_DB_Name',
                            'Protein_Collection_List',
                            'Protein_Options_List',
                            'Organism_ID',
                            'Dataset_ID',
                            'Comment',
                            'Owner',
                            'Batch_ID',
                            'State_ID',
                            'Start',
                            'Finish',
                            'Propagation_Mode',
                            'Dataset_Unreviewed',
                            'Special_Processing'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------',
                                     '----------',
                                     '--------',
                                     '--------------------',
                                     '----------------',
                                     '------------------------------------------------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '----------------------------------------',
                                     '-----------',
                                     '----------',
                                     '----------------------------------------',
                                     '----------',
                                     '--------',
                                     '--------',
                                     '--------------------',
                                     '--------------------',
                                     '----------------',
                                     '------------------',
                                     '--------------------'
                                    );

        ---------------------------------------------------
        -- Lookup the Dataset ID
        ---------------------------------------------------

        SELECT Dataset_ID
        INTO _datasetID
        FROM Tmp_DatasetInfo
        LIMIT 1;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            _currentLocation := 'Prepare to add a new job';

            If _preventDuplicateJobs Then
                ---------------------------------------------------
                -- See if an existing, matching job already exists
                -- If it does, do not add another job
                ---------------------------------------------------

                _currentLocation := 'Check for an existing, matching job';

                SELECT COUNT(AJ.job),
                       MAX(AJ.job)
                INTO _existingJobCount, _existingMatchingJob
                FROM t_dataset DS INNER JOIN
                     t_analysis_job AJ ON AJ.dataset_id = DS.dataset_id INNER JOIN
                     t_analysis_tool AJT ON AJ.analysis_tool_id = AJT.analysis_tool_id INNER JOIN
                     t_organisms Org ON AJ.organism_id = Org.organism_id INNER JOIN
                     -- t_analysis_job_state AJS ON AJ.job_state_id = AJS.job_state_id INNER JOIN
                     Tmp_DatasetInfo ON Tmp_DatasetInfo.dataset_name = DS.dataset
                WHERE ( _preventDuplicatesIgnoresNoExport     AND NOT AJ.job_state_id IN (5, 13, 14) OR
                        Not _preventDuplicatesIgnoresNoExport AND AJ.job_state_id <> 5
                      ) AND
                      AJT.analysis_tool = _toolName::citext AND
                      AJ.param_file_name = _paramFileName::citext AND
                      AJ.settings_file_name = _settingsFileName::citext AND
                      (
                        ( _protCollNameList::citext = 'na' AND
                          AJ.organism_db_name = _organismDBName::citext AND
                          Org.organism = Coalesce(_organismName::citext, Org.organism)
                        ) OR
                        ( _protCollNameList::citext <> 'na' AND
                          AJ.protein_collection_list = Coalesce(_protCollNameList::citext, AJ.protein_collection_list) AND
                           AJ.protein_options_list = Coalesce(_protCollOptionsList::citext, AJ.protein_options_list)
                        ) OR
                        ( AJT.org_db_required = 0 )
                      );

                If _existingJobCount > 0 Then
                    _message := format('Job not created since duplicate job exists: %s', _existingMatchingJob);

                    If _infoOnly Then
                        RAISE INFO '%', _message;
                    End If;

                    -- Do not change this error code since procedure create_predefined_analysis_jobs
                    -- checks for error code 'U5250' (previously 52500)
                    _returnCode := 'U5250'

                    RETURN;
                End If;
            End If;

            ---------------------------------------------------
            -- Check whether the dataset is unreviewed
            ---------------------------------------------------

            _currentLocation := 'Lookup dataset rating';

            If Exists (SELECT dataset_id FROM t_dataset WHERE dataset_id = _datasetID AND dataset_rating_id = -10) Then
                _datasetUnreviewed := 1;
            End If;

            ---------------------------------------------------
            -- Get ID for new job
            ---------------------------------------------------

            _currentLocation := 'Get ID for new job';

            _jobID := public.get_new_job_id('Created in t_analysis_job', _infoOnly);

            If _jobID = 0 Then
                _msg := 'Failed to get valid new job ID';
                If _infoOnly Then
                    RAISE INFO '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;

            _job := _jobID::text;

            If Coalesce(_specialProcessingWaitUntilReady, false) And Coalesce(_specialProcessing, '') <> '' Then
                _newStateID := 19;
            End If;

            If _stateName::citext Like 'hold%' Then
                _newStateID := 8;
            End If;

            If _infoOnly Then
                _currentLocation := 'Preview adding a new job';

                RAISE INFO '';
                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN

                SELECT format('Preview ', _mode) AS Mode,
                       _jobID AS Job,
                       _priority AS Priority,
                       public.timestamp_text(CURRENT_TIMESTAMP) AS Created,
                       _analysisToolID AS AnalysisToolID,
                       _paramFileName AS ParmFileName,
                       _settingsFileName AS SettingsFileName,
                       _organismDBName AS OrganismDBName,
                       _protCollNameList AS ProteinCollectionList,
                       _protCollOptionsList AS ProteinOptionsList,
                       _organismID AS OrganismID,
                       _datasetID AS DatasetID,
                       REPLACE(_comment, '#DatasetNum#', _datasetID::text) AS Comment,
                       _specialProcessing AS SpecialProcessing,
                       _ownerUsername AS Owner,
                       _batchID AS BatchID,
                       _newStateID AS StateID,
                       '' As Start,
                       '' As Finish,
                       _propMode AS PropagationMode,
                       _datasetUnreviewed AS DatasetUnreviewed
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Mode,
                                        _previewData.Job,
                                        _previewData.Priority,
                                        _previewData.Created,
                                        _previewData.AnalysisToolID,
                                        _previewData.ParmFileName,
                                        _previewData.SettingsFileName,
                                        _previewData.OrganismDBName,
                                        _previewData.ProteinCollectionList,
                                        _previewData.ProteinOptionsList,
                                        _previewData.OrganismID,
                                        _previewData.DatasetID,
                                        _previewData.Comment,
                                        _previewData.Owner,
                                        _previewData.BatchID,
                                        _previewData.StateID,
                                        _previewData.Start,
                                        _previewData.Finish,
                                        _previewData.PropagationMode,
                                        _previewData.DatasetUnreviewed,
                                        _previewData.SpecialProcessing
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

                DROP TABLE Tmp_DatasetInfo;
                RETURN;
            End If;

            _currentLocation := 'Add the new job to t_analysis_job';

            INSERT INTO t_analysis_job (
                job,
                priority,
                created,
                analysis_tool_id,
                param_file_name,
                settings_file_name,
                organism_db_name,
                protein_collection_list,
                protein_options_list,
                organism_id,
                dataset_id,
                comment,
                special_processing,
                owner_username,
                batch_id,
                job_state_id,
                propagation_mode,
                dataset_unreviewed
            ) VALUES (
                _jobID,
                _priority,
                CURRENT_TIMESTAMP,
                _analysisToolID,
                _paramFileName,
                _settingsFileName,
                _organismDBName,
                _protCollNameList,
                _protCollOptionsList,
                _organismID,
                _datasetID,
                REPLACE(_comment, '#DatasetNum#', _datasetID::text),
                _specialProcessing,
                _ownerUsername,
                _batchID,
                _newStateID,
                _propMode,
                _datasetUnreviewed
            );

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                CALL public.alter_event_log_entry_user ('public', 5, _jobID, _newStateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Associate job with processor group

            If _gid <> 0 Then
                INSERT INTO t_analysis_job_processor_group_associations ( job, group_id )
                VALUES (_jobID, _gid);
            End If;

            DROP TABLE Tmp_DatasetInfo;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Or _mode = 'reset' Then
            _currentLocation := 'Prepare to update or reset a job';

            -- Resolve state ID according to mode and state name

            If _mode = 'reset' Then
                _updateStateID := 1;
            Else
                SELECT job_state_id
                INTO _updateStateID
                FROM t_analysis_job_state
                WHERE job_state = _stateName::citext;

                If Not FOUND Then
                    _msg := format('State name not recognized: %s', _stateName);
                    If _infoOnly Then
                        RAISE INFO '%', _msg;
                    End If;

                    RAISE EXCEPTION '%', _msg;
                End If;
            End If;

            ---------------------------------------------------
            -- Associate job with processor group
            ---------------------------------------------------

            _currentLocation := 'Lookup the processor group for the existing job';

            -- Is there an existing association between the job
            -- and a processor group?

            SELECT group_id
            INTO _pgaAssocID
            FROM t_analysis_job_processor_group_associations
            WHERE job = _jobID;

            If Not FOUND Then
                _pgaAssocID := 0;
            End If;

            If _infoOnly Then
                _currentLocation := 'Preview updating a job';

                RAISE INFO '';
                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT format('Preview %s', _mode) AS Mode,
                           _jobID AS Job,
                           _priority AS Priority,
                           public.timestamp_text(Created) As Created,
                           _analysisToolID AS AnalysisToolID,
                           _paramFileName AS ParmFileName,
                           _settingsFileName AS SettingsFileName,
                           _organismDBName AS OrganismDBName,
                           _protCollNameList AS ProteinCollectionList,
                           _protCollOptionsList AS ProteinOptionsList,
                           _organismID AS OrganismID,
                           _datasetID AS DatasetID,
                           _comment AS Comment,
                           _specialProcessing AS SpecialProcessing,
                           _ownerUsername AS Owner,
                           batch_id AS BatchID,
                           _updateStateID AS StateID,
                           CASE WHEN _mode <> 'reset' THEN public.timestamp_text(start)  ELSE '' End AS Start,
                           CASE WHEN _mode <> 'reset' THEN public.timestamp_text(finish) ELSE '' End AS Finish,
                           _propMode AS PropagationMode,
                           dataset_unreviewed AS DatasetUnreviewed
                    FROM t_analysis_job
                    WHERE job = _jobID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Mode,
                                        _previewData.Job,
                                        _previewData.Priority,
                                        _previewData.Created,
                                        _previewData.AnalysisToolID,
                                        _previewData.ParmFileName,
                                        _previewData.SettingsFileName,
                                        _previewData.OrganismDBName,
                                        _previewData.ProteinCollectionList,
                                        _previewData.ProteinOptionsList,
                                        _previewData.OrganismID,
                                        _previewData.DatasetID,
                                        _previewData.Comment,
                                        _previewData.Owner,
                                        _previewData.BatchID,
                                        _previewData.StateID,
                                        _previewData.Start,
                                        _previewData.Finish,
                                        _previewData.PropagationMode,
                                        _previewData.DatasetUnreviewed,
                                        _previewData.SpecialProcessing
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

                DROP TABLE Tmp_DatasetInfo;
                RETURN;
            End If;

            ---------------------------------------------------
            -- Update the database
            ---------------------------------------------------

            _currentLocation := format('Update job %s', _jobID);

            UPDATE t_analysis_job
            SET priority = _priority,
                analysis_tool_id = _analysisToolID,
                param_file_name = _paramFileName,
                settings_file_name = _settingsFileName,
                organism_db_name = _organismDBName,
                protein_collection_list = _protCollNameList,
                protein_options_list = _protCollOptionsList,
                organism_id = _organismID,
                dataset_id = _datasetID,
                comment = _comment,
                special_processing = _specialProcessing,
                owner_username = _ownerUsername,
                job_state_id = _updateStateID,
                start  = CASE WHEN _mode <> 'reset' THEN start  ELSE NULL End,
                finish = CASE WHEN _mode <> 'reset' THEN finish ELSE NULL End,
                propagation_mode = _propMode
            WHERE job = _jobID;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                _currentLocation := format('Call alter_event_log_entry_user for job %s', _jobID);

                CALL public.alter_event_log_entry_user ('public', 5, _jobID, _updateStateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Deal with job association with group,
            -- If no group is given, but existing association exists for job, delete it

            If _gid = 0 Then
                _currentLocation := format('Remove job %s from t_analysis_job_processor_group_associations', _jobID);

                DELETE FROM t_analysis_job_processor_group_associations
                WHERE job = _jobID;
            End If;

            -- If group is given, and no association for job exists create one

            If _gid <> 0 and _pgaAssocID = 0 Then
                _currentLocation := format('Add job %s to t_analysis_job_processor_group_associations', _jobID);

                INSERT INTO t_analysis_job_processor_group_associations ( job, group_id )
                VALUES (_jobID, _gid);

                _alterEnteredByRequired := true;
            End If;

            -- If group is given, and an association for job does exist update it

            If _gid <> 0 and _pgaAssocID <> 0 and _pgaAssocID <> _gid Then
                _currentLocation := format('Update info for job %s in t_analysis_job_processor_group_associations', _jobID);

                UPDATE t_analysis_job_processor_group_associations
                SET group_id = _gid,
                    entered = CURRENT_TIMESTAMP,
                    entered_by = session_user
                WHERE job = _jobID;

                _alterEnteredByRequired := true;
            End If;

            If char_length(_callingUser) > 0 And _alterEnteredByRequired Then
                _currentLocation := format('Call alter_entered_by_user for job %s', _jobID);

                -- Call public.alter_entered_by_user
                -- to alter the entered_by field in t_analysis_job_processor_group_associations

                CALL public.alter_entered_by_user ('public', 't_analysis_job_processor_group_associations', 'job', _jobID, _callingUser, _message => _alterEnteredByMessage);
            End If;
        End If;

        DROP TABLE Tmp_DatasetInfo;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Job %s', _exceptionMessage, _job);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);

        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
END
$$;


ALTER PROCEDURE public.add_update_analysis_job(IN _datasetname text, IN _priority integer, IN _toolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _organismdbname text, IN _ownerusername text, IN _comment text, IN _specialprocessing text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _statename text, INOUT _job text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _preventduplicatejobs boolean, IN _preventduplicatesignoresnoexport boolean, IN _specialprocessingwaituntilready boolean, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_analysis_job(IN _datasetname text, IN _priority integer, IN _toolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _organismdbname text, IN _ownerusername text, IN _comment text, IN _specialprocessing text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _statename text, INOUT _job text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _preventduplicatejobs boolean, IN _preventduplicatesignoresnoexport boolean, IN _specialprocessingwaituntilready boolean, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_analysis_job(IN _datasetname text, IN _priority integer, IN _toolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _organismdbname text, IN _ownerusername text, IN _comment text, IN _specialprocessing text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _statename text, INOUT _job text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _preventduplicatejobs boolean, IN _preventduplicatesignoresnoexport boolean, IN _specialprocessingwaituntilready boolean, IN _infoonly boolean) IS 'AddUpdateAnalysisJob';

