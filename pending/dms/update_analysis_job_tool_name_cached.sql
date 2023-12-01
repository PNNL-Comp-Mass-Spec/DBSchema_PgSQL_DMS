--
CREATE OR REPLACE PROCEDURE public.update_analysis_job_tool_name_cached
(
    _jobStart int = 0,
    _jobFinish int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates column analysis_tool_cached in t_analysis_job for one or more jobs
**
**  Arguments:
**    _jobStart     First job number
**    _jobFinish    Last job number; if 0 or a negative number, will use 2147483647
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   04/03/2014 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobCount int := 0;
    _usageMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobStart  := Coalesce(_jobStart, 0);
    _jobFinish := Coalesce(_jobFinish, 0);
    _infoOnly  := Coalesce(_infoOnly, false);

    If _jobFinish = 0 Then
        _jobFinish := 2147483647;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Tool_Name_Cached',
                            'New_Tool_Name_Cached'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        _jobCount := 0;

        FOR _previewData IN
            SELECT AJ.Job,
                   AJ.analysis_tool_cached AS Tool_Name_Cached,
                   AnalysisTool.analysis_tool AS New_Tool_Name_Cached
            FROM t_analysis_job AJ
                 INNER JOIN t_analysis_tool AnalysisTool
                   ON AJ.analysis_tool_id = AnalysisTool.analysis_tool_id
            WHERE AJ.job >= _jobStart AND
                  AJ.job <= _jobFinish AND
                  AJ.analysis_tool_cached IS DISTINCT FROM AnalysisTool.analysis_tool
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Tool_Name_Cached,
                                _previewData.New_Tool_Name_Cached
                               );

            RAISE INFO '%', _infoData;

            _jobCount := _jobCount + 1;
        END LOOP;

        If _jobCount = 0 Then
            _message := 'All jobs have up-to-date cached analysis tool names';
        Else
            _message := format('Found %s %s to update', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));
        End If;

        RAISE INFO '%', _message;
    Else
        ---------------------------------------------------
        -- Update the specified jobs
        ---------------------------------------------------

        UPDATE t_analysis_job AJ
        SET analysis_tool_cached = Coalesce(AnalysisTool.analysis_tool, '')
        FROM t_analysis_tool AnalysisTool
        WHERE AJ.job >= _jobStart AND
              AJ.job <= _jobFinish AND
              AJ.analysis_tool_id = AnalysisTool.analysis_tool_id AND
              AJ.analysis_tool_cached IS DISTINCT FROM AnalysisTool.analysis_tool;
        --
        GET DIAGNOSTICS _jobCount = ROW_COUNT;

        If _jobCount = 0 Then
            _message := '';
        Else
            _message := format('Updated the cached analysis tool name for %s %s', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));
        End If;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));

    If Not _infoOnly Then
        CALL post_usage_log_entry ('update_analysis_job_tool_name_cached', _usageMessage;);
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_analysis_job_tool_name_cached IS 'UpdateAnalysisJobToolNameCached';
