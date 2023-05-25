--
CREATE OR REPLACE PROCEDURE sw.set_update_required_for_running_managers
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets ManagerUpdateRequired to True in the Manager Control database
**      for currently running managers
**
**  Auth:   mem
**  Date:   04/17/2014 mem - Initial release
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _mgrList text;
    _mgrCount int;
BEGIN
    _message := '';
    _returnCode:= '';

    _infoOnly := Coalesce(_infoOnly, false);

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
    -- Get a list of the currently running managers
    ---------------------------------------------------
    --

    SELECT string_agg(processor, ',' ORDER BY processor)
    INTO _mgrList
    FROM sw.t_job_steps
    WHERE state = 4;
    --
    GET DIAGNOSTICS _mgrCount = ROW_COUNT;

    If _infoOnly Then
        RAISE INFO 'Managers needing an update: %', _mgrList;
    Else
        RAISE INFO 'Calling SetManagerUpdateRequired for % %', _mgrCount, public.check_plural(_mgrCount, 'manager', 'managers');
        CALL mc.set_manager_update_required (_mgrList, _showtable => true);
    End If;

END
$$;

COMMENT ON PROCEDURE sw.set_update_required_for_running_managers IS 'SetUpdateRequiredForRunningManagers';
