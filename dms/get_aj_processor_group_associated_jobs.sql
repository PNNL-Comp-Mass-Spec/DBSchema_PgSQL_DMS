--
-- Name: get_aj_processor_group_associated_jobs(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aj_processor_group_associated_jobs(_groupid integer, _jobstatefilter integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get jobs associated with given group
**
**  Return value: comma-separated list
**
**  Arguments:
**    _jobStateFilter   0 means new only, 1 means new and in progress only, anything else means all states
**
**  Auth:   grk
**  Date:   02/16/2007
**          02/23/2007 mem - Added parameter _jobStateFilter
**          06/17/2022 mem - Ported to PostgreSQL
**          07/06/2022 mem - Move Group By queries into subqueries
**          05/05/2023 mem - Change table alias name
**          05/24/2023 mem - Use format() for string concatenation
**          05/30/2023 mem - Use append_to_text() for string concatenation
**          06/16/2023 mem - Use named arguments when calling append_to_text()
**
*****************************************************/
DECLARE
    _result text;
    _resultAppend text;
BEGIN
    _jobStateFilter := Coalesce(_jobStateFilter, 2);
    _result := '';

    If _jobStateFilter = 0 Then
        SELECT string_agg(format('%s: %s', CountQ.job_state, CountQ.Jobs), ', ' ORDER BY CountQ.job_state_id)
        INTO _result
        FROM (
            SELECT AJS.job_state, J.job_state_id, COUNT(AJPGA.job) AS Jobs
            FROM t_analysis_job_processor_group_associations AJPGA INNER JOIN
                 t_analysis_job J ON AJPGA.job = J.job INNER JOIN
                 t_analysis_job_state AJS ON J.job_state_id = AJS.job_state_id
            WHERE AJPGA.group_id = _groupID AND J.job_state_id IN (1, 8, 10)
            GROUP BY AJS.job_state, J.job_state_id) CountQ;
    End If;

    If _jobStateFilter = 1 Then
        SELECT string_agg(format('%s: %s', CountQ.job_state, CountQ.Jobs), ', ' ORDER BY CountQ.job_state_id)
        INTO _resultAppend
        FROM (
            SELECT AJS.job_state, J.job_state_id, COUNT(AJPGA.job) AS Jobs
            FROM t_analysis_job_processor_group_associations AJPGA INNER JOIN
                t_analysis_job J ON AJPGA.job = J.job INNER JOIN
                t_analysis_job_state AJS ON J.job_state_id = AJS.job_state_id
            WHERE AJPGA.group_id = _groupID AND J.job_state_id IN (1, 2, 3, 8, 9, 10, 11, 16, 17)
            GROUP BY AJS.job_state, J.job_state_id) CountQ;

        If Coalesce(_resultAppend, '') <> '' Then
            _result := public.append_to_text(_result, _resultAppend, _delimiter => ', ');
        End If;

    End If;

    If Not _jobStateFilter In (0, 1) Then
        _resultAppend := '';

        SELECT string_agg(format('%s: %s', CountQ.job_state, CountQ.Jobs), ', ' ORDER BY CountQ.job_state_id)
        INTO _resultAppend
        FROM (
            SELECT AJS.job_state, J.job_state_id, COUNT(AJPGA.job) AS Jobs
            FROM t_analysis_job_processor_group_associations AJPGA INNER JOIN
                 t_analysis_job J ON AJPGA.job = J.job INNER JOIN
                 t_analysis_job_state AJS ON J.job_state_id = AJS.job_state_id
            WHERE AJPGA.group_id = _groupID
            GROUP BY AJS.job_state, J.job_state_id) CountQ;

        If Coalesce(_resultAppend, '') <> '' Then
            _result := public.append_to_text(_result, _resultAppend, _delimiter => ', ');
        End If;
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_aj_processor_group_associated_jobs(_groupid integer, _jobstatefilter integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_aj_processor_group_associated_jobs(_groupid integer, _jobstatefilter integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_aj_processor_group_associated_jobs(_groupid integer, _jobstatefilter integer) IS 'GetAJProcessorGroupAssociatedJobs';

