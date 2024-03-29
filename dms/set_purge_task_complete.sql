--
-- Name: set_purge_task_complete(text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_purge_task_complete(IN _datasetname text, IN _completioncode integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set archive state for the dataset based on the purge task completion code
**
**  Arguments:
**    _datasetName      Dataset name
**    _completionCode   Completion code
**    _message          Status message
**    _returnCode       Return code
**
**  Completion codes (as defined in the DMS Space Manager):
**      0 = Success
**      1 = Purge failed
**      2 = Archive update required
**      3 = Stage MD5 file required (obsolete)
**      4 = Drive missing
**      5 = Purged instrument data (and any other auto-purge items)
**      6 = Purged all data except QC folder
**      7 = Dataset directory missing in archive
**      8 = Archive offline
**      9 = Preview purge
**
**  Auth:   grk
**  Date:   03/04/2003
**          02/16/2007 grk - Add completion code options and also set archive state (Ticket #131)
**          08/04/2008 mem - Now updating column instrument_data_purged (Ticket #683)
**          01/26/2011 grk - Modified actions for _completionCode = 2 to bump holdoff and call broker
**          01/28/2011 mem - Changed holdoff bump from 12 to 24 hours when _completionCode = 2
**          02/01/2011 mem - Added support for _completionCode 3
**          09/02/2011 mem - Now updating t_analysis_job.purged for jobs associated with this dataset
**                         - Now calling Post_Usage_Log_Entry
**          01/27/2012 mem - Now bumping AS_purge_holdoff_date by 90 minutes when _completionCode = 3
**          04/17/2012 mem - Added support for _completionCode = 4 (drive missing)
**          06/12/2012 mem - Added support for _completionCode = 5 and _completionCode = 6 (corresponding to Archive States 14 and 15)
**          06/15/2012 mem - No longer changing the purge holdoff date if _completionCode = 4 (drive missing)
**          08/13/2013 mem - Now using explicit parameter names when calling S_Make_New_Archive_Update_Job
**          08/15/2013 mem - Added support for _completionCode = 7 (dataset folder missing in archive)
**          08/26/2013 mem - Now mentioning 'permissions error' when _completionCode = 7
**          03/21/2014 mem - Tweaked log message for _completionCode = 7
**          07/05/2016 mem - Added support for _completionCode = 8 (Aurora is offline)
**                         - Archive path is now aurora.emsl.pnl.gov
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov
**          11/09/2016 mem - Include the storage server name when calling post_log_entry
**          07/11/2017 mem - Add support for _completionCode = 9 (Previewed purge)
**          09/09/2022 mem - Use new argument names when calling Make_New_Archive_Update_Job
**          06/21/2023 mem - Remove parameter _pushDatasetToMyEMSL in call to cap.make_new_archive_update_task
**          10/05/2023 mem - Archive path is now agate.emsl.pnl.gov
**          02/23/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _storageServerName text;
    _datasetState int;
    _completionState int;
    _instrumentClass text;
    _currentState int;
    _currentUpdateState int;
    _postedBy text;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Resolve dataset into ID
    -- Also determine the storage server name
    ---------------------------------------------------

    SELECT DS.dataset_id,
           SPath.machine_name
    INTO _datasetID, _storageServerName
    FROM t_dataset DS
         LEFT OUTER JOIN t_storage_path SPath
           ON DS.storage_path_id = SPath.storage_path_id
    WHERE DS.dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset %s not found in t_dataset', _datasetName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine current 'Archive' state and current 'ArchiveUpdate' state
    ---------------------------------------------------

    SELECT archive_state_id,
           archive_update_state_id
    INTO _currentState, _currentUpdateState
    FROM t_dataset_archive
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID %s not found in t_dataset_archive for dataset %s', _datasetID, _datasetName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _currentState <> 7 Then
        _message := format('Current archive state is incorrect for dataset %s; expecting 7 but actually %s', _datasetName, _currentState);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Choose archive state and archive update state
    -- based upon completion code
    ---------------------------------------------------
/*
Code 0 (success)
    Set t_dataset_archive.archive_state_id to 4 (Purged).
    Leave t_dataset_archive.archive_update_state_id unchanged.

Code 1 (failed)
    Set t_dataset_archive.archive_state_id to 8 (Failed).
    Leave t_dataset_archive.archive_update_state_id unchanged.

Code 2 (update reqd)
    Set t_dataset_archive.archive_state_id to 3 (Complete).
    Set t_dataset_archive.archive_update_state_id to 2 (Update Required)
    Bump up Purge Holdoff Date by 90 minutes

Code 3 (Stage MD5 file required)
    Set t_dataset_archive.archive_state_id to 3 (Complete).
    Leave t_dataset_archive.archive_update_state_id unchanged.
    Set stagemd5_required to 1
    Bump up Purge Holdoff Date by 90 minutes

Code 4 (Drive Missing)
    Set t_dataset_archive.archive_state_id to 3 (Complete).
    Leave t_dataset_archive.archive_update_state_id unchanged.
    Leave Purge Holdoff Date unchanged

Code 5 (Purged Instrument Data and any other auto-purge items)
    Set t_dataset_archive.archive_state_id to 14
    Leave t_dataset_archive.archive_update_state_id unchanged.

Code 6 (Purged all data except QC folder)
    Set t_dataset_archive.archive_state_id to 15
    Leave t_dataset_archive.archive_update_state_id unchanged.

*/

    If Coalesce(_storageServerName, '') = '' Then
        _storageServerName := '??';
    End If;

    _postedBy := format('Set_Purge_Task_Complete: %s', _storageServerName);

    _completionState := -1;

    If _completionCode = 0 Then
        -- Success
        _completionState := 4;      -- Purged

    ElsIf _completionCode = 1 Then
        -- Failed
        _completionState := 8;      -- Purge failed

    ElsIf _completionCode = 2 Then
        -- Update required
        _completionState := 3;      -- Complete
        _currentUpdateState := 2;   -- Update Required
        CALL cap.make_new_archive_update_task (
                    _datasetName,
                    _resultsDirectoryName => '',
                    _allowBlankResultsDirectory => true,
                    _message => _message,
                    _returncode => _returncode);

    ElsIf _completionCode = 3 Then
        -- MD5 results file is missing; need to have stageMD5 file created by the DatasetPurgeArchiveHelper

        _completionState := 3;   -- Complete

    ElsIf _completionCode = 4 Then
        -- Drive Missing

        _message := format('Drive not found for dataset %s', _datasetName);
        CALL post_log_entry ('Error', _message, _postedBy);

        _completionState := 3; -- Complete

    ElsIf _completionCode = 5 Then
        -- Purged Instrument Data (plus auto-purge)
        _completionState := 14; -- Purged instrument data; corresponds to Purge_Policy=0

    ElsIf _completionCode = 6 Then
        -- Purged all data except QC folder
        _completionState := 15; -- Purged all data except QC; corresponds to Purge_Policy=1

    ElsIf _completionCode = 7 Then
        -- Dataset folder missing in archive, either in MyEMSL or at \\agate.emsl.pnl.gov\dmsarch

        _message := format('Dataset folder not found in archive or in MyEMSL; most likely a MyEMSL timeout, but could be a permissions error; dataset %s', _datasetName);
        CALL post_log_entry ('Error', _message, _postedBy);

        _completionState := 3; -- Complete

    ElsIf _completionCode = 8 Then
        -- Archive is offline (Aurora is offline): \\agate.emsl.pnl.gov\dmsarch

        _message := format('Archive is offline; cannot purge dataset %s', _datasetName);
        CALL post_log_entry ('Error', _message, _postedBy);

        _completionState := 3; -- Complete

    ElsIf _completionCode = 9 Then
        -- Previewed purge
        _message := format('Previewed purge of dataset %s', _datasetName);
        _completionState := 3; -- Complete

    Else
        _message := format('Completion code %s was not recognized for dataset %s', _completionCode, _datasetName);
        RAISE WARNING '%', _message;

        CALL post_log_entry ('Error', _message, _postedBy);

        RETURN;
    End If;

    UPDATE t_dataset_archive
    SET archive_state_id        = _completionState,
        archive_update_state_id = _currentUpdateState,
        purge_holdoff_date = CASE WHEN _currentUpdateState = 2   THEN CURRENT_TIMESTAMP + INTERVAL '24 hours'
                                  WHEN _completionCode IN (2, 3) THEN CURRENT_TIMESTAMP + INTERVAL '90 minutes'
                                  WHEN _completionCode = 7       THEN CURRENT_TIMESTAMP + INTERVAL '48 hours'
                                  ELSE purge_holdoff_date
                             END,
        stagemd5_required  = CASE WHEN _completionCode = 3
                                  THEN 1
                                  ELSE stagemd5_required
                             END
    WHERE dataset_id = _datasetID;

    If _completionState In (4, 14) Then
        -- Dataset was purged; update instrument_data_purged to be 1

        -- This field is useful because, if an analysis job is run on a purged dataset,
        -- archive_state_id will change back to 3=Complete, and we therefore
        -- wouldn't be able to tell if the raw instrument file is available

        -- Note that trigger trig_t_dataset_archive_after_update will likely have already updated instrument_data_purged

        UPDATE t_dataset_archive
        SET instrument_data_purged = 1
        WHERE dataset_id = _datasetID AND
              Coalesce(instrument_data_purged, 0) = 0;
    End If;

    If _completionState In (4) Then
        -- Make sure QC_Data_Purged is now 1
        -- Note that trigger trig_t_dataset_archive_after_update will likely have already updated instrument_data_purged

        UPDATE t_dataset_archive
        SET qc_data_purged = 1
        WHERE dataset_id = _datasetID AND
              Coalesce(qc_data_purged, 0) = 0;
    End If;

    If _completionState In (4, 15) Then
        -- Update purged in t_analysis_job for all jobs associated with this dataset
        UPDATE t_analysis_job
        SET purged = 1
        WHERE dataset_id = _datasetID AND purged = 0;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_purge_task_complete', _usageMessage);

END
$$;


ALTER PROCEDURE public.set_purge_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_purge_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_purge_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text) IS 'SetPurgeTaskComplete';

