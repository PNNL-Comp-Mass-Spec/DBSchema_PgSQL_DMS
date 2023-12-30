--
CREATE OR REPLACE PROCEDURE public.delete_new_analysis_job
(
    _job text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
    _callingUser text = '',
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete the analysis job if it has state 'New', 'Failed', or 'Special Proc. Waiting'
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
**          12/15/2024 mem - Ported to PostgreSQL
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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    _job   := Trim(Coalesce(_job, ''));
    _jobID := public.try_cast(_job, null::int);

    If _jobID is null Then
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
        _message := format('Job "%s" not in database', _job);
        If _infoOnly Then
            RAISE WARNING '%', _message;
        Else
            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    -- Verify that analysis job has state 'New', 'Failed', or 'Special Proc. Waiting'
    If Not _state In (0, 1, 5, 19) Then
        _message := format('Job "%s" must be in "new" or "failed" state to be deleted by user', _job);
        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Delete the analysis job
    --
    CALL public.delete_analysis_job (
                    _job         => _jobID,
                    _callingUser => _callingUser,
                    _infoOnly    =>_infoOnly,
                    _message     => _message,
                    _returnCode  => _returnCode);

END
$$;

COMMENT ON PROCEDURE public.delete_new_analysis_job IS 'DeleteNewAnalysisJob';
