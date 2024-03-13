--
-- Name: set_update_required_for_running_managers(boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.set_update_required_for_running_managers(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set ManagerUpdateRequired to True in mc.t_param_value for currently running managers
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   04/17/2014 mem - Initial release
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/26/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(step) instead of COUNT(*)
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _mgrList text;
    _mgrCount int;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

    RAISE INFO '';

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

    _infoOnly := Coalesce(_infoOnly, false);

    SELECT COUNT(step)
    INTO _mgrCount
    FROM sw.t_job_steps
    WHERE State = 4;

    If _mgrCount = 0 Then
        _message := 'None of the steps in sw.t_job_steps is state 4 (Running); skipping call to mc.set_manager_update_required';

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        RETURN;
    End If;

    -- Make a list of the currently running managers

    SELECT string_agg(Processor, ', ' ORDER BY Processor)
    INTO _mgrList
    FROM sw.t_job_steps
    WHERE State = 4;

    If _infoOnly Then
        _message := format('Managers to update: %s', _mgrList);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    RAISE INFO 'Calling mc.set_manager_update_required for % %', _mgrCount, public.check_plural(_mgrCount, 'manager', 'managers');

    CALL mc.set_manager_update_required (
                _mgrList,
                _showTable  => true,
                _infoonly   => false,
                _message    => _message,        -- Output
                _returnCode => _returnCode);    -- Output
END
$$;


ALTER PROCEDURE sw.set_update_required_for_running_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_update_required_for_running_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.set_update_required_for_running_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SetUpdateRequiredForRunningManagers';

