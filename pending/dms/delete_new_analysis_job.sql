--
CREATE OR REPLACE PROCEDURE public.delete_new_analysis_job
(
    _job text,
    INOUT _message text = '',
    INOUT _returnCode text = ''
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete analysis job if it is in 'new' or 'failed' state
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _jobID int;
    _msg text;
    _state int := 0;
    _result int;
BEGIN
    _job := Coalesce(_job, '');
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    _jobID := public.try_cast(_job, null::int);

    If _jobID is null Then
        _message := 'Job number is not numeric: ' || _job;
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that the job exists
    ---------------------------------------------------
    --
    --
    SELECT job_state_id
    INTO _state
    FROM t_analysis_job
    WHERE job = _jobID;

    If Not FOUND Then
        _message := 'Job "' || _job || '" not in database';
        If _infoOnly Then
            RAISE WARNING '%', _message;
        Else
            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    -- Verify that analysis job has state 'new', 'failed', or 'Special Proc. Waiting'
    If Not _state IN (0, 1, 5, 19) Then
        _message := 'Job "' || _job || '" must be in "new" or "failed" state to be deleted by user';
        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Delete the analysis job
    --
    Call delete_analysis_job (_jobID, _callingUser, _infoOnly, _message => _message)

END
$$;

COMMENT ON PROCEDURE public.delete_new_analysis_job IS 'DeleteNewAnalysisJob';
