--
CREATE OR REPLACE PROCEDURE public.schedule_predefined_analysis_jobs
(
    _datasetName text,
    _callingUser text = '',
    _analysisToolNameFilter text = '',
    _excludeDatasetsNotReleased = true,
    _preventDuplicateJobs boolean = true,
    _infoOnly boolean = false,
    INOUT _returnCode text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
        Schedules analysis jobs for dataset according to defaults
**
**  Arguments:
**    _datasetName                  Dataset name
**    _callingUser                  Calling user
**    _analysisToolNameFilter       Optional: if not blank, only considers predefines that match the given tool name (can contain wildcards)
**    _excludeDatasetsNotReleased   When true, excludes datasets with a rating of -5 or -6 (we always exclude datasets with a rating < 2 but <> -10)
**    _preventDuplicateJobs         When true, will not create new jobs that duplicate old jobs
**    _infoOnly                     When true, use RAISE INFO to show a message about whether the dataset will be added to t_predefined_analysis_scheduling_queue or not
**    _returnCode                   Error code if an exception is caught
**
**  Auth:   grk
**  Date:   06/29/2005 grk - Supersedes procedure ScheduleDefaultAnalyses
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          06/01/2006 grk - Fixed calling sequence to AddUpdateAnalysisJob
**          03/15/2007 mem - Updated call to AddUpdateAnalysisJob (Ticket #394)
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text := '';
    _state text := 'New';
    _datasetID int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _analysisToolNameFilter := Coalesce(_analysisToolNameFilter, '');
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _infoOnly := Coalesce(_infoOnly, false);
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Auto-populate _callingUser if necessary
        ---------------------------------------------------

        If Coalesce(_callingUser, '') = '' Then
            _callingUser := session_user;
        End If;

        ---------------------------------------------------
        -- Lookup dataset ID
        ---------------------------------------------------

        SELECT dataset_id
        INTO _datasetID
        FROM t_dataset
        WHERE dataset = _datasetName;

        If _datasetID = 0 Then
            _message := 'Could not find ID for dataset';
            _state := 'Error';

            -- Leave _returnCode as ''
        End If;

        ---------------------------------------------------
        -- Add a new row to t_predefined_analysis_scheduling_queue
        -- However, if the dataset already exists and has state 'New', don't add another row
        ---------------------------------------------------

        If Exists (SELECT * FROM t_predefined_analysis_scheduling_queue WHERE dataset_id = _datasetID AND state = 'New') Then
            If _infoOnly Then
                RAISE INFO 'Skip % since already has a "New" entry in t_predefined_analysis_scheduling_queue', _datasetName;
            End If;
        Else
            If _infoOnly Then
                RAISE INFO 'Add new row to t_predefined_analysis_scheduling_queue for %', _datasetName
            Else
                INSERT INTO t_predefined_analysis_scheduling_queue( dataset_id,;
                                                                    CALLingUser,
                                                                    AnalysisToolNameFilter,
                                                                    ExcludeDatasetsNotReleased,
                                                                    PreventDuplicateJobs,
                                                                    State,
                                                                    Message )
                VALUES (_datasetID,
                        _callingUser,
                        _analysisToolNameFilter,
                        CASE WHEN _excludeDatasetsNotReleased THEN 1 ELSE 0 End,
                        CASE WHEN _preventDuplicateJobs       THEN 1 ELSE 0 End,
                        _state,
                        _message)
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

END
$$;

COMMENT ON PROCEDURE public.schedule_predefined_analysis_jobs IS 'SchedulePredefinedAnalyses or SchedulePredefinedAnalysisJobs';
