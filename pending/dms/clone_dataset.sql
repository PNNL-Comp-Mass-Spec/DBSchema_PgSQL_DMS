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
**      Clones a dataset, including creating a new requested run; does not clone any jobs
**
**      This procedure is intended to be used in cases where a dataset's files have been manually duplicated on a storage server
**      and we wish to run new analysis jobs against the cloned dataset using DMS
**
**  Arguments:
**    _infoOnly                   Change to false to actually perform the clone; when true, preview items that would be created
**    _dataset                    Dataset name to clone
**    _suffix                     Suffix to apply to cloned dataset and requested run
**    _createDatasetArchiveTask   Set to true to instruct DMS to archive the cloned dataset
**
**  Auth:   mem
**  Date:   02/27/2014
**          09/25/2014 mem - Updated T_Job_Step_Dependencies to use Job
**                           Removed the Machine column from T_Job_Steps
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling AddUpdateRequestedRun
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling AddUpdateRequestedRun
**          11/25/2022 mem - Update call to AddUpdateRequestedRun to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingProcName text;
    _tranClone text := 'Clone';
    _requestID int := 0;
    _datasetInfo record;
    _datasetIDNew int;
    _datasetNew text;
    _requestNameNew text;
    _captureJob int := 0;
    _captureJobNew int := 0;
    _dateStamp timestamp;
    _jobMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _dataset := Coalesce(_dataset, '');
    _suffix := Coalesce(_suffix, '');
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
    --
    SELECT RR.request_id
    INTO _requestID
    FROM t_requested_run RR
         INNER JOIN t_dataset DS
           ON RR.dataset_id = DS.dataset_id
    WHERE DS.dataset = _dataset;

    If Not FOUND Then
        _message := format('Source dataset not found: %s', _dataset);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the target dataset does not already exist
    ---------------------------------------------------

    _datasetNew := _Dataset || _suffix;

    If Exists (SELECT * FROM t_dataset WHERE dataset = _datasetNew) Then
        _message := format('Target dataset already exists: %s', _datasetNew);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    BEGIN

        -- Lookup the EUS Users for the request associated with the dataset we are cloning
        --
        SELECT string_agg(eus_person_id::text, ',' ORDER BY eus_person_id)
        INTO _eusUsersList
        FROM t_requested_run_eus_users
        WHERE request_id = _requestID;

        _eusUsersList := Coalesce(_eusUsersList, '');

        -- Lookup the information requred to create a new requested run
        --
        SELECT E.experiment As ExperimentName
               DS.operator_username As OperatorUsername
               Inst.instrument As InstrumentName
               RR.work_package As WorkPackage
               DTN.Dataset_Type As DatasetType                         -- Aka _msType
               RR.instrument_setting As InstrumentSettings
               RR.wellplate As Wellplate
               RR.well As WellNum
               RR.request_internal_standard As InternalStandard
               'Automatically created by dataset entry' As Comment
               RR.eus_proposal_id As EusProposalID
               EUT.eus_usage_type As EusUsageType
               RR.separation_group As SecSep
        INTO _datasetInfo
        FROM t_dataset DS
             INNER JOIN t_requested_run RR
               ON DS.dataset_id = RR.dataset_id
             INNER JOIN t_experiments E
               ON DS.exp_id = E.exp_id
             INNER JOIN t_instrument_name Inst
               ON DS.instrument_id = Inst.instrument_id
             INNER JOIN t_dataset_rating_name DTN
               ON DS.dataset_type_ID = DTN.DST_Type_ID
             INNER JOIN t_eus_usage_type EUT
               ON RR.eus_usage_type_id = EUT.request_id
        WHERE DS.dataset = _dataset;

        _requestNameNew := format('AutoReq_%s', _DatasetNew);

        If _infoOnly Then
        -- <a>
            ---------------------------------------------------
            -- Preview the new dataset
            ---------------------------------------------------

            -- ToDo: Use RAISE INFO to show this info

            SELECT _datasetNew AS Dataset_Name_New, *
            FROM t_dataset
            WHERE dataset = _dataset;

            ---------------------------------------------------
            -- Preview the new requested run
            ---------------------------------------------------

            -- ToDo: Use RAISE INFO to show this info

            SELECT _requestNameNew AS Request_Name_New,
                   _datasetInfo.ExperimentName AS Experiment,
                   _datasetInfo.InstrumentName AS Instrument,
                   _datasetInfo.WorkPackage AS WorkPackage,
                   _datasetInfo.DatasetType AS Dataset_Type,
                   _datasetInfo.InstrumentSettings AS Instrument_Settings,
                   _datasetInfo.Wellplate AS Wellplate,
                   _datasetInfo.WellNum AS Well_Num,
                   _datasetInfo.InternalStandard AS Internal_standard,
                   _datasetInfo.Comment AS Comment,
                   _datasetInfo.EusProposalID AS EUS_Proposal_ID,
                   _datasetInfo.EusUsageType AS EUS_UsageType,
                   _datasetInfo.EusUsersList AS EUS_UsersList,
                   _datasetInfo.SecSep AS Sec_Sep;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Duplicate the dataset
        ---------------------------------------------------

        -- Add a new row to t_dataset
        --
        INSERT INTO t_dataset (dataset, DS_Oper_username, comment, created, DS_instrument_name_ID, DS_LC_column_ID, DS_type_ID,
                               DS_wellplate_num, DS_well_num, separation_type, dataset_state_id, last_affected, folder_name, DS_storage_path_ID,
                               -- Remove or update since skipped column: exp_id, DS_internal_standard_ID, dataset_rating_id, DS_Comp_State, DS_Compress_Date, ds_prep_server_name,
                               acq_time_start, acq_time_end, scan_count, File_Size_Bytes, File_Info_Last_Modified, Interval_to_Next_DS
        )
        SELECT _datasetNew AS Dataset_Name,
            operator_username,
            'Cloned from dataset ' || _dataset AS DS_comment,
            CURRENT_TIMESTAMP AS Created,
            instrument_id,
            lc_column_ID,
            dataset_type_ID,
            wellplate,
            well,
            separation_type,
            dataset_state_id,
            CURRENT_TIMESTAMP AS DS_Last_Affected,
            _datasetNew AS DS_folder_name,
            storage_path_ID,
            exp_id,
            internal_standard_ID,
            dataset_rating_id,
            -- Remove or update since skipped column: DS_Comp_State,
            -- Remove or update since skipped column: DS_Compress_Date,
            ds_prep_server_name,
            acq_time_start,
            acq_time_end,
            scan_count,
            file_size_bytes,
            file_info_last_modified,
            interval_to_next_ds
        FROM t_dataset
        WHERE dataset = _dataset
        RETURNING dataset_id
        INTO _datasetIDNew;

        -- Create a requested run for the dataset
        -- (code is from AddUpdateDataset)

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
                                _secSep => _datasetInfo.SecSep,
                                _mRMAttachment => '',
                                _status => 'Completed',
                                _skipTransactionRollback => true,
                                _autoPopulateUserListIfBlank => true);        -- Auto populate _eusUsersList if blank since this is an Auto-Request

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
        --
        UPDATE t_requested_run
        SET dataset_id = _datasetIDNew
        WHERE request_name = _requestNameNew AND dataset_id Is Null

        -- Possibly create a Dataset Archive task
        --
        If _createDatasetArchiveTask Then
            CALL AddArchiveDataset (_datasetIDNew);
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
        WHERE Dataset = _dataset AND Script LIKE '%capture%';

        If Coalesce(_captureJob, 0) = 0 Then

            -- Job not found; examine T_Jobs_History
            SELECT Job, Saved
            INTO _captureJob, _dateStamp
            FROM cap.t_tasks_History
            WHERE Dataset = _dataset AND
                  Script LIKE '%capture%'
            ORDER BY Saved DESC
            LIMIT 1;

            If Not FOUND Then
                RAISE INFO '%', 'Unable to create capture job in DMS_Capture since source job not found for dataset ' || _dataset;
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

                INSERT INTO cap.T_Job_Steps( Job,
                                             Step_Number,
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
                       Step_Number,
                       Step_Tool,
                       Case When State Not In (3,5,7) Then 7 Else State End As State,
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
                FROM cap.T_Job_Steps_History
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
                   'Cloned from dataset ' || _dataset AS Comment
            FROM cap.t_tasks
            WHERE Dataset = _dataset AND
                  Script LIKE '%capture%'
            ORDER BY cap.t_tasks.Job Desc
            LIMIT 1
            RETURNING cap.t_tasks.Job
            INTO _captureJobNew;

            If FOUND Then

                INSERT INTO cap.T_Job_Steps( Job,
                                             Step_Number,
                                             Step_Tool,
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
                       Step_Number,
                       Step_Tool,
                       CPU_Load,
                       Dependencies,
                       Case When State Not In (3,5,7) Then 7 Else State End As State,
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
                FROM cap.T_Job_Steps
                WHERE Job = _captureJob

                INSERT INTO cap.T_Job_Step_Dependencies (Job, Step_Number, Target_Step_Number,
                                                         Condition_Test, Test_Value, Evaluated,
                                                         Triggered, Enable_Only)
                SELECT _captureJobNew AS Job,
                       Step_Number,
                       Target_Step_Number,
                       Condition_Test,
                       Test_Value,
                       Evaluated,
                       Triggered,
                       Enable_Only
                FROM cap.T_Job_Step_Dependencies
                WHERE Job = _captureJob;

            End If;

        End If;

        If Coalesce(_captureJobNew, 0) > 0 Then
            CALL cap.update_parameters_for_job (_captureJobNew)

            _jobMessage := format('Created capture task job %s for dataset %s by cloning job %s',
                                    _captureJobNew, _datasetNew, _captureJob

            CALL post_log_entry ('Normal', _jobMessage, 'Clone_Dataset');

            _message := _message || '; ' || _jobMessage;
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
