--
-- Name: schedule_predefined_analysis_jobs(text, text, text, boolean, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.schedule_predefined_analysis_jobs(IN _datasetnamesorids text, IN _callinguser text DEFAULT ''::text, IN _analysistoolnamefilter text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _preventduplicatejobs boolean DEFAULT true, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Schedule analysis jobs for dataset according to defaults
**
**  Arguments:
**    _datasetNamesOrIDs            Comma separated list of dataset names or dataset IDs
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
**          06/25/2025 mem - Add support for a list of dataset names and/or IDs
**                         - Rename parameter _datasetName to _datasetNamesOrIDs
**          06/27/2025 mem - Rename temp table to avoid a naming conflict with calling procedures
**
*****************************************************/
DECLARE
    _state text := 'New';
    _datasetCount int;
    _datasetInfo record;
    _invalidNames citext;
    _msg citext;

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
        -- Resolve dataset names to IDs, storing in a temporary table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Datasets_to_Schedule (
            Entry_ID int NOT NULL GENERATED ALWAYS AS IDENTITY,
            Dataset_Name_Or_ID citext,
            Dataset_Name citext NULL,
            Dataset_ID int NULL,
            Ignore bool NOT NULL default false,
            Processed bool NOT NULL default false,
            Skipped bool NOT NULL default false
        );

        INSERT INTO Tmp_Datasets_to_Schedule (Dataset_Name_Or_ID)
        SELECT value
        FROM public.parse_delimited_list(_datasetNamesOrIDs)
        ORDER BY value;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_Datasets_to_Schedule;

        -- Check for matching dataset names
        UPDATE Tmp_Datasets_to_Schedule
        SET dataset_name = DS.dataset, dataset_id = DS.dataset_id
        FROM T_Dataset DS
        WHERE Tmp_Datasets_to_Schedule.Dataset_Name_Or_ID = DS.dataset;

        -- Check for matching dataset IDs
        UPDATE Tmp_Datasets_to_Schedule
        SET dataset_name = DS.dataset, dataset_id = DS.dataset_id
        FROM T_Dataset DS
        WHERE Tmp_Datasets_to_Schedule.Dataset_Name Is Null AND
              public.try_cast(Tmp_Datasets_to_Schedule.Dataset_Name_Or_ID, null::int) = DS.dataset_id;

        ---------------------------------------------------
        -- Raise a warning for items that did not resolve
        ---------------------------------------------------

        SELECT String_Agg(dataset_name_or_id, ', ' ORDER BY dataset_name_or_id)
        INTO _invalidNames
        FROM Tmp_Datasets_to_Schedule
        WHERE dataset_id IS NULL;

        If Coalesce(_invalidNames, '') <> '' Then
            _message := format('Could not resolve dataset name or ID for %s %s',
                public.check_plural(_invalidNames, 'dataset', 'datasets'),
                _invalidNames);
            RAISE WARNING '%', _message;

            -- Leave _returnCode as ''
            DROP TABLE Tmp_Datasets_to_Schedule;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Find datasets that are already in t_predefined_analysis_scheduling_queue with state 'New'
        -- For any matches, set Ignore to true in the temporary table
        ---------------------------------------------------

        UPDATE Tmp_Datasets_to_Schedule
        SET Ignore = true
        FROM t_predefined_analysis_scheduling_queue PASQ
        WHERE Tmp_Datasets_to_Schedule.dataset_id = PASQ.dataset_id AND
              PASQ.State = 'New';

        ---------------------------------------------------
        -- Process each dataset in Tmp_Datasets_to_Schedule
        ---------------------------------------------------

        If _infoOnly Then
            RAISE INFO '';
        End If;

        FOR _datasetInfo IN
            SELECT dataset_name, dataset_id, ignore, MIN(entry_id) AS entry_id
            FROM Tmp_Datasets_to_Schedule
            GROUP BY dataset_name, dataset_id, ignore
            ORDER BY dataset_id
        LOOP
            If _datasetInfo.ignore Then
                If _infoOnly Then
                    RAISE INFO 'Skip Dataset ID % since it already has a "New" entry in t_predefined_analysis_scheduling_queue: %',
                               _datasetInfo.dataset_id, _datasetInfo.dataset_name;
                End If;

                UPDATE Tmp_Datasets_to_Schedule
                SET Skipped = true
                WHERE entry_id = _datasetInfo.entry_id;

                CONTINUE;
            End If;

            If _infoOnly Then
                RAISE INFO 'Would add a new row to t_predefined_analysis_scheduling_queue for Dataset ID % (%)',
                           _datasetInfo.dataset_id,
                           _datasetInfo.dataset_name;

                UPDATE Tmp_Datasets_to_Schedule
                SET Processed = true
                WHERE entry_id = _datasetInfo.entry_id;

                CONTINUE;
            End If;

            INSERT INTO t_predefined_analysis_scheduling_queue (
                dataset_id,
                calling_user,
                analysis_tool_name_filter,
                exclude_datasets_not_released,
                prevent_duplicate_jobs,
                state,
                message
            )
            VALUES (_datasetInfo.dataset_id,
                    _callingUser,
                    _analysisToolNameFilter,
                    CASE WHEN _excludeDatasetsNotReleased THEN 1 ELSE 0 End,
                    CASE WHEN _preventDuplicateJobs       THEN 1 ELSE 0 End,
                    _state,
                    _message);

            UPDATE Tmp_Datasets_to_Schedule
            SET Processed = true
            WHERE entry_id = _datasetInfo.entry_id;
        END LOOP;

        If _datasetCount > 0 Then
            RAISE INFO '';

            _msg := '';

            SELECT String_Agg(dataset_name, ', ' ORDER BY dataset_name)
            INTO _msg
            FROM Tmp_Datasets_to_Schedule
            WHERE Processed;

            If Coalesce(_msg, '') <> '' Then
                If _infoOnly Then
                    RAISE INFO 'Would process % %', check_plural(_msg, 'dataset', 'datasets'), _msg;
                Else
                    RAISE INFO 'Processed % %', check_plural(_msg, 'dataset', 'datasets'), _msg;
                End If;
            End If;

            _msg := '';

            SELECT String_Agg(dataset_name, ', ' ORDER BY dataset_name)
            INTO _msg
            FROM Tmp_Datasets_to_Schedule
            WHERE Skipped;

            If Coalesce(_msg, '') <> '' Then
                RAISE INFO 'Skipped % %', check_plural(_msg, 'dataset', 'datasets'), _msg;
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

    DROP TABLE IF EXISTS Tmp_Datasets_to_Schedule;
END
$$;


ALTER PROCEDURE public.schedule_predefined_analysis_jobs(IN _datasetnamesorids text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE schedule_predefined_analysis_jobs(IN _datasetnamesorids text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.schedule_predefined_analysis_jobs(IN _datasetnamesorids text, IN _callinguser text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _preventduplicatejobs boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SchedulePredefinedAnalyses or SchedulePredefinedAnalysisJobs';

