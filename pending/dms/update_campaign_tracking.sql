--
CREATE OR REPLACE PROCEDURE public.update_campaign_tracking()
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates summary stats in T_Campaign_Tracking
**
**  Auth:   grk
**  Date:   10/20/2002
**          11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**          01/18/2010 grk - Added update for run requests and sample prep requests (http://prismtrac.pnl.gov/trac/ticket/753)
**          01/25/2010 grk - Added 'most recent activity' (http://prismtrac.pnl.gov/trac/ticket/753)
**          04/15/2015 mem - Added Data_Package_Count
**          08/29/2018 mem - Added Sample_Submission_Count and Sample_Submission_Most_Recent
**          08/30/2018 mem - Use merge instead of truncate
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Create a temporary table to hold the stats
    ----------------------------------------------------------

    CREATE TEMP TABLE Tmp_CampaignStats (
        Campaign_ID int NOT NULL,
        Sample_Submission_Count int NOT NULL,
        Biomaterial_Count int NOT NULL,
        Experiment_Count int NOT NULL,
        Dataset_Count int NOT NULL,
        Job_Count int NOT NULL,
        Run_Request_Count int NOT NULL,
        Sample_Prep_Request_Count int NOT NULL,
        Data_Package_Count int NOT NULL,
        Sample_Submission_Most_Recent timestamp NULL,
        Biomaterial_Most_Recent timestamp NULL,
        Experiment_Most_Recent timestamp NULL,
        Dataset_Most_Recent timestamp NULL,
        Job_Most_Recent timestamp NULL,
        Run_Request_Most_Recent timestamp NULL,
        Sample_Prep_Request_Most_Recent timestamp NULL,
        Most_Recent_Activity timestamp NULL,
        CONSTRAINT PK_Tmp_CampaignStats PRIMARY KEY (Campaign_ID ASC)
    );

    ----------------------------------------------------------
    -- Make entry in results table for each campaign
    ----------------------------------------------------------

    INSERT INTO Tmp_CampaignStats( campaign_id,
                                   Most_Recent_Activity,
                                   Sample_Submission_Count,
                                   Biomaterial_Count,
                                   Experiment_Count,
                                   Dataset_Count,
                                   Job_Count,
                                   Run_Request_Count,
                                   Sample_Prep_Request_Count,
                                   Data_Package_Count )
    SELECT campaign_id,
           created AS Most_Recent_Activity,
           0, 0, 0, 0, 0, 0, 0, 0
    FROM t_campaign;

    ----------------------------------------------------------
    -- Update sample submission statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Sample_Submission_Count = S.Cnt,
        Sample_Submission_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_campaign.campaign_id,
                             COUNT(t_sample_submission.submission_id) AS Cnt,
                             MAX(t_sample_submission.created) AS Most_Recent
                      FROM t_campaign
                           INNER JOIN t_sample_submission
                             ON t_campaign.campaign_id = t_sample_submission.campaign_id
                      GROUP BY t_campaign.campaign_id ) AS S
           ON Tmp_CampaignStats.campaign_id = S.campaign_id

    ----------------------------------------------------------
    -- Update biomaterial statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Biomaterial_Count = S.Cnt,
        Biomaterial_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_campaign.campaign_id,
                             COUNT(T_Biomaterial.Biomaterial_ID) AS Cnt,
                             MAX(T_Biomaterial.Created) AS Most_Recent
                      FROM t_campaign
                           INNER JOIN T_Biomaterial
                             ON t_campaign.campaign_id = T_Biomaterial.Campaign_ID
                      GROUP BY t_campaign.campaign_id ) AS S
           ON Tmp_CampaignStats.campaign_id = S.campaign_id

    ----------------------------------------------------------
    -- Update experiment statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Experiment_Count = S.Cnt,
        Experiment_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_campaign.campaign_id,
                             COUNT(t_experiments.exp_id) AS cnt,
                             MAX(t_experiments.created) AS Most_Recent
                      FROM t_campaign
                           INNER JOIN t_experiments
                             ON t_campaign.campaign_id = t_experiments.campaign_id
                      GROUP BY t_campaign.campaign_id ) AS S
           ON Tmp_CampaignStats.campaign_id = S.campaign_id

    ----------------------------------------------------------
    -- Update dataset statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Dataset_Count = S.Cnt,
        Dataset_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_campaign.campaign_id,
                             COUNT(t_dataset.dataset_id) AS Cnt,
                             MAX(t_dataset.created) AS Most_Recent
                      FROM t_experiments
                           INNER JOIN t_dataset
                             ON t_experiments.exp_id = t_dataset.exp_id
                           INNER JOIN t_campaign
                             ON t_experiments.campaign_id = t_campaign.campaign_id
                      GROUP BY t_campaign.campaign_id ) AS S
           ON Tmp_CampaignStats.campaign_id = S.campaign_id

    ----------------------------------------------------------
    -- Update analysis statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Job_Count = S.Cnt,
        Job_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_campaign.campaign_id,
                             COUNT(t_analysis_job.job) AS Cnt,
                             MAX(t_analysis_job.created) AS Most_Recent
                      FROM t_experiments
                           INNER JOIN t_dataset
                             ON t_experiments.exp_id = t_dataset.exp_id
                           INNER JOIN t_analysis_job
                             ON t_dataset.dataset_id = t_analysis_job.dataset_id
                           INNER JOIN t_campaign
                             ON t_experiments.campaign_id = t_campaign.campaign_id
                      GROUP BY t_campaign.campaign_id ) AS S
           ON Tmp_CampaignStats.campaign_id = S.campaign_id

    ----------------------------------------------------------
    -- Update requested run statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Run_Request_Count = S.cnt,
        Run_Request_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_experiments.campaign_id AS ID,
                             COUNT(t_requested_run.request_id) AS cnt,
                             MAX(t_requested_run.created) AS Most_Recent
                      FROM t_requested_run
                           INNER JOIN t_experiments
                             ON t_requested_run.exp_id = t_experiments.exp_id
                      GROUP BY t_experiments.campaign_id ) AS S
           ON S.request_id = Tmp_CampaignStats.campaign_id

    ----------------------------------------------------------
    -- Update sample prep statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Sample_Prep_Request_Count = S.cnt,
        Sample_Prep_Request_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM Tmp_CampaignStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CampaignStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CampaignStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT t_campaign.campaign_id AS ID,
                             COUNT(t_sample_prep_request.prep_request_id) AS cnt,
                             MAX(t_sample_prep_request.created) AS Most_Recent
                      FROM t_sample_prep_request
                           INNER JOIN t_campaign
                             ON t_sample_prep_request.campaign = t_campaign.campaign
                      GROUP BY t_campaign.campaign_id ) AS S
           ON S.prep_request_id = Tmp_CampaignStats.campaign_id

    ----------------------------------------------------------
    -- Update Data Package counts
    ----------------------------------------------------------

    UPDATE t_campaign_tracking
    SET data_package_count = S.cnt
    FROM t_campaign_tracking

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE t_campaign_tracking
    **   SET ...
    **   FROM source
    **   WHERE source.id = t_campaign_tracking.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT E.campaign_id ID,
                             COUNT(DISTINCT Data_Package_ID) AS cnt
                      FROM S_V_Data_Package_Experiments_Export DPE
                           INNER JOIN t_experiments E
                             ON E.exp_id = DPE.Experiment_ID
                      GROUP BY E.campaign_id ) AS S
           ON S.ID = t_campaign_tracking.campaign_id

    ----------------------------------------------------------
    -- Update t_campaign_tracking using Tmp_CampaignStats
    ----------------------------------------------------------

    MERGE INTO t_campaign_tracking AS T
    USING ( SELECT * FROM Tmp_CampaignStats
          ) AS s
    ON (t.campaign_id = s.campaign_id)
    WHEN MATCHED AND
         (t.biomaterial_count <> s.biomaterial_count OR
          t.experiment_count <> s.experiment_count OR
          t.dataset_count <> s.dataset_count OR
          t.job_count <> s.job_count OR
          t.run_request_count <> s.run_request_count OR
          t.sample_prep_request_count <> s.sample_prep_request_count OR
          t.sample_submission_count         IS DISTINCT FROM s.sample_submission_count OR
          t.data_package_count              IS DISTINCT FROM s.data_package_count OR
          t.sample_submission_most_recent   IS DISTINCT FROM s.sample_submission_most_recent OR
          t.biomaterial_most_recent         IS DISTINCT FROM s.biomaterial_most_recent OR
          t.experiment_most_recent          IS DISTINCT FROM s.experiment_most_recent OR
          t.dataset_most_recent             IS DISTINCT FROM s.dataset_most_recent OR
          t.job_most_recent                 IS DISTINCT FROM s.job_most_recent OR
          t.run_request_most_recent         IS DISTINCT FROM s.run_request_most_recent OR
          t.sample_prep_request_most_recent IS DISTINCT FROM s.sample_prep_request_most_recent OR
          t.most_recent_activity            IS DISTINCT FROM s.most_recent_activity) THEN
        UPDATE SET
            sample_submission_count = s.sample_submission_count,
            biomaterial_count = s.biomaterial_count,
            experiment_count = s.experiment_count,
            dataset_count = s.dataset_count,
            job_count = s.job_count,
            run_request_count = s.run_request_count,
            sample_prep_request_count = s.sample_prep_request_count,
            data_package_count = s.data_package_count,
            sample_submission_most_recent = s.sample_submission_most_recent,
            biomaterial_most_recent = s.biomaterial_most_recent,
            experiment_most_recent = s.experiment_most_recent,
            dataset_most_recent = s.dataset_most_recent,
            job_most_recent = s.job_most_recent,
            run_request_most_recent = s.run_request_most_recent,
            sample_prep_request_most_recent = s.sample_prep_request_most_recent,
            most_recent_activity = s.most_recent_activity
    WHEN NOT MATCHED THEN
        INSERT (campaign_id, sample_submission_count, Biomaterial_Count, experiment_count,
                dataset_count, Job_Count, Run_Request_Count, Sample_Prep_Request_Count, Data_Package_Count,
                Sample_Submission_Most_Recent, Biomaterial_Most_Recent, Experiment_Most_Recent,
                Dataset_Most_Recent, Job_Most_Recent, Run_Request_Most_Recent,
                Sample_Prep_Request_Most_Recent, Most_Recent_Activity)
        VALUES (s.campaign_id, s.sample_submission_count, s.Biomaterial_Count, s.experiment_count,
                s.Dataset_Count, s.Job_Count, s.Run_Request_Count, s.Sample_Prep_Request_Count, s.Data_Package_Count,
                s.Sample_Submission_Most_Recent, s.Biomaterial_Most_Recent, s.Experiment_Most_Recent,
                s.Dataset_Most_Recent, s.Job_Most_Recent, s.Run_Request_Most_Recent,
                s.Sample_Prep_Request_Most_Recent, s.Most_Recent_Activity);

    -- Delete rows in t_campaign_tracking that are not in Tmp_CampaignStats

    DELETE FROM t_campaign_tracking target
    WHERE NOT EXISTS (SELECT source.campaign_id
                      FROM Tmp_CampaignStats source
                      WHERE target.campaign_id = source.campaign_id
                     );

    DROP TABLE Tmp_CampaignStats;
END
$$;

COMMENT ON PROCEDURE public.update_campaign_tracking IS 'UpdateCampaignTracking';
