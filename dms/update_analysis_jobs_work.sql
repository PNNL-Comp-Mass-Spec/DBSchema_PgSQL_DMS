--
-- Name: update_analysis_jobs_work(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_jobs_work(IN _state text DEFAULT '[no change]'::text, IN _priority text DEFAULT '[no change]'::text, IN _comment text DEFAULT '[no change]'::text, IN _findtext text DEFAULT '[no change]'::text, IN _replacetext text DEFAULT '[no change]'::text, IN _assignedprocessor text DEFAULT '[no change]'::text, IN _associatedprocessorgroup text DEFAULT ''::text, IN _propagationmode text DEFAULT '[no change]'::text, IN _paramfilename text DEFAULT '[no change]'::text, IN _settingsfilename text DEFAULT '[no change]'::text, IN _organismname text DEFAULT '[no change]'::text, IN _protcollnamelist text DEFAULT '[no change]'::text, IN _protcolloptionslist text DEFAULT '[no change]'::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _showerrors boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update parameters to new values for jobs in temporary table Tmp_AnalysisJobs
**
**      The calling procedure must create table Tmp_AnalysisJobs
**
**      CREATE TEMP TABLE Tmp_AnalysisJobs (job int);
**
**  Arguments:
**    _state                        Job state name
**    _priority                     Processing priority (1, 2, 3, etc.)
**    _comment                      Text to append to the comment
**    _findText                     Text to find in the comment; ignored if '[no change]'
**    _replaceText                  The replacement text when _findText is not '[no change]'
**    _assignedProcessor            Assigned processor name (obsolete)
**    _associatedProcessorGroup     Processor group; deprecated in May 2015
**    _propagationMode              Propagation mode ('Export' or 'No Export')
**    _paramFileName                Parameter file name
**    _settingsFileName             Settings file name
**    _organismName                 Organism name
**    _protCollNameList             Protein collection list
**    _protCollOptionsList          Protein options list
**    _mode                         Mode: 'update' or 'reset' to change data; otherwise, will simply validate parameters
**    _message                      Status message
**    _returnCode                   Return code
**    _callingUser                  Username of the calling user
**    _showErrors                   When true, show errors using RAISE WARNING
**
**  Auth:   grk
**  Date:   04/06/2006
**          04/10/2006 grk - Widened size of list argument to 6000 characters
**          04/12/2006 grk - Eliminated forcing null for blank assigned processor
**          06/20/2006 jds - Added support to find/replace text in the comment field
**          08/02/2006 grk - Clear the Results_Folder_Name, extraction_processor, extraction_start, and extraction_finish fields when resetting a job
**          11/15/2006 grk - Add logic for propagation mode (ticket #328)
**          03/02/2007 grk - Add _associatedProcessorGroup (ticket #393)
**          03/18/2007 grk - Make _associatedProcessorGroup viable for reset mode (ticket #418)
**          05/07/2007 grk - Corrected spelling of sproc name
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user_multi_id (Ticket #644)
**          03/14/2008 grk - Fixed problem with null arguments (Ticket #655)
**          04/09/2008 mem - Now calling Alter_Entered_By_User_Multi_ID if the jobs are associated with a processor group
**          07/11/2008 jds - Added 5 new fields (_paramFileName, _settingsFileName, _organismID, _protCollNameList, _protCollOptionsList)
**                           and code to validate param file settings file against tool type
**          10/06/2008 mem - Now updating parameter file name, settings file name, protein collection list, protein options list, and organism when a job is reset (for any of these that are not '[no change]')
**          11/05/2008 mem - Now allowing for find/replace in comments when _mode = 'reset'
**          02/27/2009 mem - Changed default values to [no change]
**                           Expanded update failure messages to include more detail
**                           Expanded _comment to varchar(512)
**          03/12/2009 grk - Removed [no change] from _associatedProcessorGroup to allow dissasociation of jobs with groups
**          07/16/2009 mem - Added missing rollback transaction statements when verifying _associatedProcessorGroup
**          09/16/2009 mem - Extracted code from Update_Analysis_Jobs
**                         - Added parameter _disableRaiseError (later renamed to _showErrors)
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          03/30/2015 mem - Tweak warning message grammar
**          05/28/2015 mem - No longer updating processor group entries (thus _associatedProcessorGroup is ignored)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**          05/05/2023 mem - Ported to PostgreSQL
**          05/11/2023 mem - Update return codes
**          05/12/2023 mem - Rename variables
**          05/31/2023 mem - Use format() for string concatenation
**                         - Use procedure name without schema when calling verify_sp_authorized()
**          06/07/2023 mem - Add Order By to string_agg()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          07/27/2023 mem - Add schema name parameter when calling alter_entered_by_user_multi_id()
**                         - Use local variable for the return value of _message from alter_event_log_entry_user_multi_id()
**          09/05/2023 mem - Use schema name when calling procedures
**          09/08/2023 mem - Adjust capitalization of keywords
**                         - Use a case insensitive search when finding text to replace
**          09/13/2023 mem - Remove unnecessary delimiter argument when calling append_to_text()
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user_multi_id()
**          12/29/2023 mem - Rename procedure argument to _showErrors
**          01/03/2024 mem - Update warning message
**          02/16/2024 mem - Use try_cast() to parse the new priority value
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _noChangeText citext := '[no change]';
    _list text;
    _alterEventLogRequired boolean := false;
    _alterEnteredByRequired boolean := false;
    _alterData boolean;
    _jobCountToUpdate int;
    _jobCountUpdated int;
    _processorGroupAssociationsUpdated int;
    _action text;
    _action2 text;
    _stateID int;
    _newPriority int;
    _orgid int := 0;
    _result int;
    _commaList text;
    _id text;
    _invalidJobList text;
    _propMode int;
    _gid int;
    _targetType int;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    _alterData := false;
    _jobCountUpdated := 0;
    _processorGroupAssociationsUpdated := 0;

    _action := '';
    _action2 := '';
    _message := '';
    _returnCode := '';

    _stateID := 0;
    _newPriority := 2;

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

    ---------------------------------------------------
    -- Clean up null arguments
    ---------------------------------------------------

    _state                    := Trim(Coalesce(_state, _noChangeText));
    _priority                 := Trim(Coalesce(_priority, _noChangeText));
    _comment                  := Trim(Coalesce(_comment, _noChangeText));
    _findText                 := Trim(Coalesce(_findText, _noChangeText));
    _replaceText              := Trim(Coalesce(_replaceText, _noChangeText));
    _assignedProcessor        := Trim(Coalesce(_assignedProcessor, _noChangeText));
    _associatedProcessorGroup := Trim(Coalesce(_associatedProcessorGroup, ''));
    _propagationMode          := Trim(Coalesce(_propagationMode, _noChangeText));
    _paramFileName            := Trim(Coalesce(_paramFileName, _noChangeText));
    _settingsFileName         := Trim(Coalesce(_settingsFileName, _noChangeText));
    _organismName             := Trim(Coalesce(_organismName, _noChangeText));
    _protCollNameList         := Trim(Coalesce(_protCollNameList, _noChangeText));
    _protCollOptionsList      := Trim(Coalesce(_protCollOptionsList, _noChangeText));

    _callingUser              := Trim(Coalesce(_callingUser, ''));
    _showErrors               := Coalesce(_showErrors, true);

    _mode                     := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If (_findText::citext = _noChangeText And _replaceText::citext <> _noChangeText) Or (_findText::citext <> _noChangeText And _replaceText::citext = _noChangeText) Then
        _message := format('The Find In Comment and Replace In Comment arguments must either both be defined, or both be "%s"', _noChangeText);

        If _showErrors Then
            RAISE WARNING '%', _message;
        End If;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that all jobs exist
    ---------------------------------------------------

    SELECT string_agg(Job::text, ', ' ORDER BY Job)
    INTO _list
    FROM Tmp_AnalysisJobs
    WHERE NOT job IN (SELECT job FROM t_analysis_job);

    If Coalesce(_list, '') <> '' Then
        If Position(',' In _list) > 0 Then
            _message := format('Cannot update; the following jobs do not exist: %s', _list);
        Else
            _message := format('Cannot update: job %s does not exist', _list);
        End If;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Define the job counts and initialize the action text
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _jobCountToUpdate
    FROM Tmp_AnalysisJobs;

    ---------------------------------------------------
    -- Resolve state name
    ---------------------------------------------------

    If _state <> _noChangeText Then
        SELECT job_state_id
        INTO _stateID
        FROM  t_analysis_job_state
        WHERE job_state = _state;

        If Not FOUND Then
            _message := format('State name not found: "%s"', _state);

            If _showErrors Then
                RAISE WARNING '%', _message;
            End If;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------

    If _organismName <> _noChangeText Then
        SELECT ID
        INTO _orgid
        FROM V_Organism_List_Report
        WHERE Name = _organismName;

        If Not FOUND Then
            _message := format('Organism name not found: "%s"', _organismName);

            If _showErrors Then
                RAISE WARNING '%', _message;
            End If;

            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate param file for tool
    ---------------------------------------------------

    _result := 0;

    If _paramFileName <> _noChangeText Then
        SELECT param_file_id
        INTO _result
        FROM t_param_files
        WHERE param_file_name = _paramFileName;

        If Not FOUND Then
            _message := format('Parameter file could not be found: "%s"', _paramFileName);
            _returnCode := 'U5205';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate parameter file for tool
    ---------------------------------------------------

    If _paramFileName <> _noChangeText Then

        SELECT string_agg(TD.job::text, ',' ORDER BY TD.job)
        INTO _commaList
        FROM Tmp_AnalysisJobs TD
        WHERE NOT EXISTS (
                SELECT AJ.job
                FROM t_param_files PF
                    INNER JOIN t_analysis_tool AnTool
                        ON PF.param_file_type_id = AnTool.param_file_type_id
                    JOIN t_analysis_job AJ
                        ON AJ.analysis_tool_id = AnTool.analysis_tool_id
                WHERE PF.valid = 1 AND
                      PF.param_file_name = _paramFileName AND
                      AJ.job = TD.job
              );

        If _commaList <> '' Then
            _message := format('Based on the parameter file entered, the following Analysis Job(s) were not compatible with the the tool type: "%s"', _commaList);

            _returnCode := 'U5206';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate settings file for tool
    ---------------------------------------------------

    If _settingsFileName <> _noChangeText And _settingsFileName::citext <> 'na' Then
        -- Validate settings file for tool only

        SELECT string_agg(TD.job::text, ',' ORDER BY TD.job)
        INTO _invalidJobList
        FROM Tmp_AnalysisJobs TD
        WHERE NOT EXISTS (
                SELECT AJ.job
                FROM t_settings_files SF
                    INNER JOIN t_analysis_tool AnTool
                        ON SF.analysis_tool = AnTool.analysis_tool
                    JOIN t_analysis_job AJ
                        ON AJ.analysis_tool_id = AnTool.analysis_tool_id
                WHERE SF.file_name = _settingsFileName AND
                      AJ.job = TD.job
              );

        If _invalidJobList <> '' Then
            _message := format('Based on the settings file entered, the following Analysis Job(s) were not compatible with the the tool type: "%s"', _invalidJobList);

            _returnCode := 'U5207';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Update jobs from temporary table
    -- in cases where parameter has changed
    ---------------------------------------------------

    If _mode = 'update' Then

        _alterData := true;

        -----------------------------------------------
        If _state <> _noChangeText Then
            UPDATE t_analysis_job
            SET job_state_id = _stateID
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  job_state_id <> _stateID;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _alterEventLogRequired := true;

            _action := format('Update state to %s', _stateID);
        End If;

        -----------------------------------------------
        If _priority <> _noChangeText Then
            _newPriority := public.try_cast(_priority, null::int);

            If _newPriority Is Null Then
                _action := format('New priority is not numeric; cannot update to %s', _priority);
            Else
                UPDATE t_analysis_job
                SET priority = _newPriority
                WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                      priority <> _newPriority;
                --
                GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

                _action := format('Update priority to %s', _newPriority);
            End If;
        End If;

        -----------------------------------------------
        If _comment <> _noChangeText Then
            UPDATE t_analysis_job
            SET comment = public.append_to_text(comment, _comment)
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  NOT comment LIKE '%' || _comment;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Append comment text';
        End If;

        -----------------------------------------------
        If _findText::citext <> _noChangeText And _replaceText::citext <> _noChangeText Then
            UPDATE t_analysis_job
            SET comment = Replace(comment, _findText::citext, _replaceText::citext)
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs);
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Replace comment text';
        End If;

        -----------------------------------------------
        If _assignedProcessor <> _noChangeText Then
            UPDATE t_analysis_job
            SET assigned_processor_name = _assignedProcessor
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  assigned_processor_name <> _assignedProcessor;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Update assigned processor to %s', _assignedProcessor);
        End If;

        -----------------------------------------------
        If _propagationMode <> _noChangeText Then
            _propMode := CASE Lower(_propagationMode)
                                WHEN 'export' THEN 0
                                WHEN 'no export' THEN 1
                                ELSE 0
                         END;

            UPDATE t_analysis_job
            SET propagation_mode = _propMode
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  propagation_mode <> _propMode;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Update propagation mode to %s', _propagationMode);
        End If;

        -----------------------------------------------
        If _paramFileName <> _noChangeText Then
            UPDATE t_analysis_job
            SET param_file_name = _paramFileName
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  param_file_name <> _paramFileName;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Update parameter file to %s', _paramFileName);
        End If;

        -----------------------------------------------
        If _settingsFileName <> _noChangeText Then
            UPDATE t_analysis_job
            SET settings_file_name = _settingsFileName
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  settings_file_name <> _settingsFileName;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Update settings file to %s', _settingsFileName);
        End If;

        -----------------------------------------------
        If _organismName <> _noChangeText Then
            UPDATE t_analysis_job
            SET organism_id = _orgid
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  organism_id <> _orgid;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Change organism to %s', _organismName);
        End If;

        -----------------------------------------------
        If _protCollNameList <> _noChangeText Then
            UPDATE t_analysis_job
            SET protein_collection_list = _protCollNameList
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  protein_collection_list <> _protCollNameList;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Change protein collection list to %s', _protCollNameList);
        End If;

        -----------------------------------------------
        If _protCollOptionsList <> _noChangeText Then
            UPDATE t_analysis_job
            SET protein_options_list = _protCollOptionsList
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  protein_options_list <> _protCollOptionsList;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := format('Change protein options list to %s', _protCollOptionsList);
        End If;

    End If;

    ---------------------------------------------------
    -- Reset job to New state
    ---------------------------------------------------

    If _mode = 'reset' Then

        _alterData := true;
        _stateID := 1;

        UPDATE t_analysis_job
        SET job_state_id            = _stateID,
            start                   = NULL,
            finish                  = NULL,
            results_folder_name     = '',
            extraction_processor    = '',
            extraction_start        = NULL,
            extraction_finish       = NULL,
            param_file_name         = CASE WHEN _paramFileName = _noChangeText                   THEN param_file_name         ELSE _paramFileName END,
            settings_file_name      = CASE WHEN _settingsFileName = _noChangeText                THEN settings_file_name      ELSE _settingsFileName END,
            protein_collection_list = CASE WHEN _protCollNameList = _noChangeText                THEN protein_collection_list ELSE _protCollNameList END,
            protein_options_list    = CASE WHEN _protCollOptionsList = _noChangeText             THEN protein_options_list    ELSE _protCollOptionsList END,
            organism_id             = CASE WHEN _organismName = _noChangeText                    THEN organism_id             ELSE _orgid END,
            priority                = CASE WHEN _priority = _noChangeText                        THEN priority                ELSE Coalesce(public.try_cast(_priority, null::int), priority) END,
            comment                 = format('%s%s', comment, CASE WHEN _comment = _noChangeText THEN ''                      ELSE format(' %s', _comment) END),
            assigned_processor_name = CASE WHEN _assignedProcessor = _noChangeText               THEN assigned_processor_name ELSE _assignedProcessor END
        WHERE job IN (SELECT job FROM Tmp_AnalysisJobs);
        --
        GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

        _action := 'Reset job state';

        If _paramFileName <> _noChangeText Then
            _action2 := format('%s; changed param file to %s', _action2, _paramFileName);
        End If;

        If _settingsFileName <> _noChangeText Then
            _action2 := format('%s; changed settings file to %s', _action2, _settingsFileName);
        End If;

        If _protCollNameList <> _noChangeText Then
            _action2 := format('%s; changed protein collection to %s', _action2, _protCollNameList);
        End If;

        If _protCollOptionsList <> _noChangeText Then
            _action2 := format('%s; changed protein options to %s', _action2, _protCollOptionsList);
        End If;

        If _organismName <> _noChangeText Then
            _action2 := format('%s; changed organism name to %s', _action2, _organismName);
        End If;

        If _priority <> _noChangeText Then
            _action2 := format('%s; changed priority to %s', _action2, _priority);
        End If;

        If _comment <> _noChangeText Then
            _action2 := format('%s; appended comment text', _action2);
        End If;

        If _assignedProcessor <> _noChangeText Then
            _action2 := format('%s; updated assigned processor to %s', _action2, _assignedProcessor);
        End If;

        -----------------------------------------------
        If _findText::citext <> _noChangeText And _replaceText::citext <> _noChangeText Then
            UPDATE t_analysis_job
            SET comment = Replace(comment, _findText::citext, _replaceText::citext)
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs);

            If _assignedProcessor <> _noChangeText Then
                _action2 := format('%s; replaced text in comment', _action2);
            End If;

        End If;

        _alterEventLogRequired := true;
    End If;

     /*
    ---------------------------------------------------
    -- Deprecated in May 2015:
    -- Handle associated processor Group
    -- (though only if we're actually performing an update or reset)

    If _associatedProcessorGroup <> _noChangeText And _mode In ('update', 'reset') Then

        ---------------------------------------------------
        -- Resolve processor group ID

        _gid := 0;

        If _associatedProcessorGroup <> '' Then
            SELECT group_id
            INTO _gid
            FROM t_analysis_job_processor_group
            WHERE group_name = _associatedProcessorGroup;

            If Not FOUND Then
                _msg := format('Processor group name not found: "%s"', _associatedProcessorGroup);

                ROLLBACK;

                If _showErrors Then
                    RAISE EXCEPTION '%', _msg;
                Else
                    _message := _msg;
                End If;

                _returnCode := 'U5208';
                RETURN;
            End If;
        End If;

        If _gid = 0 Then
            -- Dissassociate given jobs from group

            DELETE FROM t_analysis_job_processor_group_associations
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _jobCountUpdated = 0 Then
                _jobCountUpdated := _deleteCount;
            End If;

            _action2 := format('%s; remove jobs from processor group', _action2);
        Else
            -- For jobs with existing association, change it

            UPDATE t_analysis_job_processor_group_associations
            SET group_id = _gid,
                entered = CURRENT_TIMESTAMP,
                entered_by = SESSION_USER
            WHERE job IN (SELECT job FROM Tmp_AnalysisJobs) AND
                  group_id <> _gid;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount <> 0 Then
                _processorGroupAssociationsUpdated := 1;
            End If;

            -- For jobs without existing association, create it

            INSERT INTO t_analysis_job_processor_group_associations (job, group_id)
            SELECT job, _gid FROM Tmp_AnalysisJobs
            WHERE NOT job IN (SELECT job FROM t_analysis_job_processor_group_associations);
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            If _jobCountUpdated = 0 Then
                _jobCountUpdated := _insertCount;
            End If;

            If _insertCount <> 0 OR _processorGroupAssociationsUpdated <> 0 Then
                _action2 := format('%s; associate jobs with processor group %s', _action2, _associatedProcessorGroup);
            End If;

            _alterEnteredByRequired := true;
        End If;
    End If;
    */

     If _callingUser <> '' And (_alterEventLogRequired Or _alterEnteredByRequired) Then
        -- _callingUser is defined and items need to be updated in t_event_log and/or t_analysis_job_processor_group_associations

        -- Populate a temporary table with the list of job IDs just updated
        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT DISTINCT Job
        FROM Tmp_AnalysisJobs;

        If _alterEventLogRequired Then
            -- Call public.alter_event_log_entry_user_multi_id to alter the entered_by field in t_event_log

            _targetType := 5;
            CALL public.alter_event_log_entry_user_multi_id ('public', _targetType, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        If _alterEnteredByRequired Then
            -- Call public.alter_entered_by_user_multi_id
            -- to alter the entered_by field in t_analysis_job_processor_group_associations

            CALL public.alter_entered_by_user_multi_id ('public', 't_analysis_job_processor_group_associations', 'job', _callingUser, _message => _message);
        End If;

        DROP TABLE Tmp_ID_Update_List;
    End If;

    _message := format('Number of jobs to update: %s', _jobCountToUpdate);

    If Not _alterData Then
        If _jobCountUpdated = 0 Then
            If _action = '' Then
                _message := format('No parameters were specified to be updated (%s)', _message);
            Else
                _message := format('%s; all jobs were already up-to-date (%s)', _message, _action);
            End If;
        Else
            _message := format('%s; %s for %s %s%s',
                                _message,
                                _action,
                                _jobCountUpdated,
                                public.check_plural(_jobCountUpdated, 'job', 'jobs'),
                                _action2     -- Note that _action2 is either an empty string or it starts with a semicolon
                              );
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.update_analysis_jobs_work(IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showerrors boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_analysis_jobs_work(IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showerrors boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_analysis_jobs_work(IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showerrors boolean) IS 'UpdateAnalysisJobsWork';

