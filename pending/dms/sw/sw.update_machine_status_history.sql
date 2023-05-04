--
CREATE OR REPLACE PROCEDURE sw.update_machine_status_history
(
    _minimumTimeIntervalHours int = 1,
    _activeProcessWindowHours int = 24,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Appends new entries to T_Machine_Status_History,
**      summarizing the number of active jobs on each machine
**      and the max reported free memory in the last 24 hours
**
**  Arguments:
**    _minimumTimeIntervalHours   Set this to 0 to force the addition of new data to T_Analysis_Job_Status_History
**    _activeProcessWindowHours   Will consider status values posted within the last _activeProcessWindowHours as valid status values
**
**  Auth:   mem
**  Date:   08/10/2010 mem - Initial version
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _timeIntervalLastUpdateHours real;
    _updateTable boolean;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------
    -- Validate the inputs
    ----------------------------------------
    --
    _minimumTimeIntervalHours := Coalesce(_minimumTimeIntervalHours, 1);
    _activeProcessWindowHours := Coalesce(_activeProcessWindowHours, 24);
    _message := '';
    _returnCode:= '';

    If Coalesce(_minimumTimeIntervalHours, 0) = 0 Then
        _updateTable := true;
    Else
        ----------------------------------------
        -- Lookup how long ago the table was last updated
        ----------------------------------------
        --
        SELECT extract(epoch FROM (CURRENT_TIMESTAMP - MAX(posting_time))) / 3600.0
        INTO _timeIntervalLastUpdateHours
        FROM sw.t_machine_status_history;

        If Coalesce(_timeIntervalLastUpdateHours, _minimumTimeIntervalHours) >= _minimumTimeIntervalHours Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;

    End If;

    If _updateTable Then

        INSERT INTO sw.t_machine_status_history( posting_time,
                                      machine,
                                      processor_count_active,
                                      free_memory_mb )
        SELECT CURRENT_TIMESTAMP,
               M.machine,
               COUNT(*) AS Processor_Count_Active,
               CONVERT(int, MAX(PS.free_memory_mb)) AS Free_Memory_MB
        FROM sw.t_processor_status PS
             INNER JOIN sw.t_local_processors LP
               ON PS.processor_name = LP.processor_name
             INNER JOIN sw.t_machines M
               ON LP.machine = M.machine
        WHERE PS.status_date > CURRENT_TIMESTAMP - make_interval(hours => _activeProcessWindowHours)
        GROUP BY M.machine
        ORDER BY M.machine
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := format('Appended %s rows to the Machine Status History table', _myRowCount);
    Else
        _message := format('Update skipped since last update was %s hours ago', Round(_timeIntervalLastUpdateHours, 1));
    End If;

END
$$;

COMMENT ON PROCEDURE sw.update_machine_status_history IS 'UpdateMachineStatusHistory';
