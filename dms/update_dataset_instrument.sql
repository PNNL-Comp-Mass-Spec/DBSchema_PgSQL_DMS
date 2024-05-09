--
-- Name: update_dataset_instrument(text, text, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_instrument(IN _datasetname text, IN _newinstrument text, IN _infoonly boolean DEFAULT true, IN _updatecaptured boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Change the instrument name of a dataset
**
**      Typically used for datasets that are new and failed capture due to the instrument name being wrong
**      (e.g. 15T_FTICR instead of 15T_FTICR_Imaging)
**
**      However, when _updateCaptured is true, will change the instrument of a dataset that has already been successfully captured
**
**  Arguments:
**    _datasetName      Dataset name
**    _newInstrument    New instrument name
**    _infoOnly         When true, preview updates
**    _updateCaptured   If true, allow changing the instrument for datasets that were already successfully added to DMS
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   04/30/2019 mem - Initial Version
**          08/02/2023 mem - Add call to update_cached_dataset_instruments
**          02/27/2024 mem - Call update_cached_dataset_folder_paths
**          02/29/2024 mem - Ported to PostgreSQL
**          05/08/2024 mem - Reference t_cached_dataset_stats instead of t_cached_dataset_instruments
**
*****************************************************/
DECLARE
    _errMsg text;
    _datasetId int;
    _state int;
    _captureJob int;
    _stepState int;
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
    _deleteCaptureJob boolean := false;
    _msg text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _datasetName    := Trim(Coalesce(_datasetName, ''));
    _newInstrument  := Trim(Coalesce(_newInstrument, ''));
    _infoOnly       := Coalesce(_infoOnly, true);
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
    WHERE dataset = _datasetName::citext;

    If Not FOUND Or Coalesce(_datasetId, 0) = 0 Then
        _message := format('Dataset not found: %s', _datasetName);
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not _updateCaptured And _state <> 5 Then
        _message := 'Dataset state is not "Capture failed"; not changing the instrument';
        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Find the capture job for this dataset
    SELECT T.job, TS.state
    INTO _captureJob, _stepState
    FROM cap.t_tasks T
         INNER JOIN cap.t_task_steps TS
           ON T.job = TS.job
    WHERE T.Dataset_ID = _datasetId AND
          TS.Tool = 'DatasetCapture';

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
        _deleteCaptureJob := true;
    End If;

    SELECT instrument
    INTO _instrumentNameOld
    FROM t_instrument_name
    WHERE instrument_id = _instrumentIdOld;

    SELECT instrument_id,
           instrument,
           instrument_class
    INTO _instrumentIdNew, _instrumentNameNew, _instrumentClassNew
    FROM t_instrument_name
    WHERE instrument = _newInstrument;

    If Not FOUND Or Coalesce(_instrumentIdNew, 0) = 0 Then
        _message := format('New instrument not found: %s', _newInstrument);
        _returnCode := 'U5205';
        RETURN;
    End If;

    If _instrumentIdOld = _instrumentIdNew Then
        _message := format('Old and new instrument names are the same: %s vs. %s', _instrumentNameOld, _instrumentNameNew);
        _returnCode := 'U5206';
        RETURN;
    End If;

    _storagePathIdNew := public.get_instrument_storage_path_for_new_datasets(_instrumentIdNew, _datasetCreated, _autoSwitchActiveStorage => false, _infoOnly => false);

    SELECT public.combine_paths(vol_name_client, storage_path)
    INTO _storagePathNew
    FROM t_storage_path
    WHERE storage_path_id = _storagePathIdNew;

    If _infoOnly Then
        SELECT public.combine_paths(vol_name_client, storage_path)
        INTO _storagePathOld
        FROM t_storage_path
        WHERE storage_path_id = _storagePathIdOld;

        RAISE INFO '';

        _formatSpecifier := '%-10s %-80s %-60s %-20s %-25s %-25s %-80s %-80s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Dataset',
                            'Experiment',
                            'State',
                            'Instrument_Old',
                            'Instrument_New',
                            'Storage_Path_Old',
                            'Storage_Path_New',
                            'Created'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '--------------------',
                                     '-------------------------',
                                     '-------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT DS.dataset_id,
                   DS.dataset,
                   E.experiment,
                   DSN.dataset_state,
                   CDS.instrument     AS instrument_old,
                   _instrumentNameNew AS instrument_new,
                   _storagePathOld    AS storage_path_old,
                   _storagePathNew    AS storage_path_new,
                   public.timestamp_text(DS.created) AS created
            FROM t_dataset DS
                 INNER JOIN t_experiments E
                   ON DS.exp_id = E.exp_id
                 INNER JOIN t_dataset_state_name DSN
                   ON DSN.dataset_state_id = DS.dataset_state_id
                 LEFT OUTER JOIN t_cached_dataset_stats CDS
                   ON DS.dataset_id = CDS.dataset_id
            WHERE DS.dataset_id = _datasetId
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.dataset_id,
                                _previewData.dataset,
                                _previewData.experiment,
                                _previewData.dataset_state,
                                _previewData.instrument_old,
                                _previewData.instrument_new,
                                _previewData.storage_path_old,
                                _previewData.storage_path_new,
                                _previewData.created
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        _formatSpecifier := '%-9s %-80s %-10s %-4s %-25s %-25s %-15s %-5s %-20s %-20s %-15s %-60s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Dataset',
                            'Dataset_ID',
                            'Step',
                            'Script',
                            'Tool',
                            'State_Name',
                            'State',
                            'Start',
                            'Finish',
                            'Runtime_Minutes',
                            'Output_Folder',
                            'Instrument'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------------------------------------------------------------------------------',
                                     '----------',
                                     '----',
                                     '-------------------------',
                                     '-------------------------',
                                     '---------------',
                                     '-----',
                                     '--------------------',
                                     '--------------------',
                                     '---------------',
                                     '------------------------------------------------------------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT T.job,
                   T.dataset,
                   T.dataset_id,
                   TS.step,
                   T.script,
                   TS.tool,
                   SSN.step_state AS state_name,
                   TS.state,
                   public.timestamp_text(TS.start)  AS start,
                   public.timestamp_text(TS.finish) AS finish,
                   round((EXTRACT(epoch FROM (COALESCE((ts.finish), CURRENT_TIMESTAMP) - (ts.start))) / 60), 1) AS runtime_minutes,
                   TS.Output_Folder_name AS output_folder,
                   T.instrument
            FROM cap.t_tasks T
                 INNER JOIN cap.t_task_steps TS
                   ON T.job = TS.job
                 INNER JOIN cap.t_task_step_state_name SSN
                   ON TS.state = SSN.step_state_id
            WHERE T.Job = _captureJob AND
                  TS.Tool = 'DatasetCapture'
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.job,
                                _previewData.dataset,
                                _previewData.dataset_id,
                                _previewData.step,
                                _previewData.script,
                                _previewData.tool,
                                _previewData.state_name,
                                _previewData.state,
                                _previewData.start,
                                _previewData.finish,
                                _previewData.runtime_minutes,
                                _previewData.output_folder,
                                _previewData.instrument
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    SELECT machine_name
    INTO _storageServerNew
    FROM t_storage_path
    WHERE storage_path_id = _storagePathIdNew;

    If Not FOUND Then
        _message := format('Storage path ID %s not found in t_storage_path; aborting', _storagePathIdNew);
        _returnCode := 'U5207';
        RETURN;
    End If;

    UPDATE t_dataset
    SET instrument_id = _instrumentIdNew,
        storage_path_ID = _storagePathIdNew
    WHERE dataset_id = _datasetId;

    RAISE INFO '';

    If _deleteCaptureJob Then
        DELETE FROM cap.t_tasks
        WHERE Job = _captureJob AND Dataset_ID = _datasetId;

        UPDATE t_dataset
        SET dataset_state_id = 1
        WHERE dataset_id = _datasetId;

        RAISE INFO 'Deleted capture task job % and reset state of dataset ID % to 1', _captureJob, _datasetId;
    Else
        UPDATE cap.t_tasks
        SET Storage_Server = _storageServerNew,
            Instrument = _instrumentNameNew,
            Instrument_Class = _instrumentClassNew
        WHERE Job = _captureJob AND Dataset_ID = _datasetId;

        CALL cap.update_parameters_for_task (
                    _jobList => _captureJob::text,
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output

        RAISE INFO 'Updated storage server and instrument info in cap.t_tasks for capture task job %, dataset ID %', _captureJob, _datasetId;
    End If;

    UPDATE t_cached_dataset_folder_paths
    SET update_required = 1
    WHERE dataset_id = _datasetId;

    CALL update_cached_dataset_folder_paths (
            _processingMode => 0,
            _showDebug      => false,
            _message        => _message,
            _returnCode     => _returnCode);

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    _message := format('Changed instrument from %s to %s for dataset %s, Dataset_ID %s; Storage path ID changed from %s to %s',
                        _instrumentNameOld, _instrumentNameNew, _datasetName, _datasetId, _storagePathIdOld, _storagePathIdNew);

    CALL post_log_entry ('Normal', _message, 'Update_Dataset_Instrument');

    -- Update t_cached_dataset_stats
    CALL public.update_cached_dataset_instruments (
                    _processingMode => 0,
                    _datasetId      => _datasetID,
                    _infoOnly       => false,
                    _message        => _msg,            -- Output
                    _returnCode     => _returnCode);    -- Output

    If _msg <> '' Then
        _message = public.append_to_text(_message, _msg);
    End If;

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    If Coalesce(_message, '') <> '' Then
        If _returnCode <> '' Then
            RAISE WARNING '%', _message;
        Else
            RAISE INFO '%', _message;
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.update_dataset_instrument(IN _datasetname text, IN _newinstrument text, IN _infoonly boolean, IN _updatecaptured boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dataset_instrument(IN _datasetname text, IN _newinstrument text, IN _infoonly boolean, IN _updatecaptured boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_dataset_instrument(IN _datasetname text, IN _newinstrument text, IN _infoonly boolean, IN _updatecaptured boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateDatasetInstrument';

