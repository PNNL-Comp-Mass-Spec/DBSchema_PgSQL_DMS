--
-- Name: delete_storage_path(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_storage_path(IN _pathid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete given storage path from the storage path table
**
**      Storage path may not have any associated datasets
**
**  Arguments:
**    _pathID       Storage path ID
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   03/14/2006
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/02/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _result int;
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

    If Coalesce(_pathID, 0) <= 0 Then
        RAISE WARNING 'Storage path ID is not a positive integer; nothing to delete';
        RETURN;
    End If;

    If Not Exists (SELECT storage_path_id FROM t_storage_path WHERE storage_path_id = _pathID) Then
        RAISE WARNING 'Storage path ID % does not exist; nothing to delete', _pathID;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify no associated datasets
    ---------------------------------------------------

    If Exists (SELECT dataset_id FROM t_dataset WHERE storage_path_ID = _pathID) Then
        _returnCode := 'U5201';
        _message := 'Cannot delete storage path that is being used by existing datasets';
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Delete storage path from table
    ---------------------------------------------------

    DELETE FROM t_storage_path
    WHERE storage_path_id = _pathID;

    _message := format('Deleted storage path ID %s', _pathID);
    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE public.delete_storage_path(IN _pathid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_storage_path(IN _pathid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_storage_path(IN _pathid integer, INOUT _message text, INOUT _returncode text) IS 'DeleteStoragePath';
