--
-- Name: update_analysis_jobs_work(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_jobs_work(IN _state text DEFAULT '[no change]'::text, IN _priority text DEFAULT '[no change]'::text, IN _comment text DEFAULT '[no change]'::text, IN _findtext text DEFAULT '[no change]'::text, IN _replacetext text DEFAULT '[no change]'::text, IN _assignedprocessor text DEFAULT '[no change]'::text, IN _associatedprocessorgroup text DEFAULT ''::text, IN _propagationmode text DEFAULT '[no change]'::text, IN _paramfilename text DEFAULT '[no change]'::text, IN _settingsfilename text DEFAULT '[no change]'::text, IN _organismname text DEFAULT '[no change]'::text, IN _protcollnamelist text DEFAULT '[no change]'::text, IN _protcolloptionslist text DEFAULT '[no change]'::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _disableraiseerror boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in temporary table Tmp_AnalysisJobs
**
**      The calling table must create table Tmp_AnalysisJobs
**
**      CREATE TEMP TABLE Tmp_AnalysisJobs (job int)
**
**  Arguments:
**    _comment                    Text to append to the comment
**    _findText                   Text to find in the comment; ignored if '[no change]'
**    _replaceText                The replacement text when _findText is not '[no change]'
**    _associatedProcessorGroup   Processor group; deprecated in May 2015
**    _mode                       'update' or 'reset' to change data; otherwise, will simply validate parameters
**
**  Auth:   grk
**  Date:   04/06/2006
**          04/10/2006 grk - widened size of list argument to 6000 characters
**          04/12/2006 grk - eliminated forcing null for blank assigned processor
**          06/20/2006 jds - added support to find/replace text in the comment field
**          08/02/2006 grk - clear the Results_Folder_Name, AJ_extractionProcessor,
**                         AJ_extractionStart, and AJ_extractionFinish fields when resetting a job
**          11/15/2006 grk - add logic for propagation mode (ticket #328)
**          03/02/2007 grk - add _associatedProcessorGroup (ticket #393)
**          03/18/2007 grk - make _associatedProcessorGroup viable for reset mode (ticket #418)
**          05/07/2007 grk - corrected spelling of sproc name
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user_multi_id (Ticket #644)
**          03/14/2008 grk - Fixed problem with null arguments (Ticket #655)
**          04/09/2008 mem - Now calling AlterEnteredByUserMultiID if the jobs are associated with a processor group
**          07/11/2008 jds - Added 5 new fields (_paramFileName, _settingsFileName, _organismID, _protCollNameList, _protCollOptionsList)
**                           and code to validate param file settings file against tool type
**          10/06/2008 mem - Now updating parameter file name, settings file name, protein collection list, protein options list, and organism when a job is reset (for any of these that are not '[no change]')
**          11/05/2008 mem - Now allowing for find/replace in comments when _mode = 'reset'
**          02/27/2009 mem - Changed default values to [no change]
**                           Expanded update failure messages to include more detail
**                           Expanded _comment to varchar(512)
**          03/12/2009 grk - Removed [no change] from _associatedProcessorGroup to allow dissasociation of jobs with groups
**          07/16/2009 mem - Added missing rollback transaction statements when verifying _associatedProcessorGroup
**          09/16/2009 mem - Extracted code from UpdateAnalysisJobs
**                         - Added parameter _disableRaiseError
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
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _noChangeText text := '[no change]';
    _msg text;
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
BEGIN
    _message := '';
    _returnCode := '';

    _alterData := false;
    _jobCountUpdated := 0;
    _processorGroupAssociationsUpdated := 0;

    _action := '';
    _action2 := '';
    _message := '';
    _returnCode:= '';

    _stateID := 0;
    _newPriority := 2;

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

    ---------------------------------------------------
    -- Clean up null arguments
    ---------------------------------------------------

    _state := Trim(Coalesce(_state, _noChangeText));
    _priority := Trim(Coalesce(_priority, _noChangeText));
    _comment := Trim(Coalesce(_comment, _noChangeText));
    _findText := Trim(Coalesce(_findText, _noChangeText));
    _replaceText := Trim(Coalesce(_replaceText, _noChangeText));
    _assignedProcessor := Trim(Coalesce(_assignedProcessor, _noChangeText));
    _associatedProcessorGroup := Trim(Coalesce(_associatedProcessorGroup, ''));
    _propagationMode := Trim(Coalesce(_propagationMode, _noChangeText));
    _paramFileName := Trim(Coalesce(_paramFileName, _noChangeText));
    _settingsFileName := Trim(Coalesce(_settingsFileName, _noChangeText));
    _organismName := Trim(Coalesce(_organismName, _noChangeText));
    _protCollNameList := Trim(Coalesce(_protCollNameList, _noChangeText));
    _protCollOptionsList := Trim(Coalesce(_protCollOptionsList, _noChangeText));

    _callingUser := Trim(Coalesce(_callingUser, ''));
    _disableRaiseError := Coalesce(_disableRaiseError, false);

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If (_findText = _noChangeText and _replaceText <> _noChangeText) OR (_findText <> _noChangeText and _replaceText = _noChangeText) Then
        _message := format('The Find In Comment and Replace In Comment arguments must either both be defined, or both be "%s"', _noChangeText);

        If Not _disableRaiseError Then
            RAISE WARNING '%', _message;
        End If;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that all jobs exist
    ---------------------------------------------------
    --
    SELECT string_agg(Job::text, ', ')
    INTO _list
    FROM Tmp_AnalysisJobs
    WHERE NOT job IN (SELECT job FROM t_analysis_job);

    If Coalesce(_list, '') <> '' Then
        _message := 'The following jobs were not in the database: "' || _list || '"';
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
    --
    If _state <> _noChangeText Then
        --
        SELECT job_state_id
        INTO _stateID
        FROM  t_analysis_job_state
        WHERE job_state = _state;

        If Not FOUND Then
            _message := 'State name not found: "' || _state || '"';

            If Not _disableRaiseError Then
                RAISE WARNING '%', _message;
            End If;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------
    --
    If _organismName <> _noChangeText Then
        SELECT ID
        INTO _orgid
        FROM V_Organism_List_Report
        WHERE Name = _organismName;

        If Not FOUND Then
            _message := 'Organism name not found: "' || _organismName || '"';

            If Not _disableRaiseError Then
                RAISE WARNING '%', _message;
            End If;

            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate param file for tool
    ---------------------------------------------------
    --
    _result := 0;
    --
    If _paramFileName <> _noChangeText Then
        SELECT param_file_id
        INTO _result
        FROM t_param_files
        WHERE param_file_name = _paramFileName;

        If Not FOUND Then
            _message := 'Parameter file could not be found' || ':"' || _paramFileName || '"';
            _returnCode := 'U5205';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate parameter file for tool
    ---------------------------------------------------
    --
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
            _message := 'Based on the parameter file entered, the following Analysis Job(s) were not compatible with the the tool type' || ':"' || _commaList || '"';

            _returnCode := 'U5206';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Validate settings file for tool
    ---------------------------------------------------
    --
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
            _message := 'Based on the settings file entered, the following Analysis Job(s) were not compatible with the the tool type' || ':"' || _invalidJobList || '"';

            _returnCode := 'U5207';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Update jobs from temporary table
    -- in cases where parameter has changed
    ---------------------------------------------------
    --
    If _mode = 'update' Then

        _alterData := true;

        -----------------------------------------------
        If _state <> _noChangeText Then
            UPDATE t_analysis_job
            SET job_state_id = _stateID
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  job_state_id <> _stateID;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _alterEventLogRequired := true;

            _action := 'Update state to ' || _stateID::text;
        End If;

        -----------------------------------------------
        If _priority <> _noChangeText Then
            _newPriority := cast(_priority as int);

            UPDATE t_analysis_job
            SET priority = _newPriority
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  priority <> _newPriority;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Update priority to ' || _newPriority::text;
        End If;

        -----------------------------------------------
        If _comment <> _noChangeText Then
            UPDATE t_analysis_job
            SET comment = public.append_to_text(comment, _comment, _delimiter => '; ')
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) And
                  Not comment LIKE '%' || _comment;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Append comment text';
        End If;

        -----------------------------------------------
        If _findText <> _noChangeText and _replaceText <> _noChangeText Then
            UPDATE t_analysis_job
            SET comment = replace(comment, _findText, _replaceText)
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs);
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Replace comment text';
        End If;

        -----------------------------------------------
        If _assignedProcessor <> _noChangeText Then
            UPDATE t_analysis_job
            SET assigned_processor_name =  _assignedProcessor
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  assigned_processor_name <> _assignedProcessor;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Update assigned processor to ' || _assignedProcessor;
        End If;

        -----------------------------------------------
        If _propagationMode <> _noChangeText Then
            _propMode := CASE Lower(_propagationMode)
                                WHEN 'export' THEN 0
                                WHEN 'no export' THEN 1
                                ELSE 0
                         END;

            UPDATE t_analysis_job
            SET propagation_mode =  _propMode
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  propagation_mode <> _propMode;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Update propagation mode to ' || _propagationMode;
        End If;

        -----------------------------------------------
        If _paramFileName <> _noChangeText Then
            UPDATE t_analysis_job
            SET param_file_name =  _paramFileName
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  param_file_name <> _paramFileName;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Update parameter file to ' || _paramFileName;
        End If;

        -----------------------------------------------
        If _settingsFileName <> _noChangeText Then
            UPDATE t_analysis_job
            SET settings_file_name =  _settingsFileName
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  settings_file_name <> _settingsFileName;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Update settings file to ' || _settingsFileName;
        End If;

        -----------------------------------------------
        If _organismName <> _noChangeText Then
            UPDATE t_analysis_job
            SET organism_id =  _orgid
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  organism_id <> _orgid;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Change organism to ' || _organismName;
        End If;

        -----------------------------------------------
        If _protCollNameList <> _noChangeText Then
            UPDATE t_analysis_job
            SET protein_collection_list = _protCollNameList
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  protein_collection_list <> _protCollNameList;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Change protein collection list to ' || _protCollNameList;
        End If;

        -----------------------------------------------
        If _protCollOptionsList <> _noChangeText Then
            UPDATE t_analysis_job
            SET protein_options_list =  _protCollOptionsList
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  protein_options_list <> _protCollOptionsList;
            --
            GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

            _action := 'Change protein options list to ' || _protCollOptionsList;
        End If;

    End If;

    ---------------------------------------------------
    -- Reset job to New state
    ---------------------------------------------------
    --
    If _mode = 'reset' Then

        _alterData := true;
        _stateID := 1;

        UPDATE t_analysis_job
        SET job_state_id = _stateID,
            start = NULL,
            finish = NULL,
            results_folder_name = '',
            extraction_processor = '',
            extraction_start = NULL,
            extraction_finish = NULL,
            param_file_name = CASE WHEN _paramFileName = _noChangeText             THEN param_file_name ELSE _paramFileName END,
            settings_file_name = CASE WHEN _settingsFileName = _noChangeText       THEN settings_file_name ELSE _settingsFileName END,
            protein_collection_list = CASE WHEN _protCollNameList = _noChangeText  THEN protein_collection_list ELSE _protCollNameList END,
            protein_options_list = CASE WHEN _protCollOptionsList = _noChangeText  THEN protein_options_list ELSE _protCollOptionsList END,
            organism_id = CASE WHEN _organismName = _noChangeText                  THEN organism_id ELSE _orgid END,
            priority =  CASE WHEN _priority = _noChangeText                        THEN priority ELSE CAST(_priority AS int) END,
            comment = comment || CASE WHEN _comment = _noChangeText                THEN '' ELSE ' ' || _comment END,
            assigned_processor_name = CASE WHEN _assignedProcessor = _noChangeText THEN assigned_processor_name ELSE _assignedProcessor END
        WHERE job in (SELECT job FROM Tmp_AnalysisJobs);
        --
        GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

        _action := 'Reset job state';

        If _paramFileName <> _noChangeText Then
            _action2 := _action2 || '; changed param file to ' || _paramFileName;
        End If;

        If _settingsFileName <> _noChangeText Then
            _action2 := _action2 || '; changed settings file to ' || _settingsFileName;
        End If;

        If _protCollNameList <> _noChangeText Then
            _action2 := _action2 || '; changed protein collection to ' || _protCollNameList;
        End If;

        If _protCollOptionsList <> _noChangeText Then
            _action2 := _action2 || '; changed protein options to ' || _protCollOptionsList;
        End If;

        If _organismName <> _noChangeText Then
            _action2 := _action2 || '; changed organism name to ' || _organismName;
        End If;

        If _priority <> _noChangeText Then
            _action2 := _action2 || '; changed priority to ' || _priority;
        End If;

        If _comment <> _noChangeText Then
            _action2 := _action2 || '; appended comment text';
        End If;

        If _assignedProcessor <> _noChangeText Then
            _action2 := _action2 || '; updated assigned processor to ' || _assignedProcessor;
        End If;

        -----------------------------------------------
        If _findText <> _noChangeText and _replaceText <> _noChangeText Then
            UPDATE t_analysis_job
            SET comment = replace(comment, _findText, _replaceText)
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs);

            If _assignedProcessor <> _noChangeText Then
                _action2 := _action2 || '; replaced text in comment';
            End If;

        End If;

        _alterEventLogRequired := true;
    End If;

     /*
    ---------------------------------------------------
    -- Deprecated in May 2015:
    -- Handle associated processor Group
    -- (though only if we're actually performing an update or reset)
    --
    If _associatedProcessorGroup <> _noChangeText And _mode IN ('update', 'reset') Then
    -- <associated processor group>

        ---------------------------------------------------
        -- Resolve processor group ID
        --
        _gid := 0;
        --
        If _associatedProcessorGroup <> '' Then
            SELECT group_id
            INTO _gid
            FROM t_analysis_job_processor_group
            WHERE group_name = _associatedProcessorGroup;

            If Not FOUND Then
                _msg := 'Processor group name not found: "' || _associatedProcessorGroup || '"';

                ROLLBACK;

                If Not _disableRaiseError Then
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
            --
            DELETE FROM t_analysis_job_processor_group_associations
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _jobCountUpdated = 0 Then
                _jobCountUpdated := _deleteCount;
            End If;

            _action2 := _action2 || '; remove jobs from processor group';
        Else
            -- For jobs with existing association, change it
            --
            UPDATE t_analysis_job_processor_group_associations
            SET group_id = _gid,
                entered = CURRENT_TIMESTAMP,
                entered_by = session_user
            WHERE job in (SELECT job FROM Tmp_AnalysisJobs) AND
                  group_id <> _gid;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount <> 0 Then
                _processorGroupAssociationsUpdated := 1;
            End If;

            -- For jobs without existing association, create it
            --
            INSERT INTO t_analysis_job_processor_group_associations (job, group_id)
            SELECT job, _gid FROM Tmp_AnalysisJobs
            WHERE NOT job IN (SELECT job FROM t_analysis_job_processor_group_associations);
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            If _jobCountUpdated = 0 Then
                _jobCountUpdated := _insertCount;
            End If;

            If _insertCount <> 0 OR _processorGroupAssociationsUpdated <> 0 Then
                _action2 := _action2 || '; associate jobs with processor group ' || _associatedProcessorGroup;
            End If;

            _alterEnteredByRequired := true;
        End If;
    End If;  -- </associated processor Group>
    */

     If char_length(_callingUser) > 0 AND (_alterEventLogRequired OR _alterEnteredByRequired) Then
        -- _callingUser is defined and items need to be updated in t_event_log and/or t_analysis_job_processor_group_associations
        --
        -- Populate a temporary table with the list of job IDs just updated
        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT DISTINCT Job
        FROM Tmp_AnalysisJobs;

        If _alterEventLogRequired Then
            -- CALL public.alter_event_log_entry_user_multi_id
            -- to alter the entered_by field in t_event_log

            CALL alter_event_log_entry_user_multi_id (5, _stateID, _callingUser);
        End If;

        If _alterEnteredByRequired Then
            -- CALL public.alter_entered_by_user_multi_id
            -- to alter the entered_by field in t_analysis_job_processor_group_associations

            CALL alter_entered_by_user_multi_id ('t_analysis_job_processor_group_associations', 'job', _callingUser);
        End If;

        DROP TABLE Tmp_ID_Update_List;
    End If;

    _message := 'Number of jobs to update: ' || _jobCountToUpdate::text;

    If Not _alterData Then
        If _jobCountUpdated = 0 Then
            If _action = '' Then
                _message := 'No parameters were specified to be updated (' || _message || ')';
            Else
                _message := _message || '; all jobs were already up-to-date (' || _action || ')';
            End If;
        Else
            _message := _message || '; ' || _action || ' for ' ||  _jobCountUpdated::text || ' job(s)' || _action2;
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.update_analysis_jobs_work(IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _disableraiseerror boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_analysis_jobs_work(IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _disableraiseerror boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_analysis_jobs_work(IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _disableraiseerror boolean) IS 'UpdateAnalysisJobsWork';

