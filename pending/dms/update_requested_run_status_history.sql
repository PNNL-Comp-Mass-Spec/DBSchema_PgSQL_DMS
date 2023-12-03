--
CREATE OR REPLACE PROCEDURE public.update_requested_run_status_history
(
    _minimumTimeIntervalHours integer = 1,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates stats in t_requested_run_status_history, summarizing the number of requested runs in each state in t_requested_run
**
**  Arguments:
**    _minimumTimeIntervalHours     Set this to 0 to force the addition of new data to t_requested_run_status_history
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   09/25/2012 mem - Initial Version
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int;
    _timeIntervalLastUpdateHours real;
    _updateTable int;
    _sql text;
BEGIN
    _message := '';
    _returnCode := '';

    If Coalesce(_minimumTimeIntervalHours, 0) = 0 Then
        _updateTable := 1;
    Else

        SELECT extract(epoch FROM CURRENT_TIMESTAMP - MAX(posting_time)) / 60.0
        INTO _timeIntervalLastUpdateHours
        FROM t_requested_run_status_history

        If Coalesce(_timeIntervalLastUpdateHours, _minimumTimeIntervalHours) >= _minimumTimeIntervalHours Then
            _updateTable := 1;
        Else
            _updateTable := 0;
        End If;

    End If;

    If _updateTable = 1 Then

        INSERT INTO t_requested_run_status_history (posting_time, state_id, origin, Request_Count,
                                                    queue_time_0days, queue_time_1to6days, queue_time_7to44days,
                                                    queue_time_45to89days, queue_time_90to179days, queue_time_180days_and_up)
        SELECT CURRENT_TIMESTAMP AS Posting_Time,
               state_id,
               origin,
               COUNT(request_id) AS Request_Count,
               SUM(CASE WHEN DaysInQueue = 0                THEN 1 ELSE 0 END) AS QueueTime_0Days,
               SUM(CASE WHEN DaysInQueue BETWEEN  1 AND   1 THEN 1 ELSE 0 END) AS QueueTime_1to6Days,
               SUM(CASE WHEN DaysInQueue BETWEEN  7 AND  44 THEN 1 ELSE 0 END) AS QueueTime_7to44Days,
               SUM(CASE WHEN DaysInQueue BETWEEN 45 AND  89 THEN 1 ELSE 0 END) AS QueueTime_45to89Days,
               SUM(CASE WHEN DaysInQueue BETWEEN 90 AND 179 THEN 1 ELSE 0 END) AS QueueTime_90to179Days,
               SUM(CASE WHEN DaysInQueue >= 180             THEN 1 ELSE 0 END) AS QueueTime_180DaysAndUp
        FROM ( SELECT DISTINCT RRSN.state_id,
                               RR.origin AS Origin,
                               RR.request_id,
                               QT.days_in_queue AS DaysInQueue
               FROM t_requested_run RR
                    INNER JOIN t_requested_run_state_name RRSN
                      ON RR.state_name = RRSN.state_name
                    LEFT OUTER JOIN V_Requested_Run_Queue_Times QT
                      ON RR.request_id = QT.Requested_Run_ID
             ) SourceQ
        GROUP BY state_id, origin
        ORDER BY state_id, origin;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        _message := format('Appended %s rows to the Requested Run Status History table', _insertCount);
    Else
        _message := format('Update skipped since last update was %s hours ago', Round(_timeIntervalLastUpdateHours, 1));
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_requested_run_status_history IS 'UpdateRequestedRunStatusHistory';
