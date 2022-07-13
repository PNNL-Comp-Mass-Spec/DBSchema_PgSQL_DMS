--
-- Name: get_job_backlog_on_date_by_tool(timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_backlog_on_date_by_tool(_targetdate timestamp without time zone, _analysistoolid integer DEFAULT 1) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns number of jobs in backlog for given timestamp (date and time)
**      and given analysis tool id
**
**  Arguments:
**    _targetDate       Target date and time,       '2022-04-01 12:00 pm'
**    _analysisToolID   Tool ID, e.g. 13 = MASIC_Finnigan, 68 = MSGFPlus_MzML, 69 = MSGFPlus_MzML_NoRefine, 83 = TopPIC, 88 = MSFragger, 91 = MaxQuant
**
**  Usage examples:
**    SELECT get_job_backlog_on_date_by_tool('2022-04-11 12:00 pm', 68);
**
**    SELECT get_job_backlog_on_date_by_tool('2022-04-11 12:00 pm', 69);
**
**    SELECT SampleTime, get_job_backlog_on_date_by_tool(SampleTime, 68)
**    FROM generate_series('2022-04-01'::timestamp, '2022-04-04'::timestamp, '6 hours'::interval) SampleTime
**    ORDER BY SampleTime;
**
**    SELECT Day, get_job_backlog_on_date_by_tool(Day::timestamp, 69)
**    FROM generate_series('2022-01-01'::date, '2022-01-30'::date, Interval '1 day') as Day
**    ORDER BY Day;
**
**  Auth:   grk
**  Date:   01/21/2005
**          01/22/2005 mem - Added two additional parameters
**          06/23/2022 mem - Ported to PostgreSQL
**                         - Removed argument _processorNameFilter since all jobs are processed by the Job Broker
**          07/12/2022 mem - Renamed function and added another usage example
**
*****************************************************/
DECLARE
    _backlog integer;
BEGIN
    SELECT count(*)
    INTO _backlog
    FROM t_analysis_job
    WHERE extract(epoch FROM (finish - _targetDate)) / 3600.0 >= 0 AND
          extract(epoch FROM (created - _targetDate)) / 3600.0 <= 0 AND
          job_state_id = 4 AND
          analysis_tool_id = _analysisToolID;

    RETURN _backlog;
END
$$;


ALTER FUNCTION public.get_job_backlog_on_date_by_tool(_targetdate timestamp without time zone, _analysistoolid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_backlog_on_date_by_tool(_targetdate timestamp without time zone, _analysistoolid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_backlog_on_date_by_tool(_targetdate timestamp without time zone, _analysistoolid integer) IS 'JobBacklogOnDateByTool';

