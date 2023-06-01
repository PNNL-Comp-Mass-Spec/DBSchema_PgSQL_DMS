--
CREATE OR REPLACE PROCEDURE public.do_analysis_job_operation
(
    _job text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Perform analysis job operation defined by 'mode'
**
**  Arguments:
**    _job   Analysis job ID
**    _mode     'delete', 'reset', 'previewDelete' ; recognizes mode 'reset', but no changes are made (it is a legacy mode)
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _msg text;
    _jobID int;
    _state int;
    _result int;
    _infoOnly boolean := false;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _mode::citext Like 'preview%' Then
        _infoOnly := true;
    End If;

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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
        -- Delete job if it is in 'new' or 'failed' state
        ---------------------------------------------------

        If _mode::citext in ('delete', 'previewDelete') Then

            ---------------------------------------------------
            -- Delete the job
            ---------------------------------------------------

            CALL DeleteNewAnalysisJob (
                    _job,
                    _message => _msg,               -- Output
                    _returnCode => _returnCode,     -- Output
                    _callingUser,
                    _infoOnly)
            --
            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

            RETURN;
        End If; -- mode 'delete'

        ---------------------------------------------------
        -- Legacy mode; not supported
        ---------------------------------------------------

        If _mode = 'reset' Then
            _msg := 'Warning: the reset mode does not do anything in procedure DoAnalysisJobOperation';
            RAISE EXCEPTION '%', _msg;

            RETURN;
        End If; -- mode 'reset'

        ---------------------------------------------------
        -- Mode was unrecognized
        ---------------------------------------------------

        _msg := format('Mode "%s" was unrecognized', _mode);
        RAISE EXCEPTION '%', _msg;

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

COMMENT ON PROCEDURE public.do_analysis_job_operation IS 'DoAnalysisJobOperation';
