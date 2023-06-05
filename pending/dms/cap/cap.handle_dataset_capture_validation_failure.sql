--
CREATE OR REPLACE PROCEDURE cap.handle_dataset_capture_validation_failure
(
    _datasetNameOrID text,
    _comment text = 'Bad .raw file',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      This procedure can be used with datasets that
**      are successfully captured but fail the dataset integrity check
**      (.Raw file too small, expected files missing, etc).
**
**      The procedure changes the capture task job state to 101
**      then calls public.handle_dataset_capture_validation_failure()
**
**  Auth:   mem
**  Date:   04/28/2011
**          09/13/2011 mem - Updated to support script 'IMSDatasetCapture' in addition to 'DatasetCapture'
**          11/05/2012 mem - Added additional Print statement
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          08/10/2018 mem - Call update_dms_file_info_xml to push the dataset info into public.t_dataset_info
**          11/02/2020 mem - Fix bug validating the dataset name
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _datasetName text;
    _captureJob int;
    _infoMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------
    -- Validate the inputs
    ----------------------------------------

    _datasetNameOrID := Coalesce(_datasetNameOrID, '');
    _comment := Coalesce(_comment, '');

    If _comment = '' Then
        _comment := 'Bad dataset';
    End If;

    _datasetID := Coalesce(public.try_cast(_datasetNameOrID, 0), 0);

    If _datasetID <> 0 Then
        ----------------------------------------
        -- Lookup the Dataset Name
        ----------------------------------------

        SELECT Dataset
        INTO _datasetName
        FROM cap.t_tasks
        WHERE Dataset_ID = _datasetID AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture')

        If Not FOUND Then
            _message := format('Dataset ID not found: %s', _datasetNameOrID);
            _returnCode := 'U5201';

            RAISE INFO '%', _message;
            RETURN;
        End If;

    Else
        ----------------------------------------
        -- Lookup the dataset ID
        ----------------------------------------

        _datasetName := _datasetNameOrID;

        SELECT Dataset_ID
        INTO _datasetID
        FROM cap.t_tasks
        WHERE Dataset = _datasetName AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture');

        If Not FOUND Then
            _message := format('Dataset not found: %s', _datasetNameOrID);
            _returnCode := 'U5202';

            RAISE INFO '%', _message;
            RETURN;
        End If;
    End If;

    If _returnCode = '' Then
        -- Make sure the DatasetCapture task has failed
        SELECT Job
        INTO _captureJob
        FROM cap.t_tasks
        WHERE Dataset_ID = _datasetID AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture') AND
              State = 5;

        If Not FOUND Then
            _message := format('DatasetCapture task for dataset %s is not in State 5; unable to continue', _datasetName);
            _returnCode := 'U5203';

            RAISE INFO '%', _message;
            RETURN;
        End If;
    End If;

    If _infoOnly Then

        _message := format('Mark dataset %s As bad: %s', _datasetName, _comment);
        RAISE INFO '%', _message;

        SELECT format('Capture Task Job %s, Dataset_ID %s, Instrument %s, Imported %s',
                      job, dataset_id, instrument, public.timestamp_text(imported))
        INTO _infoMessage
        FROM cap.t_tasks
        WHERE Dataset_ID = _datasetID AND
              Script IN ('DatasetCapture', 'IMSDatasetCapture') AND
              State = 5
        ORDER BY job desc
        LIMIT 1;

        RAISE INFO '%', _infoMessage;

        RETURN;
    End If;

    -- Call update_dms_file_info_xml to push the dataset info into public.t_dataset_info
    -- If a duplicate dataset is found, _returnCode will be 'U5360'
    CALL cap.update_dms_file_info_xml (_datasetID, _deleteFromTableOnSuccess => 1, _message => _message, _returnCode => _returnCode);

    If _returnCode = 'U5360' Then
        -- Use special completion code of 101
        CALL public.set_capture_task_complete (_datasetName, 101, _message => _message, _failureMessage => _message);

        -- Fail out the capture task job with state 14 (Failed, Ignore Job Step States)
        UPDATE cap.t_tasks
        SET State = 14
        WHERE Job = _captureJob;

        RETURN;
    End If;

    UPDATE cap.t_tasks
    SET State = 101
    WHERE Job = _captureJob;

    If Not FOUND Then
        _message := format('Unable to update capture task job %s in t_tasks for dataset %s', _captureJob, _datasetName);
        _returnCode := 'U5204';
        RAISE INFO '%', _message;
    Else
        -- Mark the dataset as bad in public.t_dataset
        CALL public.handle_dataset_capture_validation_failure (_datasetID, _comment, _infoOnly, _message => _message, _returnCode => _returnCode);

        _message := format('Marked dataset As bad: %s', _datasetName);
        RAISE INFO '%', _message;

    End If;

END
$$;

COMMENT ON PROCEDURE cap.handle_dataset_capture_validation_failure IS 'HandleDatasetCaptureValidationFailure';
