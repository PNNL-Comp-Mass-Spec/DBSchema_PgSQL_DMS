--
-- Name: get_event_log_summary(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_event_log_summary(_startdate timestamp with time zone, _enddate timestamp with time zone) RETURNS TABLE(sortkey numeric, label public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Desc:
**      Summarizes DMS activity, errors, and warnings between the start and end timestamps
**
**  Auth:   mem
**  Date:   07/12/2022 mem - Initial release (based on view V_Event_Log_24_Hour_Summary)
**          08/26/2022 mem - Use new column name in t_log_entries
**
*****************************************************/
DECLARE
    _timeRange citext;
    _rangeDescription citext;
    _hoursInRange int;
    _daysInRange int;
    _isPreviousHours bool;
BEGIN

    _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - Interval '24 hours');
    _endDate := Coalesce(_endDate, _startDate + Interval '24 hours');

    _hoursInRange := Round(extract(epoch FROM _endDate - _startDate) / 3600.0)::int;
    _daysInRange  := Round(extract(epoch FROM _endDate - _startDate) / 86400.0)::int;

    If Abs(extract(epoch FROM CURRENT_TIMESTAMP - _endDate)) < 5 Then
        _isPreviousHours := true;
        _timeRange = '';

        If _hoursInRange <= 72 Then
            _rangeDescription := 'Previous ' || _hoursInRange::text || ' hours';
        Else
            _rangeDescription := 'Previous ' || _daysInRange::text || ' days';
        End If;
    Else
        _isPreviousHours := false;

        If _hoursInRange <= 72 Then
            _rangeDescription := 'Over ' || _hoursInRange::text || ' hours';
        Else
            _rangeDescription := 'Over ' || _daysInRange::text || ' days';
        End If;

        If _daysInRange <= 3 Then
            _timeRange := to_char(_startDate, 'yyyy-mm-dd hh:mi am') || ' to ' || to_char(_endDate, 'yyyy-mm-dd hh:mi am');
        Else
            _timeRange := to_char(_startDate, 'yyyy-mm-dd') || ' to ' || to_char(_endDate, 'yyyy-mm-dd');
        End If;
    End If;

    RETURN QUERY
    SELECT 0::numeric As SortKey,
        ('DMS ACTIVITY REPORT (' || _rangeDescription || ')')::citext AS Label,
        (Case When _isPreviousHours
             Then to_char(CURRENT_TIMESTAMP, 'yyyy-mm-dd hh:mi am')
             Else _timeRange
         End)::citext as Value
    UNION
    SELECT 1.0 As SortKey, 'NEW ENTRIES' AS label, '' AS Value
    UNION
    SELECT 2.0 As SortKey, 'DATASET ACTIVITY' AS label, '' AS Value
    UNION
    SELECT 3.0 As SortKey, 'ANALYSIS JOB ACTIVITY' AS label, '' AS Value
    UNION
    SELECT 4.0 As SortKey, 'ARCHIVE ACTIVITY' AS label, '' AS Value
    UNION
    SELECT 1.1 As SortKey, '  Campaigns entered' AS label, COUNT(*)::citext AS Value
    FROM public.t_campaign
    WHERE created Between _startDate And _endDate
    UNION
    SELECT 1.2 As SortKey, '  Cell Cultures entered' AS Label, COUNT(*)::citext AS Value
    FROM public.t_biomaterial
    WHERE created Between _startDate And _endDate
    UNION
    SELECT 1.3 As SortKey, '  Experiments entered' AS Label, COUNT(*)::citext AS Value
    FROM public.t_experiments
    WHERE created Between _startDate And _endDate
    UNION
    SELECT 1.4 As SortKey, '  Datasets entered' AS Label, COUNT(*)::citext AS Value
    FROM public.t_dataset
    WHERE created Between _startDate And _endDate
    UNION
    SELECT 1.5 As SortKey, '  Analysis Jobs entered (total)' AS Label, COUNT(*)::citext AS Value
    FROM public.t_analysis_job
    WHERE created Between _startDate And _endDate
    UNION
    SELECT 1.6 As SortKey, '  Analysis Jobs entered (auto)' AS Label, COUNT(*)::citext AS Value
    FROM public.t_analysis_job
    WHERE created Between _startDate And _endDate AND (comment LIKE '%Auto predefined%')
    UNION
    SELECT 2.1 As SortKey, '   Dataset Capture Successful' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 3)
    UNION
    SELECT 2.2 As SortKey, '  Dataset Received Successful' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 6)
    UNION
    SELECT 5.1 As SortKey, '  Dataset Capture Failed' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 5)
    UNION
    SELECT 5.2 As SortKey, '  Dataset Prep Failed' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 4) AND (Target_State = 8)
    UNION
    SELECT 4.1 As SortKey, '  Dataset Archive Successful' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 3)
    UNION
    SELECT 4.2 As SortKey, '  Dataset Purge Successful' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 4)
    UNION
    SELECT 5.7 As SortKey, '  Dataset Archive Fail' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 6)
    UNION
    SELECT 5.8 As SortKey, '   Dataset Purge Fail' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 6) AND (Target_State = 8)
    UNION
    SELECT 3.1 As SortKey, '  Analysis Jobs Successful' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 5) AND (Target_State = 4)
    UNION
    SELECT 5.3 As SortKey, '  Analysis Jobs Fail' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 5) AND (Target_State = 5)
    UNION
    SELECT 5.4 As SortKey, '  Analysis Jobs Fail (no intermed. files)' AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND (Target_Type = 5) AND (Target_State = 7)
    UNION
    SELECT 5.0 As SortKey, 'FAILURES' AS Label,
           (CASE WHEN COUNT(*) > 0 THEN 'Errors Detected: ' || COUNT(*)::citext ELSE '' END)::citext AS Value
    FROM public.t_event_log
    WHERE Entered Between _startDate And _endDate AND
          ( Target_Type = 4 AND Target_State = 5 OR
            Target_Type = 4 AND Target_State = 8 OR
            Target_Type = 6 AND Target_State = 6 OR
            Target_Type = 6 AND Target_State = 8 OR
            Target_Type = 5 AND Target_State = 5 OR
            Target_Type = 5 AND Target_State = 7
          )
    UNION
    SELECT 1.51 As SortKey,
           ('    Analysis Jobs entered (' || Tool.analysis_tool || ')')::citext AS Label, COUNT(*)::citext AS Value
    FROM public.t_analysis_job J INNER JOIN
         public.t_analysis_tool Tool ON J.analysis_tool_id = Tool.analysis_tool_id
    WHERE     J.created Between _startDate And _endDate
    GROUP BY Tool.analysis_tool
    UNION
    SELECT 3.11 As SortKey,
           ('    Analysis Jobs Successful (' || Tool.analysis_tool || ')')::citext AS Label, COUNT(*)::citext AS Value
    FROM   public.t_event_log EL INNER JOIN
           public.t_analysis_job J ON EL.Target_ID = J.job INNER JOIN
           public.t_analysis_tool Tool ON J.analysis_tool_id = Tool.analysis_tool_id
    WHERE EL.Entered Between _startDate And _endDate AND (EL.Target_Type = 5) AND (EL.Target_State = 4)
    GROUP BY Tool.analysis_tool
    UNION
    SELECT 1.41 As SortKey,
           ('    Datasets entered (' || InstName.instrument_class || ')')::citext AS Label, COUNT(*)::citext AS Value
    FROM public.t_dataset DS INNER JOIN
         public.t_instrument_name InstName ON DS.instrument_id = InstName.Instrument_ID
    WHERE DS.created Between _startDate And _endDate
    GROUP BY InstName.instrument_class
    UNION
    SELECT 2.11 As SortKey,
           ('    Dataset Capture Successful (' || InstName.instrument_class || ')')::citext AS Label, COUNT(*)::citext AS Value
    FROM public.t_event_log EL INNER JOIN
         public.t_dataset DS ON EL.Target_ID = DS.Dataset_ID INNER JOIN
         public.t_instrument_name InstName ON DS.instrument_id = InstName.Instrument_ID
    WHERE EL.Entered Between _startDate And _endDate AND (EL.Target_Type = 4) AND (EL.Target_State = 3)
    GROUP BY InstName.instrument_class
    UNION
    SELECT 6.0 As SortKey, 'LOG ENTRIES' AS Label,
           (CASE WHEN StatsQ.Errors + StatsQ.Warnings > 0 THEN 'Errors / Warnings: ' || (StatsQ.Errors + StatsQ.Warnings)::text ELSE '' END)::citext AS Value
    FROM (  SELECT Sum(Case When type = 'Error' Then 1 Else 0 End) as Errors,
                   Sum(Case When type = 'Warning' Then 1 Else 0 End) as Warnings
            FROM public.t_log_entries
            WHERE entered Between _startDate And _endDate AND type IN ('Error', 'Warning')
         ) StatsQ
    UNION
    SELECT 6.1 As SortKey, '  Warnings' AS Label, COUNT(*)::citext AS Value
    FROM public.t_log_entries
    WHERE entered Between _startDate And _endDate AND type = 'Warning'
    UNION
    SELECT 6.2 As SortKey, '  Errors' AS Label, COUNT(*)::citext AS Value
    FROM public.t_log_entries
    WHERE entered Between _startDate And _endDate AND type = 'Error'
    ;
END
$$;


ALTER FUNCTION public.get_event_log_summary(_startdate timestamp with time zone, _enddate timestamp with time zone) OWNER TO d3l243;

