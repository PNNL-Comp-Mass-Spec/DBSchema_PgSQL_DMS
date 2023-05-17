--
CREATE OR REPLACE PROCEDURE public.update_job_status_history
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
**      Appends new entries to T_Analysis_Job_Status_History,
**      summarizing the number of analysis jobs in each state
**      in T_Analysis_Job
**
**  Arguments:
**    _minimumTimeIntervalHours   Set this to 0 to force the addition of new data to T_Analysis_Job_Status_History
**
**  Auth:   mem
**  Date:   03/31/2005
**          05/12/2005 mem - Changed default for _databaseName to be ''
**          10/20/2022 mem - Removed the _databaseName argument
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _timeIntervalLastUpdateHours real;
    _updateTable boolean;
    _s text;
BEGIN
    _message := '';
    _returnCode:= '';

    If Coalesce(_minimumTimeIntervalHours, 0) = 0 Then
        _updateTable := true;
    Else

        SELECT extract(epoch FROM CURRENT_TIMESTAMP - MAX(posting_time)) / 60.0
        INTO _timeIntervalLastUpdateHours
        FROM t_analysis_job_status_history

        If Coalesce(_timeIntervalLastUpdateHours, _minimumTimeIntervalHours) >= _minimumTimeIntervalHours Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;

    End If;

    If _updateTable Then

        INSERT INTO t_analysis_job_status_history (posting_time, tool_id, state_id, Job_Count)
        SELECT CURRENT_TIMESTAMP AS Posting_Time, Tool_ID, State_ID, Job_Count
        FROM (    SELECT AJ.analysis_tool_id AS Tool_ID,
                         AJ.job_state_id AS State_ID, COUNT(AJ.job) AS Job_Count
                  FROM t_analysis_job AS AJ
                  GROUP BY AJ.analysis_tool_id, AJ.job_state_id
                  ) LookupQ
        ORDER BY tool_id, state_id;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _message := format('Appended %s %s to the Job Status History table', _matchCount, public.check_plural(_matchCount, 'row', 'rows'));
    Else
        _message := format('Update skipped since last update was %s hours ago', Round(_timeIntervalLastUpdateHours, 1));
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_job_status_history IS 'UpdateJobStatusHistory';
