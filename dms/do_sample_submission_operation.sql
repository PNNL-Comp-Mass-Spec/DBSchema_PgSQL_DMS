--
-- Name: do_sample_submission_operation(integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_sample_submission_operation(IN _id integer, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform an operation on a sample submission item
**
**      Note: this procedure has not been used since 2012
**
**  Arguments:
**    _id               Sample submission ID
**    _mode             Mode: 'make_folder'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   05/07/2010 grk - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**                         - Add call to Post_Usage_Log_Entry
**          08/01/2017 mem - Use THROW if not authorized
**          01/12/2023 mem - Remove call to CallSendMessage since it was deprecated in 2016
**          02/12/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _storagePathID int;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _id          := Coalesce(_id, 0);
        _mode        := Trim(Lower(Coalesce(_mode, '')));
        _callingUser := Trim(Coalesce(_callingUser, ''));

        If _callingUser = '' Then
            _callingUser := SESSION_USER;
        End If;

        ---------------------------------------------------
        -- Make the folder for the sample submission
        ---------------------------------------------------

        If _mode = 'make_folder' Then

            -- Get storage path from sample submission

            SELECT Coalesce(storage_id, 0)
            INTO _storagePathID
            FROM t_sample_submission
            WHERE submission_id = _id;

            -- If storage path not defined, get valid path ID and update sample submission

            If Not Found Then
                _message := format('Invalid sample submission ID: %s', _id);
                _returnCode := 'U5202';
            End If;

            If Coalesce(_storagePathID, 0) = 0 Then
                SELECT storage_id
                INTO _storagePathID
                FROM t_prep_file_storage
                WHERE state = 'Active' AND
                      purpose = 'Sample_Prep';

                If Not FOUND Then
                    RAISE EXCEPTION 'Storage path for files could not be found in t_prep_file_storage';
                End If;

                UPDATE t_sample_submission
                SET storage_id = _storagePathID
                WHERE submission_id = _id;
            End If;
        Else
            _message := format('Unsupported mode for sample submission operation: %s', _mode);
            _returnCode := 'U5201';
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

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_id, 0) > 0 Then
        _usageMessage := format('Performed submission operation for submission ID %s; mode %s; user %s', _id, _mode, _callingUser);

        CALL post_usage_log_entry ('do_sample_submission_operation', _usageMessage, _minimumUpdateInterval => 2);
    End If;

END
$$;


ALTER PROCEDURE public.do_sample_submission_operation(IN _id integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_sample_submission_operation(IN _id integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_sample_submission_operation(IN _id integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DoSampleSubmissionOperation';

