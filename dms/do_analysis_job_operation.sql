--
-- Name: do_analysis_job_operation(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_analysis_job_operation(IN _job text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform analysis job operation defined by _mode
**
**      The only supported modes are 'delete' and 'previewDelete'
**      Jobs can only be deleted if the job state is 'New', 'Failed', or 'Special Proc. Waiting'
**
**  Arguments:
**    _job          Analysis job ID
**    _mode         Mode: 'delete', 'reset', 'previewDelete' ; recognizes mode 'reset', but no changes are made (it is a legacy mode)
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   05/02/2002
**          05/05/2005 grk - Removed default mode value
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          08/19/2010 grk - Use try-catch for error handling
**          11/18/2010 mem - Now returning 0 after successful call to Delete_New_Analysis_Job
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add _mode previewDelete
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/27/2018 mem - Rename _previewMode to _infoOnly
**          02/03/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _infoOnly boolean;

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

        _job  := Trim(Coalesce(_job, ''));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode Like 'preview%' Then
            _infoOnly := true;
        Else
            _infoOnly := false;
        End If;

        If _mode In ('delete', 'previewdelete') Then

            ---------------------------------------------------
            -- Delete job if it is in 'new' or 'failed' state
            ---------------------------------------------------

            CALL public.delete_new_analysis_job (
                    _job         => _job,
                    _message     => _msg,           -- Output
                    _returnCode  => _returnCode,    -- Output
                    _callingUser => _callingUser,
                    _infoOnly    => _infoOnly);

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

            RETURN;
        End If;

        If _mode = 'reset' Then
            -- Reset is a legacy, unsupported mode

            RAISE EXCEPTION 'Warning: the reset mode does not do anything in procedure Do_Analysis_Job_Operation';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Mode was unrecognized
        ---------------------------------------------------

        RAISE EXCEPTION 'Mode "%" was unrecognized', _mode;

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


ALTER PROCEDURE public.do_analysis_job_operation(IN _job text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_analysis_job_operation(IN _job text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_analysis_job_operation(IN _job text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DoAnalysisJobOperation';

