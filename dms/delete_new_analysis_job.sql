--
-- Name: delete_new_analysis_job(text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_new_analysis_job(IN _job text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the analysis job if its state is 'New', 'Failed', or 'Special Proc. Waiting'
**
**  Arguments:
**    _job              Job to delete
**    _infoOnly         When true, preview the updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/29/2001
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          02/18/2008 grk - Modified to accept jobs in failed state (Ticket #723)
**          02/19/2008 grk - Modified not to call broker DB (Ticket #723)
**          09/28/2012 mem - Now allowing a job to be deleted if state 19 = "Special Proc. Waiting"
**          04/21/2017 mem - Added parameter _previewMode
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/27/2018 mem - Rename _previewMode to _infoOnly
**          02/02/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobID int;
    _state int := 0;
    _result int;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job   := Trim(Coalesce(_job, ''));
    _jobID := public.try_cast(_job, null::int);

    If _jobID Is Null Then
        _message := format('Job number is not numeric: %s', _job);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that the job exists
    ---------------------------------------------------

    SELECT job_state_id
    INTO _state
    FROM t_analysis_job
    WHERE job = _jobID;

    If Not FOUND Then
        _message := format('Cannot delete: job %s does not exist', _job);
        If _infoOnly Then
            RAISE WARNING '%', _message;
        Else
            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    -- Verify that analysis job has state '(none)', 'New', 'Failed', or 'Special Proc. Waiting'
    If Not _state In (0, 1, 5, 19) Then
        _message := format('Job "%s" must be in "new" or "failed" state to be deleted by user', _job);
        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Delete the analysis job

    CALL public.delete_analysis_job (
                    _job          => _jobID::text,
                    _infoOnly     => _infoOnly,
                    _message      => _message,
                    _returnCode   => _returnCode,
                    _callingUser  => _callingUser);
END
$$;


ALTER PROCEDURE public.delete_new_analysis_job(IN _job text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_new_analysis_job(IN _job text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_new_analysis_job(IN _job text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteNewAnalysisJob';

