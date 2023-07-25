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
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
]
    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int,
        Start_New timestamp Null,
        Finish_New timestamp Null
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
    GROUP BY J.job;

    UPDATE Tmp_JobsToUpdate
    SET Start_New = SourceQ.Step_Start,
        Finish_New = SourceQ.Step_Finish
    FROM ( SELECT J.job,
                  MIN(JS.start) AS Step_Start,
                  MAX(JS.finish) AS Step_Finish
           FROM sw.t_jobs J
                INNER JOIN sw.t_job_steps JS
                  ON J.job = JS.job
           WHERE J.job IN ( SELECT job FROM Tmp_JobsToUpdate )
           GROUP BY J.Job
         ) SourceQ
    WHERE Tmp_JobsToUpdate.Job = SourceQ.Job

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-5s %-20s %-20s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'State',
                            'Start',
                            'Finish',
                            'Start_New',
                            'Finish_New'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '-----',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT J.Job,
                   J.State,
                   public.timestamp_text(J.Start)        AS Start,
                   public.timestamp_text(J.Finish)       AS Finish,
                   public.timestamp_text(JTU.Start_New)  AS Start_New,
                   public.timestamp_text(JTU.Finish_New) AS Finish_New
            FROM sw.t_jobs J
                 INNER JOIN Tmp_JobsToUpdate JTU
                   ON J.job = JTU.job
            ORDER BY J.job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.State,
                                _previewData.Start,
                                _previewData.Finish,
                                _previewData.Start_New,
                                _previewData.Finish_New
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else

        ---------------------------------------------------
        -- Update the Start/Finish times
        ---------------------------------------------------

        UPDATE sw.t_jobs J
        SET start = JTU.Start_New,
            finish = JTU.Finish_New
        FROM Tmp_JobsToUpdate JTU
        WHERE J.Job = JTU.Job;

    End If;

    DROP TABLE Tmp_JobsToUpdate;

END
$$;

COMMENT ON PROCEDURE sw.synchronize_job_stats_with_job_steps IS 'SynchronizeJobStatsWithJobSteps';
