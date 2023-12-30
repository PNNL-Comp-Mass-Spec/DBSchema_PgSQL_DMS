--
-- Name: reset_failed_managers(boolean, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.reset_failed_managers(IN _infoonly boolean DEFAULT false, IN _resetallwitherror boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Reset managers with a status message of 'Flag file' posted to sw.t_processor_status within the last 6 hours
**
**      This procedure is intended to be run on a regular basis by a job scheduler,
**      though only in cases where we expect managers to fail and we want to auto-reset them on a regular basis
**
**  Arguments:
**    _infoOnly             When true, preview updates
**    _resetAllWithError    When false, the manager must have Most_Recent_Log_Message = 'Flag file'; when true, also matches managers with Mgr_Status = 'Stopped Error'
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   12/02/2014 mem - Initial version
**          03/29/2019 mem - Add parameter _resetAllWithError
**          08/07/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
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

    _infoOnly          := Coalesce(_infoOnly, false);
    _resetAllWithError := Coalesce(_resetAllWithError, false);

    -- Temp table for managers
    CREATE TEMP TABLE Tmp_ManagersToReset (
        Processor_Name text NOT NULL,
        Status_Date timestamp
    );

    -----------------------------------------------------------
    -- Find managers reporting error 'Flag file' within the last 6 hours
    -----------------------------------------------------------

    INSERT INTO Tmp_ManagersToReset (Processor_Name, Status_Date)
    SELECT Processor_Name,
           Status_Date
    FROM sw.v_processor_status_warnings
    WHERE (Most_Recent_Log_Message = 'Flag file' Or
           _resetAllWithError And Mgr_Status = 'Stopped Error') AND
          Status_Date > CURRENT_TIMESTAMP - INTERVAL '6 hours';

    If Not FOUND Then
        _message := 'No failed managers were found';
        RAISE INFO '%', _message;

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
    -- Call the manager control procedure
    -----------------------------------------------------------

    CALL mc.set_manager_error_cleanup_mode (
                _managerList,
                _cleanupMode => 1,
                _showTable   => true,
                _infoOnly    => _infoOnly,
                _message     => _message,       -- Output
                _returnCode  => _returnCode);   -- Output

    DROP TABLE Tmp_ManagersToReset;
END
$$;


ALTER PROCEDURE sw.reset_failed_managers(IN _infoonly boolean, IN _resetallwitherror boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_failed_managers(IN _infoonly boolean, IN _resetallwitherror boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.reset_failed_managers(IN _infoonly boolean, IN _resetallwitherror boolean, INOUT _message text, INOUT _returncode text) IS 'ResetFailedManagers';

