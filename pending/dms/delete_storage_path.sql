--
CREATE OR REPLACE PROCEDURE public.delete_storage_path
(
    _pathID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes given storage path from the storage path table
**
**      Storage path may not have any associated datasets.
**
**  Arguments:
**
**  Auth:   grk
**  Date:   03/14/2006
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
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
    -- Verify no associated datasets
    ---------------------------------------------------

    If Exists (SELECT COUNT(dataset_id) FROM t_dataset WHERE storage_path_ID = _pathID) Then
        RAISE EXCEPTION 'Cannot delete storage path that is being used by existing datasets';

         _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete storage path from table
    ---------------------------------------------------

    DELETE FROM t_storage_path
    WHERE storage_path_id = _pathID;

END
$$;

COMMENT ON PROCEDURE public.delete_storage_path IS 'DeleteStoragePath';
