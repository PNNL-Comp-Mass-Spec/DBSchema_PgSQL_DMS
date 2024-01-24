--
-- Name: update_requested_run_assignments(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_assignments(IN _mode text, IN _newvalue text, IN _reqrunidlist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the specified requested runs to change priority, instrument group, separation group, dataset type, or assigned instrument
**
**      This procedure is called via two mechanisms:
**
**      1) Via POST calls to requested_run/operation/ , originating from https://dms2.pnl.gov/requested_run_admin/report
**         - See file requested_run_admin_cmds.php at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/master/application/views/cmd/requested_run_admin_cmds.php
**           and file lcmd.js at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/d2eab881133cfe4c71f17b06b09f52fc4e61c8fb/javascript/lcmd.js#L225
**
**      2) When the user clicks "Delete this request" or "Convert Request Into Fractions" at the bottom of a Requested Run Detail report
**         - See the detail_report_commands and sproc_args sections at https://dms2.pnl.gov/config_db/show_db/requested_run.db
**
**  Arguments:
**    _mode             Mode: 'priority', 'instrumentGroup', 'instrumentGroupIgnoreType', 'assignedInstrument', 'separationGroup', 'datasetType', or 'delete'
**    _newValue         New instrument group, assigned instrument, separation group, dataset type, or priority
**    _reqRunIDList     Comma-separated list of requested run IDs
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   01/26/2003
**          12/11/2003 grk - Removed LCMS cart modes
**          07/27/2007 mem - When _mode = 'instrument, then checking dataset type (_datasetTypeName) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #503)
**                         - Added output parameter _message to report the number of items updated
**          09/16/2009 mem - Now checking dataset type (_datasetTypeName) using Instrument_Allowed_Dataset_Type table (Ticket #748)
**          08/28/2010 mem - Now auto-switching _newValue to be instrument group instead of instrument name (when _mode = 'instrument')
**                         - Now validating dataset type for instrument using T_Instrument_Group_Allowed_DS_Type
**                         - Added try-catch for error handling
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          12/12/2011 mem - Added parameter _callingUser, which is passed to DeleteRequestedRun
**          06/26/2013 mem - Added mode 'instrumentIgnoreType' (doesn't validate dataset type when changing the instrument group)
**                     mem - Added mode 'datasetType'
**          07/24/2013 mem - Added mode 'separationGroup'
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/22/2016 mem - Now passing _skipDatasetCheck to DeleteRequestedRun
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/31/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Do not log an error when a requested run cannot be deleted because it is associated with a dataset
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/01/2019 mem - Change argument _reqRunIDList from varchar(2048) to varchar(max)
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          10/20/2020 mem - Rename mode 'instrument' to 'instrumentGroup'
**                         - Rename mode 'instrumentIgnoreType' to 'instrumentGroupIgnoreType'
**                         - Add mode 'assignedInstrument'
**          02/04/2021 mem - Provide a delimiter when calling Get_Instrument_Group_Dataset_Type_List
**          01/13/2023 mem - Refactor instrument group validation code into validate_instrument_group_for_requested_runs
**                         - Validate the instrument group for modes 'instrumentGroup' and 'assignedInstrument'
**          01/16/2023 mem - Ported to PostgreSQL
**          05/10/2023 mem - Capitalize procedure name sent to post_usage_log_entry
**          05/11/2023 mem - Update return codes
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Move INTO to new line
**                         - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Use schema name with try_cast
**          12/08/2023 mem - Select a single column when using If Not Exists()
**          01/03/2024 mem - Update warning messages
**          01/23/2024 mem - When updating the instrument group, block the update if it would result in a mix of instrument groups for any of the batches associated with the requested runs
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _updateCount int;
    _inactiveCount int;
    _requestCount int := 0;
    _msg text;
    _requestID int;

    _newInstrumentGroup citext := '';
    _instrumentGroupFromInstName citext;
    _newSeparationGroup citext := '';
    _newAssignedInstrumentID int := 0;
    _newQueueState int := 0;
    _newDatasetType citext := '';
    _newDatasetTypeID int := 0;

    _batchID int;
    _instrumentGroupCount int;
    _instrumentGroups text;
    _requestIDs text;
    _requestedRunDesc text;

    _logErrors boolean := false;
    _pri int;
    _countDeleted int := 0;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

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

    BEGIN

        -- Uncomment to log the values of the procedure arguments in T_Log_Entries
        --
        -- _msg := format('Procedure called with _mode=%s, _newValue=%s, _reqRunIDList=%s',
        --                 Coalesce(_mode, '??'), Coalesce(_newValue, '??'), Coalesce(_reqRunIDList, '??'));
        -- CALL post_log_entry ('Debug', _msg, 'Update_Requested_Run_Assignments');

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode         := Trim(Lower(Coalesce(_mode, '')));
        _newValue     := Trim(Coalesce(_newValue, ''));
        _reqRunIDList := Trim(Coalesce(_reqRunIDList, ''));

        ---------------------------------------------------
        -- Populate a temporary table with the values in _reqRunIDList
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestIDs (
            RequestID int
        );

        INSERT INTO Tmp_RequestIDs (RequestID)
        SELECT value
        FROM public.parse_delimited_integer_list(_reqRunIDList);
        --
        GET DIAGNOSTICS _requestCount = ROW_COUNT;

        If Not FOUND Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Request ID list was empty; nothing to do';
        End If;

        -- Initial validation checks are complete; now enable _logErrors
        _logErrors := true;

        If _mode::citext In ('instrumentGroup', 'instrumentGroupIgnoreType') Then

            ---------------------------------------------------
            -- Validate the instrument group
            -- Note that as of 6/26/2013 mode 'instrument' does not appear to be used by the DMS website
            -- This unused mode was renamed to 'instrumentGroup' in October 2020
            -- Mode 'instrumentGroupIgnoreType' is used by http://dms2.pnl.gov/requested_run_admin/report
            ---------------------------------------------------

            -- Set the instrument group to _newValue for now
            _newInstrumentGroup := _newValue;

            If Not Exists (SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _newInstrumentGroup) Then
                -- Try to update instrument group using t_instrument_name
                SELECT instrument_group
                INTO _instrumentGroupFromInstName
                FROM t_instrument_name
                WHERE instrument = _newValue::citext;

                If FOUND Then
                    _newInstrumentGroup = _instrumentGroupFromInstName;
                End If;
            End If;

            ---------------------------------------------------
            -- Make sure a valid instrument group was chosen (or auto-selected via an instrument name)
            -- This also assures the text is properly capitalized
            ---------------------------------------------------

            SELECT instrument_group
            INTO _newInstrumentGroup
            FROM t_instrument_group
            WHERE instrument_group = _newInstrumentGroup;

            If Not FOUND Then
                _logErrors := false;
                _returnCode := 'U5202';
                RAISE EXCEPTION 'Invalid instrument group (or instrument): "%" does not exist', _newValue;
            End If;

            If _mode::citext = 'instrumentGroup' Then

                ---------------------------------------------------
                -- Make sure the dataset type defined for each of the requested runs
                -- is appropriate for instrument group _newInstrumentGroup
                ---------------------------------------------------

                CALL public.validate_instrument_group_for_requested_runs (
                                    _reqRunIDList,
                                    _newInstrumentGroup,
                                    _message    => _message,        -- Output
                                    _returnCode => _returnCode);    -- Output

                If _returnCode <> '' Then
                    _logErrors := false;
                    RAISE EXCEPTION '%', _message;
                End If;

            End If;

            ---------------------------------------------------
            -- Make sure that the instrument group change will not result in a mix of instrument groups for active requested runs that are associated with a batch
            ---------------------------------------------------

            CREATE TEMP TABLE Tmp_BatchIDs (
                Batch_ID int
            );

            INSERT INTO Tmp_BatchIDs (Batch_ID)
            SELECT DISTINCT RR.batch_id
            FROM t_requested_run RR
                 INNER JOIN Tmp_RequestIDs
                   ON Tmp_RequestIDs.RequestID = RR.request_id
            WHERE RR.batch_id > 0;

            FOR _batchID IN
                SELECT Batch_ID
                FROM Tmp_BatchIDs
                ORDER BY Batch_ID
            LOOP
                SELECT COUNT(DISTINCT InstGroup)
                INTO _instrumentGroupCount
                FROM (SELECT DISTINCT RR.instrument_group AS InstGroup
                      FROM t_requested_run RR
                           LEFT OUTER JOIN Tmp_RequestIDs
                             ON Tmp_RequestIDs.RequestID = RR.request_id
                      WHERE RR.batch_id = _batchID AND
                            RR.state_name = 'Active' AND
                            Tmp_RequestIDs.RequestID Is Null
                      UNION
                      SELECT _newInstrumentGroup As InstGroup
                     ) UnionQ;

                If _instrumentGroupCount > 1 Then

                    SELECT string_agg(InstGroup, ', ' ORDER BY InstGroup)
                    INTO _instrumentGroups
                    FROM ( SELECT DISTINCT RR.instrument_group AS InstGroup
                           FROM t_requested_run RR
                                LEFT OUTER JOIN Tmp_RequestIDs
                                  ON Tmp_RequestIDs.RequestID = RR.request_id
                           WHERE RR.batch_id = _batchID AND
                                 RR.state_name = 'Active' AND
                                 Tmp_RequestIDs.RequestID Is Null
                         ) DistinctQ;

                    SELECT string_agg(RR.request_id::text, ', ' ORDER BY RR.request_id)
                    INTO _requestIDs
                    FROM t_requested_run RR
                         INNER JOIN Tmp_RequestIDs
                           ON Tmp_RequestIDs.RequestID = RR.request_id
                    WHERE RR.batch_id = _batchID AND
                          RR.state_name = 'Active';

                    If char_length(_requestIDs) > 100 Then
                        _requestIDs := Trim(Substring(_requestIDs, 1, 100));

                        If _requestIDs Like '%,' Then
                            _requestIDs := Trim(Substring(_requestIDs, char_length(_requestIDs) - 1));
                        End If;

                        _requestIDs := _requestIDs || ' ...';
                    End If;

                    _requestedRunDesc := format('requested run%s', CASE WHEN _requestIDs LIKE '%,%' THEN 's' ELSE '' END);

                    _message := format('Cannot set the instrument group to %s for %s %s since that would result in a mix of instrument groups for batch %s (which corresponds to %s); '
                                       'either update the instrument group for all active requests in the batch or create a new batch for the %s',
                                       _newInstrumentGroup, _requestedRunDesc, _requestIDs, _batchID, _instrumentGroups, _requestedRunDesc);

                    _logErrors := false;
                    _returnCode := 'U5203';
                    RAISE EXCEPTION '%', _message;

                End If;

            END LOOP;

            DROP TABLE Tmp_BatchIDs;
        End If;

        If _mode::citext = 'assignedInstrument' Then
            If Coalesce(_newValue, '') = '' Then
                -- Unassign the instrument
                _newQueueState := 1;
            Else
                ---------------------------------------------------
                -- Determine the Instrument ID of the selected instrument
                ---------------------------------------------------

                SELECT instrument_id, instrument_group
                INTO _newAssignedInstrumentID, _newInstrumentGroup
                FROM t_instrument_name
                WHERE instrument = _newValue::citext;

                If Not FOUND Then
                    _logErrors := false;
                    _returnCode := 'U5204';
                    RAISE EXCEPTION 'Invalid instrument: "%" does not exist', _newValue;
                End If;

                _newQueueState := 2;

                ---------------------------------------------------
                -- Make sure the dataset type defined for each of the requested runs
                -- is appropriate for instrument group _newInstrumentGroup
                ---------------------------------------------------

                CALL public.validate_instrument_group_for_requested_runs (
                                    _reqRunIDList,
                                    _newInstrumentGroup,
                                    _message    => _message,        -- Output
                                    _returnCode => _returnCode);    -- Output

                If _returnCode <> '' Then
                    _logErrors := false;
                    RAISE EXCEPTION '%', _message;
                End If;

            End If;
        End If;

        If _mode::citext = 'separationGroup' Then

            ---------------------------------------------------
            -- Validate the separation group
            -- Mode 'separationGroup' is used by http://dms2.pnl.gov/requested_run_admin/report
            ---------------------------------------------------

            -- Set the separation group to _newValue for now
            _newSeparationGroup := _newValue;

            If Not Exists (SELECT separation_group FROM t_separation_group WHERE separation_group = _newSeparationGroup) Then
                -- Try to update Separation group using t_secondary_sep
                SELECT separation_group
                INTO _newSeparationGroup
                FROM t_secondary_sep
                WHERE separation_type = _newValue::citext;
            End If;

            ---------------------------------------------------
            -- Make sure a valid separation group was chosen (or auto-selected via a separation name)
            -- This also assures the text is properly capitalized
            ---------------------------------------------------

            SELECT separation_group
            INTO _newSeparationGroup
            FROM t_separation_group
            WHERE separation_group = _newSeparationGroup;

            If Not FOUND Then
                _logErrors := false;
                _returnCode := 'U5205';
                RAISE EXCEPTION 'Invalid separation group: "%" does not exist', _newValue;
            End If;

        End If;

        If _mode::citext = 'datasetType' Then

            ---------------------------------------------------
            -- Validate the dataset type
            -- Mode 'datasetType' is used by http://dms2.pnl.gov/requested_run_admin/report
            ---------------------------------------------------

            -- Set the dataset type to _newValue for now
            _newDatasetType := _newValue;

            ---------------------------------------------------
            -- Make sure a valid dataset type was chosen
            ---------------------------------------------------

            SELECT dataset_type,
                   dataset_type_id
            INTO _newDatasetType, _newDatasetTypeID
            FROM T_Dataset_Type_Name
            WHERE Dataset_Type = _newDatasetType;

            If Not FOUND Then
                _logErrors := false;
                _returnCode := 'U5206';
                RAISE EXCEPTION 'Invalid dataset type: "%" does not exist', _newValue;
            End If;

        End If;

        -------------------------------------------------
        -- Apply the changes, as defined by _mode
        -------------------------------------------------

        If _mode::citext = 'priority' Then

            -- Get priority numerical value (use 0 if _newValue is not an integer)

            _pri := public.try_cast(_newValue, 0);

            -- If priority is being set to non-zero, clear the note field

            UPDATE t_requested_run RR
            SET priority = _pri,
                note = CASE WHEN _pri > 0 THEN '' ELSE note END
            FROM Tmp_RequestIDs
            WHERE RR.request_id = Tmp_RequestIDs.RequestID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Set the priority to %s for %s requested %s',
                                _pri, _updateCount, public.check_plural(_updateCount, 'run', 'runs'));

        End If;

        -------------------------------------------------
        If _mode::citext In ('instrumentGroup', 'instrumentGroupIgnoreType') Then

            UPDATE t_requested_run RR
            SET instrument_group = _newInstrumentGroup
            FROM Tmp_RequestIDs
            WHERE RR.request_id = Tmp_RequestIDs.RequestID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Changed the instrument group to %s for %s requested %s',
                                _newInstrumentGroup, _updateCount, public.check_plural(_updateCount, 'run', 'runs'));

        End If;

        ------------------------------------------------
        If _mode::citext = 'assignedInstrument' Then

            UPDATE t_requested_run RR
            SET queue_instrument_id = CASE WHEN _newQueueState > 1 THEN _newAssignedInstrumentID ELSE queue_instrument_id END,
                queue_state = _newQueueState,
                queue_date = CASE WHEN _newQueueState > 1 THEN CURRENT_TIMESTAMP ELSE queue_date END,
                instrument_group = CASE WHEN _newQueueState > 1 THEN _newInstrumentGroup ELSE instrument_group END
            FROM Tmp_RequestIDs
            WHERE RR.request_id = Tmp_RequestIDs.RequestID AND
                  RR.state_name = 'Active';
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount = 0 Then
                _message := 'Can only update the assigned instrument for Active requested runs; all of the selected items are Completed or Inactive';
            Else
                _message := format('Changed the assigned instrument to %s for %s requested %s',
                                    _newValue, _updateCount, public.check_plural(_updateCount, 'run', 'runs'));

                SELECT COUNT(*)
                INTO _inactiveCount
                FROM t_requested_run RR INNER JOIN
                     Tmp_RequestIDs ON RR.request_id = Tmp_RequestIDs.RequestID
                WHERE RR.state_name <> 'Active';

                If _inactiveCount > 0 Then
                    _message := format('%s; skipped %s %s since not Active',
                                        _message, _inactiveCount, public.check_plural(_inactiveCount, 'request', 'requests'));
                End If;
            End If;
        End If;

        -------------------------------------------------
        If _mode::citext = 'separationGroup' Then

            UPDATE t_requested_run RR
            SET separation_group = _newSeparationGroup
            FROM Tmp_RequestIDs
            WHERE RR.request_id = Tmp_RequestIDs.RequestID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Changed the separation group to %s for %s requested %s',
                                _newSeparationGroup, _updateCount, public.check_plural(_updateCount, 'run', 'runs'));
        End If;

        -------------------------------------------------
        If _mode::citext = 'datasetType' Then

            UPDATE t_requested_run RR
            SET request_type_id = _newDatasetTypeID
            FROM Tmp_RequestIDs
            WHERE RR.request_id = Tmp_RequestIDs.RequestID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Changed the dataset type to %s for %s requested %s',
                                _newDatasetType, _updateCount, public.check_plural(_updateCount, 'run', 'runs'));
        End If;

        -------------------------------------------------
        If _mode = 'delete' Then

            -- Step through the entries in Tmp_RequestIDs and delete each

            FOR _requestID IN
                SELECT RequestID
                FROM Tmp_RequestIDs
                ORDER BY RequestID
            LOOP

                CALL public.delete_requested_run (
                                    _requestID,
                                    _skipDatasetCheck => false,
                                    _message          => _message,          -- Output
                                    _returnCode       => _returnCode,       -- Output
                                    _callingUser      => _callingUser);

                If _returnCode <> '' Then

                    If _message Like '%associated with dataset%' Then
                        -- Message is of the form
                        -- Error deleting Request ID 123456: Cannot delete requested run 123456 because it is associated with dataset xyz
                        _logErrors := false;
                    End If;

                    RAISE EXCEPTION 'Error deleting Request ID %: %', _requestID, _message;
                End If;

                _countDeleted := _countDeleted + 1;
            END LOOP;

            _message := format('Deleted %s requested %s', _countDeleted, public.check_plural(_countDeleted, 'run', 'runs'));

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If char_length(_reqRunIDList) < 128 Then
                _logMessage := format('%s; Requests %s', _exceptionMessage, _reqRunIDList);
            Else
                _logMessage := format('%s; Requests %s ...', _exceptionMessage, Substring(_reqRunIDList, 1, 128));
            End If;

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Updated %s requested %s',
                            _requestCount, public.check_plural(_requestCount, 'run', 'runs'));

    CALL post_usage_log_entry ('update_requested_run_assignments', _usageMessage);

    DROP TABLE IF EXISTS Tmp_RequestIDs;

    If _returnCode <> '' Then
        -- Raise an exception so that the web page will show the error message
        RAISE EXCEPTION '%', _message;
    End If;
END
$$;


ALTER PROCEDURE public.update_requested_run_assignments(IN _mode text, IN _newvalue text, IN _reqrunidlist text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_requested_run_assignments(IN _mode text, IN _newvalue text, IN _reqrunidlist text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_requested_run_assignments(IN _mode text, IN _newvalue text, IN _reqrunidlist text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRequestedRunAssignments';

