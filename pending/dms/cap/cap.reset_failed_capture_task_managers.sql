--
CREATE OR REPLACE PROCEDURE cap.reset_failed_capture_task_managers
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
**      Resets managers that report 'flag file' in V_Processor_Status_Warnings_CTM
**
**  Arguments:
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   10/20/2016 mem - Ported from DMS_Pipeline
**          01/16/2023 mem - Use new view name
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _managerList text := null;
BEGIN
    _message := '';
    _returnCode := '';

    -- Temp table for managers
    CREATE TEMP TABLE Tmp_ManagersToReset (
        Processor_Name text NOT NULL,
        Status_Date timestamp
    )

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    _infoOnly := Coalesce(_infoOnly, false);

    -----------------------------------------------------------
    -- Find managers reporting error 'Flag file' within the last 6 hours
    -----------------------------------------------------------
    --

    INSERT INTO Tmp_ManagersToReset (Processor_Name, Status_Date)
    SELECT Processor_Name,
           Status_Date
    FROM cap.V_Processor_Status_Warnings_CTM
    WHERE Most_Recent_Log_Message Like '%Flag file%' AND
          Status_Date > CURRENT_TIMESTAMP - Interval '6 hours';

    If Not Exists (SELECT * FROM Tmp_ManagersToReset) Then
        SELECT 'No failed managers were found' AS Message
    Else

        -----------------------------------------------------------
        -- Construct a comma-separated list of manager names
        -----------------------------------------------------------
        --

        SELECT string_agg(Processor_Name, ',')
        INTO _managerList
        FROM Tmp_ManagersToReset
        ORDER BY Processor_Name

        -----------------------------------------------------------
        -- Call the manager control error cleanup procedure
        -----------------------------------------------------------
        --
        CALL mc.set_manager_error_cleanup_mode (_managerList, _cleanupMode => 1, _showTable => 1, _infoOnly => _infoOnly);

    End If;

    DROP TABLE Tmp_ManagersToReset;

END
$$;

COMMENT ON PROCEDURE cap.reset_failed_capture_task_managers IS 'ResetFailedManagers';
