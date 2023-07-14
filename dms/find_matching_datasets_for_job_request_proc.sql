--
-- Name: find_matching_datasets_for_job_request_proc(integer, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.find_matching_datasets_for_job_request_proc(IN _requestid integer, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return list of datasets for given analysis job request,
**      showing how many jobs exist for each that match the parameters of the request
**      (regardless of whether or not job is linked to the request)
**
**  Arguments:
**    _requestID        Analysis job request ID
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL public.find_matching_datasets_for_job_request_proc (
**              _requestID => 20015
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   07/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _requestID := Coalesce(_requestID, 0);

    Open _results For
        SELECT '' AS Sel,
               Dataset,
               Jobs,
               New,
               Busy,
               Complete,
               Failed,
               Holding
        FROM public.find_matching_datasets_for_job_request(_requestID);

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

END
$$;


ALTER PROCEDURE public.find_matching_datasets_for_job_request_proc(IN _requestid integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

