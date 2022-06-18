--
-- Name: get_aj_processor_group_associated_jobs(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aj_processor_group_associated_jobs(_groupid integer, _jobstatefilter integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets jobs associated with given group
**
**  Return value: comma separated list
**
**  Arguments:
**    _jobStateFilter   0 means new only, 1 means new and in progress only, anything else means all states
**
**  Auth:   grk
**  Date:   02/16/2007
**          02/23/2007 mem - Added parameter _jobStateFilter
**          06/17/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
    _resultAppend text;
BEGIN
    _jobStateFilter := Coalesce(_jobStateFilter, 2);
    _result := '';

    If _jobStateFilter = 0 Then
        SELECT string_agg(JS.job_state || ': ' || COUNT(AJPGA.job)::text, ', ' ORDER BY AJ.job_state_id)
        INTO _result
        FROM t_analysis_job_processor_group_associations AJPGA INNER JOIN
             t_analysis_job AJ ON AJPGA.job = AJ.job INNER JOIN
             t_analysis_job_state JS ON AJ.job_state_id = JS.job_state_id
        WHERE AJPGA.group_id = _groupID AND AJ.job_state_id IN (1, 8, 10)
        GROUP BY JS.job_state, AJ.job_state_id;
    End If;

    If _jobStateFilter = 1 Then
        SELECT string_agg(JS.job_state + ': ' + COUNT(AJPGA.job)::text, ', ' ORDER BY AJ.job_state_id)
        INTO _resultAppend
        FROM t_analysis_job_processor_group_associations AJPGA INNER JOIN
            t_analysis_job AJ ON AJPGA.job = AJ.job INNER JOIN
            t_analysis_job_state JS ON AJ.job_state_id = JS.job_state_id
        WHERE AJPGA.group_id = _groupID AND AJ.job_state_id IN (1, 2, 3, 8, 9, 10, 11, 16, 17)
        GROUP BY JS.job_state, AJ.job_state_id;

        If Coalesce(_resultAppend, '') <> '' Then
            If _result <> '' THEN
                _result := _result || ', ';
            End If;

            _result := _result || ', ' || _resultAppend;
        End If;
    End If;

    If _jobStateFilter Not In (0, 1) Then
        _resultAppend := '';

        SELECT string_agg(JS.job_state + ': ' + COUNT(AJPGA.job)::text, ', ' ORDER BY AJ.job_state_id)
        INTO _resultAppend
        FROM t_analysis_job_processor_group_associations AJPGA INNER JOIN
             t_analysis_job AJ ON AJPGA.job = AJ.job INNER JOIN
             t_analysis_job_state JS ON AJ.job_state_id = JS.job_state_id
        WHERE AJPGA.group_id = _groupID
        GROUP BY JS.job_state, AJ.job_state_id;

        If Coalesce(_resultAppend, '') <> '' Then
            If _result <> '' THEN
                _result := _result || ', ';
            End If;

            _result := _result || ', ' || _resultAppend;
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

