--
-- Name: update_campaign_tracking(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_campaign_tracking(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update summary stats in t_campaign_tracking
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   10/20/2002
**          11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**          01/18/2010 grk - Added update for run requests and sample prep requests (http://prismtrac.pnl.gov/trac/ticket/753)
**          01/25/2010 grk - Added 'most recent activity' (http://prismtrac.pnl.gov/trac/ticket/753)
**          04/15/2015 mem - Added Data_Package_Count
**          08/29/2018 mem - Added Sample_Submission_Count and Sample_Submission_Most_Recent
**          08/30/2018 mem - Use merge instead of truncate
**          02/29/2024 mem - Fix bug that updated T_Campaign_Tracking instead of #Tmp_CampaignStats when counting data packages
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;

    _addOrUpdateCount int;
    _rowsAdded int;
    _rowsUpdated int;

    _deleteCount int;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Cache the count of the current number of items in t_campaign_tracking
    ----------------------------------------------------------

    SELECT COUNT(*)
    INTO _countBeforeMerge
    FROM t_campaign_tracking;

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
        CONSTRAINT PK_Tmp_CampaignStats PRIMARY KEY (Campaign_ID)
    );

    ----------------------------------------------------------
    -- Make entry in results table for each campaign
    ----------------------------------------------------------

    INSERT INTO Tmp_CampaignStats (
        Campaign_ID,
        Most_Recent_Activity,
        Sample_Submission_Count,
        Biomaterial_Count,
        Experiment_Count,
        Dataset_Count,
        Job_Count,
        Run_Request_Count,
        Sample_Prep_Request_Count,
        Data_Package_Count
    )
    SELECT campaign_id,
           created AS Most_Recent_Activity,
           0, 0, 0, 0, 0, 0, 0, 0
    FROM t_campaign;

    ----------------------------------------------------------
    -- Update campaign statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Sample_Submission_Count = StatsQ.Items,
        Sample_Submission_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT C.campaign_id,
                 COUNT(SS.submission_id) AS Items,
                 MAX(SS.created) AS Most_Recent
          FROM t_campaign C
               INNER JOIN t_sample_submission SS
                 ON C.campaign_id = SS.campaign_id
          GROUP BY C.campaign_id
         ) AS StatsQ
    WHERE Tmp_CampaignStats.campaign_id = StatsQ.campaign_id;

    ----------------------------------------------------------
    -- Update biomaterial statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Biomaterial_Count = StatsQ.Items,
        Biomaterial_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT C.campaign_id,
                 COUNT(B.biomaterial_id) AS Items,
                 MAX(B.created) AS Most_Recent
          FROM t_campaign C
               INNER JOIN t_biomaterial B
                 ON C.campaign_id = B.campaign_id
          GROUP BY C.campaign_id
         ) AS StatsQ
    WHERE Tmp_CampaignStats.campaign_id = StatsQ.campaign_id;

    ----------------------------------------------------------
    -- Update experiment statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Experiment_Count = StatsQ.Items,
        Experiment_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT C.campaign_id,
                 COUNT(E.exp_id) AS Items,
                 MAX(E.created) AS Most_Recent
          FROM t_campaign C
               INNER JOIN t_experiments E
                 ON C.campaign_id = E.campaign_id
          GROUP BY C.campaign_id
         ) AS StatsQ
    WHERE Tmp_CampaignStats.campaign_id = StatsQ.campaign_id;

    ----------------------------------------------------------
    -- Update dataset statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Dataset_Count = StatsQ.Items,
        Dataset_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT C.campaign_id,
                 COUNT(DS.dataset_id) AS Items,
                 MAX(DS.created) AS Most_Recent
          FROM t_experiments E
               INNER JOIN t_dataset DS
                 ON E.exp_id = DS.exp_id
               INNER JOIN t_campaign C
                 ON E.campaign_id = C.campaign_id
          GROUP BY C.campaign_id
         ) AS StatsQ
    WHERE Tmp_CampaignStats.campaign_id = StatsQ.campaign_id;

    ----------------------------------------------------------
    -- Update analysis job statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Job_Count = StatsQ.Items,
        Job_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT C.campaign_id,
                 COUNT(AJ.job) AS Items,
                 MAX(AJ.created) AS Most_Recent
          FROM t_experiments E
               INNER JOIN t_dataset DS
                 ON E.exp_id = DS.exp_id
               INNER JOIN t_analysis_job AJ
                 ON DS.dataset_id = AJ.dataset_id
               INNER JOIN t_campaign C
                 ON E.campaign_id = C.campaign_id
          GROUP BY C.campaign_id
         ) AS StatsQ
    WHERE Tmp_CampaignStats.campaign_id = StatsQ.campaign_id;

    ----------------------------------------------------------
    -- Update requested run statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Run_Request_Count = StatsQ.Items,
        Run_Request_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT E.campaign_id,
                 COUNT(RR.request_id) AS Items,
                 MAX(RR.created) AS Most_Recent
          FROM t_requested_run RR
               INNER JOIN t_experiments E
                 ON RR.exp_id = E.exp_id
          GROUP BY E.campaign_id
         ) AS StatsQ
    WHERE StatsQ.campaign_id = Tmp_CampaignStats.campaign_id;

    ----------------------------------------------------------
    -- Update sample prep statistics
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET Sample_Prep_Request_Count = StatsQ.Items,
        Sample_Prep_Request_Most_Recent = StatsQ.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN StatsQ.Most_Recent > Most_Recent_Activity THEN StatsQ.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM (SELECT C.campaign_id,
                 COUNT(SPR.prep_request_id) AS Items,
                 MAX(SPR.created) AS Most_Recent
          FROM t_sample_prep_request SPR
               INNER JOIN t_campaign C
                 ON SPR.campaign = C.campaign
          GROUP BY C.campaign_id
         ) AS StatsQ
    WHERE StatsQ.campaign_id = Tmp_CampaignStats.campaign_id;

    ----------------------------------------------------------
    -- Update Data Package counts
    ----------------------------------------------------------

    UPDATE Tmp_CampaignStats
    SET data_package_count = StatsQ.Items
    FROM (SELECT E.campaign_id,
                 COUNT(DISTINCT DPE.data_pkg_id) AS Items
          FROM dpkg.t_data_package_experiments DPE
               INNER JOIN t_experiments E
                 ON E.exp_id = DPE.experiment_id
          GROUP BY E.campaign_id
         ) AS StatsQ
    WHERE StatsQ.campaign_id = Tmp_CampaignStats.campaign_id;

    ----------------------------------------------------------
    -- Update t_campaign_tracking using Tmp_CampaignStats
    ----------------------------------------------------------

    MERGE INTO t_campaign_tracking AS Target
    USING (SELECT Campaign_ID,
                  Sample_Submission_Count,
                  Biomaterial_Count,
                  Experiment_Count,
                  Dataset_Count,
                  Job_Count,
                  Run_Request_Count,
                  Sample_Prep_Request_Count,
                  Data_Package_Count,
                  Sample_Submission_Most_Recent,
                  Biomaterial_Most_Recent,
                  Experiment_Most_Recent,
                  Dataset_Most_Recent,
                  Job_Most_Recent,
                  Run_Request_Most_Recent,
                  Sample_Prep_Request_Most_Recent,
                  Most_Recent_Activity
           FROM Tmp_CampaignStats
          ) AS Src
    ON (Target.campaign_id = Src.campaign_id)
    WHEN MATCHED AND
         (Target.biomaterial_count         <> Src.biomaterial_count OR
          Target.experiment_count          <> Src.experiment_count OR
          Target.dataset_count             <> Src.dataset_count OR
          Target.job_count                 <> Src.job_count OR
          Target.run_request_count         <> Src.run_request_count OR
          Target.sample_prep_request_count <> Src.sample_prep_request_count OR
          Target.sample_submission_count         IS DISTINCT FROM Src.sample_submission_count OR
          Target.data_package_count              IS DISTINCT FROM Src.data_package_count OR
          Target.sample_submission_most_recent   IS DISTINCT FROM Src.sample_submission_most_recent OR
          Target.biomaterial_most_recent         IS DISTINCT FROM Src.biomaterial_most_recent OR
          Target.experiment_most_recent          IS DISTINCT FROM Src.experiment_most_recent OR
          Target.dataset_most_recent             IS DISTINCT FROM Src.dataset_most_recent OR
          Target.job_most_recent                 IS DISTINCT FROM Src.job_most_recent OR
          Target.run_request_most_recent         IS DISTINCT FROM Src.run_request_most_recent OR
          Target.sample_prep_request_most_recent IS DISTINCT FROM Src.sample_prep_request_most_recent OR
          Target.most_recent_activity            IS DISTINCT FROM Src.most_recent_activity) THEN
        UPDATE SET
            sample_submission_count = Src.sample_submission_count,
            biomaterial_count = Src.biomaterial_count,
            experiment_count = Src.experiment_count,
            dataset_count = Src.dataset_count,
            job_count = Src.job_count,
            run_request_count = Src.run_request_count,
            sample_prep_request_count = Src.sample_prep_request_count,
            data_package_count = Src.data_package_count,
            sample_submission_most_recent = Src.sample_submission_most_recent,
            biomaterial_most_recent = Src.biomaterial_most_recent,
            experiment_most_recent = Src.experiment_most_recent,
            dataset_most_recent = Src.dataset_most_recent,
            job_most_recent = Src.job_most_recent,
            run_request_most_recent = Src.run_request_most_recent,
            sample_prep_request_most_recent = Src.sample_prep_request_most_recent,
            most_recent_activity = Src.most_recent_activity
    WHEN NOT MATCHED THEN
        INSERT (campaign_id, sample_submission_count, Biomaterial_Count, experiment_count,
                dataset_count, Job_Count, Run_Request_Count, Sample_Prep_Request_Count, Data_Package_Count,
                Sample_Submission_Most_Recent, Biomaterial_Most_Recent, Experiment_Most_Recent,
                Dataset_Most_Recent, Job_Most_Recent, Run_Request_Most_Recent,
                Sample_Prep_Request_Most_Recent, Most_Recent_Activity)
        VALUES (Src.campaign_id, Src.sample_submission_count, Src.Biomaterial_Count, Src.experiment_count,
                Src.Dataset_Count, Src.Job_Count, Src.Run_Request_Count, Src.Sample_Prep_Request_Count, Src.Data_Package_Count,
                Src.Sample_Submission_Most_Recent, Src.Biomaterial_Most_Recent, Src.Experiment_Most_Recent,
                Src.Dataset_Most_Recent, Src.Job_Most_Recent, Src.Run_Request_Most_Recent,
                Src.Sample_Prep_Request_Most_Recent, Src.Most_Recent_Activity);

    GET DIAGNOSTICS _addOrUpdateCount = ROW_COUNT;

    SELECT COUNT(*)
    INTO _countAfterMerge
    FROM t_campaign_tracking;

    _rowsAdded    := _countAfterMerge - _countBeforeMerge;
    _rowsUpdated := _addOrUpdateCount - _rowsAdded;

    If _rowsAdded > 0 Then
        _message := format('added %s %s', _rowsAdded, public.check_plural(_rowsAdded, 'row', 'rows'));
    End If;

    If _rowsUpdated > 0 Then
        _message := public.append_to_text(
                            _message,
                            format('updated %s %s', _rowsUpdated, public.check_plural(_rowsUpdated, 'row', 'rows')));
    End If;

    -- Delete rows in t_campaign_tracking that are not in Tmp_CampaignStats

    DELETE FROM t_campaign_tracking target
    WHERE NOT EXISTS (SELECT 1
                      FROM Tmp_CampaignStats source
                      WHERE target.campaign_id = source.campaign_id
                     );
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        _message := public.append_to_text(
                            _message,
                            format('deleted %s extra %s', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows')));
    End If;

    If _message <> '' Then
        _message := format('Updated t_campaign_tracking: %s', _message);
        RAISE INFO '%', _message;
    Else
        RAISE INFO 'Table t_campaign_tracking is already up-to-date';
    End If;

    DROP TABLE Tmp_CampaignStats;
END
$$;


ALTER PROCEDURE public.update_campaign_tracking(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_campaign_tracking(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_campaign_tracking(INOUT _message text, INOUT _returncode text) IS 'UpdateCampaignTracking';

