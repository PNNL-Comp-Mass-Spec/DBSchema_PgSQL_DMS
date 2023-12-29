--
-- Name: get_new_job_id_block(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_new_job_id_block(_jobcount integer, _note text) RETURNS TABLE(job integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get a series of unique numbers for making new analysis jobs
**      Accomplishes this by appending new rows to table t_analysis_job_id
**
**  Example usage:
**
**      CREATE TEMP TABLE Tmp_Jobs (Job int);
**
**      INSERT INTO Tmp_Jobs (Job)
**      SELECT job
**      FROM public.get_new_job_id_block(4, 'Created in t_analysis_job');
**
**      INSERT INTO Tmp_Jobs (Job)
**      SELECT job
**      FROM public.get_new_job_id_block(1, 'Created in sw.t_jobs');
**
**  Arguments:
**    _jobCount   Number of jobs to make
**    _note       Text to store in the "note" column in t_analysis_job_id
**
**  Auth:   mem
**  Date:   08/05/2009 mem - Initial release (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          10/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN

    If _jobCount < 1 Then
        RAISE INFO '_jobCount is zero or negative; nothing to do';
        RETURN;
    End If;

    RETURN QUERY
    WITH InsertQ AS (
        INSERT INTO t_analysis_job_id ( note )
        SELECT Coalesce(_note, '') AS Note
        FROM generate_series(1, _jobCount)
        RETURNING t_analysis_job_id.job
    )
    SELECT InsertQ.job
    FROM InsertQ
    ORDER BY InsertQ.Job;

END
$$;


ALTER FUNCTION public.get_new_job_id_block(_jobcount integer, _note text) OWNER TO d3l243;

--
-- Name: FUNCTION get_new_job_id_block(_jobcount integer, _note text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_new_job_id_block(_jobcount integer, _note text) IS 'GetNewJobIDBlock';

