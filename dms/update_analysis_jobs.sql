--
-- Name: update_analysis_jobs(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_jobs(IN _joblist text, IN _state text DEFAULT '[no change]'::text, IN _priority text DEFAULT '[no change]'::text, IN _comment text DEFAULT '[no change]'::text, IN _findtext text DEFAULT '[no change]'::text, IN _replacetext text DEFAULT '[no change]'::text, IN _assignedprocessor text DEFAULT '[no change]'::text, IN _associatedprocessorgroup text DEFAULT ''::text, IN _propagationmode text DEFAULT '[no change]'::text, IN _paramfilename text DEFAULT '[no change]'::text, IN _settingsfilename text DEFAULT '[no change]'::text, IN _organismname text DEFAULT '[no change]'::text, IN _protcollnamelist text DEFAULT '[no change]'::text, IN _protcolloptionslist text DEFAULT '[no change]'::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in list
**
**  Arguments:
**    _jobList                  Comma separated list of job numbers
**    _state                    Job state name
**    _priority                 Processing priority (1, 2, 3, etc.)
**    _comment                  Text to append to the comment
**    _findText                 Text to find in the comment; ignored if '[no change]'
**    _replaceText              The replacement text when _findText is not '[no change]'
**    _assignedProcessor        Assigned processor name (obsolete)
**    _associatedProcessorGroup Processor group; deprecated in May 2015
**    _propagationMode          Propagation mode ('Export' or 'No Export')
**    _paramFileName            Parameter file name
**    _settingsFileName         Settings file name
**    _organismName             Organism name
**    _protCollNameList         Protein collection list
**    _protCollOptionsList      Protein options list
**    _mode                     'update' or 'reset' to change data; otherwise, will simply validate parameters
**
**  Auth:   grk
**  Date:   04/06/2006
**          04/10/2006 grk - Widened size of list argument to 6000 characters
**          04/12/2006 grk - Eliminated forcing null for blank assigned processor
**          06/20/2006 jds - Added support to find/replace text in the comment field
**          08/02/2006 grk - Clear the Results_Folder_Name, AJ_extractionProcessor,
**                           AJ_extractionStart, and AJ_extractionFinish fields when resetting a job
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
**          09/16/2009 mem - Expanded _jobList to varchar(max)
**                         - Now calls Update_Analysis_Jobs_Work to do the work
**          08/19/2010 grk - Use try-catch for error handling
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**          05/05/2023 mem - Ported to PostgreSQL
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _jobCount int := 0;
    _dropTempTable boolean := false;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If Coalesce(_jobList, '') = '' Then
            _msg := 'Job list is empty';
            RAISE EXCEPTION '%', _msg;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Create temporary table to hold list of jobs
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_AnalysisJobs (
            Job int
        );

        _dropTempTable := true;

        ---------------------------------------------------
        -- Populate table from job list
        ---------------------------------------------------

        INSERT INTO Tmp_AnalysisJobs (Job)
        SELECT Value
        FROM public.parse_delimited_integer_list(_jobList);
        --
        GET DIAGNOSTICS _jobCount = ROW_COUNT;

        ---------------------------------------------------
        -- Call Update_Analysis_Jobs to do the work
        -- It uses Tmp_AnalysisJobs to determine which jobs to update
        ---------------------------------------------------

        CALL update_analysis_jobs_work (
                            _state,
                            _priority,
                            _comment,
                            _findText,
                            _replaceText,
                            _assignedProcessor,
                            _associatedProcessorGroup,
                            _propagationMode,
                            _paramFileName,
                            _settingsFileName,
                            _organismName,
                            _protCollNameList,
                            _protCollOptionsList,
                            _mode,
                            _message => _msg,               -- Output
                            _returnCode => _returnCode,     -- Output
                            _callingUser => _callingUser);

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
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

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));

    CALL post_usage_log_entry ('Update_Analysis_Jobs', _usageMessage);

    If _dropTempTable Then
        DROP TABLE IF EXISTS Tmp_AnalysisJobs;
    End If;
END
$$;


ALTER PROCEDURE public.update_analysis_jobs(IN _joblist text, IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_analysis_jobs(IN _joblist text, IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_analysis_jobs(IN _joblist text, IN _state text, IN _priority text, IN _comment text, IN _findtext text, IN _replacetext text, IN _assignedprocessor text, IN _associatedprocessorgroup text, IN _propagationmode text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateAnalysisJobs';

