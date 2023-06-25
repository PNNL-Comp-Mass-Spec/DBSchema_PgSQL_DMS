--
-- Name: reset_failed_capture_task_managers(boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.reset_failed_capture_task_managers(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Resets managers that report 'flag file' in cap.V_Processor_Status_Warnings_CTM
**
**  Arguments:
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   10/20/2016 mem - Ported from DMS_Pipeline
**          01/16/2023 mem - Use new view name
**          06/24/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _managerList text := null;
BEGIN
    _message := '';
    _returnCode := '';

    CREATE TEMP TABLE Tmp_ManagersToReset (
        Processor_Name text NOT NULL,
        Status_Date timestamp
    );

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    -----------------------------------------------------------
    -- Find managers reporting error 'Flag file' within the last 6 hours
    -----------------------------------------------------------

    INSERT INTO Tmp_ManagersToReset (Processor_Name, Status_Date)
    SELECT Processor_Name,
           Status_Date
    FROM cap.V_Processor_Status_Warnings_CTM
    WHERE Most_Recent_Log_Message Like '%Flag file%' AND
          Status_Date > CURRENT_TIMESTAMP - Interval '6 hours';

    If Not Exists (SELECT * FROM Tmp_ManagersToReset) Then
        _message := 'No failed managers were found';

        DROP TABLE Tmp_ManagersToReset;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Construct a comma-separated list of manager names
    -----------------------------------------------------------

    SELECT string_agg(Processor_Name, ',' ORDER BY Processor_Name)
    INTO _managerList
    FROM Tmp_ManagersToReset;

    -----------------------------------------------------------
    -- Call the manager control error cleanup procedure
    -----------------------------------------------------------

    CALL mc.set_manager_error_cleanup_mode (
                _managerList,
                _cleanupMode => 1,
                _showTable => true,
                _infoOnly => _infoOnly,
                _message => _message,
                _returnCode => _returnCode);

    DROP TABLE Tmp_ManagersToReset;

END
$$;


ALTER PROCEDURE cap.reset_failed_capture_task_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_failed_capture_task_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.reset_failed_capture_task_managers(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'ResetFailedManagers';

