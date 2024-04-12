--
-- Name: set_up_to_extend_existing_job(integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.set_up_to_extend_existing_job(IN _job integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populate temporary table Tmp_Jobs, which must be created by the calling procedure
**
**      CREATE TEMP TABLE Tmp_Jobs (
**          Job int NOT NULL,
**          Priority int NULL,
**          Script citext NULL,
**          State int NOT NULL,
**          Dataset citext NULL,
**          Dataset_ID int NULL,
**          DataPkgID int NULL,
**          Results_Directory_Name citext NULL
**      );
**
**  Arguments:
**    _job          Analysis job number
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   02/03/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          07/31/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- If job is not in main tables, restore it from the history tables
    ---------------------------------------------------

    If Not Exists (SELECT job FROM sw.t_jobs WHERE job = _job) Then
        CALL sw.copy_history_to_job (_job, _message => _message, _returnCode => _returnCode);

        If _returnCode <> '' Then
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Populate Tmp_Jobs using T_Jobs
    ---------------------------------------------------

    INSERT INTO Tmp_Jobs (job, priority, script, state, dataset, dataset_id, results_directory_name)
    SELECT job, priority, script, state, dataset, dataset_id, results_folder_name
    FROM sw.t_jobs
    WHERE job = _job;

END
$$;


ALTER PROCEDURE sw.set_up_to_extend_existing_job(IN _job integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_up_to_extend_existing_job(IN _job integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.set_up_to_extend_existing_job(IN _job integer, INOUT _message text, INOUT _returncode text) IS 'SetUpToExtendExistingJob';

