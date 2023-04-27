--
CREATE OR REPLACE PROCEDURE public.update_analysis_job_tool_name_cached
(
    _jobStart int = 0,
    _jobFinish int = 0,
    INOUT _message text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates column analysis_tool_cached in T_Analysis_Job for 1 or more jobs
**
**  Auth:   mem
**  Date:   04/03/2014 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _jobCount int := 0;
    _usageMessage text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    _jobStart := Coalesce(_jobStart, 0);
    _jobFinish := Coalesce(_jobFinish, 0);
    _message := '';
    _infoOnly := Coalesce(_infoOnly, false);

    If _jobFinish = 0 Then
        _jobFinish := 2147483647;
    End If;

    ---------------------------------------------------
    -- Update the specified jobs
    ---------------------------------------------------
    If _infoOnly Then
        SELECT  AJ.job AS Job,
                AJ.analysis_tool_cached AS Tool_Name_Cached,
                AnalysisTool.analysis_tool AS New_Tool_Name_Cached
        FROM t_analysis_job AJ INNER JOIN
             t_analysis_tool AnalysisTool ON AJ.analysis_tool_id = AnalysisTool.analysis_tool_id
        WHERE (AJ.job >= _jobStart) AND
              (AJ.job <= _jobFinish) AND
              Coalesce(AJ.analysis_tool_cached, '') <> Coalesce(AnalysisTool.analysis_tool, '')
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _message := 'All jobs have up-to-date cached analysis tool names';
        Else
            _message := 'Found ' || _myRowCount::text || ' jobs to update';
        End If;

        RAISE INFO '%', _message;
    Else
        UPDATE t_analysis_job
        SET analysis_tool_cached = Coalesce(AnalysisTool.analysis_tool, '')
        FROM t_analysis_job AJ INNER JOIN
             t_analysis_tool AnalysisTool ON AJ.analysis_tool_id = AnalysisTool.analysis_tool_id
        WHERE (AJ.job >= _jobStart) AND
              (AJ.job <= _jobFinish) AND
              Coalesce(analysis_tool_cached, '') <> Coalesce(AnalysisTool.analysis_tool, '')
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _jobCount := _myRowCount;

        If _jobCount = 0 Then
            _message := '';
        Else
            _message := ' Updated the cached analysis tool name for ' || _jobCount::text || ' jobs';
        End If;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := _jobCount::text || ' jobs updated';

    If Not _infoOnly Then
        Call post_usage_log_entry ('UpdateAnalysisJobToolNameCached', _usageMessage;);
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_analysis_job_tool_name_cached IS 'UpdateAnalysisJobToolNameCached';
