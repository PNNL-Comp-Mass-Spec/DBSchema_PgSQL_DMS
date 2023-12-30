--
CREATE OR REPLACE PROCEDURE public.delete_experiment_group
(
    _groupID int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete the given experiment group (but not any associated experiments)
**
**  Arguments:
**    _groupID      Experiment group ID
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   07/13/2006
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _delim text := ',';
    _count int;
    _msg text;
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
    -- Delete the items
    ---------------------------------------------------

    DELETE FROM t_experiment_group_members
    WHERE group_id = _groupID;

    DELETE FROM t_experiment_groups
    WHERE group_id = _groupID;

END
$$;

COMMENT ON PROCEDURE public.delete_experiment_group IS 'DeleteExperimentGroup';
