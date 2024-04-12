--
-- Name: update_job_status_history(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_job_status_history(IN _minimumtimeintervalhours integer DEFAULT 1, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Append new entries to t_analysis_job_status_history, summarizing the number of analysis jobs in each state in t_analysis_job
**
**  Arguments:
**    _minimumTimeIntervalHours     Set this to 0 to force the addition of new data to t_analysis_job_status_history
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   03/31/2005
**          05/12/2005 mem - Changed default for _databaseName to be ''
**          10/20/2022 mem - Removed the _databaseName argument
**          03/04/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _timeIntervalLastUpdateHours numeric;
    _updateTable boolean;
BEGIN
    _message := '';
    _returnCode := '';

    If Coalesce(_minimumTimeIntervalHours, 0) = 0 Then
        _updateTable := true;
    Else
        SELECT Extract(epoch from CURRENT_TIMESTAMP - MAX(posting_time)) / 3600
        INTO _timeIntervalLastUpdateHours
        FROM t_analysis_job_status_history;

        If Not FOUND Or Coalesce(_timeIntervalLastUpdateHours, _minimumTimeIntervalHours) >= _minimumTimeIntervalHours Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;
    End If;

    If Not _updateTable Then
        _message := format('Update skipped since the last update was %s hours ago', Round(_timeIntervalLastUpdateHours, 2));
        RAISE INFO '%', _message;
        RETURN;
    End If;

    INSERT INTO t_analysis_job_status_history (
        posting_time,
        tool_id,
        state_id,
        Job_Count
    )
    SELECT CURRENT_TIMESTAMP AS Posting_Time,
           Tool_ID,
           State_ID,
           Job_Count
    FROM (SELECT AJ.analysis_tool_id AS Tool_ID,
                 AJ.job_state_id AS State_ID, COUNT(AJ.job) AS Job_Count
          FROM t_analysis_job AS AJ
          GROUP BY AJ.analysis_tool_id, AJ.job_state_id
         ) LookupQ
    ORDER BY tool_id, state_id;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    _message := format('Appended %s %s to t_analysis_job_status_history', _matchCount, public.check_plural(_matchCount, 'row', 'rows'));
    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE public.update_job_status_history(IN _minimumtimeintervalhours integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_status_history(IN _minimumtimeintervalhours integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_job_status_history(IN _minimumtimeintervalhours integer, INOUT _message text, INOUT _returncode text) IS 'UpdateJobStatusHistory';

