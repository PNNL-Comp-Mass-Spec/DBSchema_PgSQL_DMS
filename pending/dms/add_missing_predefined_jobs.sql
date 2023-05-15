--
CREATE OR REPLACE PROCEDURE public.add_missing_predefined_jobs
(
    _infoOnly boolean = false,
    _maxDatasetsToProcess int = 0,
    _dayCountForRecentDatasets int = 30,
    _previewOutputType text = 'Show Jobs',
    _analysisToolNameFilter text = '',
    _excludeDatasetsNotReleased boolean = true,
    _excludeUnreviewedDatasets boolean = true,
    _instrumentSkipList text = 'Agilent_GC_MS_01, TSQ_1, TSQ_3',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _datasetNameIgnoreExistingJobs text = '',
    _ignoreJobsCreatedBeforeDisposition boolean = true,
    _campaignFilter text = '',
    _datasetIDFilterList text = '',
    _showDebug boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for Datasets that don't have predefined analysis jobs
**      but possibly should. Calls schedule_predefined_analysis_jobs for each.
**      This procedure is intended to be run once per day to add missing jobs
**      for datasets created within the last 30 days (but more than 12 hours ago).
**
**  Arguments:
**    _infoOnly                             False to create jobs, true to preview jobs that would be created
**    _dayCountForRecentDatasets            Will examine datasets created within this many days of the present
**    _previewOutputType                    Used if _infoOnly is true; options are 'Show Rules' or 'Show Jobs'
**    _analysisToolNameFilter               Optional: if not blank, only considers predefines and jobs that match the given tool name (can contain wildcards)
**    _excludeDatasetsNotReleased           When true, excludes datasets with a rating of -5, -6, or -7 (we always exclude datasets with a rating of -1, and -2)
**    _excludeUnreviewedDatasets            When true, excludes datasets with a rating of -10
**    _instrumentSkipList                   Comma-separated list of instruments to skip
**    _datasetNameIgnoreExistingJobs        If defined, we'll create predefined jobs for this dataset even if it has existing jobs
**    _ignoreJobsCreatedBeforeDisposition   When true, ignore jobs created before the dataset was dispositioned
**    _campaignFilter                       Optional: if not blank, filters on the given campaign name
**    _datasetIDFilterList                  Comma-separated list of Dataset IDs to process
**    _showDebug                            When true, show additional debug information
**
**  Auth:   mem
**  Date:   05/23/2008 mem - Ticket #675
**          10/30/2008 mem - Updated to only create jobs for datasets in state 3=Complete
**          05/14/2009 mem - Added parameters _analysisToolNameFilter and _excludeDatasetsNotReleased
**          10/25/2010 mem - Added parameter _datasetNameIgnoreExistingJobs
**          11/18/2010 mem - Now skipping datasets with a rating of -6 (Rerun, good data) when _excludeDatasetsNotReleased is true
**          02/10/2011 mem - Added parameters _excludeUnreviewedDatasets and _instrumentSkipList
**          05/24/2011 mem - Added parameter _ignoreJobsCreatedBeforeDisposition
**                         - Added support for rating -7
**          08/05/2013 mem - Now passing _analysisToolNameFilter to predefined_analysis_job_preview (predefined_analysis_jobs) when _infoOnly is true
**                         - Added parameter _campaignFilter
**          01/08/2014 mem - Now returning additional debug information when _infoOnly is true
**          06/18/2014 mem - Now passing default to udfParseDelimitedList
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/03/2017 mem - Exclude datasets associated with the Tracking experiment
**                         - Exclude datasets of type Tracking
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          03/25/2020 mem - Add parameter _datasetIDFilterList and add support for _showDebug
**          11/28/2022 mem - Always log an error if schedule_predefined_analysis_jobs has a non-zero return code
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _showRules boolean := false;
    _updateCount int := 0;
    _datasetsProcessed int;
    _datasetsWithNewJobs int;
    _entryID int;
    _datasetID int;
    _datasetName text;
    _jobCountAdded int;
    _startDate timestamp;
    _callingProcName text;
    _currentLocation text := 'Start';

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
    --
    _infoOnly := Coalesce(_infoOnly, false);
    _maxDatasetsToProcess := Coalesce(_maxDatasetsToProcess, 0);
    _dayCountForRecentDatasets := Coalesce(_dayCountForRecentDatasets, 30);
    _previewOutputType := Coalesce(_previewOutputType, 'Show Rules');
    _analysisToolNameFilter := Coalesce(_analysisToolNameFilter, '');
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _excludeUnreviewedDatasets := Coalesce(_excludeUnreviewedDatasets, true);
    _instrumentSkipList := Coalesce(_instrumentSkipList, '');
    _datasetNameIgnoreExistingJobs := Coalesce(_datasetNameIgnoreExistingJobs, '');
    _ignoreJobsCreatedBeforeDisposition := Coalesce(_ignoreJobsCreatedBeforeDisposition, true);
    _campaignFilter := Coalesce(_campaignFilter, '');
    _datasetIDFilterList := Coalesce(_datasetIDFilterList, '');
    _showDebug := Coalesce(_showDebug, false);

    If _dayCountForRecentDatasets < 1 Then
        _dayCountForRecentDatasets := 1;
    End If;

    If _infoOnly And (Not _previewOutputType::citext IN ('Show Rules', 'Show Jobs')) Then
        _message := 'Unknown value for _previewOutputType (' || _previewOutputType || '); should be "Show Rules" or "Show Jobs"';

        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _infoOnly And _previewOutputType::citext = 'Show Rules'::citext Then
        _showRules := true;
    Else
        _showRules := false;
    End If;

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToProcess (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Dataset_ID int NOT NULL,
        Process_Dataset boolean
    )

    CREATE TEMP TABLE Tmp_DSRating_Exclusion_List (
        Rating int
    )

    CREATE TEMP TABLE Tmp_DatasetID_Filter_List (
        Dataset_ID int
    )

    -- Populate Tmp_DSRating_Exclusion_List
    INSERT INTO Tmp_DSRating_Exclusion_List (Rating) Values (-1);        -- No Data (Blank/Bad)
    INSERT INTO Tmp_DSRating_Exclusion_List (Rating) Values (-2);        -- Data Files Missing

    If _excludeUnreviewedDatasets Then
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) Values (-10);        -- Unreviewed
    End If;

    If _excludeDatasetsNotReleased Then
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) Values (-5);    -- Not Released
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) Values (-6);    -- Rerun (Good Data)
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) Values (-7);    -- Rerun (Superseded)
    End If;

    If char_length(_datasetIDFilterList) > 0 Then
        INSERT INTO Tmp_DatasetID_Filter_List (Dataset_ID)
        SELECT Value
        FROM public.parse_delimited_integer_list(_datasetIDFilterList, ',');
    End If;

    ---------------------------------------------------
    -- Find datasets that were created within the last _dayCountForRecentDatasets days
    -- (but over 12 hours ago) that do not have analysis jobs
    -- Also excludes datasets with an undesired state or undesired rating
    -- Optionally only matches analysis tools with names matching _analysisToolNameFilter
    ---------------------------------------------------
    --
    -- First construct a list of all recent datasets that have an instrument class
    -- that has an active predefined job
    -- Optionally filter on campaign
    --
    INSERT INTO Tmp_DatasetsToProcess( dataset_id, Process_Dataset )
    SELECT DISTINCT DS.dataset_id, true AS Process_Dataset
    FROM t_dataset DS
         INNER JOIN T_Dataset_Type_Name DSType
           ON DSType.DST_Type_ID = DS.dataset_type_ID
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_campaign C
           ON E.campaign_id = C.campaign_id
    WHERE (NOT DS.dataset_rating_id IN (SELECT Rating FROM Tmp_DSRating_Exclusion_List)) AND
          (DS.dataset_state_id = 3) AND
          (_campaignFilter = '' Or C.campaign Like _campaignFilter) AND
          (NOT DSType.Dataset_Type IN ('tracking')) AND
          (NOT E.experiment in ('tracking')) AND
          (DS.created BETWEEN CURRENT_TIMESTAMP - make_interval(days => _dayCountForRecentDatasets) AND
                              CURRENT_TIMESTAMP - INTERVAL '12 HOURS') AND
          InstName.instrument_class IN ( SELECT DISTINCT InstClass.instrument_class
                                 FROM t_predefined_analysis PA
                                      INNER JOIN t_instrument_class InstClass
                                        ON PA.instrument_class_criteria = InstClass.instrument_class
                                 WHERE (PA.enabled <> 0) AND
                                       (_analysisToolNameFilter = '' OR
                                        PA.analysis_tool_name LIKE _analysisToolNameFilter) )
    ORDER BY DS.dataset_id

    If _infoOnly And _showDebug AND EXISTS (SELECT * FROM Tmp_DatasetID_Filter_List) Then

        -- ToDo: Show this using RAISE INFO

        SELECT 'Debug_Output #1' AS Status,
               InstName.instrument,
               DS.dataset_id,
               DS.dataset,
               DS.created,
               DS.comment,
               DS.dataset_state_id,
               DS.dataset_rating_id,
               DTP.Process_Dataset
        FROM Tmp_DatasetsToProcess DTP
             INNER JOIN t_dataset DS
               ON DTP.dataset_id = DS.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
             INNER JOIN Tmp_DatasetID_Filter_List FilterList
               ON FilterList.dataset_id = DTP.dataset_id
        ORDER BY DS.dataset_id
    End If;

    -- Now exclude any datasets that have analysis jobs in t_analysis_job
    -- Filter on _analysisToolNameFilter if not empty
    --
    UPDATE Tmp_DatasetsToProcess DTP
    Set Process_Dataset = false
    FROM ( SELECT AJ.dataset_id AS Dataset_ID
           FROM t_analysis_job AJ
                INNER JOIN t_analysis_tool Tool
                  ON AJ.analysis_tool_id = Tool.analysis_tool_id
           WHERE (_analysisToolNameFilter = '' OR Tool.analysis_tool LIKE _analysisToolNameFilter) AND
                 (Not _ignoreJobsCreatedBeforeDisposition OR AJ.dataset_unreviewed = 0 )
          ) JL
    WHERE DTP.dataset_id = JL.dataset_id AND
          DTP.Process_Dataset;

    If _infoOnly And _showDebug And EXISTS (SELECT * FROM Tmp_DatasetID_Filter_List) Then

        -- ToDo: Show this using RAISE INFO

        SELECT 'Debug_Output #2' AS Status,
               InstName.instrument,
               DS.dataset_id,
               DS.dataset,
               DS.created,
               DS.comment,
               DS.dataset_state_id,
               DS.dataset_rating_id,
               DTP.Process_Dataset
        FROM Tmp_DatasetsToProcess DTP
             INNER JOIN t_dataset DS
               ON DTP.dataset_id = DS.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
             INNER JOIN Tmp_DatasetID_Filter_List FilterList
               ON FilterList.dataset_id = DTP.dataset_id
        ORDER BY DS.dataset_id;
    End If;

    -- Next, exclude any datasets that have been processed by schedule_predefined_analysis_jobs
    -- This check also compares the dataset's current rating to the rating it had when previously processed
    --
    UPDATE Tmp_DatasetsToProcess DTP
    Set Process_Dataset = false
    FROM t_dataset DS INNER JOIN
         t_predefined_analysis_scheduling_queue_history QH
         ON DS.dataset_id = QH.dataset_id AND DS.dataset_rating_id = QH.dataset_rating_id
    WHERE DTP.dataset_id =DS.dataset_id AND
          DTP.Process_Dataset;

    If _infoOnly And _showDebug And EXISTS (SELECT * FROM Tmp_DatasetID_Filter_List) Then

        -- ToDo: Show this using RAISE INFO

        SELECT 'Debug_Output #3' AS Status,
               InstName.instrument,
               DS.dataset_id,
               DS.dataset,
               DS.created,
               DS.comment,
               DS.dataset_state_id,
               DS.dataset_rating_id,
               DTP.Process_Dataset
        FROM Tmp_DatasetsToProcess DTP
             INNER JOIN t_dataset DS
               ON DTP.dataset_id = DS.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
             INNER JOIN Tmp_DatasetID_Filter_List FilterList
               ON FilterList.dataset_id = DTP.dataset_id
        ORDER BY DS.dataset_id;
    End If;

    If Exists (SELECT * FROM Tmp_DatasetID_Filter_List) Then
        -- Exclude datasets not in Tmp_DatasetID_Filter_List
        UPDATE Tmp_DatasetsToProcess
        Set Process_Dataset = false
        WHERE Process_Dataset And
              NOT Dataset_ID IN (SELECT Dataset_ID FROM Tmp_DatasetID_Filter_List);
    End If;

    -- Exclude datasets from instruments in _instrumentSkipList
    If _instrumentSkipList <> '' Then
        UPDATE Tmp_DatasetsToProcess
        SET Process_Dataset = false
        FROM Tmp_DatasetsToProcess Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE Tmp_DatasetsToProcess
        **   SET ...
        **   FROM source
        **   WHERE source.id = Tmp_DatasetsToProcess.id;
        ********************************************************************************/

                               ToDo: Fix this query

         INNER JOIN t_dataset DS
               ON Target.dataset_id = DS.dataset_id
             INNER JOIN t_instrument_name InstName
             ON InstName.instrument_id = DS.instrument_id
             INNER JOIN public.parse_delimited_list(_instrumentSkipList) AS ExclusionList
               ON InstName.instrument = ExclusionList.Value;
    End If;

    -- Add dataset _datasetNameIgnoreExistingJobs
    If _datasetNameIgnoreExistingJobs <> '' Then
        UPDATE Tmp_DatasetsToProcess
        SET Process_Dataset = true
        FROM t_dataset DS
        WHERE Target.dataset_id = DS.dataset_id AND
              DS.dataset = _datasetNameIgnoreExistingJobs;
    End If;

    If _infoOnly Then
        SELECT InstName.instrument,
               DS.dataset_id,
               DS.dataset,
               DS.created,
               DS.comment,
               DS.dataset_state_id,
               DS.dataset_rating_id,
               DTP.Process_Dataset
        FROM Tmp_DatasetsToProcess DTP
             INNER JOIN t_dataset DS
               ON DTP.dataset_id = DS.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
        WHERE DTP.Process_Dataset = true
        ORDER BY InstName.instrument, DS.dataset_id;

        If _infoOnly And _showDebug Then

            -- ToDo: Show this using RAISE INFO

            SELECT 'Ignored' AS Status,
                   InstName.instrument,
                   DS.dataset_id,
                   DS.dataset,
                   DS.created,
                   DS.comment,
                   DS.dataset_state_id,
                   DS.dataset_rating_id,
                   DTP.Process_Dataset
            FROM Tmp_DatasetsToProcess DTP
                 INNER JOIN t_dataset DS
                   ON DTP.dataset_id = DS.dataset_id
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
            WHERE DTP.Process_Dataset = false
            ORDER BY InstName.instrument, DS.dataset_id;
        End If;
    End If;

    -- Look for datasets with Process_Dataset = true in Tmp_DatasetsToProcess

    If Not Exists (SELECT COUNT(*) FROM Tmp_DatasetsToProcess WHERE Process_Dataset) Then
        _message := 'All recent (valid) datasets with potential predefined jobs already have existing analysis jobs';
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_DatasetsToProcess;
        DROP TABLE Tmp_DSRating_Exclusion_List;
        DROP TABLE Tmp_DatasetID_Filter_List;

        RETURN;
    End If;

    If _infoOnly Then
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
        )
    End If;

    -- Remove any extra datasets from Tmp_DatasetsToProcess
    DELETE FROM Tmp_DatasetsToProcess
    WHERE Not Process_Dataset;

    ---------------------------------------------------
    -- Loop through the datasets in Tmp_DatasetsToProcess
    -- and call schedule_predefined_analysis_jobs for each one
    ---------------------------------------------------

    _datasetsProcessed := 0;
    _datasetsWithNewJobs := 0;

    _entryID := 0;

    FOR _entryID, _datasetID, _datasetName IN
        SELECT DTP.Entry_ID,
               DTP.dataset_id,
               DS.dataset
        FROM Tmp_DatasetsToProcess DTP
             INNER JOIN t_dataset DS
               ON DTP.dataset_id = DS.dataset_id
        ORDER BY Entry_ID
    LOOP
        BEGIN

            If _infoOnly And _showRules Then

                _currentLocation := 'Querying predefined_analysis_jobs for ' || _datasetName;

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
                            _raiseErrorMessages => true,
                            _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                            _createJobsForUnreviewedDatasets => true,
                            _analysisToolNameFilter => _analysisToolNameFilter);

                -- ToDo: Show the contents of Tmp_JobsToCreate

            ElsIf _infoOnly And Not _showRules Then

                -- ToDo: Call the function that shows the predefined analysis rules that apply to this dataset

            End If;

            _currentLocation := 'Calling schedule_predefined_analysis_jobs for ' || _datasetName;
            _startDate := CURRENT_TIMESTAMP;

            Call schedule_predefined_analysis_jobs (_datasetName,
                                                    _analysisToolNameFilter => _analysisToolNameFilter,
                                                    _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                                                    _infoOnly => _infoOnly,
                                                    _returnCode => _returnCode);

            If _returnCode = '' And Not _infoOnly Then
                -- See if jobs were actually added by querying t_analysis_job

                _jobCountAdded := 0;

                SELECT COUNT(*)
                INTO _jobCountAdded
                FROM t_analysis_job
                WHERE dataset_id = _datasetID AND
                      created >= _startDate;

                If _jobCountAdded > 0 Then
                    UPDATE t_analysis_job
                    SET comment = Coalesce(comment, '') || ' (missed predefine)'
                    WHERE dataset_id = _datasetID AND
                          created >= _startDate;
                    --
                    GET DIAGNOSTICS _updateCount = ROW_COUNT;

                    If _updateCount <> _jobCountAdded Then
                        _message := 'Added ' || _jobCountAdded::text || ' missing predefined analysis job(s) for dataset ' || _datasetName ||
                                    ', but updated the comment for ' || _updateCount::text || ' job(s); mismatch is unexpected';

                        Call post_log_entry ('Error', _message, 'Add_Missing_Predefined_Jobs');
                    End If;

                    _message := 'Added ' || _jobCountAdded::text || ' missing predefined analysis job';
                    If _jobCountAdded <> 1 Then
                        _message := _message || 's';
                    End If;

                    _message := _message || ' for dataset ' || _datasetName;

                    Call post_log_entry ('Warning', _message, 'Add_Missing_Predefined_Jobs');

                    _datasetsWithNewJobs := _datasetsWithNewJobs + 1;
                End If;

            ElsIf Not _infoOnly Then
                _message := 'Error calling schedule_predefined_analysis_jobs for dataset ' || _datasetName || '; return code ' || _returnCode;
                Call post_log_entry ('Error', _message, 'Add_Missing_Predefined_Jobs');
                _message := '';
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
        END;

        If Not _infoOnly Then
            -- Commit the newly created jobs
            COMMIT;
        End If;

        _datasetsProcessed := _datasetsProcessed + 1;

        If _maxDatasetsToProcess > 0 And _datasetsProcessed >= _maxDatasetsToProcess Then
            -- Break out of the For loop
            EXIT;
        End If;

    END LOOP;

    If _datasetsProcessed > 0 And Not _infoOnly Then
        _message := 'Added predefined analysis jobs for ' || _datasetsWithNewJobs::text || ' dataset';
        If _datasetsWithNewJobs <> 1 Then
            _message := _message || 's';
        End If;

        _message := _message || ' (processed ' || _datasetsProcessed::text || ' dataset';
        If _datasetsProcessed <> 1 Then
            _message := _message || 's';
        End If;

        _message := _message || ')';

        If _datasetsWithNewJobs > 0 And Not _infoOnly Then
            Call post_log_entry ('Normal', _message, 'Add_Missing_Predefined_Jobs');
        End If;

    End If;

    DROP TABLE IF EXISTS Tmp_DatasetsToProcess;
    DROP TABLE IF EXISTS Tmp_DSRating_Exclusion_List;
    DROP TABLE IF EXISTS Tmp_DatasetID_Filter_List;
END
$$;

COMMENT ON PROCEDURE public.add_missing_predefined_jobs IS 'AddMissingPredefinedJobs';
