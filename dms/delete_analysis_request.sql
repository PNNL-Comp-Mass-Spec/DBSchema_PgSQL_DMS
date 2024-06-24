--
-- Name: delete_analysis_request(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_analysis_request(IN _requestid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given analysis job request if it is not associated with any jobs
**
**  Arguments:
**    _requestID        Analysis job request ID
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   10/13/2004
**          04/07/2006 grk - Eliminated job to request map table
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/30/2019 mem - Delete datasets from T_Analysis_Job_Request_Datasets
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
    -- Does request exist?
    ---------------------------------------------------

    _requestID := Coalesce(_requestID, 0);

    If Not Exists (SELECT request_id FROM t_analysis_job_request WHERE request_id = _requestID) Then
        _message := format('Could not find analysis job request %s', _requestID);
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine the number of jobs made from the request
    ---------------------------------------------------

    SELECT COUNT(job)
    INTO _jobCount
    FROM t_analysis_job
    WHERE request_id = _requestID;

    If _jobCount <> 0 Then
        _message := format('Cannot delete analysis job request %s since it has %s existing %s',
                           _requestID,
                           _jobCount,
                           public.check_plural(_jobCount, 'job', 'jobs'));

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete the analysis job request
    ---------------------------------------------------

    DELETE FROM t_analysis_job_request_datasets
    WHERE request_id = _requestID;

    DELETE FROM t_analysis_job_request
    WHERE request_id = _requestID;

    RAISE INFO '';
    RAISE INFO 'Deleted analysis job request %', _requestID;
END
$$;


ALTER PROCEDURE public.delete_analysis_request(IN _requestid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_analysis_request(IN _requestid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_analysis_request(IN _requestid integer, INOUT _message text, INOUT _returncode text) IS 'DeleteAnalysisRequest';

