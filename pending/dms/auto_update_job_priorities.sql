--
CREATE OR REPLACE PROCEDURE public.auto_update_job_priorities
(
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Look for groups of jobs with the default priority (3) and possibly auto-update them to priority 4
**
**      The reason for doing this is to allow certain managers to preferentially process jobs with priorities 1 through 3
**      and predefined jobs, plus manually created small batches of jobs, which will have priority 3
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   10/04/2017 mem - Initial version
**          07/29/2022 mem - No longer filter out null parameter file or settings file names since neither column allows null values
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _activeStepThreshold int := 25;
    _longRunningThreshold int := 10;
    _updateCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------
    -- Validate the inputs
    ----------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ----------------------------------------------
    -- Create temporary tables
    ----------------------------------------------

    CREATE TEMP TABLE Tmp_ProteinCollectionJobs (
        ParamFile text NOT NULL,
        SettingsFile text NOT NULL,
        ProteinCollectionList text NOT NULL
    )

    CREATE TEMP TABLE Tmp_LegacyOrgDBJobs (
        ParamFile text NOT NULL,
        SettingsFile text NOT NULL,
        OrganismDBName text NOT NULL,
    )

    CREATE TEMP TABLE Tmp_Batches (
        BatchID int NOT NULL
    )

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int NOT NULL,
        Old_Priority int NOT NULL,
        New_Priority int NOT NULL,
        Ignored int NOT NULL,
        Source text NULL
    )

    CREATE INDEX IX_Tmp_DatasetsToUpdate ON Tmp_JobsToUpdate (Job)

    ----------------------------------------------
    -- Find candidate jobs to update
    ----------------------------------------------

    -- Active jobs with similar settings (using protein collections)
    --
    INSERT INTO Tmp_ProteinCollectionJobs (ParamFile, SettingsFile, ProteinCollectionList)
    SELECT param_file_name,
           settings_file_name,
           protein_collection_list
    FROM t_analysis_job
    WHERE job_state_id IN (1, 2) AND
          priority = 3 AND
          batch_id > 0 AND
          organism_db_name = 'na' AND
          NOT protein_collection_list IS NULL
    GROUP BY param_file_name, settings_file_name, protein_collection_list
    HAVING COUNT(job) > _activeStepThreshold;

    -- Active jobs with similar settings (using organism DBs)
    --
    INSERT INTO Tmp_LegacyOrgDBJobs (ParamFile, SettingsFile, OrganismDBName)
    SELECT param_file_name,
           settings_file_name,
           organism_db_name
    FROM t_analysis_job
    WHERE job_state_id IN (1, 2) AND
          priority = 3 AND
          batch_id > 0 AND
          organism_db_name <> 'na' AND
          NOT organism_db_name IS NULL
    GROUP BY param_file_name, settings_file_name, organism_db_name
    HAVING COUNT(job) > _activeStepThreshold;

    -- Batches with active, long-running jobs
    --
    INSERT INTO Tmp_Batches(BatchID)
    SELECT J.batch_id
    FROM t_analysis_job J
         INNER JOIN sw.V_Job_Steps JS
           ON J.job = JS.job
    WHERE JS.State = 4 AND
          J.priority = 3 AND
          JS.RunTime_Minutes > 180 AND
          batch_id > 0
    GROUP BY J.batch_id
    HAVING COUNT(JS.step) > _longRunningThreshold;

    ----------------------------------------------
    -- Add candidate jobs to Tmp_JobsToUpdate
    ----------------------------------------------

    INSERT INTO Tmp_JobsToUpdate (job, Old_Priority, New_Priority, Ignored, Source)
    SELECT job, 0 AS Old_Priority, 0 AS New_Priority, 0 AS Ignored, MIN(Source)
    FROM (
        SELECT J.job AS Job,
               format('Over %s active job steps, protein collection based', _activeStepThreshold) AS Source
        FROM t_analysis_job J
                INNER JOIN Tmp_ProteinCollectionJobs Src
                ON J.param_file_name = Src.ParamFile AND
                    J.settings_file_name = Src.SettingsFile AND
                    J.protein_collection_list = Src.ProteinCollectionList
        UNION
        SELECT J.job AS Job,
               format('Over %s active job steps, organism DB based', _activeStepThreshold) AS Source
        FROM t_analysis_job J
                INNER JOIN Tmp_LegacyOrgDBJobs Src
                ON J.param_file_name = Src.ParamFile AND
                    J.settings_file_name = Src.SettingsFile AND
                    J.organism_db_name = Src.OrganismDBName
        UNION
        SELECT J.job AS Job,
               format('Over %s long running job steps (by batch)', _longRunningThreshold) AS Source
        FROM t_analysis_job J
                INNER JOIN Tmp_Batches Src
                ON J.batch_id = Src.BatchID
        ) UnionQ
    GROUP BY job;

    -- Update the old/new priority columns

    UPDATE Tmp_JobsToUpdate Target
    SET Old_Priority = J.Priority::int
        New_Priority = 4
    FROM t_analysis_job J
    WHERE J.job = Target.job;

    -- Ignore any jobs that are already in t_analysis_job_priority_updates

    UPDATE Tmp_JobsToUpdate Target
    SET Ignored = 1
    FROM t_analysis_job_priority_updates JPU
    WHERE Target.job = JPU.job;

    If _infoOnly Then
        ----------------------------------------------
        -- Preview the results
        ----------------------------------------------

        If Not Exists (SELECT * FROM Tmp_JobsToUpdate) Then
            _message := 'No candidate jobs (or ignored jobs) were found';
            RAISE INFO '%', _message;
        Else

            RAISE INFO '';

            _formatSpecifier := '%-80s %-10s %-10s %-10s %-8s %-7s %-60s %-50s %-80s %-50s %-60s';

            _infoHead := format(_formatSpecifier,
                                'Dataset',
                                'Job',
                                'Request_ID',
                                'Batch_ID',
                                'Priority',
                                'Ignored',
                                'Param_File_Name',
                                'Settings_File_Name',
                                'Protein_Collection_List',
                                'Organism_DB_Name',
                                'Source'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------------------------------------------------------------------',
                                         '----------',
                                         '----------',
                                         '----------',
                                         '--------',
                                         '-------',
                                         '------------------------------------------------------------',
                                         '--------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------',
                                         '------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DS.Dataset,
                       J.Job,
                       J.request_id AS RequestID,
                       J.batch_id AS BatchID,
                       J.priority AS Priority,
                       U.Ignored,
                       J.param_file_name,
                       J.settings_file_name,
                       J.protein_collection_list AS ProteinCollectionList,
                       J.organism_db_name AS OrganismDBName,
                       U.Source
                FROM t_analysis_job J
                     INNER JOIN Tmp_JobsToUpdate U
                       ON J.job = U.job
                     INNER JOIN t_dataset DS
                       ON J.dataset_id = DS.dataset_id
                ORDER BY J.batch_id, J.job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset,
                                    _previewData.Job,
                                    _previewData.RequestID,
                                    _previewData.BatchID,
                                    _previewData.Priority,
                                    _previewData.Ignored,
                                    _previewData.Param_File_Name,
                                    _previewData.Settings_File_Name,
                                    _previewData.ProteinCollectionList,
                                    _previewData.OrganismDBName,
                                    _previewData.Source
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        DROP TABLE Tmp_ProteinCollectionJobs;
        DROP TABLE Tmp_LegacyOrgDBJobs;
        DROP TABLE Tmp_Batches;
        DROP TABLE Tmp_JobsToUpdate;
        RETURN;
    End If;

    ----------------------------------------------
    -- Update job priorities
    ----------------------------------------------

    If Not Exists (SELECT * FROM Tmp_JobsToUpdate WHERE Ignored = 0) Then
        _message := 'No candidate jobs were found';
    Else
        INSERT INTO t_analysis_job_priority_updates( job,
                                                     old_priority,
                                                     new_priority,
                                                     comment,
                                                     entered )
        SELECT U.job,
               U.old_priority,
               U.new_priority,
               U.Source,
               CURRENT_TIMESTAMP
        FROM Tmp_JobsToUpdate U
        WHERE U.Ignored = 0

        UPDATE t_analysis_job J
        SET priority = U.New_Priority
        FROM Tmp_JobsToUpdate U
        WHERE J.job = U.Job AND
              U.Ignored = 0;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Updated job priority for %s long running %s', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));

        CALL post_log_entry ('Normal', _message, 'Auto_Update_Job_Priorities');
    End If;

    RAISE INFO '%', _message;

    DROP TABLE Tmp_ProteinCollectionJobs;
    DROP TABLE Tmp_LegacyOrgDBJobs;
    DROP TABLE Tmp_Batches;
    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_update_job_priorities IS 'AutoUpdateJobPriorities';
