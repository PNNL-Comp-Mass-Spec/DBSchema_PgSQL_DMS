--
-- Name: schedule_predefined_analysis_jobs(text, text, text, boolean, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.schedule_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text DEFAULT ''::text, IN _analysistoolnamefilter text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _preventduplicatejobs boolean DEFAULT true, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Schedule analysis jobs for dataset according to defaults
**
**  Arguments:
**    _datasetName                  Dataset name
**    _callingUser                  Calling user
**    _analysisToolNameFilter       Optional: if not blank, only considers predefines that match the given tool name (can contain wildcards)
**    _excludeDatasetsNotReleased   When true, excludes datasets with a rating of -5 or -6 (we always exclude datasets with a rating < 2 but <> -10)
**    _preventDuplicateJobs         When true, will not create new jobs that duplicate old jobs
**    _infoOnly                     When true, use RAISE INFO to show a message about whether the dataset will be added to t_predefined_analysis_scheduling_queue or not
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   grk
**  Date:   06/29/2005 grk - Supersedes procedure ScheduleDefaultAnalyses
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          06/01/2006 grk - Fixed calling sequence to Add_Update_Analysis_Job
**          03/15/2007 mem - Updated call to Add_Update_Analysis_Job (Ticket #394)
**                         - Replaced processor name with associated processor group (Ticket #388)
**          02/29/2008 mem - Added optional parameter _callingUser; If provided, will call alter_event_log_entry_user (Ticket #644)
**          04/11/2008 mem - Now passing _raiseErrorMessages to EvaluatePredefinedAnalysisRules
**          05/14/2009 mem - Added parameters _analysisToolNameFilter, _excludeDatasetsNotReleased, and _infoOnly
**          07/22/2009 mem - Improved error reporting for non-zero return values from EvaluatePredefinedAnalysisRules
**          07/12/2010 mem - Expanded protein Collection fields and variables to varchar(4000)
**          08/26/2010 grk - Gutted original and moved guts to CreatePredefinedAnalysisJobs - now just entering dataset into work queue
**          05/24/2011 mem - Added back support for _infoOnly
**          03/27/2013 mem - No longer storing dataset name in T_Predefined_Analysis_Scheduling_Queue
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/15/2023 mem - Exit the procedure if _datasetName is not found in T_Dataset
**                         - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/20/2024 mem - Ignore case when resolving dataset name to ID
**
*****************************************************/
DECLARE
    _state text := 'New';
    _datasetID int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _analysisToolNameFilter     := Trim(Coalesce(_analysisToolNameFilter, ''));
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _infoOnly                   := Coalesce(_infoOnly, false);

    BEGIN

        ---------------------------------------------------
        -- Auto-populate _callingUser if necessary
        ---------------------------------------------------

        If Trim(Coalesce(_callingUser, '')) = '' Then
            _callingUser := SESSION_USER;
        End If;

        ---------------------------------------------------
        -- Lookup dataset ID
        ---------------------------------------------------

        SELECT dataset_id
        INTO _datasetID
        FROM t_dataset
        WHERE dataset = _datasetName::citext;

        If Not FOUND Then
            _message := format('Could not find ID for dataset %s', _datasetName);
            RAISE WARNING '%', _message;

            -- Leave _returnCode as ''
            RETURN;
        End If;

        ---------------------------------------------------
        -- Add a new row to t_predefined_analysis_scheduling_queue
        -- However, if the dataset already exists and has state 'New', don't add another row
        ---------------------------------------------------

        If Exists (SELECT dataset_id FROM t_predefined_analysis_scheduling_queue WHERE dataset_id = _datasetID AND state = 'New') Then
            If _infoOnly Then
                RAISE INFO '';
                RAISE INFO 'Skip dataset since it already has a "New" entry in t_predefined_analysis_scheduling_queue: %', _datasetName;
            End If;
            RETURN;
        End If;

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Would add a new row to t_predefined_analysis_scheduling_queue for %', _datasetName;
            RETURN;
        End If;

        INSERT INTO t_predefined_analysis_scheduling_queue( dataset_id,
                                                            calling_user,
                                                            analysis_tool_name_filter,
                                                            exclude_datasets_not_released,
                                                            prevent_duplicate_jobs,
                                                            state,
                                                            message )
        VALUES (_datasetID,
                _callingUser,
                _analysisToolNameFilter,
                CASE WHEN _excludeDatasetsNotReleased THEN 1 ELSE 0 End,
                CASE WHEN _preventDuplicateJobs       THEN 1 ELSE 0 End,
                _state,
                _message);

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

END
$$;


ALTER PROCEDURE public.schedule_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE schedule_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.schedule_predefined_analysis_jobs(IN _datasetname text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SchedulePredefinedAnalyses or SchedulePredefinedAnalysisJobs';

