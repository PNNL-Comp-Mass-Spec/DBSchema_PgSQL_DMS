--
CREATE OR REPLACE PROCEDURE sw.synchronize_job_stats_with_job_steps
(
    _infoOnly boolean = true,
    _completedJobsOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Makes sure the job stats (start and finish)
**      agree with the job steps for the job
**
**  Auth:   mem
**  Date:   01/22/2010 mem - Initial version
**          03/10/2014 mem - Fixed logic related to _completedJobsOnly
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode:= '';

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int,
        StartNew timestamp Null,
        FinishNew timestamp Null
    )

    CREATE UNIQUE INDEX IX_Tmp_JobsToUpdate ON Tmp_JobsToUpdate (Job);

    ---------------------------------------------------
    -- Find jobs that need to be updated
    -- When _completedJobsOnly is true, filter on job state 4=Complete
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToUpdate ( job )
    SELECT J.job
    FROM sw.t_jobs J
         INNER JOIN sw.t_job_steps JS
           ON J.job = JS.job
    WHERE (J.state = 4 And _completedJobsOnly OR Not _completedJobsOnly) AND
          J.finish < JS.finish
    GROUP BY J.job
    UNION
    SELECT J.job
    FROM sw.t_jobs J
         INNER JOIN sw.t_job_steps JS
           ON J.job = JS.job
    WHERE (J.state = 4 And _completedJobsOnly OR Not _completedJobsOnly) AND
          J.start > JS.start
    GROUP BY J.job
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    UPDATE Tmp_JobsToUpdate
    SET StartNew = SourceQ.Step_Start,
        FinishNew = SourceQ.Step_Finish
    FROM Tmp_JobsToUpdate

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_JobsToUpdate
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_JobsToUpdate.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT J.job,
                             MIN(JS.start) AS Step_Start,
                             MAX(JS.finish) AS Step_Finish
                      FROM sw.t_jobs J
                           INNER JOIN sw.t_job_steps JS
                             ON J.job = JS.job
                      WHERE J.job IN ( SELECT job
                                       FROM Tmp_JobsToUpdate )

                                       /********************************************************************************
                                       ** This UPDATE query includes the target table name in the FROM clause
                                       ** The WHERE clause needs to have a self join to the target table, for example:
                                       **   UPDATE Tmp_JobsToUpdate
                                       **   SET ...
                                       **   FROM source
                                       **   WHERE source.id = Tmp_JobsToUpdate.id;
                                       ********************************************************************************/

                                                              ToDo: Fix this query

                      GROUP BY J.Job
                    ) SourceQ
           ON Tmp_JobsToUpdate.Job = SourceQ.Job
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        -- ToDo: Use Raise Info

        SELECT J.Job,
               J.state,
               J.start,
               J.finish,
               JTU.StartNew,
               JTU.FinishNew
        FROM sw.t_jobs J
             INNER JOIN Tmp_JobsToUpdate JTU
               ON J.job = JTU.job
    Else

        ---------------------------------------------------
        -- Update the Start/Finish times
        ---------------------------------------------------

        UPDATE sw.t_jobs
        SET start = JTU.StartNew,
            finish = JTU.FinishNew
        FROM sw.t_jobs J

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE sw.t_jobs
        **   SET ...
        **   FROM source
        **   WHERE source.id = sw.t_jobs.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN Tmp_JobsToUpdate JTU
               ON J.Job = JTU.Job

    End If;

    DROP TABLE Tmp_JobsToUpdate;

END
$$;

COMMENT ON PROCEDURE sw.synchronize_job_stats_with_job_steps IS 'SynchronizeJobStatsWithJobSteps';
