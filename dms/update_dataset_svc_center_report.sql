--
-- Name: update_dataset_svc_center_report(integer, boolean, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_svc_center_report(IN _reportid integer, IN _setcomplete boolean DEFAULT false, IN _setinactive boolean DEFAULT false, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the state of a service center use report, typically changing from Active (2) to Complete (3)
**      Alternatively, the report can be set as Inactive (4)
**
**  Arguments:
**    _reportID         Service center use report ID (see table t_service_use_report)
**    _setComplete      When true, set the state to Complete (3) if the state is Active (2)
**    _setInactive      When true, set the state to Inactive (4)
**    _infoOnly         When true, show the state change that would be applied
**    _message          Status message
**    _returnCode       Return code
**
**  Example Usage:
**      CALL update_dataset_svc_center_report(1001, _setComplete => true, _infoOnly => true);
**      CALL update_dataset_svc_center_report(1001, _setComplete => true, _infoOnly => false);
**      CALL update_dataset_svc_center_report(1002, _setInactive => true, _infoOnly => true);
**
**  Auth:   mem
**  Date:   08/06/2025 mem - Initial release
**          08/21/2025 mem - Rename procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _msg text;
    _currentLocation text := 'Start';
    _oldState int;
    _newState int;

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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _currentLocation := 'Validate inputs';

        _setComplete := Coalesce(_setComplete, false);
        _setInactive := Coalesce(_setInactive, false);
        _infoOnly    := Coalesce(_infoOnly, false);

        If _infoOnly Then
            RAISE INFO '';
        End If;

        If _reportID Is Null Then
            _msg := 'Cannot update: _reportID parameter cannot be null';

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            _returnCode := 'U5201';
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Look up the current report state
        ---------------------------------------------------

        _currentLocation := 'Lookup the report state';

        SELECT report_state_id
        INTO _oldState
        FROM t_service_use_report
        WHERE report_id = _reportID;

        If Not FOUND Then
            _msg := format('Cannot update: service use report ID %s does not exist', _reportID);

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            RAISE EXCEPTION '%', _msg;
        End If;

        If Not _setComplete And Not _setInactive Then
            _message = format('Service center report %s has state %s and _setComplete and _setInactive are both false; nothing to do',
                              _reportID, _oldState);

            RAISE INFO '%', _message;
            RETURN;
        End If;

        _newState := _oldState;

        If _setComplete Then
            If _oldState = 3 Then
                _message = format('Service center report %s already has state 3 (Complete); nothing to do', _reportID);

                RAISE INFO '%', _message;
                RETURN;
            End If;

            If Not _oldState In (1, 2) Then
                _message = format('Service center report %s does not have state 1 (New) or 2 (Active); cannot change the state to 3 (Complete)',
                                  _reportID, _oldState, _newState);

                RAISE INFO '%', _message;
                RETURN;
            End If;

            _newState := 3;
        End If;

        If _setInactive Then
            If _oldState = 4 Then
                _message = format('Service center report %s already has state 4 (Inactive); nothing to do', _reportID);

                RAISE INFO '%', _message;
                RETURN;
            End If;

            _newState := 4;
        End If;

        If _oldState = _newState Then
            _message = format('Service center report %s already has state %s; nothing to do',
                              _reportID, _newState);

            RAISE INFO '%', _message;
            RETURN;
        End If;

        If _infoOnly Then
            _message = format('Would change the state of service center report %s from %s to %s',
                              _reportID, _oldState, _newState);

            RAISE INFO '%', _message;
            RETURN;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Update the service center use report state
        ---------------------------------------------------

        _currentLocation := 'Update service use report state';

        UPDATE t_service_use_report
        SET report_state_id = _newState
        WHERE report_id = _reportID;

        _message := format('Service center report %s now has state %s (previously %s)',
                           _reportID, _newState, _oldState);

        RAISE INFO '%', _message;

        CALL post_log_entry('Normal', _message, 'update_dataset_svc_center_report');

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Current location: %s', _exceptionMessage, _currentLocation);

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
END
$$;


ALTER PROCEDURE public.update_dataset_svc_center_report(IN _reportid integer, IN _setcomplete boolean, IN _setinactive boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

