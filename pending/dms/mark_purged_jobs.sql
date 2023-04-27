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
**      This procedure is called by the SpaceManager
**
**  Auth:   mem
**  Date:   06/13/2012
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    ---------------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------------
    --

    _jobList := Coalesce(_jobList, '');
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------------
    -- Populate a temporary table with the jobs in _jobList
    ---------------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_JobList (
        Job int
    )

    INSERT INTO Tmp_JobList (Job)
    SELECT Value
    FROM public.parse_delimited_integer_list(_jobList, ',')

    If _infoOnly Then
        -- Preview the jobs
        --
        SELECT J.job AS Job, J.AJ_Purged as Job_Purged
        FROM t_analysis_job J INNER JOIN
             Tmp_JobList L ON J.job = L.job
        ORDER BY job
    Else
        -- Update AJ_Purged
        --
        UPDATE t_analysis_job
        SET purged = 1
        FROM t_analysis_job J INNER JOIN

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_analysis_job
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_analysis_job.id;
        ********************************************************************************/

                               ToDo: Fix this query

             Tmp_JobList L ON J.job = L.Job
        WHERE J.AJ_Purged = 0

    End If;

    DROP TABLE Tmp_JobList;
END
$$;

COMMENT ON PROCEDURE public.mark_purged_jobs IS 'MarkPurgedJobs';
