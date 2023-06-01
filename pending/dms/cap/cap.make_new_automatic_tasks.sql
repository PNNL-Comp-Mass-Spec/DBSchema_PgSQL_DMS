--
CREATE OR REPLACE PROCEDURE cap.make_new_automatic_tasks()
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create new capture task jobs for capture tasks that are complete
**      and have scripts that have entries in the
**      automatic capture task job creation table
**
**  Auth:   grk
**  Date:   09/11/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/26/2017 mem - Add support for column Enabled in T_Automatic_Jobs
**          01/29/2021 mem - Remove unused parameters
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    -- Find capture task jobs that are complete for which capture task jobs for the same script and dataset don't already exist

    -- In particular, after a DatasetArchive task finishes, create new SourceFileRename and MyEMSLVerify capture task jobs
    -- (since that relationship is defined in cap.t_automatic_jobs)

    INSERT INTO cap.t_tasks ( Script, Dataset, Dataset_ID, Comment )
    SELECT AJ.script_for_new_job AS Script,
           T.Dataset,
           T.Dataset_ID,
           format('Created from capture task job %s', T.Job) AS comment
    FROM cap.t_tasks AS T
         INNER JOIN cap.t_automatic_jobs AJ
           ON T.Script = AJ.script_for_completed_job AND
              AJ.enabled = 1
    WHERE T.State = 3 AND
          NOT EXISTS ( SELECT *
                       FROM cap.t_tasks
                       WHERE Script = script_for_new_job AND
                             Dataset = T.Dataset );

END
$$;

COMMENT ON PROCEDURE cap.make_new_automatic_tasks IS 'MakeNewAutomaticJobs';
