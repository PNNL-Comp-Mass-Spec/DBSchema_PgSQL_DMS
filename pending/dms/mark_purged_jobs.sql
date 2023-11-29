--
CREATE OR REPLACE PROCEDURE public.mark_purged_jobs
(
    _jobList text,
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates Purged to be 1 for the jobs in _jobList
**
**      This procedure is called by the Space Manager
**
**  Arguments:
**    _jobList      Comma-separated list of job numbers
**    _infoOnly     When true, preview updates
**
**  Auth:   mem
**  Date:   06/13/2012 grk - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    ---------------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------------

    _jobList  := Trim(Coalesce(_jobList, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------------
    -- Populate a temporary table with the jobs in _jobList
    ---------------------------------------------------------

    CREATE TEMP TABLE Tmp_JobList (
        Job int
    );

    INSERT INTO Tmp_JobList (Job)
    SELECT Value
    FROM public.parse_delimited_integer_list(_jobList);

    If _infoOnly Then
        -- Preview the jobs

        -- ToDo: Show this info using RAISE INFO

        FOR _jobInfo IN
            SELECT J.job AS Job, J.purged AS Job_Purged
            FROM t_analysis_job J INNER JOIN
                 Tmp_JobList L ON J.job = L.job
            ORDER BY job
        LOOP
            ...
            RAISE INFO format(...);
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

COMMENT ON PROCEDURE public.mark_purged_jobs IS 'MarkPurgedJobs';
