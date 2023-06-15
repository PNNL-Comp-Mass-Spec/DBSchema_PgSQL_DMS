--
CREATE OR REPLACE PROCEDURE cap.set_update_required_for_running_capture_task_managers
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
**
*****************************************************/
DECLARE
    _mgrList text;
    _mgrCount int;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Get a list of the currently running managers
    ---------------------------------------------------

    SELECT string_agg(Processor, ', ' ORDER BY Processor;)
    INTO _mgrList
    FROM cap.t_task_steps
    WHERE State = 4;

    If _infoOnly Then
        RAISE INFO 'Managers to update: %', _mgrList;
    Else
        SELECT COUNT(*)
        INTO _mgrCount
        FROM cap.t_task_steps
        WHERE State = 4;

        RAISE INFO 'Calling set_manager_update_required for % managers', _mgrCount;
        CALL mc.set_manager_update_required (_mgrList, _showTable => 1);
    End If;

END
$$;

COMMENT ON PROCEDURE cap.set_update_required_for_running_capture_task_managers IS 'SetUpdateRequiredForRunningManagers';
