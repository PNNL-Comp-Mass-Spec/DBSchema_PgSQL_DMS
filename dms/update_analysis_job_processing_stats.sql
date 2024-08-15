--
-- Name: update_analysis_job_processing_stats(integer, integer, integer, timestamp without time zone, timestamp without time zone, text, text, text, text, real, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_job_processing_stats(IN _job integer, IN _newdmsjobstate integer, IN _newbrokerjobstate integer, IN _jobstart timestamp without time zone, IN _jobfinish timestamp without time zone, IN _resultsdirectoryname text, IN _assignedprocessor text, IN _jobcommentaddnl text, IN _organismdbname text, IN _processingtimeminutes real, IN _updatecode integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update job state, start, and finish in public.t_analysis_job
**
**      Set archive status of dataset to update required
**
**  Arguments:
**    _job                      Job number
**    _newDMSJobState           New job state in public.t_analysis_job
**    _newBrokerJobState        New job state in sw.t_jobs
**    _jobStart                 Job start time
**    _jobFinish                Job finish time
**    _resultsDirectoryName     Results directory name
**    _assignedProcessor        Assigned processor
**    _jobCommentAddnl          Additional text to append to the comment
**    _organismDBName           Organism DB name (FASTA file)
**    _processingTimeMinutes    Processing time, in minutes
**    _updateCode               Safety feature to prevent unauthorized job updates
**    _infoOnly                 When true, preview updates
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   06/02/2009 mem - Initial version
**          09/02/2011 mem - Now setting t_analysis_job.purged to 0 when job is complete, no-export, or failed
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/18/2012 mem - Now preventing addition of _jobCommentAddnl to the comment field if it already contains _jobCommentAddnl
**          06/15/2015 mem - Use function Append_To_Text to concatenate _jobCommentAddnl to comment
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          08/03/2020 mem - Update T_Cached_Dataset_Links.MASIC_Directory_Name when a MASIC job finishes successfully
**          08/03/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**          09/08/2023 mem - Adjust capitalization of keywords
**          08/12/2024 mem - Ignore return code 'U5250' from set_archive_update_required
**          08/14/2024 mem - Do not call set_archive_update_required() for data package based datasets
**
*****************************************************/
DECLARE
    _datasetID int;
    _datasetName citext;
    _datasetType citext;
    _toolName citext;
    _updateCodeExpected int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _jobCommentAddnl := Trim(Coalesce(_jobCommentAddnl, ''));

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _job Is Null Then
        _message := 'Invalid job';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _newDMSJobState Is Null Or _newBrokerJobState Is Null Then
        _message := 'Job and broker state cannot be null';
        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Confirm that _updateCode is valid for this job
    If _job % 2 = 0 Then
        _updateCodeExpected := (_job % 220) + 14;
    Else
        _updateCodeExpected := (_job % 125) + 11;
    End If;

    If Coalesce(_updateCode, 0) <> _updateCodeExpected Then
        _message := 'Invalid update code';
        _returnCode := 'U5203';
        RETURN;
    End If;

    -- Uncomment to debug
    -- _debugMsg := format('Updating job state for %s, NewDMSJobState = %s, NewBrokerJobState = %s, JobCommentAddnl = %s',
    --                     _job, _newDMSJobState, _newBrokerJobState, _jobCommentAddnl);
    --
    -- CALL post_log_entry ('Debug', _debugMsg, 'Update_Analysis_Job_Processing_Stats');

    ---------------------------------------------------
    -- Perform (or preview) the update
    -- Note: Comment is not updated if _newBrokerJobState = 2
    ---------------------------------------------------

    If _infoOnly Then

        If Not Exists (SELECT job FROM t_analysis_job WHERE job = _job) Then
            RAISE WARNING 'Job % not found in t_analysis_job', _job;
            RETURN;
        End If;

        RAISE INFO '';

        _formatSpecifier := '%-8s %-12s %-20s %-20s %-20s %-20s %-60s %-60s %-20s %-20s %-30s %-60s %-60s %-23s %-27s';

        _infoHead := format(_formatSpecifier,
                            'State_ID',
                            'State_ID_New',
                            'Start',
                            'Start_New',
                            'Finish',
                            'Finish_New',
                            'Results_Folder_Name',
                            'Results_Folder_Name_New',
                            'Assigned_Processor_Name',
                            'Assigned_Processor_Name_New',
                            'Comment_New',
                            'Organism_DB_Name',
                            'Organism_DB_Name_New',
                            'Processing_Time_Minutes',
                            'Processing_Time_Minutes_New'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------',
                                     '------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '--------------------',
                                     '--------------------',
                                     '------------------------------',
                                     '------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '-----------------------',
                                     '---------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job_State_ID AS State_ID,
                   _newDMSJobState AS State_ID_New,
                   public.timestamp_text(Start) AS Start,
                   CASE
                       WHEN _newBrokerJobState >= 2
                       THEN public.timestamp_text(Coalesce(_jobStart, CURRENT_TIMESTAMP))
                       ELSE public.timestamp_text(Start)
                   END AS Start_New,
                   public.timestamp_text(Finish) AS Finish,
                   CASE
                       WHEN _newBrokerJobState IN (4, 5)
                       THEN public.timestamp_text(_jobFinish)
                       ELSE public.timestamp_text(Finish)
                   END AS Finish_New,
                   Results_Folder_Name,
                   _resultsDirectoryName AS Results_Folder_Name_New,
                   Assigned_Processor_Name,
                   _assignedProcessor AS Assigned_Processor_Name_New,
                   CASE
                       WHEN _newBrokerJobState = 2
                       THEN Comment
                       ELSE public.append_to_text(comment, _jobCommentAddnl)
                   END AS Comment_New,
                   Organism_DB_Name,
                   Coalesce(_organismDBName, Organism_DB_Name) AS Organism_DB_Name_New,
                   Processing_Time_Minutes,
                   CASE
                       WHEN _newBrokerJobState <> 2
                       THEN _processingTimeMinutes
                       ELSE Processing_Time_Minutes
                   END AS Processing_Time_Minutes_New
            FROM t_analysis_job
            WHERE job = _job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.State_ID,
                                _previewData.State_ID_New,
                                _previewData.Start,
                                _previewData.Start_New,
                                _previewData.Finish,
                                _previewData.Finish_New,
                                _previewData.Results_Folder_Name,
                                _previewData.Results_Folder_Name_New,
                                _previewData.Assigned_Processor_Name,
                                _previewData.Assigned_Processor_Name_New,
                                _previewData.Comment_New,
                                _previewData.Organism_DB_Name,
                                _previewData.Organism_DB_Name_New,
                                _previewData.Processing_Time_Minutes,
                                _previewData.Processing_Time_Minutes_New
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    -- Update the values
    UPDATE t_analysis_job
    SET job_state_id = _newDMSJobState,
        start = CASE WHEN _newBrokerJobState >= 2
                     THEN Coalesce(_jobStart, CURRENT_TIMESTAMP)
                     ELSE Start
                END,
        Finish = CASE WHEN _newBrokerJobState IN (4, 5)
                      THEN _jobFinish
                      ELSE Finish
                 END,
        Results_Folder_Name = _resultsDirectoryName,
        Assigned_Processor_Name = 'Job_Broker',
        Comment = CASE WHEN _newBrokerJobState = 2
                       THEN Comment
                       ELSE public.append_to_text(comment, _jobCommentAddnl)
                  END,
        Organism_DB_Name = Coalesce(_organismDBName, Organism_DB_Name),
        Processing_Time_Minutes = CASE WHEN _newBrokerJobState <> 2
                                       THEN _processingTimeMinutes
                                       ELSE Processing_Time_Minutes
                                  END,
        -- Note: setting Purged to 0 even if job failed since admin might later manually set job to complete and we want Purged to be 0 in that case
        Purged = CASE WHEN _newBrokerJobState IN (4, 5, 14)
                      THEN 0
                      ELSE Purged
                 END
    WHERE job = _job;

    --------------------------------------------------------------
    -- If Job is Complete or No Export, do some additional tasks
    --------------------------------------------------------------

    If _newDMSJobState In (4, 14) Then
        -- Get the dataset ID, dataset name, dataset type, and tool name

        SELECT DS.dataset_id,
               DS.dataset,
               DSType.dataset_type,
               T.analysis_tool
        INTO _datasetID, _datasetName, _datasetType, _toolName
        FROM t_analysis_job J
             INNER JOIN t_dataset DS
               ON J.dataset_id = DS.dataset_id
             INNER JOIN t_dataset_type_name DSType
               ON DS.dataset_type_id = DSType.dataset_type_id
             INNER JOIN t_analysis_tool T
               ON J.analysis_tool_id = T.analysis_tool_id
        WHERE J.job = _job;

        If FOUND Then
            -- Schedule an archive update (but not for data package based datasets)

            If _datasetName Like 'DataPackage%' And _datasetType = 'DataFiles' Then
                RAISE INFO 'Skipping call to set_archive_update_required() for data package based dataset %', _datasetName;
                RETURN;
            End If;

            CALL public.set_archive_update_required (
                            _datasetName::text,
                            _message    => _message,        -- Output
                            _returncode => _returncode);    -- Output

            If _returnCode = 'U5250' Then
                -- The dataset's archive update state is not 1, 2, 4, or 5, and thus _message has a warning message
                -- Most likely the state is 3=Update In Progress
                -- Display the warning, then clear the output variables
                RAISE INFO 'Warning from set_archive_update_required that can safely be ignored: %', _message;

                _message := '';
                _returnCode := '';
            End If;

            If _toolName LIKE 'Masic%' Then
                -- Update the cached MASIC Directory Name
                UPDATE t_cached_dataset_links
                SET masic_directory_name = _resultsDirectoryName
                WHERE dataset_id = _datasetID;
            End If;
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.update_analysis_job_processing_stats(IN _job integer, IN _newdmsjobstate integer, IN _newbrokerjobstate integer, IN _jobstart timestamp without time zone, IN _jobfinish timestamp without time zone, IN _resultsdirectoryname text, IN _assignedprocessor text, IN _jobcommentaddnl text, IN _organismdbname text, IN _processingtimeminutes real, IN _updatecode integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

