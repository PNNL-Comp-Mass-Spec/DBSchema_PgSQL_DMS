--
-- Name: get_job_backlog_on_date_by_result_type(timestamp without time zone, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_job_backlog_on_date_by_result_type(_targetdate timestamp without time zone, _resulttype public.citext DEFAULT 'MSG_Peptide_Hit'::public.citext) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns number of jobs in backlog for given timestamp (date and time)
**      and given result type; wildcards are supported, e.g. '%_Peptide_Hit'
**
**  Arguments:
**    _targetDate   Target date and time,       '2022-04-01 12:00 pm'
**    _resultType   Analysis tool result type,   'MSG_Peptide_Hit', 'SIC', 'SQC', 'HMMA_Peak', 'MXQ_Peptide_Hit', 'MSF_Peptide_Hit', etc.
**
**  Usage examples:
**    SELECT get_job_backlog_on_date_by_result_type('2022-04-11 12:00 pm', 'msg_peptide_hit');
**
**    SELECT get_job_backlog_on_date_by_result_type('2022-04-11 12:00 pm', '%_Peptide_Hit');
**
**    SELECT SampleTime, get_job_backlog_on_date_by_result_type(SampleTime, '%_Peptide_Hit')
**    FROM generate_series('2022-04-01'::timestamp, '2022-04-04'::timestamp, '6 hours'::interval) SampleTime
**    ORDER BY SampleTime;
**
**    SELECT Day::date, get_job_backlog_on_date_by_result_type(Day::timestamp, '%_Peptide_Hit')
**    FROM generate_series('2022-01-01'::date, '2022-01-30'::date, Interval '1 day') as Day
**    ORDER BY Day;
**
**  Auth:   grk
**  Date:   01/21/2005
**          01/22/2005 mem - Added two additional parameters
**          01/25/2005 grk - Modified to use result type
**          06/23/2022 mem - Ported to PostgreSQL
**                         - Removed argument _processorNameFilter since all jobs are processed by the Job Broker
**          07/12/2022 mem - Renamed function and added another usage example
**          05/22/2023 mem - Capitalize reserved word
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _backlog integer;
BEGIN
    SELECT COUNT(job)
    INTO _backlog
    FROM t_analysis_job
    WHERE extract(epoch FROM (finish - _targetDate)) / 3600.0 >= 0 AND
          extract(epoch FROM (created - _targetDate)) / 3600.0 <= 0 AND
          job_state_id = 4 AND
          analysis_tool_id IN ( SELECT analysis_tool_id
                                FROM t_analysis_tool
                                WHERE result_type LIKE _resultType );

    RETURN Coalesce(_backlog, 0);
END
$$;


ALTER FUNCTION public.get_job_backlog_on_date_by_result_type(_targetdate timestamp without time zone, _resulttype public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_backlog_on_date_by_result_type(_targetdate timestamp without time zone, _resulttype public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_job_backlog_on_date_by_result_type(_targetdate timestamp without time zone, _resulttype public.citext) IS 'JobBacklogOnDateByResultType';

