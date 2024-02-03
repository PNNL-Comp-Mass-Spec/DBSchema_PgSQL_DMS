--
-- Name: delete_sample_prep_request(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_sample_prep_request(IN _requestid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete a sample prep request
**
**  Arguments:
**    _requestID        Prep request ID to delete
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   11/10/2005
**          01/04/2006 grk - Added delete for aux info
**          05/16/2008 mem - Added optional parameter _callingUser; if provided, will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          02/02/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;
    _alterEnteredByMessage text;
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
    -- Validate the inputs
    ---------------------------------------------------

    If Coalesce(_requestID, 0) <= 0 Then
        RAISE WARNING 'Sample prep request ID is not a positive integer; nothing to delete';
        RETURN;
    End If;

    If Not Exists (SELECT prep_request_id FROM t_sample_prep_request WHERE prep_request_id = _requestID) Then
        RAISE WARNING 'Sample prep request ID % does not exist; nothing to delete', _requestID;
        RETURN;
    End If;

    _callingUser := Trim(Coalesce(_callingUser, ''));

    ---------------------------------------------------
    -- Remove any references from experiments
    ---------------------------------------------------

    UPDATE t_experiments
    SET sample_prep_request_id = 0
    WHERE sample_prep_request_id = _requestID;

    ---------------------------------------------------
    -- Delete all entries from auxiliary value table
    -- for the sample prep request
    ---------------------------------------------------

    DELETE FROM t_aux_info_value
    WHERE target_id = _requestID AND
          Aux_Description_ID IN (SELECT Item_ID
                                 FROM V_Aux_Info_Definition_with_ID
                                 WHERE Target = 'SamplePrepRequest');

    ---------------------------------------------------
    -- Delete sample prep request items
    ---------------------------------------------------

    DELETE FROM t_sample_prep_request_items
    WHERE prep_request_id = _requestID;

    ---------------------------------------------------
    -- Delete the sample prep request itself
    ---------------------------------------------------

    DELETE FROM t_sample_prep_request
    WHERE prep_request_id = _requestID;

    ---------------------------------------------------
    -- If we got here, commit the changes
    ---------------------------------------------------

    COMMIT;

    If _callingUser <> '' Then

        CALL public.alter_entered_by_user (
                'public', 't_sample_prep_request_updates', 'request_id',
                _requestID, _callingUser,
                _entryDateColumnName => 'date_of_change',
                _enteredByColumnName => 'system_account',
                _message => _alterEnteredByMessage);

    End If;

    _message := format('Deleted sample prep request ID %s', _requestID);
    RAISE INFO '%', _message;

END
$$;


ALTER PROCEDURE public.delete_sample_prep_request(IN _requestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_sample_prep_request(IN _requestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_sample_prep_request(IN _requestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteSamplePrepRequest';

