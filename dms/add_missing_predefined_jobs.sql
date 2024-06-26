--
-- Name: add_missing_predefined_jobs(boolean, integer, integer, text, text, boolean, boolean, text, text, boolean, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_missing_predefined_jobs(IN _infoonly boolean DEFAULT false, IN _maxdatasetstoprocess integer DEFAULT 0, IN _daycountforrecentdatasets integer DEFAULT 30, IN _previewoutputtype text DEFAULT 'Show Jobs'::text, IN _analysistoolnamefilter text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _excludeunrevieweddatasets boolean DEFAULT true, IN _instrumentskiplist text DEFAULT 'Agilent_GC_MS_01, TSQ_1, TSQ_3'::text, IN _datasetnameignoreexistingjobs text DEFAULT ''::text, IN _ignorejobscreatedbeforedisposition boolean DEFAULT true, IN _campaignfilter text DEFAULT ''::text, IN _datasetidfilterlist text DEFAULT ''::text, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for datasets that don't have predefined analysis jobs but possibly should; calls schedule_predefined_analysis_jobs for each
**
**      This procedure is intended to be run once per day to add missing jobs for datasets created within the last 30 days (but more than 12 hours ago)
**
**  Arguments:
**    _infoOnly                             False to create jobs, true to preview jobs that would be created
**    _maxDatasetsToProcess                 Maximum number of datasets to process
**    _dayCountForRecentDatasets            Will examine datasets created within this many days of the present
**    _previewOutputType                    Used if _infoOnly is true; options are 'Show Rules' or 'Show Jobs'
**    _analysisToolNameFilter               Optional: if not blank, only considers predefines and jobs that match the given tool name (can contain wildcards)
**    _excludeDatasetsNotReleased           When true, excludes datasets with a rating of -5, -6, or -7 (we always exclude datasets with a rating of -1, and -2)
**    _excludeUnreviewedDatasets            When true, excludes datasets with a rating of -10
**    _instrumentSkipList                   Optional: comma-separated list of instruments to skip
**    _datasetNameIgnoreExistingJobs        If defined, create predefined jobs for this dataset even if it has existing jobs
**    _ignoreJobsCreatedBeforeDisposition   When true, ignore jobs created before the dataset was dispositioned
**    _campaignFilter                       Optional: if not blank, filters on the given campaign name
**    _datasetIDFilterList                  Optional: comma-separated list of Dataset IDs to process
**    _showDebug                            When true, show additional debug information
**    _message                              Status message
**    _returnCode                           Return code
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
**          06/18/2014 mem - Now passing default to Parse_Delimited_List
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/03/2017 mem - Exclude datasets associated with the Tracking experiment
**                         - Exclude datasets of type Tracking
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          03/25/2020 mem - Add parameter _datasetIDFilterList and add support for _showDebug
**          11/28/2022 mem - Always log an error if schedule_predefined_analysis_jobs has a non-zero return code
**          12/13/2023 mem - Call procedure create_pending_predefined_analysis_tasks to create jobs
**                         - Ported to PostgreSQL
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          03/15/2024 mem - Show reason why datasets are skipped
**                         - When _datasetIDFilterList is provided, if _infoOnly and _showDebug are true, only show the specified datasets in the output pane
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

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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

    _infoOnly                           := Coalesce(_infoOnly, false);
    _maxDatasetsToProcess               := Coalesce(_maxDatasetsToProcess, 0);
    _dayCountForRecentDatasets          := Coalesce(_dayCountForRecentDatasets, 30);
    _previewOutputType                  := Trim(Coalesce(_previewOutputType, 'Show Rules'));
    _analysisToolNameFilter             := Trim(Coalesce(_analysisToolNameFilter, ''));
    _excludeDatasetsNotReleased         := Coalesce(_excludeDatasetsNotReleased, true);
    _excludeUnreviewedDatasets          := Coalesce(_excludeUnreviewedDatasets, true);
    _instrumentSkipList                 := Trim(Coalesce(_instrumentSkipList, ''));
    _datasetNameIgnoreExistingJobs      := Trim(Coalesce(_datasetNameIgnoreExistingJobs, ''));
    _ignoreJobsCreatedBeforeDisposition := Coalesce(_ignoreJobsCreatedBeforeDisposition, true);
    _campaignFilter                     := Trim(Coalesce(_campaignFilter, ''));
    _datasetIDFilterList                := Trim(Coalesce(_datasetIDFilterList, ''));
    _showDebug                          := Coalesce(_showDebug, false);

    If _dayCountForRecentDatasets < 1 Then
        _dayCountForRecentDatasets := 1;
    End If;

    If _infoOnly And (Not _previewOutputType::citext In ('Show Rules', 'Show Jobs')) Then
        _message := format('Unknown value for _previewOutputType (%s); should be "Show Rules" or "Show Jobs"', _previewOutputType);

        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _infoOnly And _previewOutputType::citext = 'Show Rules' Then
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
        Process_Dataset boolean NOT NULL,
        Skip_Reason text NOT NULL
    );

    CREATE TEMP TABLE Tmp_DSRating_Exclusion_List (
        Rating int
    );

    CREATE TEMP TABLE Tmp_DatasetID_Filter_List (
        Dataset_ID int
    );

    -- Populate Tmp_DSRating_Exclusion_List
    INSERT INTO Tmp_DSRating_Exclusion_List (Rating) VALUES (-1);        -- No Data (Blank/Bad)
    INSERT INTO Tmp_DSRating_Exclusion_List (Rating) VALUES (-2);        -- Data Files Missing

    If _excludeUnreviewedDatasets Then
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) VALUES (-10);        -- Unreviewed
    End If;

    If _excludeDatasetsNotReleased Then
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) VALUES (-5);    -- Not Released
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) VALUES (-6);    -- Rerun (Good Data)
        INSERT INTO Tmp_DSRating_Exclusion_List (Rating) VALUES (-7);    -- Rerun (Superseded)
    End If;

    If _datasetIDFilterList <> '' Then
        INSERT INTO Tmp_DatasetID_Filter_List (Dataset_ID)
        SELECT Value
        FROM public.parse_delimited_integer_list(_datasetIDFilterList);
    End If;

    ---------------------------------------------------
    -- Find datasets that were created within the last _dayCountForRecentDatasets days (but over 12 hours ago) that do not have any analysis jobs
    -- Exclude datasets with an undesired state or undesired rating
    -- Optionally only matches analysis tools with names matching _analysisToolNameFilter
    ---------------------------------------------------

    -- First construct a list of all recent datasets that have an instrument class that has an active predefined job
    -- Optionally filter on campaign

    INSERT INTO Tmp_DatasetsToProcess (Dataset_ID, Process_Dataset, Skip_Reason)
    SELECT DISTINCT DS.dataset_id, true AS Process_Dataset, '' AS Skip_Reason
    FROM t_dataset DS
         INNER JOIN t_dataset_type_name DSType
           ON DSType.dataset_type_id = DS.dataset_type_ID
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_campaign C
           ON E.campaign_id = C.campaign_id
    WHERE NOT DS.dataset_rating_id IN (SELECT Rating FROM Tmp_DSRating_Exclusion_List) AND
          DS.dataset_state_id = 3 AND
          (_campaignFilter = '' Or C.campaign ILIKE _campaignFilter) AND
          NOT DSType.Dataset_Type IN ('tracking') AND
          NOT E.experiment in ('tracking') AND
          DS.created BETWEEN CURRENT_TIMESTAMP - make_interval(days => _dayCountForRecentDatasets) AND
                             CURRENT_TIMESTAMP - INTERVAL '12 hours' AND
          InstName.instrument_class IN (SELECT DISTINCT InstClass.instrument_class
                                        FROM t_predefined_analysis PA
                                             INNER JOIN t_instrument_class InstClass
                                               ON PA.instrument_class_criteria = InstClass.instrument_class
                                        WHERE PA.enabled <> 0 AND
                                              (_analysisToolNameFilter = '' OR
                                               PA.analysis_tool_name ILIKE _analysisToolNameFilter)
                                       )
    ORDER BY DS.dataset_id;

    _formatSpecifier := '%-15s %-25s %-10s %-20s %-8s %-9s %-7s %-80s %-80s %-60s';

    _infoHead := format(_formatSpecifier,
                        'Status',
                        'Instrument',
                        'Dataset_ID',
                        'Created',
                        'State_ID',
                        'Rating_ID',
                        'Process',
                        'Skip_Reason',
                        'Dataset',
                        'Comment'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '---------------',
                                 '-------------------------',
                                 '----------',
                                 '--------------------',
                                 '--------',
                                 '---------',
                                 '-------',
                                 '--------------------------------------------------------------------------------',
                                 '--------------------------------------------------------------------------------',
                                 '------------------------------------------------------------'
                                );

    If _infoOnly And _showDebug And Exists (SELECT Dataset_ID FROM Tmp_DatasetID_Filter_List) Then

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Debug_Output #1' AS Status,
                   InstName.instrument,
                   DS.dataset_id AS DatasetID,
                   public.timestamp_text(DS.created) AS Created,
                   DS.dataset_state_id AS StateID,
                   DS.dataset_rating_id AS RatingID,
                   DTP.Process_Dataset AS Process,
                   DTP.Skip_Reason,
                   DS.Dataset,
                   DS.Comment
            FROM Tmp_DatasetsToProcess DTP
                 INNER JOIN t_dataset DS
                   ON DTP.dataset_id = DS.dataset_id
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN Tmp_DatasetID_Filter_List FilterList
                   ON FilterList.dataset_id = DTP.dataset_id
            ORDER BY DS.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Status,
                                _previewData.Instrument,
                                _previewData.DatasetID,
                                _previewData.Created,
                                _previewData.StateID,
                                _previewData.RatingID,
                                _previewData.Process,
                                _previewData.Skip_Reason,
                                _previewData.Dataset,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    -- Now exclude any datasets that have analysis jobs in t_analysis_job (regardless of whether or not the analysis job was created by a predefine)
    -- Filter on _analysisToolNameFilter if not empty

    UPDATE Tmp_DatasetsToProcess DTP
    SET Process_Dataset = false,
        Skip_Reason = CASE WHEN _analysisToolNameFilter = ''
                           THEN 'Has an existing analysis job'
                           ELSE format('Has a %s job', _analysisToolNameFilter)
                      END
    FROM (SELECT AJ.dataset_id AS Dataset_ID
          FROM t_analysis_job AJ
               INNER JOIN t_analysis_tool Tool
                 ON AJ.analysis_tool_id = Tool.analysis_tool_id
          WHERE (_analysisToolNameFilter = '' OR Tool.analysis_tool ILIKE _analysisToolNameFilter) AND
                (Not _ignoreJobsCreatedBeforeDisposition OR AJ.dataset_unreviewed = 0)
         ) JL
    WHERE DTP.dataset_id = JL.dataset_id AND
          DTP.Process_Dataset;

    If _infoOnly And _showDebug And Exists (SELECT Dataset_ID FROM Tmp_DatasetID_Filter_List) Then

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Debug_Output #2' AS Status,
                   InstName.instrument,
                   DS.dataset_id AS DatasetID,
                   public.timestamp_text(DS.created) AS Created,
                   DS.dataset_state_id AS StateID,
                   DS.dataset_rating_id AS RatingID,
                   DTP.Process_Dataset AS Process,
                   DTP.Skip_Reason,
                   DS.dataset,
                   DS.comment
            FROM Tmp_DatasetsToProcess DTP
                 INNER JOIN t_dataset DS
                   ON DTP.dataset_id = DS.dataset_id
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN Tmp_DatasetID_Filter_List FilterList
                   ON FilterList.dataset_id = DTP.dataset_id
            ORDER BY DS.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Status,
                                _previewData.Instrument,
                                _previewData.DatasetID,
                                _previewData.Created,
                                _previewData.StateID,
                                _previewData.RatingID,
                                _previewData.Process,
                                _previewData.Skip_Reason,
                                _previewData.Dataset,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    -- Next, exclude any datasets that have been processed by schedule_predefined_analysis_jobs
    -- This check also compares the dataset's current rating to the rating it had when previously processed

    UPDATE Tmp_DatasetsToProcess DTP
    SET Process_Dataset = false,
        Skip_Reason = 'Found in t_predefined_analysis_scheduling_queue_history'
    FROM t_dataset DS
         INNER JOIN t_predefined_analysis_scheduling_queue_history QH
           ON DS.dataset_id = QH.dataset_id AND
              DS.dataset_rating_id = QH.dataset_rating_id
    WHERE DTP.dataset_id = DS.dataset_id AND
          DTP.Process_Dataset;

    If _infoOnly And _showDebug And Exists (SELECT Dataset_ID FROM Tmp_DatasetID_Filter_List) Then

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Debug_Output #3' AS Status,
                   InstName.instrument,
                   DS.dataset_id AS DatasetID,
                   public.timestamp_text(DS.created) AS Created,
                   DS.dataset_state_id AS StateID,
                   DS.dataset_rating_id AS RatingID,
                   DTP.Process_Dataset AS Process,
                   DTP.Skip_Reason,
                   DS.dataset,
                   DS.comment
            FROM Tmp_DatasetsToProcess DTP
                 INNER JOIN t_dataset DS
                   ON DTP.dataset_id = DS.dataset_id
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN Tmp_DatasetID_Filter_List FilterList
                   ON FilterList.dataset_id = DTP.dataset_id
            ORDER BY DS.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Status,
                                _previewData.Instrument,
                                _previewData.DatasetID,
                                _previewData.Created,
                                _previewData.StateID,
                                _previewData.RatingID,
                                _previewData.Process,
                                _previewData.Skip_Reason,
                                _previewData.Dataset,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    If Exists (SELECT Dataset_ID FROM Tmp_DatasetID_Filter_List) Then
        -- Exclude datasets not in Tmp_DatasetID_Filter_List

        If _infoOnly And _showDebug Then
            -- Remove the datasets that we're not interested in, since we don't want to see them in the output pane
            DELETE FROM Tmp_DatasetsToProcess
            WHERE NOT EXISTS (SELECT 1
                              FROM Tmp_DatasetID_Filter_List FilterList
                              WHERE Tmp_DatasetsToProcess.dataset_id = FilterList.dataset_id);
        Else
            UPDATE Tmp_DatasetsToProcess
            SET Process_Dataset = false,
                Skip_Reason = 'Not in Dataset ID filter list'
            WHERE Process_Dataset AND
                  NOT EXISTS (SELECT 1
                              FROM Tmp_DatasetID_Filter_List FilterList
                              WHERE Tmp_DatasetsToProcess.dataset_id = FilterList.dataset_id);
        End If;

    End If;

    -- Exclude datasets from instruments in _instrumentSkipList
    If _instrumentSkipList <> '' Then
        UPDATE Tmp_DatasetsToProcess
        SET Process_Dataset = false,
            Skip_Reason = format('Instrument %s is in the instrument skip list', InstName.instrument)
        FROM t_dataset DS
             INNER JOIN t_instrument_name InstName
               ON InstName.instrument_id = DS.instrument_id
             INNER JOIN public.parse_delimited_list(_instrumentSkipList) AS ExclusionList
               ON InstName.instrument = ExclusionList.Value::citext
        WHERE Process_Dataset AND
              Tmp_DatasetsToProcess.dataset_id = DS.dataset_id;
    End If;

    -- Add dataset _datasetNameIgnoreExistingJobs, if defined
    If _datasetNameIgnoreExistingJobs <> '' Then
        UPDATE Tmp_DatasetsToProcess AS Target
        SET Process_Dataset = true,
            Skip_Reason = CASE WHEN Skip_Reason = ''
                               THEN ''
                               ELSE format('Override skip since dataset name to ignore was provided: %s', Skip_Reason)
                          END
        FROM t_dataset DS
        WHERE Target.dataset_id = DS.dataset_id AND
              DS.dataset = _datasetNameIgnoreExistingJobs::citext;

        If Not FOUND Then
            INSERT INTO Tmp_DatasetsToProcess (Dataset_ID, Process_Dataset, Skip_Reason)
            SELECT DS.dataset_id, true AS Process_Dataset, '' AS Skip_Reason
            FROM t_dataset DS
            WHERE DS.dataset = _datasetNameIgnoreExistingJobs::citext;
        End If;
    End If;

    If _infoOnly Then

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Preview' AS Status,
                   InstName.instrument,
                   DS.dataset_id AS DatasetID,
                   public.timestamp_text(DS.created) AS Created,
                   DS.dataset_state_id AS StateID,
                   DS.dataset_rating_id AS RatingID,
                   DTP.Process_Dataset AS Process,
                   DTP.Skip_Reason,
                   DS.dataset,
                   DS.comment
            FROM Tmp_DatasetsToProcess DTP
                 INNER JOIN t_dataset DS
                   ON DTP.dataset_id = DS.dataset_id
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
            WHERE DTP.Process_Dataset = true
            ORDER BY InstName.instrument, DS.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Status,
                                _previewData.Instrument,
                                _previewData.DatasetID,
                                _previewData.Created,
                                _previewData.StateID,
                                _previewData.RatingID,
                                _previewData.Process,
                                _previewData.Skip_Reason,
                                _previewData.Dataset,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        If _infoOnly And _showDebug Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT 'Ignored' AS Status,
                       InstName.instrument,
                       DS.dataset_id AS DatasetID,
                       public.timestamp_text(DS.created) AS Created,
                       DS.dataset_state_id AS StateID,
                       DS.dataset_rating_id AS RatingID,
                       DTP.Process_Dataset AS Process,
                       DTP.Skip_Reason,
                       DS.dataset,
                       DS.comment
                FROM Tmp_DatasetsToProcess DTP
                     INNER JOIN t_dataset DS
                       ON DTP.dataset_id = DS.dataset_id
                     INNER JOIN t_instrument_name InstName
                       ON DS.instrument_id = InstName.instrument_id
                WHERE DTP.Process_Dataset = false
                ORDER BY InstName.instrument, DS.dataset_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Status,
                                    _previewData.Instrument,
                                    _previewData.DatasetID,
                                    _previewData.Created,
                                    _previewData.StateID,
                                    _previewData.RatingID,
                                    _previewData.Process,
                                    _previewData.Skip_Reason,
                                    _previewData.Dataset,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

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

    -- Remove any extra datasets from Tmp_DatasetsToProcess
    DELETE FROM Tmp_DatasetsToProcess
    WHERE NOT Process_Dataset;

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

                -- Show the rules that apply to this dataset

                _currentLocation := format('Showing predefined analysis rules for %s', _datasetName);

                RAISE INFO '';

                _formatSpecifier := '%-80s %-5s %-5s %-5s %-12s %-8s %-18s %-11s %-6s %-13s %-115s %-25s %-25s %-20s %-20s %-25s %-25s %-25s %-25s %-20s %-25s %-30s %-20s %-20s %-20s %-20s %-20s %-20s %-24s %-15s %-15s %-60s %-60s %-30s %-60s %-40s %-50s %-8s %-200s';

                _infoHead := format(_formatSpecifier,
                                    'Dataset',
                                    'Step',
                                    'Level',
                                    'Seq',
                                    'Predefine_ID',
                                    'Next_Lvl',
                                    'Trigger_Mode',
                                    'Export_Mode',
                                    'Action',
                                    'Reason',
                                    'Notes',
                                    'Analysis_Tool',
                                    'Instrument_Class_Criteria',
                                    'Instrument_Criteria',
                                    'Instrument_Exclusion',
                                    'Campaign_Criteria',
                                    'Campaign_Exclusion',
                                    'Experiment_Criteria',
                                    'Experiment_Exclusion',
                                    'Exp_Comment_Criteria',
                                    'Organism_Criteria',
                                    'Dataset_Criteria',
                                    'Dataset_Exclusion',
                                    'Dataset_Type',
                                    'Scan_Type_Criteria',
                                    'Scan_Type_Exclusion',
                                    'Labelling_Inclusion',
                                    'Labelling_Exclusion',
                                    'Separation_Type_Criteria',
                                    'Scan_Count_Min',
                                    'Scan_Count_Max',
                                    'Param_File',
                                    'Settings_File',
                                    'Organism',
                                    'Protein_Collections',
                                    'Protein_Options',
                                    'Organism_DB',
                                    'Priority',
                                    'Special_Processing'
                                   );


                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------------------------------------------------------------------------------',
                                             '-----',
                                             '-----',
                                             '-----',
                                             '------------',
                                             '--------',
                                             '------------------',
                                             '-----------',
                                             '------',
                                             '-------------',
                                             '-------------------------------------------------------------------------------------------------------------------',
                                             '-------------------------',
                                             '-------------------------',
                                             '--------------------',
                                             '--------------------',
                                             '-------------------------',
                                             '-------------------------',
                                             '-------------------------',
                                             '-------------------------',
                                             '--------------------',
                                             '-------------------------',
                                             '------------------------------',
                                             '--------------------',
                                             '--------------------',
                                             '--------------------',
                                             '--------------------',
                                             '--------------------',
                                             '--------------------',
                                             '------------------------',
                                             '---------------',
                                             '---------------',
                                             '------------------------------------------------------------',
                                             '------------------------------------------------------------',
                                             '------------------------------',
                                             '------------------------------------------------------------',
                                             '----------------------------------------',
                                             '--------------------------------------------------',
                                             '--------',
                                             '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT _datasetName AS Dataset,
                           Step,
                           Level,
                           Seq,
                           Predefine_ID,
                           Next_Lvl,
                           Trigger_Mode,
                           Export_Mode,
                           Action,
                           Reason,
                           Notes,
                           Analysis_Tool,
                           Instrument_Class_Criteria,
                           Instrument_Criteria,
                           Instrument_Exclusion,
                           Campaign_Criteria,
                           Campaign_Exclusion,
                           Experiment_Criteria,
                           Experiment_Exclusion,
                           Exp_Comment_Criteria,
                           Organism_Criteria,
                           Dataset_Criteria,
                           Dataset_Exclusion,
                           Dataset_Type,
                           Scan_Type_Criteria,
                           Scan_Type_Exclusion,
                           Labelling_Inclusion,
                           Labelling_Exclusion,
                           Separation_Type_Criteria,
                           Scan_Count_Min,
                           Scan_Count_Max,
                           Param_File,
                           Settings_File,
                           Organism,
                           Protein_Collections,
                           Protein_Options,
                           Organism_DB,
                           Priority,
                           Special_Processing
                    FROM predefined_analysis_rules (
                                _datasetName,
                                _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                                _analysisToolNameFilter => _analysisToolNameFilter)
                    ORDER BY Step, Level, Seq
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Dataset,
                                        _previewData.Step,
                                        _previewData.Level,
                                        _previewData.Seq,
                                        _previewData.Predefine_ID,
                                        _previewData.Next_Lvl,
                                        _previewData.Trigger_Mode,
                                        _previewData.Export_Mode,
                                        _previewData.Action,
                                        _previewData.Reason,
                                        _previewData.Notes,
                                        _previewData.Analysis_Tool,
                                        _previewData.Instrument_Class_Criteria,
                                        _previewData.Instrument_Criteria,
                                        _previewData.Instrument_Exclusion,
                                        _previewData.Campaign_Criteria,
                                        _previewData.Campaign_Exclusion,
                                        _previewData.Experiment_Criteria,
                                        _previewData.Experiment_Exclusion,
                                        _previewData.Exp_Comment_Criteria,
                                        _previewData.Organism_Criteria,
                                        _previewData.Dataset_Criteria,
                                        _previewData.Dataset_Exclusion,
                                        _previewData.Dataset_Type,
                                        _previewData.Scan_Type_Criteria,
                                        _previewData.Scan_Type_Exclusion,
                                        _previewData.Labelling_Inclusion,
                                        _previewData.Labelling_Exclusion,
                                        _previewData.Separation_Type_Criteria,
                                        _previewData.Scan_Count_Min,
                                        _previewData.Scan_Count_Max,
                                        _previewData.Param_File,
                                        _previewData.Settings_File,
                                        _previewData.Organism,
                                        _previewData.Protein_Collections,
                                        _previewData.Protein_Options,
                                        _previewData.Organism_DB,
                                        _previewData.Priority,
                                        _previewData.Special_Processing
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            ElsIf _infoOnly And Not _showRules Then

                -- Show the jobs that would be created for this dataset

                _currentLocation := format('Showing predefined analysis jobs for %s', _datasetName);

                RAISE INFO '';

                _formatSpecifier := '%-80s %-8s %-25s %-60s %-60s %-60s %-50s %-80s %-40s %-15s %-20s %-18s %-16s %-200s';

                _infoHead := format(_formatSpecifier,
                                    'Dataset_Name',
                                    'Priority',
                                    'Analysis_Tool_Name',
                                    'Param_File_Name',
                                    'Settings_File_Name',
                                    'Organism_DB_Name',
                                    'Organism_Name',
                                    'Protein_Collection_List',
                                    'Protein_Options_List',
                                    'Owner_Username',
                                    'Comment',
                                    'Existing_Job_Count',
                                    'Propagation_Mode',
                                    'Special_Processing'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------------------------------------------------------------------------------',
                                             '--------',
                                             '-------------------------',
                                             '------------------------------------------------------------',
                                             '------------------------------------------------------------',
                                             '------------------------------------------------------------',
                                             '--------------------------------------------------',
                                             '--------------------------------------------------------------------------------',
                                             '----------------------------------------',
                                             '---------------',
                                             '--------------------',
                                             '------------------',
                                             '----------------',
                                             '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Dataset,
                           Priority,
                           Analysis_Tool_Name AS AnalysisToolName,
                           Param_File_Name AS ParamFileName,
                           Settings_File_Name AS SettingsFileName,
                           Organism_DB_Name AS OrganismDBName,
                           Organism_Name AS OrganismName,
                           Protein_Collection_List AS ProteinCollectionList,
                           Protein_Options_List AS ProteinOptionsList,
                           Owner_Username AS OwnerUsername,
                           Comment,
                           Existing_Job_Count AS ExistingJobCount,
                           Propagation_Mode AS PropagationMode,
                           Special_Processing AS SpecialProcessing
                    FROM public.predefined_analysis_jobs (
                                _datasetName,
                                _raiseErrorMessages => true,
                                _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                                _createJobsForUnreviewedDatasets => true,
                                _analysisToolNameFilter => _analysisToolNameFilter)
                    ORDER BY Dataset, AnalysisToolName
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Dataset,
                                        _previewData.Priority,
                                        _previewData.AnalysisToolName,
                                        _previewData.ParamFileName,
                                        _previewData.SettingsFileName,
                                        _previewData.OrganismDBName,
                                        _previewData.OrganismName,
                                        _previewData.ProteinCollectionList,
                                        _previewData.ProteinOptionsList,
                                        _previewData.OwnerUsername,
                                        _previewData.Comment,
                                        _previewData.ExistingJobCount,
                                        _previewData.PropagationMode,
                                        _previewData.SpecialProcessing
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            End If;

            _currentLocation := format('Calling schedule_predefined_analysis_jobs for %s', _datasetName);
            _startDate := CURRENT_TIMESTAMP;

            CALL public.schedule_predefined_analysis_jobs (
                            _datasetName,
                            _analysisToolNameFilter     => _analysisToolNameFilter,
                            _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                            _infoOnly                   => _infoOnly,
                            _message                    => _message,        -- Output
                            _returnCode                 => _returnCode);    -- Output

            If _returnCode = '' And Not _infoOnly Then

                -- If the dataset has a row with state "New" in T_Predefined_Analysis_Scheduling_Queue,
                -- use create_pending_predefined_analysis_tasks to process the predefine rules and possibly create jobs

                If Exists (SELECT item FROM t_predefined_analysis_scheduling_queue WHERE dataset_id = _datasetID AND State = 'New') Then

                    CALL public.create_pending_predefined_analysis_tasks (
                                _maxDatasetsToProcess => 0,
                                _datasetID            => _datasetID,
                                _infoOnly             => false,
                                _message              => _message,      -- Output
                                _returnCode           => _returnCode);  -- Output

                    -- See if jobs were actually added by querying t_analysis_job

                    _jobCountAdded := 0;

                    SELECT COUNT(job)
                    INTO _jobCountAdded
                    FROM t_analysis_job
                    WHERE dataset_id = _datasetID AND
                          created >= _startDate;

                    If _jobCountAdded > 0 Then
                        UPDATE t_analysis_job
                        SET comment = public.append_to_text(comment, '(missed predefine)', _delimiter => ' ')
                        WHERE dataset_id = _datasetID AND
                              created >= _startDate;
                        --
                        GET DIAGNOSTICS _updateCount = ROW_COUNT;

                        If _updateCount <> _jobCountAdded Then
                            _message := format('Added %s missing predefined analysis job(s) for dataset %s, but updated the comment for %s job(s); mismatch is unexpected',
                                                _jobCountAdded, _datasetName, _updateCount);

                            CALL post_log_entry ('Error', _message, 'Add_Missing_Predefined_Jobs');
                        End If;

                        _message := format('Added %s missing predefined analysis %s for dataset %s',
                                            _jobCountAdded,
                                            public.check_plural(_jobCountAdded, 'job', 'jobs'),
                                            _datasetName);

                        CALL post_log_entry ('Warning', _message, 'Add_Missing_Predefined_Jobs');

                        _datasetsWithNewJobs := _datasetsWithNewJobs + 1;
                    End If;
                End If;

            ElsIf Not _infoOnly Then
                _message := format('Error calling schedule_predefined_analysis_jobs for dataset %s; return code %s',
                                   _datasetName, _returnCode);

                CALL post_log_entry ('Error', _message, 'Add_Missing_Predefined_Jobs');

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

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;
        END;

        _datasetsProcessed := _datasetsProcessed + 1;

        If _maxDatasetsToProcess > 0 And _datasetsProcessed >= _maxDatasetsToProcess Then
            -- Break out of the for loop
            EXIT;
        End If;

    END LOOP;

    If _datasetsProcessed > 0 And Not _infoOnly Then
        _message := format('Added predefined analysis jobs for %s %s (processed %s %s)',
                           _datasetsWithNewJobs, public.check_plural(_datasetsWithNewJobs, 'dataset', 'datasets'),
                           _datasetsProcessed,   public.check_plural(_datasetsProcessed,   'dataset', 'datasets'));

        If _datasetsWithNewJobs > 0 And Not _infoOnly Then
            CALL post_log_entry ('Normal', _message, 'Add_Missing_Predefined_Jobs');
        End If;

    End If;

    DROP TABLE IF EXISTS Tmp_DatasetsToProcess;
    DROP TABLE IF EXISTS Tmp_DSRating_Exclusion_List;
    DROP TABLE IF EXISTS Tmp_DatasetID_Filter_List;

END
$$;


ALTER PROCEDURE public.add_missing_predefined_jobs(IN _infoonly boolean, IN _maxdatasetstoprocess integer, IN _daycountforrecentdatasets integer, IN _previewoutputtype text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _excludeunrevieweddatasets boolean, IN _instrumentskiplist text, IN _datasetnameignoreexistingjobs text, IN _ignorejobscreatedbeforedisposition boolean, IN _campaignfilter text, IN _datasetidfilterlist text, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_missing_predefined_jobs(IN _infoonly boolean, IN _maxdatasetstoprocess integer, IN _daycountforrecentdatasets integer, IN _previewoutputtype text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _excludeunrevieweddatasets boolean, IN _instrumentskiplist text, IN _datasetnameignoreexistingjobs text, IN _ignorejobscreatedbeforedisposition boolean, IN _campaignfilter text, IN _datasetidfilterlist text, IN _showdebug boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_missing_predefined_jobs(IN _infoonly boolean, IN _maxdatasetstoprocess integer, IN _daycountforrecentdatasets integer, IN _previewoutputtype text, IN _analysistoolnamefilter text, IN _excludedatasetsnotreleased boolean, IN _excludeunrevieweddatasets boolean, IN _instrumentskiplist text, IN _datasetnameignoreexistingjobs text, IN _ignorejobscreatedbeforedisposition boolean, IN _campaignfilter text, IN _datasetidfilterlist text, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) IS 'AddMissingPredefinedJobs';

