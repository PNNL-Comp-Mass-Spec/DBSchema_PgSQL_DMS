--
CREATE OR REPLACE PROCEDURE public.delete_experiment_group
(
    _groupID int = 0,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Remove an experiment group (but not the experiments)
**
**  Auth:   grk
**  Date:   07/13/2006
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _delim text := ',';
    _count int;
    _myRowCount int := 0;
    _msg text;
    _transName text;
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
    -- Delete the items
    ---------------------------------------------------

    DELETE FROM t_experiment_group_members
    WHERE group_id = _groupID;

    DELETE FROM t_experiment_groups
    WHERE group_id = _groupID;

END
$$;

COMMENT ON PROCEDURE public.delete_experiment_group IS 'DeleteExperimentGroup';
