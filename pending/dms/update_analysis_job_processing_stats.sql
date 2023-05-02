--
CREATE OR REPLACE PROCEDURE public.update_analysis_job_processing_stats
(
    _job int,
    _newDMSJobState int,
    _newBrokerJobState int,
    _jobStart timestamp,
    _jobFinish timestamp,
    _resultsDirectoryName text,
    _assignedProcessor text,
    _jobCommentAddnl text,
    _organismDBName text,
    _processingTimeMinutes real,
    _updateCode int,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates job state, start, and finish in T_Analysis_Job
**
**      Sets archive status of dataset to update required
**
**  Arguments:
**    _jobCommentAddnl   Additional text to append to the comment (direct append; no separator character is used when appending _jobCommentAddnl)
**    _updateCode        Safety feature to prevent unauthorized job updates
**
**  Auth:   mem
**  Date:   06/02/2009 mem - Initial version
**          09/02/2011 mem - Now setting AJ_Purged to 0 when job is complete, no-export, or failed
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          04/18/2012 mem - Now preventing addition of _jobCommentAddnl to the comment field if it already contains _jobCommentAddnl
**          06/15/2015 mem - Use function AppendToText to concatenate _jobCommentAddnl to AJ_Comment
**          06/12/2018 mem - Send _maxLength to AppendToText
**          08/03/2020 mem - Update T_Cached_Dataset_Links.MASIC_Directory_Name when a MASIC job finishes successfully
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _datasetID int := 0;
    _datasetName text := '';
    _toolName text := '';
    _updateCodeExpected int;
BEGIN
    _message := '';
    _returnCode:= '';

    _jobCommentAddnl := Trim(Coalesce(_jobCommentAddnl, ''));

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    If _job Is Null Then
        _message := 'Invalid job';
        _myError := 50000;
        RETURN;
    End If;

    If _newDMSJobState Is Null Or _newBrokerJobState Is Null Then
        _message := 'Job and Broker state cannot be null';
        _myError := 50001;
        RETURN;
    End If;

    -- Confirm that _updateCode is valid for this job
    If _job % 2 = 0 Then
        _updateCodeExpected := (_job % 220) + 14;
    Else
        _updateCodeExpected := (_job % 125) + 11;
    End If;

    If Coalesce(_updateCode, 0) <> _updateCodeExpected Then
        _message := 'Invalid Update Code';
        _myError := 50002;
        RETURN;
    End If;

    -- Uncomment to debug
    -- Declare _debugMsg text = 'Updating job state for ' || _job::text +
    --          ', NewDMSJobState = ' || _newDMSJobState::text +
    --          ', NewBrokerJobState = ' || _newBrokerJobState::text +
    --          ', JobCommentAddnl = ' || Coalesce(_jobCommentAddnl, '')
    --
    -- call PostLogEntry ('Debug', _debugMsg, UpdateAnalysisJobProcessingStats);

    ---------------------------------------------------
    -- Perform (or preview) the update
    -- Note: Comment is not updated if _newBrokerJobState = 2
    ---------------------------------------------------
    --
    If _infoOnly Then
        -- ToDo: Use RAISE INFO to display the old and new values
        SELECT State_ID,
               _newDMSJobState AS State_ID_New,
               Start,
               CASE
                   WHEN _newBrokerJobState >= 2 THEN Coalesce(_jobStart, CURRENT_TIMESTAMP)
                   ELSE Start
               END AS Start_New,
               Finish,
               CASE
                   WHEN _newBrokerJobState IN (4, 5) THEN _jobFinish
                   ELSE Finish
               END AS Finish_New,
               Results_Folder_Name,
               _resultsDirectoryName AS Results_Folder_Name_New,
               Assigned_Processor_Name,
               _assignedProcessor AS Assigned_Processor_Name_New,
               CASE
                   WHEN _newBrokerJobState = 2
                   THEN Comment
                   ELSE public.append_to_text(comment, _jobCommentAddnl, 0, '; ', 512)
               END AS Comment_New,
               Organism_DB_Name,
               Coalesce(_organismDBName, Organism_DB_Name) AS Organism_DB_Name_New,
               Processing_Time_Minutes,
               CASE
                   WHEN _newBrokerJobState <> 2 THEN _processingTimeMinutes
               ELSE Processing_Time_Minutes
               END AS Processing_Time_Minutes_New
        FROM t_analysis_job
        WHERE job = _job
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    Else

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
                           ELSE public.append_to_text(comment, _jobCommentAddnl, 0, '; ', 512)
                      END,
            Organism_DB_Name = Coalesce(_organismDBName, Organism_DB_Name),
            Processing_TimeMinutes = CASE WHEN _newBrokerJobState <> 2
                                          THEN _processingTimeMinutes
                                          ELSE Processing_TimeMinutes
                                     END,
            -- Note: setting Purged to 0 even if job failed since admin might later manually set job to complete and we want Purged to be 0 in that case
            Purged = CASE WHEN _newBrokerJobState IN (4, 5, 14)
                          THEN 0
                          ELSE Purged
                     END
        WHERE job = _job;

    End If;

    -------------------------------------------------------------------
    -- If Job is Complete or No Export, do some additional tasks
    -------------------------------------------------------------------
    --
    If _newDMSJobState in (4, 14) AND Not _infoOnly Then
        -- Get the dataset ID, dataset name, and tool name
        --
        SELECT DS.dataset_id, INTO _datasetID
               _datasetName = DS.dataset,
               _toolName    = T.analysis_tool
        FROM t_analysis_job J
             INNER JOIN t_dataset DS
               ON J.dataset_id = DS.dataset_id
             INNER JOIN t_analysis_tool T
               ON J.analysis_tool_id = T.analysis_tool_id
        WHERE J.job = _job
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            -- Schedule an archive update
            Call set_archive_update_required _datasetName, _message => _message

            If _toolName LIKE 'Masic%' Then
                -- Update the cached MASIC Directory Name
                UPDATE t_cached_dataset_links
                Set masic_directory_name= _resultsDirectoryName
                WHERE dataset_id = _datasetID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            End If;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_analysis_job_processing_stats IS 'UpdateAnalysisJobProcessingStats';
