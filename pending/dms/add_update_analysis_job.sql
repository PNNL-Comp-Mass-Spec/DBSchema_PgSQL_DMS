--
CREATE OR REPLACE PROCEDURE public.add_update_analysis_job
(
    _datasetName text,
    _priority int = 2,
    _toolName text,
    _paramFileName text,
    _settingsFileName text,
    _organismName text,
    _protCollNameList text,
    _protCollOptionsList text,
    _organismDBName text,
    _ownerUsername text,
    _comment text = null,
    _specialProcessing text = null,
    _associatedProcessorGroup text = '',
    _propagationMode text,
    _stateName text,
    INOUT _job text = '0',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _preventDuplicateJobs boolean = false,
    _preventDuplicatesIgnoresNoExport boolean = true,
    _specialProcessingWaitUntilReady boolean = false,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new analysis job to job table
**
**  Arguments:
**    _associatedProcessorGroup          Processor group
**    _propagationMode                   Propagation mode, aka export mode
**    _stateName                         Job state when updating or resetting the job.  When _mode is 'add', if this is 'hold' or 'holding', the job will be created and placed in state holding
**    _job                               New job number if adding a job; existing job number if updating or resetting a job
**    _mode                              or 'update' or 'reset'; use 'previewadd' or 'previewupdate' to validate the parameters but not actually make the change (used by the Spreadsheet loader page)
**    _preventDuplicateJobs              Only used if _mode is 'add'; when true, ignores jobs with state 5 (failed), 13 (inactive) or 14 (no export)
**    _specialProcessingWaitUntilReady   When true, sets the job state to 19="Special Proc. Waiting" when the _specialProcessing parameter is not empty
**    _infoOnly                          When true, preview the change even when _mode is 'add' or 'update'
**
**  Auth:   grk
**  Date:   01/10/2002
**          01/30/2004 fixed @@identity problem with insert
**          05/06/2004 grk - allowed analysis processor preset
**          11/05/2004 grk - added parameter for assigned processor
**                           removed batchID parameter
**          02/10/2005 grk - fixed update to include assigned processor
**          03/28/2006 grk - added protein collection fields
**          04/04/2006 grk - increased size of param file name
**          04/07/2006 grk - revised validation logic to use ValidateAnalysisJobParameters
**          04/11/2006 grk - added state field and reset mode
**          04/21/2006 grk - reset now allowed even if job not in 'new' state
**          06/01/2006 grk - added code to handle '(default)' organism
**          11/30/2006 mem - Added column Dataset_Type to Tmp_DatasetInfo (Ticket #335)
**          12/20/2006 mem - Added column dataset_rating_id to Tmp_DatasetInfo (Ticket #339)
**          01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**          02/07/2007 grk - eliminated 'Spectra Required' states (Ticket #249)
**          02/15/2007 grk - added associated processor group (Ticket #383)
**          02/15/2007 grk - Added propagation mode (Ticket #366)
**          02/21/2007 grk - removed _assignedProcessor (Ticket #383)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to Tmp_DatasetInfo
**          02/22/2008 mem - Updated to allow updating jobs in state 'holding'
**                         - Updated to convert _comment and _associatedProcessorGroup to '' if null (Ticket #648)
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644, http://prismtrac.pnl.gov/trac/ticket/644)
**          04/22/2008 mem - Updated to call AlterEnteredByUser when updating T_Analysis_Job_Processor_Group_Associations
**          09/12/2008 mem - Now passing _paramFileName and _settingsFileName ByRef to ValidateAnalysisJobParameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          02/27/2009 mem - Expanded _comment to varchar(512)
**          04/15/2009 grk - handles wildcard DTA folder name in comment field (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          08/05/2009 grk - assign job number from separate table (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          05/05/2010 mem - Now passing _ownerUsername to ValidateAnalysisJobParameters as input/output
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          08/18/2010 mem - Now allowing job update if state is Failed, in addition to New or Holding
**          08/19/2010 grk - try-catch for error handling
**          08/26/2010 mem - Added parameter _preventDuplicateJobs
**          03/29/2011 grk - Added _specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          04/26/2011 mem - Added parameter _preventDuplicatesIgnoresNoExport
**          05/24/2011 mem - Now populating column AJ_DatasetUnreviewed when adding new jobs
**          05/03/2012 mem - Added parameter _specialProcessingWaitUntilReady
**          06/12/2012 mem - Removed unused code related to Archive State in Tmp_DatasetInfo
**          09/18/2012 mem - Now clearing _organismDBName if _mode='reset' and we're searching a protein collection
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          01/04/2013 mem - Now ignoring _organismName, _protCollNameList, _protCollOptionsList, and _organismDBName for analysis tools that do not use protein collections (AJT_orgDbReqd = 0)
**          04/02/2013 mem - Now updating _msg if it is blank yet _result is non-zero
**          03/13/2014 mem - Now passing _job to ValidateAnalysisJobParameters
**          04/08/2015 mem - Now passing _autoUpdateSettingsFileToCentroided and _warning to ValidateAnalysisJobParameters
**          05/28/2015 mem - No longer creating processor group entries (thus _associatedProcessorGroup is ignored)
**          06/24/2015 mem - Added parameter _infoOnly
**          07/21/2015 mem - Now allowing job comment and Export Mode to be changed
**          01/20/2016 mem - Update comments
**          02/15/2016 mem - Re-enabled handling of _associatedProcessorGroup
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Expand error messages
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/09/2017 mem - Add support for state 13 (inactive)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/09/2017 mem - Allow job state to be changed from Complete (state 4) to No Export (state 14) if _propagationMode is 1 (aka 'No Export')
**          12/06/2017 mem - Set _allowNewDatasets to false when calling ValidateAnalysisJobParameters
**          06/12/2018 mem - Send _maxLength to AppendToText
**          09/05/2018 mem - When _mode is 'add', if _state is 'hold' or 'holding', create the job, but put it on hold (state 8)
**          06/30/2022 mem - Rename parameter file argument
**          07/29/2022 mem - Assure that the parameter file and settings file names are not null
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _alterEnteredByRequired boolean := false;
    _msg text;
    _batchID int := 0;
    _logErrors boolean := false;
    _jobID int := 0;
    _currentStateID int := 0;
    _propMode int;
    _currentStateName text;
    _currentExportMode int;
    _currentComment text;
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
    _updateStateID int := -1;
    _pgaAssocID int := 0;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _paramFileName := Trim(Coalesce(_paramFileName, ''));
    _settingsFileName := Trim(Coalesce(_settingsFileName, ''));

    _comment := Trim(Coalesce(_comment, ''));
    _associatedProcessorGroup := Trim(Coalesce(_associatedProcessorGroup, ''));
    _callingUser := Trim(Coalesce(_callingUser, ''));
    _preventDuplicateJobs := Coalesce(_preventDuplicateJobs, false);
    _preventDuplicatesIgnoresNoExport := Coalesce(_preventDuplicatesIgnoresNoExport, true);
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

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

        If _mode = 'update' or _mode = 'reset' Then
            -- Cannot update a non-existent entry
            --
            SELECT job,
                   job_state_id
            INTO _jobID, _currentStateID
            FROM t_analysis_job
            WHERE job = public.try_cast(_job, 0)

            If _jobID = 0 Then
                _msg := 'Cannot update: Analysis Job "' || _job || '" is not in database';
                If _infoOnly Then
                    RAISE INFO '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;

        End If;

        ---------------------------------------------------
        -- Resolve propagation mode
        ---------------------------------------------------
        _propMode := CASE _propagationMode;
                            WHEN 'Export' THEN 0
                            WHEN 'No Export' THEN 1
                            ELSE 0
                        End

        If _mode = 'update' Then
            -- Changes are typically only allowed to jobs in 'new', 'failed', or 'holding' state
            -- However, we do allow the job comment or export mode to be updated
            --
            If Not _currentStateID IN (1,5,8,19) Then
                -- Allow the job comment and Export Mode to be updated

                SELECT AJS.job_state,
                       Coalesce(J.comment, ''),
                       Coalesce(J.propagation_mode, 0)
                INTO _currentStateName, _currentComment, _currentExportMode
                FROM t_analysis_job J
                     INNER JOIN t_analysis_job_state AJS
                       ON J.job_state_id = AJS.job_state_id
                WHERE J.job = _jobID;

                If _comment <> _currentComment Or
                   _propMode <> _currentExportMode Or
                   _currentStateName = 'Complete' And _stateName = 'No export' Then

                    If Not _infoOnly Then
                        UPDATE t_analysis_job
                        SET comment = _comment,
                            propagation_mode = _propMode
                        WHERE job = _jobID
                    End If;

                    If _comment <> _currentComment And _propMode <> _currentExportMode Then
                        _message := 'Updated job comment and export mode';
                    End If;

                    If _message = '' And _comment <> _currentComment Then
                        _message := 'Updated job comment';
                    End If;

                    If _message = '' And _propMode <> _currentExportMode Then
                        _message := 'Updated export mode';
                    End If;

                    If _stateName <> _currentStateName Then
                        If _propMode = 1 And _currentStateName = 'Complete' And _stateName = 'No export' Then
                            If Not _infoOnly Then
                                UPDATE t_analysis_job
                                SET job_state_id = 14
                                WHERE job = _jobID
                            End If;

                            _message := public.append_to_text(_message, 'set job state to "No export"', 0, '; ', 512);
                        Else
                            _msg := 'job state cannot be changed from ' || _currentStateName || ' to ' || _stateName;
                            _message := public.append_to_text(_message, _msg, 0, '; ', 512);

                            If _propagationMode = 'Export' And _stateName = 'No export' Then
                                -- Job propagation mode is Export (0) but user wants to set the state to No export
                                _message := public.append_to_text(_message, 'to make this change, set the Export Mode to "No Export"', 0, '; ', 512);
                            End If;
                        End If;
                    End If;

                    If _infoOnly Then
                        _message := 'Preview: ' || _message;
                    End If;

                    RETURN;
                End If;

                _msg := 'Cannot update: Analysis Job "' || _job || '" is not in "new", "holding", or "failed" state';
                If _infoOnly Then
                    RAISE INFO '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        If _mode = 'reset' Then
            If _organismDBName SIMILAR TO 'ID[_]%' And Not Coalesce(_protCollNameList, '')::citext In ('', 'na') Then
                -- We are resetting a job that used a protein collection; clear _organismDBName
                _organismDBName := '';
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve processor group ID
        ---------------------------------------------------
        --
        --
        If _associatedProcessorGroup <> '' Then
            SELECT group_id
            INTO _gid
            FROM t_analysis_job_processor_group
            WHERE (group_name = _associatedProcessorGroup)

            If Not FOUND Then
                _msg := 'Processor group name not found';
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Create temporary table to hold the dataset details
        -- This table will only have one row
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name text,
            Dataset_ID int NULL,
            Instrument_class text NULL,
            Dataset_State_ID int NULL,
            Archive_State_ID int NULL,
            Dataset_Type text NULL,
            Dataset_rating int NULL
        );

        ---------------------------------------------------
        -- Add dataset to table
        ---------------------------------------------------
        --
        INSERT INTO Tmp_DatasetInfo( Dataset_Name )
        VALUES (_datasetName);

        ---------------------------------------------------
        -- Handle '(default)' organism
        ---------------------------------------------------

        If _organismName = '(default)' Then
            SELECT t_organisms.organism
            INTO _organismName
            FROM
                t_experiments INNER JOIN
                t_dataset ON t_experiments.exp_id = t_dataset.exp_id INNER JOIN
                t_organisms ON t_experiments.organism_id = t_organisms.organism_id
            WHERE t_dataset.dataset = _datasetName;
        End If;

        ---------------------------------------------------
        -- Validate job parameters
        ---------------------------------------------------
        --
        _msg := '';

        CALL validate_analysis_job_parameters (
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
                                _message => _msg,                               -- Output
                                _returnCode => _returnCode,                     -- Output
                                _autoRemoveNotReleasedDatasets => false,
                                _job => _jobID,
                                _autoUpdateSettingsFileToCentroided => true,
                                _allowNewDatasets => false,
                                _warning => _warning,                           -- Output
                                _showDebugMessages => _infoOnly)

        If _returnCode <> '' Then
            If Coalesce(_msg, '') = '' Then
                _msg := 'Error code ' || _returnCode || ' returned by ValidateAnalysisJobParameters';
            End If;

            If _infoOnly Then
                RAISE INFO '%', _msg;
            End If;

            RAISE EXCEPTION '%', _msg;
        End If;

        If Coalesce(_warning, '') <> '' Then
            _comment := public.append_to_text(_comment, _warning, 0, '; ', 512);

            If _mode Like 'preview%' Then
                _message := _warning;
            End If;

        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Lookup the Dataset ID
        ---------------------------------------------------
        --
        --
        SELECT Dataset_ID
        INTO _datasetID
        FROM Tmp_DatasetInfo
        LIMIT 1;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        --
        If _mode = 'add' Then

            If _preventDuplicateJobs Then
                ---------------------------------------------------
                -- See if an existing, matching job already exists
                -- If it does, do not add another job
                ---------------------------------------------------

                SELECT COUNT(*),
                       MAX(job)
                INTO _existingJobCount, _existingMatchingJob
                FROM
                    t_dataset DS INNER JOIN
                    t_analysis_job AJ ON AJ.dataset_id = DS.dataset_id INNER JOIN
                    t_analysis_tool AJT ON AJ.analysis_tool_id = AJT.analysis_tool_id INNER JOIN
                    t_organisms Org ON AJ.organism_id = Org.organism_id  INNER JOIN
                    -- t_analysis_job_state AJS ON AJ.job_state_id = AJS.job_state_id INNER JOIN
                    Tmp_DatasetInfo ON Tmp_DatasetInfo.dataset = DS.dataset
                WHERE
                    ( _preventDuplicatesIgnoresNoExport     AND NOT AJ.job_state_id IN (5, 13, 14) OR
                      Not _preventDuplicatesIgnoresNoExport AND AJ.job_state_id <> 5
                    ) AND
                    AJT.analysis_tool = _toolName AND
                    AJ.param_file_name = _paramFileName AND
                    AJ.settings_file_name = _settingsFileName AND
                    (
                      ( _protCollNameList = 'na' AND
                        AJ.organism_db_name = _organismDBName AND
                        Org.organism = Coalesce(_organismName, Org.organism)
                      ) OR
                      ( _protCollNameList <> 'na' AND
                        AJ.protein_collection_list = Coalesce(_protCollNameList, AJ.protein_collection_list) AND
                         AJ.protein_options_list = Coalesce(_protCollOptionsList, AJ.protein_options_list)
                      ) OR
                      ( AJT.org_db_required = 0 )
                    )

                If _existingJobCount > 0 Then
                    _message := 'Job not created since duplicate job exists: ' || _existingMatchingJob::text;

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

            If Exists (SELECT * FROM t_dataset WHERE dataset_id = _datasetID AND dataset_rating_id = -10) Then
                _datasetUnreviewed := 1;
            End If;

            ---------------------------------------------------
            -- Get ID for new job
            ---------------------------------------------------
            --
            _jobID := public.get_new_job_id ('Job created in DMS', _infoOnly)

            If _jobID = 0 Then
                _msg := 'Failed to get valid new job ID';
                If _infoOnly Then
                    RAISE INFO '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;

            _job := _jobID::text

            If Coalesce(_specialProcessingWaitUntilReady, false) And Coalesce(_specialProcessing, '') <> '' Then
                _newStateID := 19;
            End If;

            If _stateName Like 'hold%' Then
                _newStateID := 8;
            End If;

            If _infoOnly Then

                -- ToDo: show this info using RAISE INFO

                SELECT 'Preview ' || _mode as Mode,
                       _jobID AS job,
                       _priority AS priority,
                       CURRENT_TIMESTAMP AS created,
                       _analysisToolID AS AnalysisToolID,
                       _paramFileName AS ParmFileName,
                       _settingsFileName AS SettingsFileName,
                       _organismDBName AS OrganismDBName,
                       _protCollNameList AS ProteinCollectionList,
                       _protCollOptionsList AS ProteinOptionsList,
                       _organismID AS OrganismID,
                       _datasetID AS DatasetID,
                       REPLACE(_comment, '#DatasetNum#', _datasetID)::text AS Comment,
                       _specialProcessing AS SpecialProcessing,
                       _ownerUsername AS Owner,
                       _batchID AS BatchID,
                       _newStateID AS StateID,
                       _propMode AS PropagationMode,
                       _datasetUnreviewed AS DatasetUnreviewed

            Else

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
                    owner,
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
                    REPLACE(_comment, '#DatasetNum#', _datasetID)::text,
                    _specialProcessing,
                    _ownerUsername,
                    _batchID,
                    _newStateID,
                    _propMode,
                    _datasetUnreviewed
                )

                -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If char_length(_callingUser) > 0 Then
                    CALL alter_event_log_entry_user (5, _jobID, _newStateID, _callingUser);
                End If;

                ---------------------------------------------------
                -- Associate job with processor group
                --
                If _gid <> 0 Then
                    INSERT INTO t_analysis_job_processor_group_associations( job,
                                                                             group_id )
                    VALUES (_jobID, _gid)
                End If;

            End If;
        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' or _mode = 'reset' Then

            ---------------------------------------------------
            -- Resolve state ID according to mode and state name
            --
            --
            If _mode = 'reset' Then
                _updateStateID := 1;
            Else
                --
                SELECT job_state_id
                INTO _updateStateID
                FROM t_analysis_job_state
                WHERE job_state = _stateName;

                If _updateStateID = -1 Then
                    _msg := 'State name not recognized: ' || _stateName;
                    If _infoOnly Then
                        RAISE INFO '%', _msg;
                    End If;

                    RAISE EXCEPTION '%', _msg;
                End If;
            End If;

            ---------------------------------------------------
            -- Associate job with processor group
            ---------------------------------------------------
            --
            -- Is there an existing association between the job
            -- and a processor group?
            --
            --
            SELECT group_id
            INTO _pgaAssocID
            FROM t_analysis_job_processor_group_associations
            WHERE job = _jobID

            If _infoOnly Then
                -- ToDo: Convert this to RAISE INFO

                SELECT 'Preview ' || _mode as Mode,
                       _jobID AS job,
                       _priority AS Priority,
                       created,
                       _analysisToolID AS AnalysisToolID,
                       _paramFileName AS ParmFileName,
                       _settingsFileName AS SettingsFileName,
                       _organismDBName AS OrganismDBName,
                       _protCollNameList AS ProteinCollectionList,
                       _protCollOptionsList AS ProteinOptionsList,
                       _organismID AS OrganismID,
                       _datasetID AS DatasetID,
                      _comment comment,
                       _specialProcessing AS SpecialProcessing,
                       _ownerUsername AS Owner,
                       batch_id,
                       _updateStateID AS StateID,
                       CASE WHEN _mode <> 'reset' THEN start ELSE NULL End AS Start,
                       CASE WHEN _mode <> 'reset' THEN finish ELSE NULL End AS Finish,
                       _propMode AS PropagationMode,
                       dataset_unreviewed
                FROM t_analysis_job
                WHERE (job = _jobID)

            Else

                ---------------------------------------------------
                -- Make changes to database
                --
                UPDATE t_analysis_job
                SET
                    priority = _priority,
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
                    owner = _ownerUsername,
                    job_state_id = _updateStateID,
                    start = CASE WHEN _mode <> 'reset' THEN start ELSE NULL End,
                    finish = CASE WHEN _mode <> 'reset' THEN finish ELSE NULL End,
                    propagation_mode = _propMode
                WHERE (job = _jobID)

                -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If char_length(_callingUser) > 0 Then
                    CALL alter_event_log_entry_user (5, _jobID, _updateStateID, _callingUser);
                End If;

                ---------------------------------------------------
                -- Deal with job association with group,
                ---------------------------------------------------
                --
                -- If no group is given, but existing association
                -- exists for job, delete it
                --
                If _gid = 0 Then
                    DELETE FROM t_analysis_job_processor_group_associations
                    WHERE (job = _jobID);
                End If;

                -- If group is given, and no association for job exists
                -- create one
                --
                If _gid <> 0 and _pgaAssocID = 0 Then
                    INSERT INTO t_analysis_job_processor_group_associations( job,
                                                                             group_id )
                    VALUES (_jobID, _gid);

                    _alterEnteredByRequired := true;
                End If;

                -- If group is given, and an association for job does exist
                -- update it
                --
                If _gid <> 0 and _pgaAssocID <> 0 and _pgaAssocID <> _gid Then
                    UPDATE t_analysis_job_processor_group_associations
                    SET group_id = _gid,
                        entered = CURRENT_TIMESTAMP,
                        entered_by = session_user
                    WHERE job = _jobID

                    _alterEnteredByRequired := true;
                End If;

                If char_length(_callingUser) > 0 AND _alterEnteredByRequired Then
                    -- Call public.alter_entered_by_user
                    -- to alter the entered_by field in t_analysis_job_processor_group_associations

                    CALL alter_entered_by_user ('t_analysis_job_processor_group_associations', 'job', _jobID, _callingUser);
                End If;
            End If;

        End If; -- update mode

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
                            _callingProcLocation => '', _logError => true);
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

COMMENT ON PROCEDURE public.add_update_analysis_job IS 'AddUpdateAnalysisJob';
