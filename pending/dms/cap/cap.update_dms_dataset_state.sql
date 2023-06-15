--
CREATE OR REPLACE PROCEDURE cap.update_dms_dataset_state
(
    _job int,
    _datasetName text,
    _datasetID int,
    _script text,
    _storageServerName text,
    _jobInfo.NewState int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update dataset state in public.t_dataset or public.t_dataset_archive
**
**  Auth:   grk
**  Date:   01/05/2010 grk - Initial Version
**          01/14/2010 grk - Removed path ID fields
**          05/05/2010 grk - Added handling for dataset info XML
**          09/01/2010 mem - Now calling update_dms_file_info_xml
**          03/16/2011 grk - Now recognizes IMSDatasetCapture
**          04/04/2012 mem - Now passing _failureMessage to public.set_capture_task_complete when the capture task job is failed in the broker
**          06/13/2018 mem - Check for error code 53600 (aka 'U5360') returned by update_dms_file_info_xml to indicate a duplicate dataset
**          08/09/2018 mem - Set the capture task job state to 14 when the error code is 'U5360'
**          08/17/2021 mem - Remove extra information from Completion messages with warning "Over 10% of the MS/MS spectra have a minimum m/z value larger than the required minimum; reporter ion peaks likely could not be detected"
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _startPos int;
    _failureMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Dataset Capture
    ---------------------------------------------------

    If _script = 'DatasetCapture' OR _script = 'IMSDatasetCapture' Then
        If _jobInfo.NewState in (2, 3, 5) Then -- always call in case capture task job completes too quickly for normal update cycle Then
            CALL public.set_capture_task_busy (_datasetName, '(broker)', _message => _message);
        End If;

        If _jobInfo.NewState = 3 Then
            ---------------------------------------------------
            -- Capture task job succeeded
            --
            -- Call update_dms_file_info_xml to push the dataset info into public.t_dataset_info
            -- If a duplicate dataset is found, _returnCode will be 'U5360'
            ---------------------------------------------------

            CALL cap.update_dms_file_info_xml (_datasetID, _deleteFromTableOnSuccess => 1, _message => _message, _returnCode => _returnCode);

            If _returnCode = 'U5360' Then
                -- Use special completion code of 101
                CALL public.set_capture_task_complete (_datasetName, 101, _message => _message, _failureMessage => _message);

                -- Fail out the capture task job with state 14 (Failed, Ignore Job Step States)
                Update cap.t_tasks
                Set State = 14
                Where Job = _job;
            Else
                -- Use special completion code of 100
                CALL public.set_capture_task_complete (_datasetName, 100, _message => _message);
            End If;
        End If;

        If _jobInfo.NewState = 5 Then
            ---------------------------------------------------
            -- Capture task job failed
            ---------------------------------------------------

            -- Look for any failure messages in t_task_steps for this capture task job
            -- First check the Evaluation_Message column
            SELECT TS.Evaluation_Message
            INTO _failureMessage
            FROM cap.t_task_steps TS inner join
                 cap.t_tasks T ON TS.Job = T.Job
            WHERE (TS.Job = _job) AND Coalesce(TS.Evaluation_Message, '') <> '';

            If Coalesce(_failureMessage, '') = '' Then
                -- Next check the Completion_Message column
                SELECT TS.Completion_Message
                INTO _failureMessage
                FROM cap.t_task_steps TS inner join
                     cap.t_tasks T ON TS.Job = T.Job
                WHERE (TS.Job = _job) AND Coalesce(TS.Completion_Message, '') <> '';

                -- Auto remove "; To ignore this error, use Exec Add_Update_Job_Parameter" or
                --             "; To ignore this error, use call add_update_task_parameter"
                --             "; To ignore this error, use call add_update_task_parameter"
                -- from the completion message
                _startPos := position('; To ignore this error, use' In _failureMessage);

                If _startPos > 1 Then
                    _failureMessage := Substring(_failureMessage, 1, _startPos - 1);
                End If;
            End If;

            CALL public.set_capture_task_complete (_datasetName, 1, _message => _message, _failureMessage => _failureMessage);
        End If;
    End If;

    ---------------------------------------------------
    -- Dataset Archive
    ---------------------------------------------------

    If _script = 'DatasetArchive' Then
        If _jobInfo.NewState in (2, 3, 5) -- always call in case capture task job completes too quickly for normal update cycle Then
            CALL public.set_archive_task_busy (_datasetName, _storageServerName, _message => _message);
        End If;

        If _jobInfo.NewState = 3 Then
            CALL public.set_archive_task_complete (_datasetName, 100, _message => _message); -- using special completion code of 100
        End If;

        If _jobInfo.NewState = 5 Then
            CALL public.set_archive_task_complete (_datasetName, 1, _message => _message);
        End If;
    End If;

    ---------------------------------------------------
    -- Archive Update
    ---------------------------------------------------

    If _script = 'ArchiveUpdate' Then
        If _jobInfo.NewState in (2, 3, 5) -- always call in case capture task job completes too quickly for normal update cycle Then
            CALL public.set_archive_update_task_busy (_datasetName, _storageServerName, _message => _message);
        End If;

        If _jobInfo.NewState = 3 Then
            CALL public.set_archive_update_task_complete (_datasetName, 0, _message => _message);
        End If;

        If _jobInfo.NewState = 5 Then
            CALL public.set_archive_update_task_complete (_datasetName, 1, _message => _message);
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE cap.update_dms_dataset_state IS 'UpdateDMSDatasetState';
