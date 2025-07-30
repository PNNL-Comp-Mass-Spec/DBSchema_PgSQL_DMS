--
-- Name: update_service_use(integer, text, integer, text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_service_use(IN _entryid integer, IN _chargecode text, IN _servicetypeid integer, IN _comment text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update a service use entry in cc.t_service_use
**
**  Arguments:
**    _entryID              Entry ID
**    _chargeCode           Charge code
**    _serviceTypeID        Service type ID
**    _comment              Comment
**    _mode                 Mode: typically 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**    _infoOnly             When true, preview the update
**
**  Auth:   mem
**  Date:   07/23/2025 mem - Initial release
**          07/28/2025 mem - When charge code is updated, also update t_requested_run
**                         - When service_type_id is updated, also update t_dataset and t_requested_run
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _msg text;
    _existingValues record;
    _alterEnteredByMessage text;

    _chargeCodeMatch text;
    _datasetID int = 0;
    _requestedRunValues record;
    _datasetServiceTypeID int;

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

        _chargeCode     := Trim(Coalesce(_chargeCode, ''));
        _comment        := Trim(Coalesce(_comment, ''));
        _callingUser    := Trim(Coalesce(_callingUser, ''));
        _mode           := Trim(Lower(Coalesce(_mode, '')));
        _infoOnly       := Coalesce(_infoOnly, false);

        If _infoOnly Then
            RAISE INFO '';
        End If;

        If _mode = '' Then
            RAISE EXCEPTION 'Empty string specified for parameter _mode';
        ElsIf Not _mode IN ('update', 'check_update', Lower('PreviewUpdate')) Then
            RAISE EXCEPTION 'Unsupported value for parameter _mode: %', _mode;
        End If;

        If _entryID Is Null Then
            _msg := 'Cannot update: _entryID parameter cannot be null';

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            _returnCode := 'U5201';
            RAISE EXCEPTION '%', _msg;
        End If;

        If _chargeCode = '' Then
            _msg := 'Cannot update: charge code cannot be an empty string';

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            _returnCode := 'U5202';
            RAISE EXCEPTION '%', _msg;
        End If;

        If _serviceTypeID IS NULL Then
            _msg := 'Cannot update: _serviceTypeID parameter cannot be null';

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            _returnCode := 'U5203';
            RAISE EXCEPTION '%', _msg;
        End If;

        SELECT charge_code
        INTO _chargeCodeMatch
        FROM t_charge_code
        WHERE charge_code = _chargeCode::citext;

        If Not FOUND Then
            _msg := format('Cannot update: charge code %s is not valid', _chargeCode);

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            _returnCode := 'U5204';
            RAISE EXCEPTION '%', _msg;
        Else
            -- Assure that the charge code is properly capitalized
            _chargeCode := _chargeCodeMatch;
        End If;

        If Not Exists (SELECT service_type_id FROM cc.t_service_type WHERE service_type_id = _serviceTypeID) Then
            _msg := format('Cannot update: service type ID %s is not valid', _serviceTypeID);

            If _infoOnly Then
                RAISE WARNING '%', _msg;
            End If;

            _returnCode := 'U5205';
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode IN ('update', 'check_update', Lower('PreviewUpdate'), 'reset') Then
            _currentLocation := 'Check for non-existent entry';

            If _entryID Is Null Then
                _msg := 'Cannot update: _entryID parameter cannot be null';

                If _infoOnly Then
                    RAISE WARNING '%', _msg;
                End If;

                _returnCode := 'U5206';
                RAISE EXCEPTION '%', _msg;
            End If;

            SELECT entry_id,
                   charge_code,
                   service_type_id,
                   comment,
                   dataset_id,
                   charge_code     <> _chargeCode    AS charge_code_changed,
                   service_type_id <> _serviceTypeID AS service_type_changed,
                   comment         <> _comment       AS comment_changed
            INTO _existingValues
            FROM cc.t_service_use
            WHERE entry_id = _entryID;

            If Not FOUND Then
                _msg := format('Cannot update: service use entry ID %s does not exist', _entryID);

                If _infoOnly Then
                    RAISE WARNING '%', _msg;
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;

            _datasetID := _existingValues.dataset_id;
        End If;

        If _infoOnly Then
            _currentLocation := 'Preview updating a service use entry';

            RAISE INFO 'Preview update of service use entry ID %', _entryID;

            If _existingValues.charge_code_changed THEN
                RAISE INFO '  Would change the charge code from % to %', _existingValues.charge_code, _chargeCode;
            End If;

            If _existingValues.service_type_changed THEN
                RAISE INFO '  Would change the service type ID from % to %', _existingValues.service_type_id, _serviceTypeID;
            End If;

            If _existingValues.comment_changed THEN
                RAISE INFO '  Would update the comment to "%"', _comment;
            End If;

            If Not (_existingValues.charge_code_changed OR
                    _existingValues.service_type_changed OR
                    _existingValues.comment_changed)
            Then
                RAISE INFO '  Did not update charge code, service type, or the comment';
            End If;

            RETURN;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            _currentLocation := format('Update service use entry %s', _entryID);

            UPDATE cc.t_service_use
            SET charge_code     = _chargeCode,
                service_type_id = _serviceTypeID,
                comment         = _comment
            WHERE entry_id = _entryID;

            -- If _callingUser is defined, call public.alter_entered_by_user to alter the entered_by field in t_service_use_updates
            If _callingUser <> '' Then
                _currentLocation := format('Call alter_entered_by_user for service use entry ID %s', _entryID);

                CALL public.alter_entered_by_user ('cc', 't_service_use_updates', 'service_use_entry_id', _entryID, _callingUser,
                                                   _entryDateColumnName => 'entered', _enteredByColumnName => 'entered_by', _message => _alterEnteredByMessage);
            End If;

            If _datasetID > 0 Then
                ---------------------------------------------------
                -- Update work package and service type ID in t_requested_run, if required
                ---------------------------------------------------

                SELECT request_id, work_package, service_type_id
                INTO _requestedRunValues
                FROM t_requested_run
                WHERE dataset_id = _datasetID
                ORDER BY request_id DESC
                LIMIT 1;

                If FOUND And
                   (_requestedRunValues.work_package    <> _chargeCode::citext Or
                    _requestedRunValues.service_type_id <> _serviceTypeID)
                Then
                    UPDATE t_requested_run
                    SET work_package    = _chargeCode,
                        service_type_id = _serviceTypeID
                    WHERE request_id = _requestedRunValues.request_id;
                End If;

                ---------------------------------------------------
                -- Update service type ID in t_dataset, if required
                ---------------------------------------------------

                SELECT service_type_id
                INTO _datasetServiceTypeID
                FROM t_dataset
                WHERE dataset_id = _datasetID;

                If FOUND And _datasetServiceTypeID <> _serviceTypeID Then
                    UPDATE t_dataset
                    SET service_type_id = _serviceTypeID
                    WHERE dataset_id = _datasetID;
                End If;
            End If;
        End If;

        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; entry_id %s', _exceptionMessage, _entryID);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.update_service_use(IN _entryid integer, IN _chargecode text, IN _servicetypeid integer, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) OWNER TO d3l243;

