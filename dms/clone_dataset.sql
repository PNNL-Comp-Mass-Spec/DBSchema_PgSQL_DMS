--
-- Name: clone_dataset(boolean, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.clone_dataset(IN _infoonly boolean DEFAULT true, IN _dataset text DEFAULT ''::text, IN _suffix text DEFAULT '_Test1'::text, IN _createdatasetarchivetask boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Clone a dataset, including creating a new requested run; does not clone any jobs
**
**      This procedure is intended to be used in cases where a dataset's files have been manually duplicated on a storage server
**      and we wish to run new analysis jobs against the cloned dataset using DMS
**
**  Arguments:
**    _infoOnly                     When true, preview items that would be created
**    _dataset                      Dataset name to clone
**    _suffix                       Suffix to apply to cloned dataset and requested run
**    _createDatasetArchiveTask     When true, instruct DMS to archive the cloned dataset
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   02/27/2014
**          09/25/2014 mem - Updated T_Job_Step_Dependencies to use Job
**                           Removed the Machine column from T_Job_Steps
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling Add_Update_Requested_Run
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          11/25/2022 mem - Update call to Add_Update_Requested_Run to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          03/04/2023 mem - Use new T_Task tables
**          02/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingProcName text;
    _eusUsersList text;
    _requestID int;
    _datasetInfo record;
    _datasetIDNew int;
    _datasetNew citext;
    _requestNameNew citext;
    _resolvedinstrumentinfo text;
    _captureJob int;
    _captureJobNew int;
    _dateStamp timestamp;
    _actionMessage text;
    _jobMessage text;

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

    _infoOnly                 := Coalesce(_infoOnly, true);
    _dataset                  := Trim(Coalesce(_dataset, ''));
    _suffix                   := Trim(Coalesce(_suffix, ''));
    _createDatasetArchiveTask := Coalesce(_createDatasetArchiveTask, false);

    If _dataset = '' Then
        _message := 'Dataset name must be specified';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _suffix = '' Then
        _message := 'Dataset name suffix must be specified';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the source dataset exists (and determine the Requested Run ID)
    ---------------------------------------------------

    SELECT RR.request_id
    INTO _requestID
    FROM t_requested_run RR
         INNER JOIN t_dataset DS
           ON RR.dataset_id = DS.dataset_id
    WHERE DS.dataset = _dataset::citext;

    If Not FOUND Then
        _message := format('Source dataset not found: %s', _dataset);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the target dataset does not already exist
    ---------------------------------------------------

    _datasetNew := format('%s%s', _dataset, _suffix);

    If Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _datasetNew) Then
        _message := format('Target dataset already exists: %s', _datasetNew);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    BEGIN

        -- Lookup the EUS Users for the request associated with the dataset we are cloning

        SELECT string_agg(eus_person_id::text, ',' ORDER BY eus_person_id)
        INTO _eusUsersList
        FROM t_requested_run_eus_users
        WHERE request_id = _requestID;

        _eusUsersList := Trim(Coalesce(_eusUsersList, ''));

        -- Lookup the information requred to create a new requested run
        -- Also Lookup information required for previewing the cloned dataset

        SELECT E.experiment AS ExperimentName,
               DS.operator_username AS OperatorUsername,
               DS.capture_subfolder AS CaptureSubdirectory,
               DS.cart_config_id AS LcCartConfigID,
               DS.dataset_rating_id AS DatasetRatingID,
               DS.separation_type AS SeparationType,
               Inst.instrument AS InstrumentName,
               DSType.Dataset_Type AS DatasetType,                         -- Aka _msType
               RR.instrument_setting AS InstrumentSettings,
               RR.wellplate AS Wellplate,
               RR.well AS WellNum,
               RR.request_internal_standard AS InternalStandard,
               'Automatically created by dataset entry' AS Comment,
               RR.work_package AS WorkPackage,
               EUT.eus_usage_type AS EusUsageType,
               RR.eus_proposal_id AS EusProposalID,
               RR.separation_group AS SeparationGroup,
               lccart.cart_name AS LcCartName,
               lccol.lc_column AS LcColumn
        INTO _datasetInfo
        FROM t_dataset DS
             INNER JOIN t_requested_run RR
               ON DS.dataset_id = RR.dataset_id
             INNER JOIN t_experiments E
               ON DS.exp_id = E.exp_id
             INNER JOIN t_instrument_name Inst
               ON DS.instrument_id = Inst.instrument_id
             INNER JOIN t_dataset_type_name DSType
               ON DS.dataset_type_ID = DSType.dataset_type_id
             INNER JOIN t_eus_usage_type EUT
               ON RR.eus_usage_type_id = EUT.eus_usage_type_id
             INNER JOIN t_lc_cart LCCart
               ON LCCart.cart_id = RR.cart_id
             INNER JOIN t_lc_column LCCol
               ON ds.lc_column_id = LCCol.lc_column_id
        WHERE DS.dataset = _dataset::citext;

        _requestNameNew := format('AutoReq_%s', _datasetNew);

        If Trim(Coalesce(_datasetInfo.WorkPackage, '')) = '' Then
            _datasetInfo.WorkPackage := 'none';
        End If;

        If _infoOnly Then

            RAISE INFO '';

            -- Preview the new dataset

            RAISE INFO 'New Dataset Name:     %', _datasetNew;
            RAISE INFO 'Experiment Name:      %', _datasetInfo.ExperimentName;
            RAISE INFO 'Instrument Name:      %', _datasetInfo.InstrumentName;
            RAISE INFO 'Capture Subdirectory: %', _datasetInfo.CaptureSubdirectory;
            RAISE INFO 'Separation Type:      %', _datasetInfo.SeparationType;
            RAISE INFO 'Dataset Type:         %', _datasetInfo.DatasetType;
            RAISE INFO 'Operator Username:    %', _datasetInfo.OperatorUsername;
            RAISE INFO 'Comment:              %', _datasetInfo.Comment;
            RAISE INFO 'Dataset Rating ID:    %', _datasetInfo.DatasetRatingID;
            RAISE INFO 'Wellplate:            %', Coalesce(_datasetInfo.Wellplate, '');
            RAISE INFO 'Well Number:          %', Coalesce(_datasetInfo.WellNum, '');
            RAISE INFO 'Internal Standard:    %', _datasetInfo.InternalStandard;

            RAISE INFO '';

            -- Preview the new requested run

            RAISE INFO 'New Request Name:     %', _requestNameNew;
            RAISE INFO 'Instrument Settings:  %', _datasetInfo.InstrumentSettings;
            RAISE INFO 'Separation Group:     %', _datasetInfo.SeparationGroup;
            RAISE INFO 'LC Cart Name:         %', _datasetInfo.LcCartName;
            RAISE INFO 'LC Cart Config:       %', _datasetInfo.LcCartConfigID;
            RAISE INFO 'LC Column:            %', _datasetInfo.LcColumn;
            RAISE INFO 'Work Package:         %', _datasetInfo.WorkPackage;
            RAISE INFO 'EMSL UsageType:       %', _datasetInfo.EusUsageType;
            RAISE INFO 'EMSL ProposalID:      %', Coalesce(_datasetInfo.EusProposalID, '');

            RETURN;
        End If;

        ---------------------------------------------------
        -- Duplicate the dataset
        ---------------------------------------------------

        -- Add a new row to t_dataset

        INSERT INTO t_dataset (
            dataset, operator_username, comment, created, instrument_id, lc_column_id, dataset_type_id,
            wellplate, well, separation_type, dataset_state_id, last_affected, folder_name, storage_path_id,
            exp_id, internal_standard_id, dataset_rating_id, ds_prep_server_name,
            acq_time_start, acq_time_end, scan_count, file_size_bytes, file_info_last_modified, interval_to_next_ds
        )
        SELECT _datasetNew AS Dataset_Name,
               operator_username,
               format('Cloned from dataset %s', _dataset) AS Comment,
               CURRENT_TIMESTAMP AS Created,
               instrument_id,
               lc_column_ID,
               dataset_type_ID,
               wellplate,
               well,
               separation_type,
               dataset_state_id,
               CURRENT_TIMESTAMP AS Last_Affected,
               _datasetNew AS folder_name,
               storage_path_id,
               exp_id,
               internal_standard_ID,
               dataset_rating_id,
               ds_prep_server_name,
               acq_time_start,
               acq_time_end,
               scan_count,
               file_size_bytes,
               file_info_last_modified,
               interval_to_next_ds
        FROM t_dataset
        WHERE dataset = _dataset::citext
        RETURNING dataset_id
        INTO _datasetIDNew;

        -- Create a requested run for the dataset
        -- (code is from add_update_dataset)

        CALL public.add_update_requested_run (
                                _requestName                 => _requestNameNew,
                                _experimentName              => _datasetInfo.ExperimentName::text,
                                _requesterUsername           => _datasetInfo.OperatorUsername::text,
                                _instrumentGroup             => _datasetInfo.InstrumentName::text,
                                _workPackage                 => _datasetInfo.WorkPackage::text,
                                _msType                      => _datasetInfo.DatasetType::text,
                                _instrumentSettings          => _datasetInfo.InstrumentSettings::text,
                                _wellplateName               => _datasetInfo.Wellplate::text,
                                _wellNumber                  => _datasetInfo.WellNum::text,
                                _internalStandard            => _datasetInfo.InternalStandard::text,
                                _comment                     => _datasetInfo.Comment::text,
                                _batch                       => 0,
                                _block                       => 0,
                                _runorder                    => 0,
                                _eusProposalID               => _datasetInfo.EusProposalID::text,
                                _eusUsageType                => _datasetInfo.EusUsageType::text,
                                _eusUsersList                => _eusUsersList,
                                _mode                        => 'add-auto',
                                _secSep                      => _datasetInfo.SeparationGroup::text,
                                _mrmAttachment               => '',
                                _status                      => 'Completed',
                                _skipTransactionRollback     => true,
                                _autoPopulateUserListIfBlank => true,   -- True so that _eusUsersList is auto-populated if blank (since this is an Auto-Request)
                                _callingUser                 => '',
                                _vialingConc                 => null,
                                _vialingVol                  => null,
                                _stagingLocation             => null,
                                _requestIDForUpdate          => null,
                                _logDebugMessages            => false,
                                _request                     => _requestID,                     -- Output
                                _resolvedInstrumentInfo      => _resolvedInstrumentInfo,        -- Output
                                _message                     => _message,                       -- Output
                                _returnCode                  => _returnCode);                   -- Output

        If _returnCode <> '' Then
            If Trim(Coalesce(_message, '')) = '' Then
                _message := format('add_update_requested_run returned return code %s when creating requested run %s', _returnCode, _requestNameNew);
            End If;

            CALL post_log_entry ('Error', _message, 'Clone_Dataset');
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

    If _returnCode <> '' Then
        ROLLBACK;

        RAISE INFO '';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    BEGIN
        -- Associate the requested run with the dataset

        UPDATE t_requested_run
        SET dataset_id = _datasetIDNew
        WHERE request_name = _requestNameNew AND dataset_id IS NULL;

        -- Possibly create a Dataset Archive task

        If _createDatasetArchiveTask Then
            CALL public.add_archive_dataset (
                            _datasetID  => _datasetIDNew,
                            _message    => _message,
                            _returnCode => _returnCode);

            If _returnCode <> '' Then
                If Trim(Coalesce(_message, '')) = '' Then
                    _message := format('add_archive_dataset returned return code %s when adding dataset ID %s to t_dataset_archive', _returnCode, _datasetIDNew);
                End If;

                CALL post_log_entry ('Error', _message, 'Clone_Dataset');
            End If;

        Else
            RAISE INFO '';
            RAISE INFO 'You should manually create a dataset archive task using: CALL add_archive_dataset (%);', _datasetIDNew;
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

    If _returnCode <> '' Then
        ROLLBACK;

        RAISE INFO '';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    -- Commit changes now
    COMMIT;

    BEGIN
        _message := format('Created dataset %s by cloning %s', _datasetNew, _dataset);

        CALL post_log_entry ('Normal', _message, 'Clone_Dataset');

        _actionMessage := _message;

        -- Create a capture task job for the newly cloned dataset

        SELECT MAX(Job)
        INTO _captureJob
        FROM cap.t_tasks
        WHERE Dataset = _dataset::citext AND
              Script ILIKE '%capture%';

        If Coalesce(_captureJob, 0) = 0 Then

            -- Job not found; examine t_tasks_history
            SELECT job, saved
            INTO _captureJob, _dateStamp
            FROM cap.t_tasks_History
            WHERE dataset = _dataset::citext AND
                  script ILIKE '%capture%'
            ORDER BY saved DESC
            LIMIT 1;

            If Not FOUND Then
                RAISE WARNING 'Unable to create capture task job in cap.t_tasks since source job not found for dataset %', _dataset;
                RETURN;
            End If;

            INSERT INTO cap.t_tasks (
                priority, script, state,
                dataset, dataset_id, results_folder_name,
                imported, start, finish
            )
            SELECT priority,
                   script,
                   3 as state,
                   _datasetNew AS dataset,
                   _datasetIDNew AS dataset_id,
                   '' AS results_folder_name,
                   CURRENT_TIMESTAMP AS imported,
                   CURRENT_TIMESTAMP AS start,
                   CURRENT_TIMESTAMP AS finish
            FROM cap.t_tasks_History
            WHERE job = _captureJob AND
                  saved = _dateStamp
            RETURNING cap.t_tasks.job
            INTO _captureJobNew;

            If FOUND Then

                INSERT INTO cap.t_task_steps (
                    job,
                    step,
                    tool,
                    state,
                    input_folder_name,
                    output_folder_name,
                    processor,
                    start,
                    finish,
                    tool_version_id,
                    completion_code,
                    completion_message,
                    evaluation_code,
                    evaluation_message,
                    holdoff_interval_minutes,
                    next_try,
                    retry_count
                )
                SELECT _captureJobNew AS Job,
                       step,
                       tool,
                       CASE WHEN NOT state IN (3, 5, 7) THEN 7 ELSE state END AS state,
                       input_folder_name,
                       output_folder_name,
                       'In-Silico' AS processor,
                       CASE WHEN start  IS Null THEN Null ELSE CURRENT_TIMESTAMP END AS start,
                       CASE WHEN finish IS Null THEN Null ELSE CURRENT_TIMESTAMP END AS finish,
                       1  AS tool_version_id,
                       0  AS completion_code,
                       '' AS completion_message,
                       0  AS evaluation_code,
                       '' AS evaluation_message,
                       0  AS holdoff_interval_minutes,
                       CURRENT_TIMESTAMP AS next_try,
                       0  AS retry_count
                FROM cap.t_task_steps_history
                WHERE job = _captureJob AND
                      saved = _dateStamp;

            End If;

        Else

            INSERT INTO cap.t_tasks (
                priority, script, state,
                dataset, dataset_id, storage_server, instrument, instrument_class,
                max_simultaneous_captures,
                imported, start, finish, archive_busy, comment
            )
            SELECT priority,
                   script,
                   state,
                   _datasetNew AS dataset,
                   _datasetIDNew AS dataset_id,
                   storage_server,
                   instrument,
                   instrument_class,
                   max_simultaneous_captures,
                   CURRENT_TIMESTAMP AS imported,
                   CURRENT_TIMESTAMP AS start,
                   CURRENT_TIMESTAMP AS finish,
                   0 AS archive_busy,
                   format('Cloned from dataset %s', _dataset) AS comment
            FROM cap.t_tasks
            WHERE dataset = _dataset::citext AND
                  script ILIKE '%capture%'
            ORDER BY cap.t_tasks.job DESC
            LIMIT 1
            RETURNING cap.t_tasks.job
            INTO _captureJobNew;

            If FOUND Then

                INSERT INTO cap.t_task_steps (
                    job,
                    step,
                    tool,
                    cpu_load,
                    dependencies,
                    state,
                    input_folder_name,
                    output_folder_name,
                    processor,
                    start,
                    finish,
                    tool_version_id,
                    completion_code,
                    completion_message,
                    evaluation_code,
                    evaluation_message,
                    holdoff_interval_minutes,
                    next_try,
                    retry_count
                )
                SELECT _captureJobNew AS job,
                       step,
                       tool,
                       cpu_load,
                       dependencies,
                       CASE WHEN NOT state IN (3, 5, 7) THEN 7 ELSE state END AS state,
                       input_folder_name,
                       output_folder_name,
                       'In-Silico' AS processor,
                       CASE WHEN start  IS NULL THEN NULL ELSE CURRENT_TIMESTAMP END AS start,
                       CASE WHEN finish IS NULL THEN NULL ELSE CURRENT_TIMESTAMP END AS finish,
                       1  AS tool_version_id,
                       0  AS completion_code,
                       '' AS completion_message,
                       0  AS evaluation_code,
                       '' AS evaluation_message,
                       holdoff_interval_minutes,
                       CURRENT_TIMESTAMP AS next_try,
                       retry_count
                FROM cap.t_task_steps
                WHERE job = _captureJob;

                INSERT INTO cap.t_task_step_dependencies (
                    job, step, target_step,
                    condition_test, test_value, evaluated,
                    triggered, enable_only
                )
                SELECT _captureJobNew AS job,
                       step,
                       target_step,
                       condition_test,
                       test_value,
                       evaluated,
                       triggered,
                       enable_only
                FROM cap.t_task_step_dependencies
                WHERE Job = _captureJob;

            End If;

        End If;

        If Coalesce(_captureJobNew, 0) > 0 Then
            CALL cap.update_parameters_for_task (
                        _joblist    => _captureJobNew::text,
                        _message    => _message,
                        _returnCode => _returnCode,
                        _infoonly   => false);

            _jobMessage := format('Created capture task job %s for dataset %s by cloning job %s',
                                  _captureJobNew, _datasetNew, _captureJob);

            CALL post_log_entry ('Normal', _jobMessage, 'Clone_Dataset');

            _actionMessage := format('%s; %s', _actionMessage, _jobMessage);
        End If;

        If _actionMessage <> '' Then
            _message := _actionMessage;
        End If;

        RAISE INFO '%', _message;
        RETURN;

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

    RAISE INFO '';
    RAISE WARNING '%', _message;
END
$$;


ALTER PROCEDURE public.clone_dataset(IN _infoonly boolean, IN _dataset text, IN _suffix text, IN _createdatasetarchivetask boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE clone_dataset(IN _infoonly boolean, IN _dataset text, IN _suffix text, IN _createdatasetarchivetask boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.clone_dataset(IN _infoonly boolean, IN _dataset text, IN _suffix text, IN _createdatasetarchivetask boolean, INOUT _message text, INOUT _returncode text) IS 'CloneDataset';

