--
CREATE OR REPLACE PROCEDURE public.add_update_requested_run_batch_spreadsheet
(
    INOUT _id int,
    _name text,
    _description text,
    _requestNameList text,
    _ownerUsername text,
    _requestedBatchPriority text,
    _requestedCompletionDate text,
    _justificationHighPriority text,
    _requestedInstrument text,
    _comment text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing requested run batch
**
**  Arguments:
**    _requestedInstrument   Will typically contain an instrument group, not an instrument name
**    _mode                  'add' or 'update'
**
**  Auth:   jds
**  Date:   05/18/2009
**          08/27/2010 mem - Expanded _requestedCompletionDate to varchar(24) to support long dates of the form 'Jan 01 2010 12:00:00AM'
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 mem - Use new parameter name when calling AddUpdateRequestedRunBatch
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _requestedRunList text;
BEGIN
    _message := '';
    _returnCode:= '';

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

    ---------------------------------------------------
    -- Get list of request ids based on Request name list
    ---------------------------------------------------
    --

    SELECT string_agg(rr.request_id::text, ', ')
    INTO _requestedRunList
    FROM public.parse_delimited_list(_requestNameList) r
        join t_requested_run rr on r.Item = rr.request_name

    If Coalesce(_requestedRunList, '') = '' Then
        _message := 'The requests submitted in the list do not exist in the database. Check the requests and try again.';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    Call add_update_requested_run_batch (
                           _id => _id,                      -- Output
                           _name => _name,
                           _description => _description,
                           _requestedRunList => _requestedRunList,
                           _ownerUsername => _ownerUsername,
                           _requestedBatchPriority => _requestedBatchPriority,
                           _requestedCompletionDate => _requestedCompletionDate,
                           _justificationHighPriority => _justificationHighPriority,
                           _requestedInstrumentGroup => _requestedInstrument,
                           _comment => _comment,
                           _mode => _mode,
                           _message => _message,            -- Output
                           _returnCode => _returnCode,      -- Output
                           _useRaiseError => false);

    --check for any errors from procedure
    If _message <> '' Then
        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;
END
$$;

COMMENT ON PROCEDURE public.add_update_requested_run_batch_spreadsheet IS 'AddUpdateRequestedRunBatchSpreadsheet';
