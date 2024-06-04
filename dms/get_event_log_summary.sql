--
-- Name: get_event_log_summary(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_event_log_summary(_startdate timestamp with time zone, _enddate timestamp with time zone) RETURNS TABLE(sortkey numeric, label public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Summarize DMS activity, errors, and warnings between the start and end timestamps
**
**  Usage:
**      -- DMS ACTIVITY REPORT (Previous 24 hours)
**      SELECT *
**      FROM get_event_log_summary(null, null)
**      ORDER BY sortkey, label;
**
**      -- DMS ACTIVITY REPORT (Previous 24 hours)
**      SELECT *
**      FROM get_event_log_summary(null, CURRENT_TIMESTAMP)
**      ORDER BY sortkey, label;
**
**      -- DMS ACTIVITY REPORT (Previous 12 hours)
**      SELECT *
**      FROM get_event_log_summary(CURRENT_TIMESTAMP - Interval '12 hours', CURRENT_TIMESTAMP)
**      ORDER BY sortkey, label;
**
**      -- DMS ACTIVITY REPORT (Over 5 days)
**      SELECT *
**      FROM get_event_log_summary(CURRENT_TIMESTAMP - Interval '7 days', CURRENT_TIMESTAMP - Interval '2 days')
**      ORDER BY sortkey, label;
**
**      -- DMS ACTIVITY REPORT (Over 60 days)
**      SELECT *
**      FROM public.get_event_log_summary('2023-03-01', '2023-04-30')
**      ORDER BY sortkey, label;
**
**  Auth:   mem
**  Date:   07/12/2022 mem - Initial release (based on view V_Event_Log_24_Hour_Summary)
**          08/26/2022 mem - Use new column name in t_log_entries
**          04/27/2023 mem - Use boolean for data type name
**          05/30/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT() on specific columns instead of COUNT(*)
**
*****************************************************/
DECLARE
    _timeRange citext;
    _rangeDescription citext;
    _hoursInRange int;
    _daysInRange int;
    _isPreviousHours boolean;
BEGIN

    _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - INTERVAL '24 hours');
    _endDate   := Coalesce(_endDate,   _startDate + INTERVAL '24 hours');

    _hoursInRange := Round(Extract(epoch from _endDate - _startDate) / 3600)::int;
    _daysInRange  := Round(Extract(epoch from _endDate - _startDate) / 86400)::int;

    If Abs(Extract(epoch from CURRENT_TIMESTAMP - _endDate)) < 5 Then
        -- _endDate is within 5 seconds of the current time

        _isPreviousHours := true;
        _timeRange = '';

        If _hoursInRange <= 72 Then
            _rangeDescription := format('Previous %s hours', _hoursInRange);
        Else
            _rangeDescription := format('Previous %s days', _daysInRange);
        End If;
    Else
        _isPreviousHours := false;

        If _hoursInRange <= 72 Then
            _rangeDescription := format('Over %s hours', _hoursInRange);
        Else
            _rangeDescription := format('Over %s days', _daysInRange);
        End If;

        If _daysInRange <= 3 Then
            _timeRange := format('%s to %s', to_char(_startDate, 'yyyy-mm-dd hh:mi am'), to_char(_endDate, 'yyyy-mm-dd hh:mi am'));
        Else
            _timeRange := format('%s to %s', to_char(_startDate, 'yyyy-mm-dd'), to_char(_endDate, 'yyyy-mm-dd'));
        End If;
    End If;

    RETURN QUERY
    SELECT 0::numeric AS SortKey,
        (format('DMS ACTIVITY REPORT (%s)', _rangeDescription))::citext AS Label,
        (CASE WHEN _isPreviousHours
             THEN to_char(CURRENT_TIMESTAMP, 'yyyy-mm-dd hh:mi am')
             ELSE _timeRange
         END)::citext AS Value
    UNION
    SELECT 1.0 AS SortKey, 'NEW ENTRIES' AS label, '' AS Value
    UNION
    SELECT 2.0 AS SortKey, 'DATASET ACTIVITY' AS label, '' AS Value
    UNION
    SELECT 3.0 AS SortKey, 'ANALYSIS JOB ACTIVITY' AS label, '' AS Value
    UNION
    SELECT 4.0 AS SortKey, 'ARCHIVE ACTIVITY' AS label, '' AS Value
    UNION
    SELECT 1.1 AS SortKey, '  Campaigns entered' AS label, COUNT(campaign_id)::citext AS Value
    FROM public.t_campaign
    WHERE created BETWEEN _startDate And _endDate
    UNION
    SELECT 1.2 AS SortKey, '  Cell Cultures entered' AS Label, COUNT(biomaterial_id)::citext AS Value
    FROM public.t_biomaterial
    WHERE created BETWEEN _startDate And _endDate
    UNION
    SELECT 1.3 AS SortKey, '  Experiments entered' AS Label, COUNT(exp_id)::citext AS Value
    FROM public.t_experiments
    WHERE created BETWEEN _startDate And _endDate
    UNION
    SELECT 1.4 AS SortKey, '  Datasets entered' AS Label, COUNT(dataset_id)::citext AS Value
    FROM public.t_dataset
    WHERE created BETWEEN _startDate And _endDate
    UNION
    SELECT 1.5 AS SortKey, '  Analysis Jobs entered (total)' AS Label, COUNT(job)::citext AS Value
    FROM public.t_analysis_job
    WHERE created BETWEEN _startDate And _endDate
    UNION
    SELECT 1.6 AS SortKey, '  Analysis Jobs entered (auto)' AS Label, COUNT(job)::citext AS Value
    FROM public.t_analysis_job
    WHERE created BETWEEN _startDate And _endDate AND (comment LIKE '%Auto predefined%')
    UNION
    SELECT 2.1 AS SortKey, '  Dataset Capture Successful' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 3)
    UNION
    SELECT 2.2 AS SortKey, '  Dataset Received Successful' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 6)
    UNION
    SELECT 5.1 AS SortKey, '  Dataset Capture Failed' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 5)
    UNION
    SELECT 5.2 AS SortKey, '  Dataset Prep Failed' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 8)
    UNION
    SELECT 4.1 AS SortKey, '  Dataset Archive Successful' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 3)
    UNION
    SELECT 4.2 AS SortKey, '  Dataset Purge Successful' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 4)
    UNION
    SELECT 5.7 AS SortKey, '  Dataset Archive Fail' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 6)
    UNION
    SELECT 5.8 AS SortKey, '   Dataset Purge Fail' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 8)
    UNION
    SELECT 3.1 AS SortKey, '  Analysis Jobs Successful' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 5) AND (Target_State = 4)
    UNION
    SELECT 5.3 AS SortKey, '  Analysis Jobs Fail' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 5) AND (Target_State = 5)
    UNION
    SELECT 5.4 AS SortKey, '  Analysis Jobs Fail (no intermed. files)' AS Label, COUNT(event_id)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND (Target_Type = 5) AND (Target_State = 7)
    UNION
    SELECT 5.0 AS SortKey, 'FAILURES' AS Label,
           (CASE WHEN COUNT(event_id) > 0 THEN format('Errors Detected: %s', COUNT(event_id)) ELSE '' END)::citext AS Value
    FROM public.t_event_log
    WHERE Entered BETWEEN _startDate And _endDate AND
          (Target_Type = 4 AND Target_State = 5 OR
           Target_Type = 4 AND Target_State = 8 OR
           Target_Type = 6 AND Target_State = 6 OR
           Target_Type = 6 AND Target_State = 8 OR
           Target_Type = 5 AND Target_State = 5 OR
           Target_Type = 5 AND Target_State = 7
          )
    UNION
    SELECT 1.51 AS SortKey,
           (format('    Analysis Jobs entered (%s)', Tool.analysis_tool))::citext AS Label, COUNT(J.job)::citext AS Value
    FROM public.t_analysis_job J INNER JOIN
         public.t_analysis_tool Tool ON J.analysis_tool_id = Tool.analysis_tool_id
    WHERE J.created BETWEEN _startDate And _endDate
    GROUP BY Tool.analysis_tool
    UNION
    SELECT 3.11 AS SortKey,
           (format('    Analysis Jobs Successful (%s)', Tool.analysis_tool))::citext AS Label, COUNT(EL.event_id)::citext AS Value
    FROM   public.t_event_log EL INNER JOIN
           public.t_analysis_job J ON EL.Target_ID = J.job INNER JOIN
           public.t_analysis_tool Tool ON J.analysis_tool_id = Tool.analysis_tool_id
    WHERE EL.Entered BETWEEN _startDate And _endDate AND (EL.Target_Type = 5) AND (EL.Target_State = 4)
    GROUP BY Tool.analysis_tool
    UNION
    SELECT 1.41 AS SortKey,
           (format('    Datasets entered (%s)', InstName.instrument_class))::citext AS Label, COUNT(DS.dataset_id)::citext AS Value
    FROM public.t_dataset DS INNER JOIN
         public.t_instrument_name InstName ON DS.instrument_id = InstName.Instrument_ID
    WHERE DS.created BETWEEN _startDate And _endDate
    GROUP BY InstName.instrument_class
    UNION
    SELECT 2.11 AS SortKey,
           (format('    Dataset Capture Successful (%s)', InstName.instrument_class))::citext AS Label, COUNT(EL.event_id)::citext AS Value
    FROM public.t_event_log EL INNER JOIN
         public.t_dataset DS ON EL.Target_ID = DS.Dataset_ID INNER JOIN
         public.t_instrument_name InstName ON DS.instrument_id = InstName.Instrument_ID
    WHERE EL.Entered BETWEEN _startDate And _endDate AND (EL.Target_Type = 4) AND (EL.Target_State = 3)
    GROUP BY InstName.instrument_class
    UNION
    SELECT 6.0 AS SortKey, 'LOG ENTRIES' AS Label,
           (CASE WHEN StatsQ.Errors + StatsQ.Warnings > 0
                 THEN format('Errors / Warnings: %s', StatsQ.Errors + StatsQ.Warnings)
                 ELSE ''
            END)::citext AS Value
    FROM (SELECT SUM(CASE WHEN type = 'Error'   THEN 1 ELSE 0 END) AS Errors,
                 SUM(CASE WHEN type = 'Warning' THEN 1 ELSE 0 END) AS Warnings
          FROM public.t_log_entries
          WHERE entered BETWEEN _startDate And _endDate AND type IN ('Error', 'Warning')
         ) StatsQ
    UNION
    SELECT 6.1 AS SortKey, '  Warnings' AS Label, COUNT(entry_id)::citext AS Value
    FROM public.t_log_entries
    WHERE entered BETWEEN _startDate And _endDate AND type = 'Warning'
    UNION
    SELECT 6.2 AS SortKey, '  Errors' AS Label, COUNT(entry_id)::citext AS Value
    FROM public.t_log_entries
    WHERE entered BETWEEN _startDate And _endDate AND type = 'Error'
    ;
END
$$;


ALTER FUNCTION public.get_event_log_summary(_startdate timestamp with time zone, _enddate timestamp with time zone) OWNER TO d3l243;

