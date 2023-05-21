--
CREATE OR REPLACE PROCEDURE sw.set_up_to_extend_existing_job
(
    _job int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populuates temporary table Tmp_Jobs
**      The calling procedure must create table Tmp_Jobs
**
**      CREATE TEMP TABLE Tmp_Jobs (
**          Job int NOT NULL,
**          Priority int NULL,
**           Script citext NULL,
**          State int NOT NULL,
**          Dataset citext NULL,
**          Dataset_ID int NULL,
**          DataPkgID int NULL,
**          Results_Directory_Name citext NULL
**      );
**
**  Auth:   grk
**  Date:   02/03/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- If job not in main tables,
    -- restore it from most recent successful historic job.
    ---------------------------------------------------
    --
    CALL sw.copy_history_to_job (_job, _message => _message, _returnCode => _returnCode);
    --
    If _returnCode <> '' Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate Tmp_Jobs using T_Jobs
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Jobs (job, priority, script, state, dataset, dataset_id, results_directory_name)
    SELECT job, priority, script, state, dataset, dataset_id, results_folder_name
    FROM sw.t_jobs
    WHERE job = _job;

END
$$;

COMMENT ON PROCEDURE sw.set_up_to_extend_existing_job IS 'SetUpToExtendExistingJob';

