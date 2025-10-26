--
-- Name: lock_active_dataset_svc_center_reports(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.lock_active_dataset_svc_center_reports(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the state of any active service center use reports, changing from Active (2) to Complete (3)
**
**  Arguments:
**    _infoOnly         When true, show the report IDs that would be updated
**    _message          Status message
**    _returnCode       Return code
**
**  Example usage:
**      CALL lock_active_dataset_svc_center_reports (_infoOnly => true);
**      CALL lock_active_dataset_svc_center_reports (_infoOnly => false);
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
    _reportIDs text;
    _reportDescription text;
    _currentLocation text := 'Start';

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

        _infoOnly    := Coalesce(_infoOnly, false);

        If _infoOnly Then
            RAISE INFO '';
        End If;

        ---------------------------------------------------
        -- Look for new or active service use reports
        ---------------------------------------------------

        _currentLocation := 'Look for active service use reports';

        If Not Exists (SELECT report_id FROM t_service_use_report WHERE report_state_id IN (1, 2)) Then
            _message = 'No active service center reports found; nothing to do';

            RAISE INFO '%', _message;
            RETURN;
        End If;

        SELECT string_agg(report_id::text, ', ') AS Report_IDs
        INTO _reportIDs
        FROM t_service_use_report
        WHERE report_state_id IN (1, 2);

        If _reportIDs LIKE '%,%' Then
            _reportDescription = 'reports';
        Else
            _reportDescription = 'report';
        End If;

        If _infoOnly Then
            _message = format('Would change the state of service center %s %s to 3 (Complete)',
                              _reportDescription,
                              _reportIDs);

            RAISE INFO '%', _message;
            RETURN;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Update the service center use report state
        ---------------------------------------------------

        _currentLocation := 'Update service use report state';

        UPDATE t_service_use_report
        SET report_state_id = 3
        WHERE report_state_id IN (1, 2);

        -- Example values for _message
        -- Service center report 1001 now has state 3 (Complete)
        -- Service center reports 1001, 1002 now have state 3 (Complete)

        _message := format('Service center %s %s now %s state 3 (Complete)',
                           _reportDescription,
                           _reportIDs,
                           CASE WHEN _reportDescription = 'report' THEN 'has' ELSE 'have' END);

        RAISE INFO '%', _message;

        CALL post_log_entry('Normal', _message, 'lock_active_dataset_svc_center_reports');

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


ALTER PROCEDURE public.lock_active_dataset_svc_center_reports(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

