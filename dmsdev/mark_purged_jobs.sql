--
-- Name: mark_purged_jobs(text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.mark_purged_jobs(IN _joblist text, IN _infoonly boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update purged to be 1 for the jobs in _jobList
**
**      This procedure is called by the Space Manager
**
**  Arguments:
**    _jobList      Comma-separated list of job numbers
**    _infoOnly     When true, preview updates
**
**  Auth:   mem
**  Date:   06/13/2012 grk - Initial version
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobList  := Trim(Coalesce(_jobList, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Populate a temporary table with the jobs in _jobList
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobList (
        Job int
    );

    INSERT INTO Tmp_JobList (Job)
    SELECT Value
    FROM public.parse_delimited_integer_list(_jobList);

    If _infoOnly Then
        -- Preview the jobs

        RAISE INFO '';

        _formatSpecifier := '%-10s %-12s %-20s %-20s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Job_State_ID',
                            'Start',
                            'Finish',
                            'Job_Purged'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '------------',
                                     '--------------------',
                                     '--------------------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT J.job,
                   J.job_state_id,
                   public.timestamp_text(J.start) AS start,
                   public.timestamp_text(J.finish) AS finish,
                   J.purged
            FROM t_analysis_job J
                 INNER JOIN Tmp_JobList L
                   ON J.job = L.job
            ORDER BY job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.job,
                                _previewData.job_state_id,
                                _previewData.start,
                                _previewData.finish,
                                _previewData.purged
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        -- Update purged jobs

        UPDATE t_analysis_job
        SET purged = 1
        FROM Tmp_JobList JL
        WHERE JL.job = t_analysis_job.job AND
              t_analysis_job.purged = 0;

    End If;

    DROP TABLE Tmp_JobList;
END
$$;


ALTER PROCEDURE public.mark_purged_jobs(IN _joblist text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE mark_purged_jobs(IN _joblist text, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.mark_purged_jobs(IN _joblist text, IN _infoonly boolean) IS 'MarkPurgedJobs';

