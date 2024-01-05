--
-- Name: delete_requested_run(integer, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_requested_run(IN _requestid integer DEFAULT 0, IN _skipdatasetcheck boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Remove a requested run (and all its dependencies)
**
**  Arguments:
**    _requestID            Requested run ID to delete
**    _skipDatasetCheck     Set to true to allow deleting a requested run even if it has an associated dataset
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   grk
**  Date:   02/23/2006
**          10/29/2009 mem - Made _message an optional output parameter
**          02/26/2010 grk - Delete factors
**          12/12/2011 mem - Added parameter _callingUser, which is passed to alter_event_log_entry_user
**          03/22/2016 mem - Added parameter _skipDatasetCheck
**          06/13/2017 mem - Fix typo
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          03/30/2023 mem - Ported to PostgreSQL
**                         - Append data to t_deleted_requested_run and t_deleted_factor prior to deleting the requested run
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          07/27/2023 mem - Add schema name parameter when calling alter_event_log_entry_user()
**                         - Use local variable for the return value of _message from alter_event_log_entry_user()
**          09/05/2023 mem - Use schema name when calling procedures
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _deletedBy text;
    _batchID int;
    _datasetID int := 0;
    _dataset text;
    _eusPersonID int;
    _stateID int;
    _deletedRequestedRunEntryID int;
    _message2 text;
    _targetType int;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';
    _skipDatasetCheck := Coalesce(_skipDatasetCheck, false);

    _callingUser := Trim(Coalesce(_callingUser, ''));

    _deletedBy = CASE WHEN _callingUser = ''
                      THEN session_user
                      ELSE _callingUser
                 END;

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the requested run ID
    ---------------------------------------------------

    If _requestID = 0 Then
        _message := '_requestID is 0; nothing to do';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    -- Verify that the request exists and check whether the request is in a batch

    SELECT batch_id
    INTO _batchID
    FROM t_requested_run
    WHERE request_id = _requestID;

    If Not FOUND Then
        _message := format('ID %s not found in T_Requested_Run; nothing to do', _requestID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Not _skipDatasetCheck Then

        SELECT dataset_id
        INTO _datasetID
        FROM t_requested_run
        WHERE request_id = _requestID;

        If Coalesce(_datasetID, 0) > 0 Then

            SELECT dataset
            INTO _dataset
            FROM t_dataset
            WHERE dataset_id = _datasetID;

            -- Note that update_requested_run_assignments looks for the text "associated with dataset" in the following message

            _message := format('Cannot delete requested run %s because it is associated with dataset %s (ID %s)',
                                _requestID, Coalesce(_dataset, '??'), _datasetID);

            _returnCode := 'U5275';
            RETURN;
        End If;
    End If;

    BEGIN

        -- Look for an EUS user associated with the requested run
        -- If there is more than one user, only keep the first one (since, effective February 2020, requested runs are limited to a single EUS user)

        SELECT EUS_Person_ID
        INTO _eusPersonID
        FROM T_Requested_Run_EUS_Users
        WHERE request_id = _requestID
        ORDER BY EUS_Person_ID
        LIMIT 1;

        If Not FOUND Then
            _eusPersonID := null;
        End If;

        ---------------------------------------------------
        -- Add the requested run to t_deleted_requested_run
        ---------------------------------------------------

        INSERT INTO t_deleted_requested_run (
            Request_Id, Request_Name, Requester_Username, Comment, Created, Instrument_Group,
            Request_Type_Id, Instrument_Setting, Special_Instructions, Wellplate, Well, Priority, Note, Exp_Id,
            Request_Run_Start, Request_Run_Finish, Request_Internal_Standard, Work_Package, Batch_Id,
            Blocking_Factor, Block, Run_Order, EUS_Proposal_Id, EUS_Usage_Type_Id, EUS_Person_Id,
            Cart_Id, Cart_Config_Id, Cart_Column, Separation_Group, Mrm_Attachment,
            Dataset_Id, Origin, State_Name, Request_Name_Code, Vialing_Conc, Vialing_Vol, Location_Id,
            Queue_State, Queue_Instrument_Id, Queue_Date, Entered, Updated, Updated_By, Deleted_By
            )
        SELECT Request_Id, Request_Name, Requester_Username, Comment, Created, Instrument_Group,
               Request_Type_Id, Instrument_Setting, Special_Instructions, Wellplate, Well, Priority, Note, Exp_Id,
               Request_Run_Start, Request_Run_Finish, Request_Internal_Standard, Work_Package, Batch_Id,
               Blocking_Factor, Block, Run_Order, EUS_Proposal_Id, EUS_Usage_Type_Id, _eusPersonID,
               Cart_Id, Cart_Config_Id, Cart_Column, Separation_Group, Mrm_Attachment,
               Dataset_Id, Origin, State_Name, Request_Name_Code, Vialing_Conc, Vialing_Vol, Location_Id,
               Queue_State, Queue_Instrument_Id, Queue_Date, Entered, Updated, Updated_By, _deletedBy
        FROM T_Requested_Run
        WHERE Request_Id = _requestID
        RETURNING Entry_ID
        INTO _deletedRequestedRunEntryID;

        ---------------------------------------------------
        -- Add any factors to t_deleted_factor
        ---------------------------------------------------

        INSERT INTO t_deleted_factor (Factor_ID, Type, Target_ID, Name, Value, Last_Updated, Deleted_By, Deleted_Requested_Run_Entry_ID)
        SELECT Factor_ID, Type, Target_ID, Name, Value, Last_Updated, _deletedBy, _deletedRequestedRunEntryID
        FROM T_Factor
        WHERE Type = 'Run_Request' AND
              Target_ID = _requestID;

        ---------------------------------------------------
        -- Delete associated factors
        ---------------------------------------------------

        DELETE FROM t_factor
        WHERE target_id = _requestID;

        ---------------------------------------------------
        -- Delete EUS users associated with request
        ---------------------------------------------------

        DELETE FROM t_requested_run_eus_users
        WHERE request_id = _requestID;

        ---------------------------------------------------
        -- Delete associated auto-created request
        ---------------------------------------------------

        DELETE FROM t_requested_run
        WHERE request_id = _requestID;

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
        If _callingUser <> '' Then
            _targetType := 11;
            _stateID := 0;

            CALL public.alter_event_log_entry_user ('public', _targetType, _requestID, _stateID, _callingUser, _message => _alterEnteredByMessage);

            RAISE INFO '%', _alterEnteredByMessage;
        End If;

        COMMIT;
    END;

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    If _batchID > 0 Then

        CALL public.update_cached_requested_run_batch_stats (
                        _batchID,
                        _fullRefresh => false,
                        _message     => _message2,      -- Output
                        _returncode  => _returncode);   -- Output

        If _returnCode <> '' Then
            _message := _message2;
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.delete_requested_run(IN _requestid integer, IN _skipdatasetcheck boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_requested_run(IN _requestid integer, IN _skipdatasetcheck boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_requested_run(IN _requestid integer, IN _skipdatasetcheck boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteRequestedRun';

