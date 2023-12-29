--
-- Name: synchronize_job_stats_with_job_steps(boolean, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.synchronize_job_stats_with_job_steps(IN _infoonly boolean DEFAULT true, IN _completedjobsonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make sure job start and finish times agree with job step start and finish times
**
**  Auth:   mem
**  Date:   01/22/2010 mem - Initial version
**          03/10/2014 mem - Fixed logic related to _completedJobsOnly
**          08/08/2023 mem - Handle null values for Start and Finish in sw.t_jobs
**                         - Ported to PostgreSQL
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

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int,
        Start_New timestamp Null,
        Finish_New timestamp Null
    );

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
    WHERE (J.state = 4 AND _completedJobsOnly OR Not _completedJobsOnly) AND
          (J.finish < JS.finish OR
           J.finish IS NULL AND NOT JS.finish IS NULL AND J.state > 2)  -- Do not update Finish for jobs that are New or In Progress
    GROUP BY J.job
    UNION
    SELECT J.job
    FROM sw.t_jobs J
         INNER JOIN sw.t_job_steps JS
           ON J.job = JS.job
    WHERE (J.state = 4 AND _completedJobsOnly OR Not _completedJobsOnly) AND
          (J.start > JS.start OR
           J.start IS NULL AND NOT JS.start IS NULL)
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
    WHERE Tmp_JobsToUpdate.Job = SourceQ.Job;

    If _infoOnly Then

        RAISE INFO '';

        If Not Exists (SELECT job FROM Tmp_JobsToUpdate) THEN
            RAISE INFO 'Did not find any jobs that require updating';
            DROP TABLE Tmp_JobsToUpdate;
            RETURN;
        End If;

        _formatSpecifier := '%-9s %-5s %-20s %-20s %-30s %-30s';

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
                                     '------------------------------',
                                     '------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT J.Job,
                   J.State,
                   public.timestamp_text(J.Start)        AS Start,
                   public.timestamp_text(J.Finish)       AS Finish,
                   public.timestamp_text(JTU.Start_New) ||
                       CASE WHEN J.Start IS NULL AND NOT JTU.Start_New IS NULL THEN ' (was null)'
                            WHEN NOT J.Start IS NULL AND J.Start IS DISTINCT FROM JTU.Start_New THEN ' (updated)'
                            ELSE ''
                       END AS Start_New,
                   CASE WHEN J.State IN (1,2)
                        THEN public.timestamp_text(J.Finish)
                        ELSE public.timestamp_text(JTU.Finish_New) ||
                             CASE WHEN J.Finish IS NULL AND NOT JTU.Finish_New IS NULL THEN ' (was null)'
                                  WHEN NOT J.Finish IS NULL AND J.Finish IS DISTINCT FROM JTU.Finish_New THEN ' (updated)'
                                  ELSE ''
                             END
                   END AS Finish_New
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
            finish = CASE WHEN J.State IN (1,2)
                          THEN J.Finish
                          ELSE JTU.Finish_New
                     END
        FROM Tmp_JobsToUpdate JTU
        WHERE J.Job = JTU.Job AND
              (start  IS DISTINCT FROM JTU.Start_New OR
               finish IS DISTINCT FROM JTU.Finish_New);

    End If;

    DROP TABLE Tmp_JobsToUpdate;

END
$$;


ALTER PROCEDURE sw.synchronize_job_stats_with_job_steps(IN _infoonly boolean, IN _completedjobsonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE synchronize_job_stats_with_job_steps(IN _infoonly boolean, IN _completedjobsonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.synchronize_job_stats_with_job_steps(IN _infoonly boolean, IN _completedjobsonly boolean, INOUT _message text, INOUT _returncode text) IS 'SynchronizeJobStatsWithJobSteps';

