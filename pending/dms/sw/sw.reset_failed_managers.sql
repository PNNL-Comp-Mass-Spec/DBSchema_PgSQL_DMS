--
CREATE OR REPLACE PROCEDURE sw.reset_failed_managers
(
    _infoOnly boolean = false,
    _resetAllWithError boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resets managers that report 'flag file' in V_Processor_Status_Warnings
**
**  Arguments:
**    _infoOnly            True to preview the changes
**    _resetAllWithError   When false, the manager must have Most_Recent_Log_Message = 'Flag file'; when true, also matches managers with Mgr_Status = 'Stopped Error'
**
**  Auth:   mem
**  Date:   12/02/2014 mem - Initial version
**          03/29/2019 mem - Add parameter _resetAllWithError
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _managerList text := null;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    _infoOnly := Coalesce(_infoOnly, false);
    _resetAllWithError := Coalesce(_resetAllWithError, false);

    -- Temp table for managers
    CREATE TEMP TABLE Tmp_ManagersToReset (
        Processor_Name text NOT NULL,
        Status_Date timestamp
    );

    -----------------------------------------------------------
    -- Find managers reporting error 'Flag file' within the last 6 hours
    -----------------------------------------------------------
    --

    INSERT INTO Tmp_ManagersToReset (Processor_Name, Status_Date)
    SELECT Processor_Name,
           Status_Date
    FROM sw.V_Processor_Status_Warnings
    WHERE (Most_Recent_Log_Message = 'Flag file' Or
           _resetAllWithError And Mgr_Status = 'Stopped Error') AND
          Status_Date > CURRENT_TIMESTAMP - INTERVAL '6 hours'

    If Not FOUND Then
        _message := 'No failed managers were found';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_ManagersToReset;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Construct a comma-separated list of manager names
    -----------------------------------------------------------
    --

    SELECT string_agg(Processor_Name, ',' ORDER BY Processor_Name)
    INTO _managerList
    FROM Tmp_ManagersToReset;

    -----------------------------------------------------------
    -- Call the manager control procedure
    -----------------------------------------------------------
    --
    CALL mc.set_manager_error_cleanup_mode (
            _managerList,
            _cleanupMode => 1,
            _showTable => true,
            _infoOnly => _infoOnly,
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

    DROP TABLE Tmp_ManagersToReset;
END
$$;

COMMENT ON PROCEDURE sw.reset_failed_managers IS 'ResetFailedManagers';
