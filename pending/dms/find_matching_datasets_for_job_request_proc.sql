--
CREATE OR REPLACE PROCEDURE public.find_matching_datasets_for_job_request_proc
(
    _requestID int,
    INOUT _results refcursor DEFAULT '_results'::refcursor,
    INOUT _message text DEFAULT ''::text,
    INOUT _returnCode text DEFAULT ''::text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Return list of datasets for given job request
**      showing how many jobs exist for each that
**      match the parameters of the request
**      (regardless of whether or not job is linked to request)
**
**  Auth:   mem
**  Date:   12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _message := '';
    _returnCode := '';

    -- ToDo: Query function find_matching_datasets_for_job_request and return the results using a cursor

    Open _results For
        SELECT '' AS Sel,
               Dataset,
               Jobs,
               New,
               Busy,
               Complete,
               Failed,
               Holding
        FROM find_matching_datasets_for_job_request(_requestID);

END
$$;
