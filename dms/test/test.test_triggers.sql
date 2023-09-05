--
-- Name: test_triggers(boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.test_triggers(_createitems boolean DEFAULT false, _updatestates boolean DEFAULT false, _deleteitems boolean DEFAULT false, _renameitems boolean DEFAULT false, _undorenames boolean DEFAULT false) RETURNS TABLE(entry_id integer, item_type text, item_name text, item_id integer, action text, comment text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates test campaigns, experiments, dataset, etc.
**      Item names are of the form:
**        UnitTest_2022-08-09_Campaign1
**        UnitTest_2022-08-09_Campaign2
**        UnitTest_2022-08-09_Experiment1
**        UnitTest_2022-08-09_Experiment2
**        etc.
**
**  Arguments:
**    _createItems      False to preview items that would be created, true to create the items (if they do not yet exist)
**    _updateStates     When true, update items states
**    _deleteItems      When true, delete existing unit test items
**    _renameItems      False to skip item renames, true to rename items (based on _undoRenames); this feature is not implemented
**    _undoRenames      When false, rename items from the original name to a new name (an error will be reported if the target item name already exists)
**                      When true,  rename the items back to the original name        (an error will be reported if the target item name already exists)
**
**  Usage:
**      SELECT * FROM test.test_triggers(_createItems => true,  _updateStates => false, _deleteItems => false);
**      SELECT * FROM test.test_triggers(_createItems => false, _updateStates => true,  _deleteItems => false);
**      SELECT * FROM test.test_triggers(_createItems => false, _updateStates => false, _deleteItems => true);
**
**      SELECT *
**      FROM V_event_log
**      WHERE entered >= Current_Date
**      ORDER BY event_id;
**
**  Auth:   mem
**  Date:   08/09/2022 mem - Initial version
**          02/08/2023 mem - Switch from PRN to username
**          04/27/2023 mem - Use boolean for data type name
**          05/22/2023 mem - Update whitespace
**          07/11/2023 mem - Change argument flags from integer to boolean
**                         - Use COUNT(H.entry_id) and COUNT(L.event_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _baseName text;
    _today date;
    _action text;
    _campaignsFoundOrCreated boolean;
    _experimentsFoundOrCreated boolean;
    _datasetsFoundOrCreated boolean;
    _jobsFoundOrCreated boolean;
    _plexMappingFoundOrCreated boolean;
    _username text;
    _campaignID int;
    _experimentID int;
    _analysisToolInfo record;
    _paramFileName text;
    _settingsFileName text;
    _datasetID int;
    _newJobID int;
    _organismID int;
    _instrumentID int;
    _storagePathID int;
    _datasetTypeID int;
    _lcColumnID int;
    _myRowCount int;
    _plexMapCount int;
BEGIN

    _today := CURRENT_TIMESTAMP::date;
    _baseName := 'UnitTest_' || _today::text;

    CREATE TEMP TABLE T_Tmp_Results (
        entry_id int NOT NULL GENERATED ALWAYS AS IDENTITY,
        item_type text,
        item_name text,
        item_id int,
        action text,
        comment text,
        CONSTRAINT pk_t_tmp_results PRIMARY KEY (entry_id)
    );

    CREATE TEMP TABLE T_Tmp_Campaigns (
        campaign_name text not null,
        campaign_id int null
    );

    CREATE TEMP TABLE T_Tmp_Experiments (
        campaign_id int not null,
        experiment_name text not null,
        experiment_id int null
    );

    CREATE TEMP TABLE T_Tmp_Datasets (
        experiment_id int not null,
        dataset_name text not null,
        dataset_id int null
    );

    CREATE TEMP TABLE T_Tmp_Jobs (
        dataset_id int not null,
        analysis_tool_id int not null,
        job int null
    );

    CREATE TEMP TABLE T_Tmp_Experiment_Plex_Members (
        Plex_Exp_ID int not null,
        Channel int not null,
        Exp_ID int not null,
        Channel_Type_ID int not null,
        Comment text null,
        Mapping_Defined boolean not null
    );

    -----------------------------------------------------------------
    -- Lookup required metadata
    -----------------------------------------------------------------

    -- Determine the username to use for new items
    SELECT U.username
    INTO _username
    FROM t_users U
    WHERE U.username = session_user::citext
    LIMIT 1;

    If Not FOUND Then
        RAISE NOTICE 'Warning: Session user % is not in t_users', session_user;

        SELECT O.username
        INTO _username
        FROM v_active_instrument_operators O
        ORDER BY O.name
        LIMIT 1;

        If Not FOUND Then
            SELECT U.username
            INTO _username
            FROM t_users U
            ORDER BY CASE WHEN U.status = 'active' THEN 0 ELSE 1 END, U.user_id
            LIMIT 1;
        End If;
    End If;

    -- Determine the organism ID to use for new experiments
    SELECT organism_id
    INTO _organismID
    FROM t_organisms
    WHERE organism = 'None';

    If Not FOUND Then
        RAISE NOTICE 'Warning: "none" organism not found in t_organisms';

        SELECT MIN(organism_id)
        INTO _organismID
        FROM t_organisms;
    End If;

    -- Determine the instrument ID to use for new datasets
    SELECT instrument_id
    INTO _instrumentID
    FROM t_instrument_name
    WHERE instrument_group in ('Eclipse', 'QExactive', 'VelosOrbi') AND
          status = 'active'
    ORDER BY CASE WHEN instrument LIKE 'External%' THEN 1 ELSE 0 END, instrument_id Desc
    LIMIT 1;

    If Not FOUND Then
        RAISE NOTICE 'Warning: Active instrument group expected instrument groups not found in t_instrument_name';

        SELECT MAX(instrument_id)
        INTO _instrumentID
        FROM t_instrument_name
        WHERE status = 'active';

        If Not FOUND Then
            SELECT MAX(instrument_id)
            INTO _instrumentID
            FROM t_instrument_name;
        End If;
    End If;

    SELECT SP.storage_path_id
    INTO _storagePathID
    FROM t_storage_path SP
         INNER JOIN t_instrument_name InstName
           ON SP.instrument = InstName.instrument
    WHERE InstName.instrument_id = 178
    ORDER BY CASE
                 WHEN SP.storage_path_function = 'raw-storage' THEN 0
                 WHEN SP.storage_path_function = 'old-storage' THEN SP.storage_path_id
                 ELSE 1000000000
             END
    LIMIT 1;

    SELECT lc_column_id
    INTO _lcColumnID
    FROM t_lc_column
    WHERE lc_column = 'No_Column';

    SELECT dataset_type_id
    INTO _datasetTypeID
    FROM t_dataset_type_name
    WHERE dataset_type = 'HMS-HMSn';

    SELECT analysis_tool_id, param_file_type_id, analysis_tool
    INTO _analysisToolInfo
    FROM t_analysis_tool
    WHERE analysis_tool like 'MSGFPlus%' And Active > 0
    ORDER BY analysis_tool_id
    Limit 1;

    If Not FOUND Then
        SELECT analysis_tool_id, param_file_type_id, analysis_tool
        INTO _analysisToolInfo
        FROM t_analysis_tool
        WHERE analysis_tool like 'MSGFPlus%'
        ORDER BY analysis_tool_id
        Limit 1;

        If Not FOUND Then
            RAISE NOTICE 'Warning: MSGFPlus tool not found in t_analysis_tool';

            SELECT analysis_tool_id, param_file_type_id, analysis_tool
            INTO _analysisToolInfo
            FROM t_analysis_tool
            ORDER BY active desc, analysis_tool_id desc
            Limit 1;
        End If;

    End If;

    SELECT param_file_name
    INTO _paramFileName
    FROM t_param_files
    WHERE param_file_type_id = _analysisToolInfo.param_file_type_id AND valid > 0
    ORDER BY param_file_id
    LIMIT 1;

    SELECT file_name
    INTO _settingsFileName
    FROM t_settings_files
    WHERE analysis_tool = _analysisToolInfo.analysis_tool AND active > 0
    ORDER BY settings_file_id
    LIMIT 1;

    -----------------------------------------------------------------
    -- Create / find unit test campaigns
    -----------------------------------------------------------------

    INSERT INTO T_Tmp_Campaigns (campaign_name)
    VALUES (_baseName || '_Campaign1'),
           (_baseName || '_Campaign2'),
           (_baseName || '_Campaign3');

    UPDATE T_Tmp_Campaigns
    SET campaign_id = C.campaign_id
    FROM t_campaign C
    WHERE T_Tmp_Campaigns.campaign_name = C.campaign;

    If FOUND Then
        _action := 'Verified exists in t_campaign';
        _campaignsFoundOrCreated := true;

    ElsIf _createItems Then
        -- Create the campaigns
        INSERT INTO t_campaign (campaign, project, state)
        SELECT campaign_name, 'Unit tests', 'Active'
        FROM T_Tmp_Campaigns
        ORDER BY campaign_name;

        UPDATE T_Tmp_Campaigns
        SET campaign_id = C.campaign_id
        FROM t_campaign C
        WHERE T_Tmp_Campaigns.campaign_name = C.campaign;

        _action := 'Created in t_campaign';
        _campaignsFoundOrCreated := true;
    Else
        -- Assign placeholder campaign IDs
        UPDATE T_Tmp_Campaigns
        SET campaign_id = RankQ.campaign_id
        FROM (SELECT campaign_name, row_number() over (order by campaign_name) As campaign_id
              FROM T_Tmp_Campaigns) RankQ
        WHERE T_Tmp_Campaigns.campaign_name = RankQ.campaign_name;

        _action := 'Preview create campaign';
        _campaignsFoundOrCreated := false;
    End If;

    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
    SELECT 'Campaign', campaign_name, campaign_id, _action
    FROM T_Tmp_Campaigns
    ORDER BY campaign_id;

    -----------------------------------------------------------------
    -- Create / find unit test experiments
    -----------------------------------------------------------------

    If _campaignsFoundOrCreated Then
        SELECT campaign_id
        INTO _campaignID
        FROM T_Tmp_Campaigns
        ORDER BY campaign_name
        LIMIT 1;
    Else
        -- Choose the newest existing campaign
        SELECT campaign_id
        INTO _campaignID
        FROM t_campaign
        ORDER BY campaign_id DESC
        LIMIT 1;
    End If;

    INSERT INTO T_Tmp_Experiments (campaign_id, experiment_name)
    VALUES (_campaignID, _baseName || '_Experiment1'),
           (_campaignID, _baseName || '_Experiment2'),
           (_campaignID, _baseName || '_Experiment3');

    UPDATE T_Tmp_Experiments
    SET experiment_id = E.exp_id
    FROM t_experiments E
    WHERE T_Tmp_Experiments.experiment_name = E.experiment;

    If FOUND Then
        _action := 'Verified exists in t_experiments';
        _experimentsFoundOrCreated := true;

    ElsIf _createItems Then
        -- Create the experiments
        INSERT INTO t_experiments (experiment, researcher_username, organism_id, campaign_id, labelling)
        SELECT E.experiment_name, _username, _organismID, E.campaign_id, 'None'
        FROM T_Tmp_Experiments E
        ORDER BY E.experiment_name;

        UPDATE T_Tmp_Experiments
        SET experiment_id = E.exp_id
        FROM t_experiments E
        WHERE T_Tmp_Experiments.experiment_name = E.experiment;

        _action := 'Created in t_experiments';
        _experimentsFoundOrCreated := true;
    Else
        -- Assign placeholder experiment IDs
        UPDATE T_Tmp_Experiments
        SET experiment_id = RankQ.experiment_id
        FROM (SELECT experiment_name, row_number() over (order by experiment_name) As experiment_id
              FROM T_Tmp_Experiments) RankQ
        WHERE T_Tmp_Experiments.experiment_name = RankQ.experiment_name;

        _action := 'Preview create experiment';
        _experimentsFoundOrCreated := false;
    End If;

    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
    SELECT 'Experiment', experiment_name, experiment_id, _action
    FROM T_Tmp_Experiments
    ORDER BY experiment_id;

    -----------------------------------------------------------------
    -- Create / find unit test datasets
    -----------------------------------------------------------------

    If _experimentsFoundOrCreated Then
        SELECT experiment_id
        INTO _experimentID
        FROM T_Tmp_Experiments
        ORDER BY experiment_name
        LIMIT 1;
    Else
        -- Choose the newest existing experiment
        SELECT exp_id
        INTO _experimentID
        FROM t_experiments
        ORDER BY exp_id DESC
        LIMIT 1;
    End If;

    INSERT INTO T_Tmp_Datasets (experiment_id, dataset_name)
    VALUES (_experimentID, _baseName || '_Dataset1'),
           (_experimentID, _baseName || '_Dataset2'),
           (_experimentID, _baseName || '_Dataset3');

    UPDATE T_Tmp_Datasets
    SET dataset_id = DS.dataset_id
    FROM t_dataset DS
    WHERE T_Tmp_Datasets.dataset_name = DS.dataset;

    If FOUND Then
        _action := 'Verified exists in t_dataset';
        _datasetsFoundOrCreated := true;

    ElsIf _createItems Then
        -- Create the datasets
        INSERT INTO t_dataset (dataset, operator_username, instrument_id, exp_id, folder_name, dataset_type_id, lc_column_id, storage_path_id)
        SELECT D.dataset_name, _username, _instrumentID, _experimentID, D.dataset_name, _datasetTypeID, _lcColumnID, _storagePathID
        FROM T_Tmp_Datasets D
        ORDER BY D.dataset_name;

        UPDATE T_Tmp_Datasets
        SET dataset_id = DS.dataset_ID
        FROM t_dataset DS
        WHERE T_Tmp_Datasets.dataset_name = DS.dataset;

        _action := 'Created in t_dataset';
        _datasetsFoundOrCreated := true;
    Else
        -- Assign placeholder dataset IDs
        UPDATE T_Tmp_Datasets
        SET dataset_id = RankQ.dataset_id
        FROM (SELECT dataset_name, row_number() over (order by dataset_name) As dataset_id
              FROM T_Tmp_Datasets) RankQ
        WHERE T_Tmp_Datasets.dataset_name = RankQ.dataset_name;

        _action := 'Preview create dataset';
        _datasetsFoundOrCreated := false;
    End If;

    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
    SELECT 'Dataset', dataset_name, dataset_id, _action
    FROM T_Tmp_Datasets
    ORDER BY dataset_id;

    -----------------------------------------------------------------
    -- Create / find unit test analysis jobs
    -----------------------------------------------------------------

    INSERT INTO T_Tmp_Jobs (dataset_id, analysis_tool_id)
    SELECT dataset_id, _analysisToolInfo.analysis_tool_id
    FROM T_Tmp_Datasets
    ORDER BY dataset_id;

    UPDATE T_Tmp_Jobs
    SET job = J.job
    FROM t_analysis_job J
    WHERE T_Tmp_Jobs.dataset_id = J.dataset_id;

    If FOUND Then
        _action := 'Verified exists in t_analysis_job';
        _jobsFoundOrCreated := true;

    ElsIf _createItems Then

        -- Obtain job numbers
        FOR _datasetID IN
            SELECT dataset_id
            FROM T_Tmp_Jobs
        LOOP
            INSERT INTO t_analysis_job_id (note)
            VALUES ('Job for unit test, dataset id ' || _datasetID::text)
            RETURNING job
            INTO _newJobID;

            UPDATE T_Tmp_Jobs
            SET job = _newJobID
            WHERE dataset_id = _datasetID;
        END LOOP;

        -- Create the analysis jobs
        INSERT INTO t_analysis_job (job, analysis_tool_id, param_file_name, settings_file_name, organism_id, dataset_id)
        SELECT J.job, _analysisToolInfo.analysis_tool_id, _paramFileName, _settingsFileName, _organismID, J.dataset_id
        FROM T_Tmp_Jobs J
        ORDER BY J.dataset_id;

        _action := 'Created in t_analysis_job';
        _jobsFoundOrCreated := true;
    Else
        -- Assign placeholder job numbers
        UPDATE T_Tmp_Jobs
        SET job = RankQ.job
        FROM (SELECT dataset_id, row_number() over (order by dataset_id) As job
              FROM T_Tmp_Jobs) RankQ
        WHERE T_Tmp_Jobs.dataset_id = RankQ.dataset_id;

        _action := 'Preview create analysis jobs';
        _jobsFoundOrCreated := false;
    End If;

    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
    SELECT 'Analysis Job', 'Job ' || j.job::text || ' for dataset ' || D.dataset_name, j.job, _action
    FROM T_Tmp_Jobs J
         LEFT OUTER JOIN T_Tmp_Datasets D
           ON J.dataset_id = D.dataset_id
    ORDER BY J.job;

    -----------------------------------------------------------------
    -- Create / find unit test plex mappings
    -----------------------------------------------------------------

    INSERT INTO T_Tmp_Experiment_Plex_Members (plex_exp_id, channel, exp_id, channel_type_id, comment, mapping_defined)
    SELECT _experimentID, RankQ.RowNum - 1, RankQ.experiment_id, 1, 'Unit test plex', false
    FROM ( SELECT experiment_id, Row_Number() Over (Order By experiment_id) as RowNum
           FROM T_Tmp_Experiments) RankQ
    WHERE RankQ.RowNum > 1
    ORDER BY RankQ.experiment_id;

    GET DIAGNOSTICS _plexMapCount = ROW_COUNT;

    UPDATE T_Tmp_Experiment_Plex_Members
    SET mapping_defined = true
    FROM t_experiment_plex_members PM
    WHERE PM.plex_exp_id = _experimentID AND
          PM.exp_id = T_Tmp_Experiment_Plex_Members.exp_id;

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = _plexMapCount Then
        _action := 'Verified exists in t_experiment_plex_members';
        _plexMappingFoundOrCreated := true;

    ElsIf _createItems Then

        -- Add missing items to t_experiment_plex_members
        INSERT INTO t_experiment_plex_members (plex_exp_id, channel, exp_id, channel_type_id, comment)
        SELECT PM.plex_exp_id, PM.channel, PM.exp_id, PM.channel_type_id, PM.comment
        FROM T_Tmp_Experiment_Plex_Members PM
        WHERE Not PM.mapping_defined;

        _action := 'Created in t_experiment_plex_members';
        _plexMappingFoundOrCreated := true;
    Else
        _action := 'Preview create experiment plex mapping';
        _plexMappingFoundOrCreated := false;
    End If;

    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
    SELECT 'Experiment Plex Map', 'plex_exp_id ' || PM.plex_exp_id::text || ', channel ' || PM.channel, PM.exp_id, _action
    FROM T_Tmp_Experiment_Plex_Members PM
    ORDER BY PM.channel;


    -----------------------------------------------------------------
    -- Update item states
    -----------------------------------------------------------------

    If _updateStates Then
        If _campaignsFoundOrCreated Then
            UPDATE t_campaign
            SET state = Case When state = 'Active' Then 'Inactive' Else 'Active' End
            FROM T_Tmp_Campaigns
            WHERE t_campaign.campaign_id = T_Tmp_Campaigns.campaign_id;

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Campaign', 'Update state', 0, 'Toggled active/inactive state for ' || _myRowCount::text || ' campaigns');
        End If;

        If _experimentsFoundOrCreated Then
            UPDATE t_experiments
            SET material_active = Case When material_active = 'Active' Then 'Inactive' Else 'Active' End
            FROM T_Tmp_Experiments
            WHERE t_experiments.exp_id = T_Tmp_Experiments.experiment_id;

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Experiment', 'Update state', 0, 'Toggled active/inactive state for ' || _myRowCount::text || ' experiments');
        End If;

        If _datasetsFoundOrCreated Then
            UPDATE t_dataset
            SET dataset_state_id = CASE WHEN dataset_state_id < 3
                                        THEN dataset_state_id + 1
                                        ELSE 1
                                   END
            FROM T_Tmp_Datasets
            WHERE t_dataset.dataset_id = T_Tmp_Datasets.dataset_id;

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Dataset', 'Update state', 0, 'Updated state for ' || _myRowCount::text || ' datasets');

            UPDATE t_dataset
            SET dataset_rating_id = CASE WHEN dataset_rating_id = 2 THEN 5
                                         WHEN dataset_rating_id = 5 THEN 1
                                         ELSE 2
                                    END
            FROM T_Tmp_Datasets
            WHERE t_dataset.dataset_id = T_Tmp_Datasets.dataset_id;

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Dataset', 'Update rating', 0, 'Updated rating for ' || _myRowCount::text || ' datasets');
        End If;

        If _jobsFoundOrCreated Then
            UPDATE t_analysis_job
            SET job_state_id = CASE WHEN job_state_id = 1 THEN 2
                                    WHEN job_state_id = 2 THEN 4
                                    ELSE 1
                               END
            FROM T_Tmp_Jobs
            WHERE t_analysis_job.job = T_Tmp_Jobs.job;

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Job', 'Update state', 0, 'Updated state for ' || _myRowCount::text || ' jobs');
        End If;

    End If;

    -----------------------------------------------------------------
    -- Rename items
    -----------------------------------------------------------------

    If _renameItems Then
        -- ToDo: rename items
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
        VALUES ('ToDo', 'Rename items', 0, 'Rename datasets, experiments, campaigns, etc.');
    End If;

    -----------------------------------------------------------------
    -- Delete items
    -----------------------------------------------------------------

    If _deleteItems Then
        -- Delete jobs, datasets, experiments, campaigns, etc.

        If _plexMappingFoundOrCreated Then
            DELETE FROM t_experiment_plex_members target
            WHERE EXISTS
                ( SELECT 1
                  FROM t_experiment_plex_members PM
                       INNER JOIN T_Tmp_Experiment_Plex_Members TPM
                         ON PM.plex_exp_id = TPM.plex_exp_id AND
                            PM.exp_id      = TPM.exp_id
                  WHERE target.plex_exp_id = PM.plex_exp_id AND
                        target.exp_id = PM.exp_id
                );

            If FOUND Then
                SELECT COUNT(H.entry_id)
                INTO _myRowCount
                FROM t_experiment_plex_members_history H INNER JOIN
                     T_Tmp_Experiment_Plex_Members PM
                       ON H.plex_exp_id = PM.plex_exp_id AND
                          H.exp_id = PM.exp_id
                WHERE state = 0 AND
                      entered >= CURRENT_TIMESTAMP - Interval '30 seconds';

                If FOUND Then
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                    SELECT Distinct 'Plex Mapping', 'Delete items', plex_exp_id, 'Logged deletion of ' || _myRowCount::text || ' plex mappings to t_experiment_plex_members_history'
                    FROM T_Tmp_Experiment_Plex_Members;
                Else
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
                    SELECT Distinct 'Plex Mapping', 'Delete items', plex_exp_id, 'Error: did not log deletion of plex mappings to t_experiment_plex_members_history'
                    FROM T_Tmp_Experiment_Plex_Members;
                End If;

            Else
                INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                SELECT Distinct 'Plex Mapping', 'Delete items', 0, 'Nothing to delete: plex_exp_id ' || plex_exp_id::text || ' not found in t_experiment_plex_members'
                FROM T_Tmp_Experiment_Plex_Members;
            End If;

        End If;

        If _jobsFoundOrCreated Then
            DELETE FROM t_analysis_job
            WHERE job in (select job from T_Tmp_Jobs);

            If FOUND Then
                SELECT COUNT(L.event_id)
                INTO _myRowCount
                FROM v_event_log L INNER JOIN
                     T_Tmp_Jobs
                       ON L.target_id = T_Tmp_Jobs.job AND
                          L.target = 'Job'
                WHERE L.target_state = 0 AND
                      entered >= CURRENT_TIMESTAMP - Interval '30 seconds';

                If FOUND Then
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                    SELECT 'Job', 'Delete items', 0, 'Logged deletion of ' || _myRowCount::text || ' jobs to t_event_log (IDs ' || Min(job)::text || ' to ' || Max(job) || ')'
                    FROM T_Tmp_Jobs;
                Else
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
                    SELECT 'Job', 'Delete items', 0, 'Error: did not log deletion of jobs to t_event_log (IDs ' || Min(job)::text || ' to ' || Max(job) || ')'
                    FROM T_Tmp_Jobs;
                End If;

            Else
                INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                SELECT 'Job', 'Delete items', 0, 'Nothing to delete: jobs ' || Min(job)::text || ' to ' || Max(job) || ' not found in t_analysis_job'
                FROM T_Tmp_Jobs;
            End If;

        End If;

        If _datasetsFoundOrCreated Then
            DELETE FROM t_dataset
            WHERE dataset_id in (select dataset_id from T_Tmp_Datasets);

            If FOUND Then
                SELECT COUNT(L.event_id)
                INTO _myRowCount
                FROM v_event_log L INNER JOIN
                     T_Tmp_Datasets
                       ON L.target_id = T_Tmp_Datasets.dataset_id AND
                          L.target = 'Dataset'
                WHERE L.target_state = 0 AND
                      entered >= CURRENT_TIMESTAMP - Interval '30 seconds';

                If FOUND Then
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                    SELECT 'Dataset', 'Delete items', 0, 'Logged deletion of ' || _myRowCount::text || ' datasets to t_event_log (IDs ' || Min(dataset_id)::text || ' to ' || Max(dataset_id) || ')'
                    FROM T_Tmp_Datasets;
                Else
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
                    SELECT 'Dataset', 'Delete items', 0, 'Error: did not log deletion of datasets to t_event_log (IDs ' || Min(dataset_id)::text || ' to ' || Max(dataset_id) || ')'
                    FROM T_Tmp_Datasets;
                End If;

            Else
                INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                SELECT 'Dataset', 'Delete items', 0, 'Nothing to delete: dataset IDs ' || Min(dataset_id)::text || ' to ' || Max(dataset_id) || ' not found in t_dataset'
                FROM T_Tmp_Datasets;
            End If;

        End If;

        If _experimentsFoundOrCreated Then
            DELETE FROM t_experiments
            WHERE exp_id in (select experiment_id from T_Tmp_Experiments);

            If FOUND Then
                SELECT COUNT(L.event_id)
                INTO _myRowCount
                FROM v_event_log L INNER JOIN
                     T_Tmp_Experiments
                       ON L.target_id = T_Tmp_Experiments.experiment_id AND
                          L.target = 'Experiment'
                WHERE L.target_state = 0 AND
                      entered >= CURRENT_TIMESTAMP - Interval '30 seconds';

                If FOUND Then
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                    SELECT 'Experiment', 'Delete items', 0, 'Logged deletion of ' || _myRowCount::text || ' experiments to t_event_log (IDs ' || Min(experiment_id)::text || ' to ' || Max(experiment_id) || ')'
                    FROM T_Tmp_Experiments;
                Else
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
                    SELECT 'Experiment', 'Delete items', 0, 'Error: did not log deletion of experiments to t_event_log (IDs ' || Min(experiment_id)::text || ' to ' || Max(experiment_id) || ')'
                    FROM T_Tmp_Experiments;
                End If;

            Else
                INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                SELECT 'Experiment', 'Delete items', 0, 'Nothing to delete: experiment IDs ' || Min(experiment_id)::text || ' to ' || Max(experiment_id) || ' not found in t_experiments'
                FROM T_Tmp_Experiments;
            End If;

        End If;

        If _campaignsFoundOrCreated Then
            DELETE FROM t_campaign
            WHERE campaign_id in (select campaign_id from T_Tmp_Campaigns);

            If FOUND Then
                SELECT COUNT(L.event_id)
                INTO _myRowCount
                FROM v_event_log L INNER JOIN
                     T_Tmp_Campaigns
                       ON L.target_id = T_Tmp_Campaigns.campaign_id AND
                          L.target = 'Campaign'
                WHERE L.target_state = 0 AND
                      entered >= CURRENT_TIMESTAMP - Interval '30 seconds';

                If FOUND Then
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                    SELECT 'Campaign', 'Delete items', 0, 'Logged deletion of ' || _myRowCount::text || ' campaigns to t_event_log (IDs ' || Min(campaign_id)::text || ' to ' || Max(campaign_id) || ')'
                    FROM T_Tmp_Campaigns;
                Else
                    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
                    SELECT 'Campaign', 'Delete items', 0, 'Error: did not log deletion of campaigns to t_event_log (IDs ' || Min(campaign_id)::text || ' to ' || Max(campaign_id) || ')'
                    FROM T_Tmp_Campaigns;
                End If;

            Else
                INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
                SELECT 'Campaign', 'Delete items', 0, 'Nothing to delete: campaign IDs ' || Min(campaign_id)::text || ' to ' || Max(campaign_id) || ' not found in t_campaign'
                FROM T_Tmp_Campaigns;
            End If;
        End If;
    End If;

    -----------------------------------------------------------------
    -- Append event log information
    -----------------------------------------------------------------

    If _campaignsFoundOrCreated Then
        -- Append event log entries for the unit test campaigns
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   C.campaign_name as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by target_id, state_name Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
                 INNER JOIN T_Tmp_Campaigns C
                   ON E.target_id = C.campaign_id
            WHERE entered >= _today and target = 'Campaign') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;

        If Not FOUND Then
            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Campaign', 'Warning', 0, 'Entries not found in t_event_log for unit test campaigns');
        End If;

    Else
        -- Unit test campaigns not found
        -- Append campaign related event log items from the last 2 hours
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   'Campaign ID ' || E.target_id::text as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by E.target_id, Coalesce(E.state_name, '') Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
            WHERE entered >= CURRENT_TIMESTAMP - Interval '2 hours' and target = 'Campaign') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;
    End If;

    If _experimentsFoundOrCreated Then
        -- Append event log entries for the unit test experiments
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   T_Tmp_Experiments.experiment_name as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by target_id, state_name Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
                 INNER JOIN T_Tmp_Experiments
                   ON E.target_id = T_Tmp_Experiments.experiment_id
            WHERE entered >= _today and target = 'Experiment') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;

        If Not FOUND Then
            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Experiment', 'Warning', 0, 'Entries not found in t_event_log for unit test experiments');
        End If;
    Else
        -- Unit test experiments not found
        -- Append experiment related event log items from the last 2 hours
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   'Experiment ID ' || E.target_id::text as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by E.target_id, Coalesce(E.state_name, '') Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
            WHERE entered >= CURRENT_TIMESTAMP - Interval '2 hours' and target = 'Experiment') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;
    End If;

    If _datasetsFoundOrCreated Then
        -- Append event log entries for the unit test datasets
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   T_Tmp_Datasets.dataset_name as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by target_id, state_name Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
                 INNER JOIN T_Tmp_Datasets
                   ON E.target_id = T_Tmp_Datasets.dataset_id
            WHERE entered >= _today and target IN ('Dataset', 'DS Rating')) RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;

        If Not FOUND Then
            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Datasset', 'Warning', 0, 'Entries not found in t_event_log for unit test datasets');
        End If;
    Else
        -- Unit test datasets not found
        -- Append dataset related event log items from the last 2 hours
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   'Dataset ID ' || E.target_id::text as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by E.target_id, Coalesce(E.state_name, '') Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
            WHERE entered >= CURRENT_TIMESTAMP - Interval '2 hours' and target IN ('Dataset', 'DS Rating')) RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;
    End If;

    If _jobsFoundOrCreated Then
        -- Append event log entries for the unit test jobs
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   'Job ID ' || T_Tmp_Jobs.job::text as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'for dataset ' || Coalesce(T_Tmp_Datasets.dataset_id, 0)::text || ' at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by target_id, state_name Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
                 INNER JOIN T_Tmp_Jobs
                   ON E.target_id = T_Tmp_Jobs.job
                 LEFT OUTER JOIN T_Tmp_Datasets
                   ON T_Tmp_Jobs.dataset_id = T_Tmp_Datasets.dataset_id
            WHERE entered >= _today and target = 'Job') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;

        If Not FOUND Then
            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Job', 'Warning', 0, 'Entries not found in t_event_log for unit test jobs');
        End If;
    Else
        -- Unit test jobs not found
        -- Append job related event log items from the last 2 hours
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT E.event_id,
                   'Event Log: ' || Lower(E.target) as item_type,
                   'Job ID ' || E.target_id::text as item_name,
                   E.target_id as item_id,
                   E.prev_target_state::text || '->' || E.target_state::text || ' (' || Coalesce(E.state_name, 'null') || ')' as action,
                   'at ' || public.timestamp_text(E.entered) as comment,
                   Row_Number() Over (partition by E.target_id, Coalesce(E.state_name, '') Order By E.event_id desc) as EventLogRank
            FROM v_event_log E
            WHERE entered >= CURRENT_TIMESTAMP - Interval '2 hours' and target = 'Job') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.event_id;
    End If;

    If _plexMappingFoundOrCreated Then
        -- Append history items for the unit test plex mappings
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT H.entry_id,
                   'Plex History, plex_exp_id ' || H.plex_exp_id::text as item_type,
                   'Channel ' || H.channel as item_name,
                   H.exp_id as item_id,
                   'State: ' || H.state::text as action,
                   'at ' || public.timestamp_text(H.entered) as comment,
                   Row_Number() Over (partition by H.plex_exp_id, H.exp_id, H.state Order By H.entry_id desc) as EventLogRank
            FROM t_experiment_plex_members_history H
            WHERE H.plex_exp_id in (SELECT DISTINCT plex_exp_id FROM T_Tmp_Experiment_Plex_Members) AND
                  H.entered >= _today) RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.entry_id;

        If Not FOUND Then
            INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action)
            VALUES ('Experiment Plex History', 'Warning', 0, 'Entries not found in t_experiment_plex_members_history for unit test plex mappings');
        End If;
    Else
        -- Unit test plex mapping not found
        -- Append plex member history items from the last 2 hours
        --
        INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
        SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
        FROM (
            SELECT H.entry_id,
                   'Plex History, plex_exp_id ' || H.plex_exp_id::text as item_type,
                   'Channel ' || H.channel as item_name,
                   H.exp_id as item_id,
                   'State: ' || H.state::text as action,
                   'at ' || public.timestamp_text(H.entered) as comment,
                   Row_Number() Over (partition by H.plex_exp_id, H.exp_id, H.state Order By H.entry_id desc) as EventLogRank
            FROM t_experiment_plex_members_history H
            WHERE H.entered >= CURRENT_TIMESTAMP - Interval '2 hours') RankQ
        WHERE RankQ.EventLogRank = 1
        ORDER BY RankQ.entry_id;
    End If;

    -----------------------------------------------------------------
    -- Append rename information
    -----------------------------------------------------------------

    INSERT INTO T_Tmp_Results (item_type, item_name, item_id, action, comment)
    SELECT RankQ.item_type, RankQ.item_name, RankQ.item_id, RankQ.action, RankQ.comment
    FROM (  SELECT L.entry_id,
                   'Rename log: ' || L.target_type as item_type,
                   L.type_name as item_name,
                   L.target_id as item_id,
                   'Rename to ' || new_name as action,
                   'from || ' || old_name || ' at ' || public.timestamp_text(L.entered) as comment,
                   Row_Number() Over (partition by L.target_type, L.target_id Order By L.entry_id desc) as EventLogRank
            FROM v_entity_rename_log L
            WHERE entered >= _today) RankQ
    WHERE RankQ.EventLogRank <= 2
    ORDER BY RankQ.entry_id;

    RETURN QUERY
    SELECT R.entry_id,
           R.item_type,
           R.item_name,
           R.item_id,
           R.action,
           R.comment
    FROM T_Tmp_Results R
    ORDER BY R.entry_id;

    DROP TABLE T_Tmp_Results;
    DROP TABLE T_Tmp_Campaigns;
    DROP TABLE T_Tmp_Experiments;
    DROP TABLE T_Tmp_Datasets;
    DROP TABLE T_Tmp_Jobs;
    DROP TABLE T_Tmp_Experiment_Plex_Members;

END
$$;


ALTER FUNCTION test.test_triggers(_createitems boolean, _updatestates boolean, _deleteitems boolean, _renameitems boolean, _undorenames boolean) OWNER TO d3l243;

