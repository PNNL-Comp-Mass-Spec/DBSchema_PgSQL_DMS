--
CREATE OR REPLACE PROCEDURE sw.finish_job_creation
(
    _job int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Perform a mixed bag of operations on the jobs
**      in the temporary tables to finalize them before
**      copying to the main database tables
**
**  Auth:   grk
**  Date:   01/31/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/06/2009 grk - added code for: Special = 'Job_Results'
**          07/31/2009 mem - Now filtering by job in the subquery that looks for job steps with flag Special = 'Job_Results' (necessary when Tmp_Job_Steps contains more than one job)
**          03/21/2011 mem - Added support for Special = 'ExtractSourceJobFromComment'
**          03/22/2011 mem - Now calling AddUpdateJobParameterTempTable
**          04/04/2011 mem - Removed SourceJob code since needs to occur after T_Job_Parameters has been updated for this job
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/13/2023 mem - Update Special="Job_Results" comment to mention ProMex
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Update step dependency count
    ---------------------------------------------------
    --
    UPDATE Tmp_Job_Steps
    SET Dependencies = T.dependencies
    FROM ( SELECT Step,
                  COUNT(*) AS dependencies
           FROM Tmp_Job_Step_Dependencies
           WHERE (Job = _job)
           GROUP BY Step
         ) AS T
    WHERE T.Step = Tmp_Job_Steps.Step AND
          Tmp_Job_Steps.Job = _job;

    ---------------------------------------------------
    -- Initialize the input folder to an empty string
    -- for steps that have no dependencies
    ---------------------------------------------------
    --
    UPDATE Tmp_Job_Steps
    SET Input_Folder_Name = ''
    WHERE Job = _job AND
          Dependencies = 0;

    ---------------------------------------------------
    -- Set results directory name for the job to be that of
    -- the output folder for any step designated as
    -- Special = 'Job_Results'
    --
    -- This will only affect jobs that have a step with
    -- the Special_Instructions = 'Job_Results' attribute
    --
    -- Scripts MSXML_Gen, DTA_Gen, and ProMex use this since they
    -- produce a shared results directory, yet we also want
    -- the results directory for the job to show the shared results directory name
    ---------------------------------------------------
    --
    UPDATE Tmp_Jobs
    SET Results_Directory_Name = TZ.Output_Directory_Name
    FROM (
            SELECT Job, Output_Directory_Name
            FROM Tmp_Job_Steps
            WHERE Job = _job AND
                  Special_Instructions::citext = 'Job_Results'
            ORDER BY Step
            LIMIT 1;
        ) TZ
    WHERE Tmp_Jobs.Job = TZ.Job;

    ---------------------------------------------------
    -- Set job to initialized state ('New')
    ---------------------------------------------------
    --
    UPDATE Tmp_Jobs
    SET State = 1
    WHERE Job = _job;

END
$$;

COMMENT ON PROCEDURE sw.finish_job_creation IS 'FinishJobCreation';

