--
CREATE OR REPLACE PROCEDURE public.delete_analysis_request
(
    _requestID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete the analysis job request if it is not associated with any jobs
**
**  Arguments:
**    _requestID        Analysis job request ID
**    _message          Output message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   10/13/2004
**          04/07/2006 grk - Eliminated job to request map table
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/30/2019 mem - Delete datasets from T_Analysis_Job_Request_Datasets
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _tempID int := 0;
    _jobCount int := 1;
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

    ---------------------------------------------------
    -- Does request exist?
    ---------------------------------------------------

    SELECT request_id
    INTO _tempID
    FROM t_analysis_job_request
    WHERE request_id = _requestID;

    If Not FOUND Then
        _message := 'Could not find job request';
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Look up number of jobs made from the request
    ---------------------------------------------------

    --
    SELECT COUNT(job)
    INTO _jobCount
    FROM t_analysis_job
    WHERE request_id = _requestID;

    If _jobCount <> 0 Then
        _message := 'Cannot delete an analysis request that has jobs made from it';
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete the analysis request
    ---------------------------------------------------

    DELETE FROM t_analysis_job_request_datasets
    WHERE request_id = _requestID;

    DELETE FROM t_analysis_job_request
    WHERE request_id = _requestID;

END
$$;

COMMENT ON PROCEDURE public.delete_analysis_request IS 'DeleteAnalysisRequest';
