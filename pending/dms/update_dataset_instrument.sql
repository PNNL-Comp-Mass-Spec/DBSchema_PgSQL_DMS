--
CREATE OR REPLACE PROCEDURE public.update_dataset_instrument
(
    _datasetName text,
    _newInstrument text,
    _infoOnly boolean = true,
    _updateCaptured boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Changes the instrument name of a dataset
**
**      Typically used for datasets that are new and failed capture
**      due to the instrument name being wrong (e.g. 15T_FTICR instead of 15T_FTICR_Imaging)
**
**      However, set _updateCaptured to true to also allow changing the instrument
**      of a dataset that was already successfully captured
**
**  Auth:   mem
**  Date:   04/30/2019 mem - Initial Version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _errMsg text;
    _datasetId int := 0;
    _state int := 0;
    _captureJob int := 0;
    _stepState int := 0;
    _datasetCreated timestamp;
    _instrumentIdOld Int;
    _instrumentIdNew Int;
    _storagePathIdOld int;
    _storagePathIdNew Int;
    _storagePathOld text;
    _storagePathNew text;
    _instrumentNameOld text;
    _instrumentNameNew text;
    _storageServerNew text;
    _instrumentClassNew text;
    _deleteCaptureJob int := 0;
    _instrumentUpdateTran text := 'Instrument update';
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _datasetName := Coalesce(_datasetName, '');
    _newInstrument := Coalesce(_newInstrument, '');
    _infoOnly := Coalesce(_infoOnly, true);
    _updateCaptured := Coalesce(_updateCaptured, false);

    ----------------------------------------------------------
    -- Lookup the dataset id and dataset state
    ----------------------------------------------------------

    SELECT dataset_id,
           dataset_state_id,
           created,
           instrument_id,
           storage_path_ID
    INTO _datasetId, _state, _datasetCreated, _instrumentIdOld, _storagePathIdOld
    FROM t_dataset
    WHERE dataset = _datasetName

    If Not FOUND Or Coalesce(_datasetId, 0) = 0 Then
        _message := 'Dataset not found: ' || _datasetName;
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not _updateCaptured And _state <> 5 Then
        _message := 'Dataset state is not "Capture failed"; not changing the instrument';
        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Find the capture job for this dataset
    SELECT Job,
           State
    INTO _captureJob, _stepState
    FROM cap.V_Capture_Job_Steps
    WHERE Dataset_ID = _datasetId AND
            Tool = 'DatasetCapture';

    If Not FOUND Then
        _message := 'Dataset capture job not found; not changing the instrument';
        _returnCode := 'U5203';
        RETURN;
    End If;

    If Not _updateCaptured And Coalesce(_stepState, 0) <> 6 Then
        _message := 'Dataset capture step state is not "Failed"; not changing the instrument';
        _returnCode := 'U5204';
        RETURN;
    End If;

    If _stepState = 6 Then
        _deleteCaptureJob := 1;
    End If;

    SELECT instrument
    INTO _instrumentNameOld
    FROM t_instrument_name
    WHERE instrument_id = _instrumentIdOld

    SELECT instrument_id,
           instrument,
           instrument_class
    INTO _instrumentIdNew, _instrumentNameNew, _instrumentClassNew
    FROM t_instrument_name
    WHERE instrument = _newInstrument;

    If Not FOUND Or Coalesce(_instrumentIdNew, 0) = 0 Then
        _message := 'New instrument not found: ' || _newInstrument;
        _returnCode := 'U5205';
        RETURN;
    End If;

    _storagePathIdNew := get_instrument_storage_path_for_new_datasets (_instrumentIdNew, _datasetCreated, _autoSwitchActiveStorage => false, _infoOnly => false);

    SELECT public.combine_paths(vol_client, Path)
    INTO _storagePathNew
    FROM V_Storage_List_Report
    WHERE ID = _storagePathIdNew

    If _infoOnly Then
        SELECT public.combine_paths(vol_client, Path)
        INTO _storagePathOld
        FROM V_Storage_List_Report
        WHERE ID = _storagePathIdOld

        SELECT public.combine_paths(vol_client, Path)
        INTO _storagePathNew
        FROM V_Storage_List_Report
        WHERE ID = _storagePathIdNew

        -- ToDo: Show this data using RAISE INFO

        SELECT ID,
               Dataset,
               Experiment,
               State,
               Instrument AS Instrument_Old,
               _instrumentNameNew AS Instrument_New,
               _storagePathOld AS Storage_Path_Old,
               _storagePathNew AS Storage_Path_New,
               Created
        FROM V_Dataset_List_Report_2
        WHERE ID = _datasetId

        SELECT *
        FROM cap.V_Capture_Job_Steps
        WHERE Job = _captureJob And
              Tool = 'DatasetCapture'

        RETURN;
    End If;

    SELECT machine_name
    INTO _storageServerNew
    FROM t_storage_path
    WHERE storage_path_id = _storagePathIdNew

    If Not FOUND Then
        _message := 'Storage path ID ' || Cast(_storagePathIdNew As text) || ' not found in t_storage_path; aborting';
        _returnCode := 'U5206';
        RETURN;
    End If;

    UPDATE t_dataset
    SET instrument_id = _instrumentIdNew,
        storage_path_ID = _storagePathIdNew
    WHERE dataset_id = _datasetId

    If Not _deleteCaptureJob Then

        UPDATE cap.t_tasks
        SET Storage_Server = _storageServerNew,
            Instrument = _instrumentNameNew,
            Instrument_Class = _instrumentClassNew
        WHERE Job = _captureJob And Dataset_ID = _datasetId

        Call cap.update_parameters_for_job (_captureJob);
    Else
        DELETE cap.t_tasks
        WHERE Job = _captureJob And Dataset_ID = _datasetId

        UPDATE t_dataset
        SET dataset_state_id = 1
        WHERE dataset_id = _datasetId

    End If;

    _message := 'Changed instrument from ' || _instrumentNameOld || ' to ' || _instrumentNameNew || ' ' ||;
                'for dataset ' || _datasetName || ', Dataset_ID ' || Cast(_datasetId As text) || '; ' ||
                'Storage path ID changed from ' ||
                Cast(_storagePathIdOld As text) || ' to ' || Cast(_storagePathIdNew As text)

    Call post_log_entry ('Normal', _message, 'UpdateDatasetInstrument');

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    If char_length(_message) > 0 Then
        If _returnCode <> '' Then
            RAISE WARNING '%', _message
        Else
            RAISE INFO '%', _message;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_dataset_instrument IS 'UpdateDatasetInstrument';
