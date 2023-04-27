--
CREATE OR REPLACE PROCEDURE public.delete_sample_prep_request
(
    _requestID int,
    INOUT _message text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete sample prep request
**
**  Auth:   grk
**  Date:   11/10/2005
**          01/04/2006 grk - added delete for aux info
**          05/16/2008 mem - Added optional parameter _callingUser; if provided, will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _transName text;
    _num int;
BEGIN
    _message := '';

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
    -- Start transaction
    ---------------------------------------------------
    --
    _transName := 'DeleteSamplePrepRequest';
    begin transaction _transName

    ---------------------------------------------------
    -- Remove any references from experiments
    ---------------------------------------------------
    --
    _num := 1;
    --
    UPDATE t_experiments
    SET sample_prep_request_id = 0
    WHERE (sample_prep_request_id = _requestID)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Delete all entries from auxiliary value table
    -- for the sample prep request
    ---------------------------------------------------

    DELETE FROM t_aux_info_value
    WHERE (target_id = _requestID) AND
    (
        Aux_Description_ID IN
        (
            SELECT Item_ID
            FROM V_Aux_Info_Definition_with_ID
            WHERE (Target = 'SamplePrepRequest')
        )
    )
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Delete the sample prep request itself
    ---------------------------------------------------
    --
    DELETE FROM t_sample_prep_request
    WHERE     (prep_request_id = _requestID)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- If we got here, complete transaction
    ---------------------------------------------------
    commit transaction _transName

    -- If _callingUser is defined, update system_account in t_sample_prep_request_updates
    If char_length(_callingUser) > 0 Then
        Call alter_entered_by_user (
                't_sample_prep_request_updates', 'request_id',
                _requestID, _callingUser,
                _entryDateColumnName => 'Date_of_Change',
                _enteredByColumnName => 'System_Account');
    End If;

END
$$;

COMMENT ON PROCEDURE public.delete_sample_prep_request IS 'DeleteSamplePrepRequest';
