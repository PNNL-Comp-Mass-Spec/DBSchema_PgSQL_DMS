--
-- Name: add_update_requested_run_batch_spreadsheet(integer, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_requested_run_batch_spreadsheet(INOUT _id integer, IN _name text, IN _description text, IN _requestnamelist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _comment text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing requested run batch, including updating the requested runs that are in the batch
**
**      This procedure accepts a list of requested run names, which are converted to requested run IDs
**
**      The procedure appears to be unused, as of January 2024
**
**  Arguments:
**    _id                           Batch ID to update if _mode is 'update'; otherwise, the ID of the newly created batch
**    _name                         Batch name
**    _description                  Description
**    _requestNameList              Comma-separated (or tab-separated) list of requested run names
**    _ownerUsername                Owner username
**    _requestedBatchPriority       Batch priority: 'Normal' or 'High'
**    _requestedCompletionDate      Requested completion date (as text)
**    _justificationHighPriority    Justification for high priority
**    _comment                      Batch comment
**    _mode                         Mode: 'add' or 'update'
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   jds
**  Date:   05/18/2009
**          08/27/2010 mem - Expanded _requestedCompletionDate to varchar(24) to support long dates of the form 'Jan 01 2010 12:00:00AM'
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 mem - Use new parameter name when calling Add_Update_Requested_Run_Batch
**          01/17/2024 mem - Ported to PostgreSQL
**          01/22/2024 mem - Remove argument _requestedInstrumentGroup since we no longer associate instrument groups with requested run batches
**                         - Remove deprecated instrument group argument when calling add_update_requested_run_batch()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _requestedRunList text;
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
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _requestNameList := Trim(Coalesce(_requestNameList, ''));
    _mode            := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Resolve request run names to IDs
    ---------------------------------------------------

    If _requestNameList = '' Then
        _requestedRunList := '';
    Else
        SELECT string_agg(RR.request_id::text, ', ' ORDER BY RR.request_id)
        INTO _requestedRunList
        FROM public.parse_delimited_list(_requestNameList) R
             INNER JOIN t_requested_run RR
               ON R.Value::citext = RR.request_name;

        If Coalesce(_requestedRunList, '') = '' Then
            _message := 'One or more requests do not exist. Check the requests and try again.';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    CALL public.add_update_requested_run_batch (
                   _id                        => _id,               -- Output
                   _name                      => _name,
                   _description               => _description,
                   _requestedRunList          => _requestedRunList,
                   _ownerUsername             => _ownerUsername,
                   _requestedBatchPriority    => _requestedBatchPriority,
                   _requestedCompletionDate   => _requestedCompletionDate,
                   _justificationHighPriority => _justificationHighPriority,
                   _comment                   => _comment,
                   _batchGroupID              => null,
                   _batchGroupOrder           => null,
                   _mode                      => _mode,
                   _message                   => _message,          -- Output
                   _returnCode                => _returnCode,       -- Output
                   _raiseExceptions           => false);

    -- Check for any errors from the procedure
    If _message <> '' Then
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;
END
$$;


ALTER PROCEDURE public.add_update_requested_run_batch_spreadsheet(INOUT _id integer, IN _name text, IN _description text, IN _requestnamelist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_requested_run_batch_spreadsheet(INOUT _id integer, IN _name text, IN _description text, IN _requestnamelist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_requested_run_batch_spreadsheet(INOUT _id integer, IN _name text, IN _description text, IN _requestnamelist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateRequestedRunBatchSpreadsheet';

