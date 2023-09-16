--
-- Name: update_cached_requested_run_eus_users(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_requested_run_eus_users(IN _requestid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the data in T_Active_Requested_Run_Cached_EUS_Users
**      This table tracks the list of EUS users for each active requested run
**
**      We only track active requested runs because V_Requested_Run_Active_Export
**      only returns active requested runs, and that view is the primary
**      beneficiary of T_Active_Requested_Run_Cached_EUS_Users
**
**  Arguments:
**    _requestID   Specific requested run to update, or 0 to update all active requested runs
**
**  Auth:   mem
**  Date:   11/16/2016 mem - Initial Version
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/21/2016 mem - Do not use a Merge statement when _requestID is non-zero
**          03/31/2023 mem - Ported to PostgreSQL
**          05/07/2023 mem - Remove unused variable
**          09/08/2023 mem - Adjust capitalization of keywords
**                         - Include schema name when calling function
**
*****************************************************/
DECLARE
    _callingProcName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _requestID := Coalesce(_requestID, 0);

    BEGIN

        If _requestID <> 0 Then
            -- Updating a specific requested run
            If Exists (SELECT request_id FROM t_requested_run WHERE state_name = 'Active' AND request_id = _requestID) Then
                -- Updating a single requested run; to avoid commit conflicts, do not use a merge statement
                If Exists (SELECT request_id FROM t_active_requested_run_cached_eus_users WHERE request_id = _requestID) Then
                    UPDATE t_active_requested_run_cached_eus_users
                    SET user_list = public.get_requested_run_eus_users_list(_requestID, 'V')
                    WHERE request_id = _requestID;
                Else
                    INSERT INTO t_active_requested_run_cached_eus_users (request_id, user_list)
                    Values (_requestID, public.get_requested_run_eus_users_list(_requestID, 'V'));
                End If;
            Else
                -- The request is not active; assure there is no cached entry
                If Exists (SELECT * FROM t_active_requested_run_cached_eus_users WHERE request_id = _requestID) Then
                    DELETE FROM t_active_requested_run_cached_eus_users
                    WHERE request_id = _requestID;
                End If;

            End If;

            RETURN;
        End If;

        -- Updating all active requested runs
        -- or updating a single, active requested run

        MERGE INTO t_active_requested_run_cached_eus_users AS target
        USING (SELECT request_id AS Request_ID,
                      public.get_requested_run_eus_users_list(request_id, 'V') AS User_List
               FROM t_requested_run
               WHERE state_name = 'Active' AND (_requestID = 0 OR request_id = _requestID)
              ) AS source
        ON (target.request_id = source.request_id)
        WHEN MATCHED AND target.user_list IS DISTINCT FROM source.user_list THEN
            UPDATE SET
                user_list = source.user_list
        WHEN NOT MATCHED THEN
            INSERT (request_id, user_list)
            VALUES (source.request_id, source.user_list);

        If _requestID = 0 Then

            -- Delete rows in t_active_requested_run_cached_eus_users that are not in the request list returned by get_requested_run_eus_users_list()

            DELETE FROM t_active_requested_run_cached_eus_users target
            WHERE NOT EXISTS (SELECT source.request_id
                              FROM (SELECT request_id AS Request_ID,
                                           public.get_requested_run_eus_users_list(request_id, 'V') AS User_List
                                    FROM t_requested_run
                                    WHERE state_name = 'Active' AND (_requestID = 0 OR request_id = _requestID)
                                   ) AS source
                              WHERE target.request_id = source.request_id);
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

END
$$;


ALTER PROCEDURE public.update_cached_requested_run_eus_users(IN _requestid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_requested_run_eus_users(IN _requestid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_requested_run_eus_users(IN _requestid integer, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedRequestedRunEUSUsers';

