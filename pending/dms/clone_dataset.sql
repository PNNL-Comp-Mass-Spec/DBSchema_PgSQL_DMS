--
CREATE OR REPLACE PROCEDURE public.clone_dataset
(
    _infoOnly boolean = true,
    _dataset text,
    _suffix text = '_Test1',
    _createDatasetArchiveTask boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
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
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingProcName text;
    _tranClone text := 'Clone';
    _requestID int := 0;
    _datasetInfo record;
    _datasetIDNew int;
    _datasetNew text;
    _requestNameNew citext;
    _captureJob int := 0;
    _captureJobNew int := 0;
    _dateStamp timestamp;
    _jobMessage text;
]
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
        _message := '_dataset parameter cannot be empty';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    If _suffix = '' Then
        _message := '_suffix parameter cannot be empty';
        RAISE INFO '%', _message;
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
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the target dataset does not already exist
    ---------------------------------------------------

    _datasetNew := format('%s%s', _dataset, _suffix);

    If Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _datasetNew::citext) Then
        _message := format('Target dataset already exists: %s', _datasetNew);
        RAISE INFO '%', _message;
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
        -- Also look up information required for previewing the cloned dataset

        SELECT E.experiment As ExperimentName,
               DS.operator_username As OperatorUsername,
               DS.capture_subfolder As CaptureSubdirectory,
               DS.cart_config_id As LcCartConfigID,
               DS.dataset_rating_id As DatasetRatingID,
               DS.separation_type As SeparationType,
               Inst.instrument As InstrumentName,
               DSType.Dataset_Type As DatasetType,                         -- Aka _msType
               RR.instrument_setting As InstrumentSettings,
               RR.wellplate As Wellplate,
               RR.well As WellNum,
               RR.request_internal_standard As InternalStandard,
               'Automatically created by dataset entry' As Comment,
               RR.work_package As WorkPackage,
               EUT.eus_usage_type As EusUsageType,
               RR.eus_proposal_id As EusProposalID,
               RR.separation_group As SeparationGroup,
               lccart.cart_name As LcCartName,
               lccol.lc_column As LcColumn
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

        If _infoOnly Then

            -- Preview the new dataset

            RAISE INFO '';

            RAISE INFO 'Dataset Name:         %', _datasetNew;
            RAISE INFO 'Experiment Name:      %', _datasetInfo.ExperimentName;
            RAISE INFO 'Instrument Name:      %', _datasetInfo.InstrumentName;
            RAISE INFO 'Capture Subdirectory: %', _datasetInfo.CaptureSubdirectory;
            RAISE INFO 'Separation Type:      %', _datasetInfo.SeparationType;
            RAISE INFO 'Dataset Type:         %', _datasetInfo.DatasetType;
            RAISE INFO 'Operator Username:    %', _datasetInfo.OperatorUsernamel;
            RAISE INFO 'Comment:              %', _datasetInfo.Comment;
            RAISE INFO 'Dataset Rating ID:    %', _datasetInfo.DatasetRatingID;
            RAISE INFO 'Wellplate:            %', _datasetInfo.Wellplate;
            RAISE INFO 'Well Number:          %', _datasetInfo.WellNum;
            RAISE INFO 'Internal Standard:    %', _datasetInfo.InternalStandard;

            RAISE INFO '';

            -- Preview the new requested run

            RAISE INFO '';
            RAISE INFO 'New Request Name:     %', _requestNameNew;
            RAISE INFO 'Instrument Settings:  %', _datasetInfo.InstrumentSettings;
            RAISE INFO 'Separation Group:     %', _datasetInfo.SeparationGroup;
            RAISE INFO 'LC Cart Name:         %', _datasetInfo.LcCartName;
            RAISE INFO 'LC Cart Config:       %', _datasetInfo.LcCartConfigID;
            RAISE INFO 'LC Column:            %', _datasetInfo.LcColumn;
            RAISE INFO 'Work Package:         %', _datasetInfo.WorkPackage;
            RAISE INFO 'EMSL UsageType:       %', _datasetInfo.EusUsageType;
            RAISE INFO 'EMSL ProposalID:      %', _datasetInfo.EusProposalID;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Duplicate the dataset
        ---------------------------------------------------

        -- Add a new row to t_dataset

        INSERT INTO t_dataset (dataset, operator_username, comment, created, instrument_id, lc_column_id, dataset_type_id,
                               wellplate, well, separation_type, dataset_state_id, last_affected, folder_name, storage_path_ID,
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
               storage_path_ID,
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
                                _requestName => _requestNameNew,
                                _experimentName => _datasetInfo.ExperimentName,
                                _requesterUsername =>_datasetInfo.OperatorUsername,
                                _instrumentName => _datasetInfo.InstrumentName,
                                _workPackage => _datasetInfo.WorkPackage,
                                _msType => _datasetInfo.DatasetType,
                                _instrumentSettings => _datasetInfo.nstrumentSettings,
                                _wellplateName => _datasetInfo.Wellplate,
                                _wellNumber => _datasetInfo.WellNum,
                                _internalStandard => _datasetInfo.InternalStandard,
                                _comment => _datasetInfo.Comment,
                                _eusProposalID => _datasetInfo.EusProposalID,
                                _eusUsageType => _datasetInfo.EusUsageType,
                                _eusUsersList => _datasetInfo.EusUsersList,
                                _mode => 'add-auto',
                                _request => _requestID,         -- Output
                                _message => _message,           -- Output
                                _returnCode => _returnCode,     -- Output
                                _secSep => _datasetInfo.SeparationGroup,
                                _mrmAttachment => '',
                                _status => 'Completed',
                                _skipTransactionRollback => true,
                                _autoPopulateUserListIfBlank => true,   -- Auto populate _eusUsersList if blank since this is an Auto-Request
                                _callingUser => '',
                                _vialingConc => null,
                                _vialingVol => null,
                                _stagingLocation => null,
                                _requestIDForUpdate => null,
                                _logDebugMessages => false,
                                _resolvedInstrumentInfo => _resolvedInstrumentInfo);    -- Output


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

        CALL post_log_entry ('Error', _message, 'Clone_Dataset');
        RETURN;
    End If;

    BEGIN
        -- Associate the requested run with the dataset

        UPDATE t_requested_run
        SET dataset_id = _datasetIDNew
        WHERE request_name = _requestNameNew AND dataset_id Is Null;

        -- Possibly create a Dataset Archive task

        If _createDatasetArchiveTask Then
            CALL public.add_archive_dataset (
                            _datasetID  => _datasetIDNew,
                            _message    => _message,
                            _returnCode => _returnCode);
        Else
            RAISE INFO 'You should manually create a dataset archive task using: CALL Add_Archive_Dataset %', _datasetIDNew;
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

    -- Commit changes now
    COMMIT;

    BEGIN
        _message := format('Created dataset %s by cloning %s', _datasetNew, _dataset);

        CALL post_log_entry ('Normal', _message, 'Clone_Dataset');

        -- Create a Capture job for the newly cloned dataset

        SELECT MAX(Job)
        INTO _captureJob
        FROM cap.t_tasks
        WHERE Dataset = _dataset::citext AND Script ILIKE '%capture%';

        If Coalesce(_captureJob, 0) = 0 Then

            -- Job not found; examine T_Jobs_History
            SELECT Job, Saved
            INTO _captureJob, _dateStamp
            FROM cap.t_tasks_History
            WHERE Dataset = _dataset::citext AND
                  Script ILIKE '%capture%'
            ORDER BY Saved DESC
            LIMIT 1;

            If Not FOUND Then
                RAISE INFO 'Unable to create capture job in cap.t_tasks since source job not found for dataset %', _dataset;
                RETURN;
            End If;

            INSERT INTO cap.t_tasks (Priority, Script, State,
                                     Dataset, Dataset_ID, Results_Folder_Name,
                                     Imported, Start, Finish)
            SELECT Priority,
                   Script,
                   3 AS State,
                   _datasetNew AS Dataset,
                   _datasetIDNew AS Dataset_ID,
                   '' AS Results_Folder_Name,
                   CURRENT_TIMESTAMP AS Imported,
                   CURRENT_TIMESTAMP AS Start,
                   CURRENT_TIMESTAMP AS Finish
            FROM cap.t_tasks_History
            WHERE Job = _captureJob AND
                  Saved = _dateStamp
            RETURNING cap.t_tasks.Job
            INTO _captureJobNew;

            If FOUND Then

                INSERT INTO cap.t_task_steps ( Job,
                                               Step,
                                               Step_Tool,
                                               State,
                                               Input_Folder_Name,
                                               Output_Folder_Name,
                                               Processor,
                                               Start,
                                               Finish,
                                               Tool_Version_ID,
                                               Completion_Code,
                                               Completion_Message,
                                               Evaluation_Code,
                                               Evaluation_Message,
                                               Holdoff_Interval_Minutes,
                                               Next_Try,
                                               Retry_Count )
                SELECT _captureJobNew AS Job,
                       Step,
                       tool,
                       Case When Not State In (3,5,7) Then 7 Else State End As State,
                       Input_Folder_Name,
                       Output_Folder_Name,
                       'In-Silico' AS Processor,
                       Case When Start Is Null Then Null Else CURRENT_TIMESTAMP End As Start,
                       Case When Finish Is Null Then Null Else CURRENT_TIMESTAMP End As Finish,
                       1 As Tool_Version_ID,
                       0 AS Completion_Code,
                       '' AS Completion_Message,
                       0 AS Evaluation_Code,
                       '' AS Evaluation_Message,
                       0 AS Holdoff_Interval_Minutes,
                       CURRENT_TIMESTAMP AS Next_Try,
                       0 AS Retry_Count
                FROM cap.t_task_steps_history
                WHERE Job = _captureJob AND
                      Saved = _dateStamp;

            End If;

        Else

            INSERT INTO cap.t_tasks (Priority, Script, State,
                                     Dataset, Dataset_ID, Storage_Server, Instrument, Instrument_Class,
                                     Max_Simultaneous_Captures,
                                     Imported, Start, Finish, Archive_Busy, Comment)
            SELECT Priority,
                   Script,
                   State,
                   _datasetNew AS Dataset,
                   _datasetIDNew AS Dataset_ID,
                   Storage_Server,
                   Instrument,
                   Instrument_Class,
                   Max_Simultaneous_Captures,
                   CURRENT_TIMESTAMP AS Imported,
                   CURRENT_TIMESTAMP AS Start,
                   CURRENT_TIMESTAMP AS Finish,
                   0 AS Archive_Busy,
                   format('Cloned from dataset %s', _dataset) AS Comment
            FROM cap.t_tasks
            WHERE Dataset = _dataset::citext AND
                  Script ILIKE '%capture%'
            ORDER BY cap.t_tasks.Job Desc
            LIMIT 1
            RETURNING cap.t_tasks.Job
            INTO _captureJobNew;

            If FOUND Then

                INSERT INTO cap.t_task_steps( Job,
                                              Step,
                                              Tool,
                                              CPU_Load,
                                              Dependencies,
                                              State,
                                              Input_Folder_Name,
                                              Output_Folder_Name,
                                              Processor,
                                              Start,
                                              Finish,
                                              Tool_Version_ID,
                                              Completion_Code,
                                              Completion_Message,
                                              Evaluation_Code,
                                              Evaluation_Message,
                                              Holdoff_Interval_Minutes,
                                              Next_Try,
                                              Retry_Count )
                SELECT _captureJobNew AS Job,
                       Step,
                       Tool,
                       CPU_Load,
                       Dependencies,
                       Case When Not State In (3,5,7) Then 7 Else State End As State,
                       Input_Folder_Name,
                       Output_Folder_Name,
                       'In-Silico' AS Processor,
                       Case When Start Is Null Then Null Else CURRENT_TIMESTAMP End As Start,
                       Case When Finish Is Null Then Null Else CURRENT_TIMESTAMP End As Finish,
                       1 AS Tool_Version_ID,
                       0 AS Completion_Code,
                       '' AS Completion_Message,
                       0 AS Evaluation_Code,
                       '' AS Evaluation_Message,
                       Holdoff_Interval_Minutes,
                       CURRENT_TIMESTAMP AS Next_Try,
                       Retry_Count
                FROM cap.t_task_steps
                WHERE Job = _captureJob

                INSERT INTO cap.t_task_step_dependencies (Job, Step, Target_Step,
                                                          Condition_Test, Test_Value, Evaluated,
                                                          Triggered, Enable_Only)
                SELECT _captureJobNew AS Job,
                       Step,
                       Target_Step,
                       Condition_Test,
                       Test_Value,
                       Evaluated,
                       Triggered,
                       Enable_Only
                FROM cap.t_task_step_dependencies
                WHERE Job = _captureJob;

            End If;

        End If;

        If Coalesce(_captureJobNew, 0) > 0 Then
            CALL cap.update_parameters_for_task (_captureJobNew, _message => _message, _returnCode => _returnCode);

            _jobMessage := format('Created capture task job %s for dataset %s by cloning job %s',
                                    _captureJobNew, _datasetNew, _captureJob);

            CALL post_log_entry ('Normal', _jobMessage, 'Clone_Dataset');

            _message := format('%s; %s', _message, _jobMessage);
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

END
$$;

COMMENT ON PROCEDURE public.clone_dataset IS 'CloneDataset';
