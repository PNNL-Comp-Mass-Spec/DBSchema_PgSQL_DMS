--
-- Name: update_cached_statistics(text, text, boolean, boolean, boolean, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_statistics(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _previewsql boolean DEFAULT false, IN _updateparamsettingsfilecounts boolean DEFAULT true, IN _updategeneralstatistics boolean DEFAULT true, IN _updatejobrequeststatistics boolean DEFAULT true, IN _showruntimestats boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update various cached statistics
**      - Job_Usage_Count in t_param_files
**      - Job_Usage_Count in t_settings_files
**      - Job_Count in t_analysis_job_request
**      - Job_Usage_Count in t_protein_collection_usage
**      - Dataset usage stats in t_cached_instrument_dataset_type_usage
**      - Dataset usage stats in t_instrument_group_allowed_ds_type
**      - Dataset usage stats in t_lc_cart_configuration
**
**  Arguments:
**    _message                          Status message
**    _returnCode                       Return code
**    _previewSql                       When true, preview the SQL used to compile stats for t_general_statistics (ignored if _updateGeneralStatistics is false)
**    _updateParamSettingsFileCounts    When true, update cached counts in t_param_files, t_settings_files, t_cached_instrument_dataset_type_usage, t_instrument_group_allowed_ds_type, and t_lc_cart_configuration
**    _updateGeneralStatistics          When true, update t_general_statistics
**    _updateJobRequestStatistics       When true, update t_analysis_job_request
**    _showRuntimeStats                 When true, show runtime stats
**
**  Auth:   mem
**  Date:   11/04/2008 mem - Initial version (Ticket: #698)
**          12/21/2009 mem - Add parameter _updateJobRequestStatistics
**          10/20/2011 mem - Now considering analysis tool name when updated T_Param_Files and T_Settings_Files
**          09/11/2012 mem - Now updating T_Protein_Collection_Usage by calling Update_Protein_Collection_Usage
**          07/18/2016 mem - Now updating Job_Usage_Last_Year in T_Param_Files and T_Settings_Files
**          02/23/2017 mem - Update dataset usage in T_LC_Cart_Configuration
**          08/30/2018 mem - Tabs to spaces
**          07/14/2022 mem - Update dataset usage in T_Instrument_Group_Allowed_DS_Type
**                         - Update dataset usage in T_Cached_Instrument_Dataset_Type_Usage
**                         - Add parameter _showRuntimeStats
**                         - Only update counts if they change
**          12/31/2022 mem - Ported to PostgreSQL
**          07/10/2023 mem - Use COUNT(AJ.job) and COUNT(DS.dataset_id) instead of COUNT(*)
**                         - Fix bug referencing a field in a record
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _statEntry record;
    _total int;
    _totalDec numeric(18,3);
    _value text;
    _startTime timestamp;
    _thresholdOneYear timestamp;
    _statInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _previewSql                    := Coalesce(_previewSql, false);
    _updateParamSettingsFileCounts := Coalesce(_updateParamSettingsFileCounts, true);
    _updateGeneralStatistics       := Coalesce(_updateGeneralStatistics, false);
    _updateJobRequestStatistics    := Coalesce(_updateJobRequestStatistics, true);
    _showRuntimeStats              := Coalesce(_showRuntimeStats, false);

    _thresholdOneYear := CURRENT_TIMESTAMP - INTERVAL '1 year';

    CREATE TEMP TABLE Tmp_Update_Stats (
        Entry_ID        int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Task            text,
        Runtime_Seconds real
    );

    If _updateParamSettingsFileCounts Then

        ------------------------------------------------
        -- Update Usage Counts for Parameter Files
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        UPDATE t_param_files target
        SET job_usage_count = StatsQ.JobCount,
            job_usage_last_year = StatsQ.JobCountLastYear        -- Usage over the last 12 months
        FROM (SELECT PF.param_file_id,
                     Coalesce(CountQ.JobCount, 0) AS JobCount,
                     Coalesce(CountQ.JobCountLastYear, 0) AS JobCountLastYear
              FROM t_param_files PF
                   LEFT OUTER JOIN (SELECT AJ.Param_File_Name,
                                           PFT.Param_File_Type_ID,
                                           COUNT(AJ.job) AS JobCount,
                                           SUM(CASE
                                                   WHEN AJ.created >= _thresholdOneYear THEN 1
                                                   ELSE 0
                                               END) AS JobCountLastYear
                                    FROM t_analysis_job AJ
                                         INNER JOIN t_analysis_tool AnTool
                                           ON AJ.analysis_tool_id = AnTool.analysis_tool_id
                                         INNER JOIN t_param_file_types PFT
                                           ON AnTool.param_file_type_id = PFT.param_file_type_id
                                    GROUP BY AJ.param_file_name, PFT.param_file_type_id
                                   ) CountQ
                     ON PF.param_file_name = CountQ.param_file_name AND
                        PF.param_file_type_id = CountQ.param_file_type_id
             ) StatsQ
        WHERE target.param_file_id = StatsQ.param_file_id AND
              (
                target.Job_Usage_Count     IS DISTINCT FROM StatsQ.JobCount OR
                target.Job_Usage_Last_Year IS DISTINCT FROM StatsQ.JobCountLastYear
              );

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update job counts in t_param_files',
               Extract(epoch from (clock_timestamp() - _startTime));

        ------------------------------------------------
        -- Update Usage Counts for Settings Files
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        UPDATE t_settings_files target
        SET job_usage_count = StatsQ.JobCount,
            job_usage_last_year = StatsQ.JobCountLastYear        -- Usage over the last 12 months
        FROM (SELECT SF.settings_file_id,
                     Coalesce(CountQ.JobCount, 0) AS JobCount,
                     Coalesce(CountQ.JobCountLastYear, 0) AS JobCountLastYear
              FROM t_settings_files SF
                   LEFT OUTER JOIN (SELECT AJ.settings_file_name,
                                           AnTool.analysis_tool,
                                           COUNT(AJ.job) AS JobCount,
                                           SUM(CASE
                                                   WHEN AJ.created >= _thresholdOneYear THEN 1
                                                   ELSE 0
                                               END) AS JobCountLastYear
                                    FROM t_analysis_job AJ
                                         INNER JOIN t_analysis_tool AnTool
                                           ON AJ.analysis_tool_id = AnTool.analysis_tool_id
                                    GROUP BY AJ.settings_file_name, AnTool.analysis_tool
                                   ) CountQ
                     ON SF.analysis_tool = CountQ.analysis_tool AND
                        SF.file_name = CountQ.settings_file_name
             ) StatsQ
        WHERE target.settings_file_id = StatsQ.settings_file_id AND
              (
                target.Job_Usage_Count     IS DISTINCT FROM StatsQ.JobCount OR
                target.Job_Usage_Last_Year IS DISTINCT FROM StatsQ.JobCountLastYear
              );

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update job counts in t_settings_files',
               Extract(epoch from (clock_timestamp() - _startTime));

        ------------------------------------------------
        -- Update Usage Counts for LC Cart Configuration items
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        UPDATE t_lc_cart_configuration target
        SET dataset_usage_count = Coalesce(StatsQ.DatasetCount, 0),
            dataset_usage_last_year = Coalesce(StatsQ.DatasetCountLastYear, 0)        -- Usage over the last 12 months
        FROM (SELECT LCCart.cart_config_id,
                     Coalesce(CountQ.DatasetCount, 0) AS DatasetCount,
                     Coalesce(CountQ.DatasetCountLastYear, 0) AS DatasetCountLastYear
              FROM t_lc_cart_configuration LCCart
                   LEFT OUTER JOIN (SELECT DS.Cart_Config_ID,
                                           COUNT(DS.dataset_id) AS DatasetCount,
                                           SUM(CASE WHEN DS.Created >= _thresholdOneYear THEN 1
                                                    ELSE 0
                                               END) AS DatasetCountLastYear
                                    FROM t_dataset DS
                                    WHERE NOT DS.cart_config_id IS NULL
                                    GROUP BY DS.cart_config_id
                                   ) CountQ
                     ON LCCart.cart_config_id = CountQ.cart_config_id
             ) StatsQ
        WHERE target.cart_config_id = StatsQ.cart_config_ID AND
              (
                target.dataset_usage_count     IS DISTINCT FROM StatsQ.DatasetCount or
                target.dataset_usage_last_year IS DISTINCT FROM StatsQ.DatasetCountLastYear
              );

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update dataset counts in t_lc_cart_configuration',
               Extract(epoch from (clock_timestamp() - _startTime));

        ------------------------------------------------
        -- Update Usage Counts for Instrument Groups
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        UPDATE t_instrument_group_allowed_ds_type target
        SET dataset_usage_count = StatsQ.DatasetCount,
            dataset_usage_last_year = StatsQ.DatasetCountLastYear        -- Usage over the last 12 months
        FROM (SELECT IGDT.instrument_group,
                     IGDT.dataset_type,
                     Coalesce(CountQ.DatasetCount, 0) AS DatasetCount,
                     Coalesce(CountQ.DatasetCountLastYear, 0) AS DatasetCountLastYear
              FROM t_instrument_group_allowed_ds_type IGDT
                   LEFT OUTER JOIN (SELECT InstName.instrument_group,
                                           DTN.Dataset_Type,
                                           COUNT(DS.dataset_id) AS DatasetCount,
                                           SUM(CASE
                                                   WHEN DS.Created >= _thresholdOneYear THEN 1
                                                   ELSE 0
                                               END) AS DatasetCountLastYear
                                    FROM t_dataset DS
                                         INNER JOIN t_instrument_name InstName
                                           ON DS.instrument_id = InstName.instrument_id
                                         INNER JOIN T_Dataset_Type_Name DTN
                                           ON DS.dataset_type_id = DTN.dataset_type_id
                                    GROUP BY InstName.instrument_group, DTN.Dataset_Type
                                   ) CountQ
                     ON IGDT.instrument_group = CountQ.instrument_group AND
                        IGDT.Dataset_Type = CountQ.Dataset_Type
             ) StatsQ
        WHERE target.instrument_group = StatsQ.instrument_group AND
              target.Dataset_Type = StatsQ.Dataset_Type AND
              (
                  target.dataset_usage_count     IS DISTINCT FROM StatsQ.DatasetCount OR
                  target.dataset_usage_last_year IS DISTINCT FROM StatsQ.DatasetCountLastYear
              );

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update dataset counts in t_instrument_group_allowed_ds_type',
               Extract(epoch from (clock_timestamp() - _startTime));

        ------------------------------------------------
        -- Update Usage Counts for Instruments, by dataset type
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        -- Add missing rows to t_cached_instrument_dataset_type_usage

        INSERT INTO t_cached_instrument_dataset_type_usage (
            instrument_id,
            dataset_type
        )
        SELECT DISTINCT InstName.instrument_id,
               GT.dataset_type AS Dataset_Type
        FROM t_instrument_name InstName
             INNER JOIN t_instrument_group_allowed_ds_type GT
               ON GT.instrument_group = InstName.instrument_group
             LEFT OUTER JOIN t_cached_instrument_dataset_type_usage CachedUsage
               ON InstName.instrument_id = CachedUsage.instrument_id AND
                  GT.dataset_type = CachedUsage.dataset_type
        WHERE CachedUsage.instrument_id IS NULL
        ORDER BY instrument_id, dataset_type;

        -- Remove extra rows from t_cached_instrument_dataset_type_usage

        DELETE FROM t_cached_instrument_dataset_type_usage
        WHERE entry_id IN (SELECT CachedData.entry_id
                           FROM t_instrument_group_allowed_ds_type AS GT
                                INNER JOIN t_instrument_name AS InstName
                                  ON GT.instrument_group = InstName.instrument_group
                                RIGHT OUTER JOIN t_cached_instrument_dataset_type_usage AS CachedData
                                  ON GT.dataset_type = CachedData.dataset_type AND
                                     InstName.instrument_id = CachedData.instrument_id
                           WHERE GT.instrument_group IS NULL);

        -- Update stats in t_cached_instrument_dataset_type_usage

        UPDATE t_cached_instrument_dataset_type_usage target
        SET dataset_usage_count = StatsQ.DatasetCount,
            dataset_usage_last_year = StatsQ.DatasetCountLastYear
        FROM (SELECT IDTU.instrument_id,
                     IDTU.dataset_type,
                     Coalesce(CountQ.DatasetCount, 0) AS DatasetCount,
                     Coalesce(CountQ.DatasetCountLastYear, 0) AS DatasetCountLastYear
              FROM t_cached_instrument_dataset_type_usage IDTU
                   LEFT OUTER JOIN (SELECT InstName.Instrument_ID,
                                           DTN.Dataset_Type AS Dataset_Type,
                                           COUNT(DS.dataset_id) AS DatasetCount,
                                           SUM(CASE WHEN DS.Created >= _thresholdOneYear THEN 1
                                                    ELSE 0
                                               END) AS DatasetCountLastYear
                                     FROM t_dataset DS
                                          INNER JOIN t_instrument_name InstName
                                            ON DS.instrument_id = InstName.instrument_id
                                          INNER JOIN T_Dataset_Type_Name DTN
                                            ON DS.dataset_type_id = DTN.dataset_type_id
                                     GROUP BY InstName.instrument_id, DTN.Dataset_Type
                                    ) CountQ
                     ON IDTU.instrument_id = CountQ.instrument_id AND
                        IDTU.dataset_type = CountQ.dataset_type
               ) StatsQ
        WHERE target.instrument_id = StatsQ.instrument_id AND
              target.dataset_type = StatsQ.dataset_type AND
              (
                  target.dataset_usage_count     IS DISTINCT FROM StatsQ.DatasetCount OR
                  target.dataset_usage_last_year IS DISTINCT FROM StatsQ.DatasetCountLastYear
              );

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update dataset counts in t_cached_instrument_dataset_type_usage',
               Extract(epoch from (clock_timestamp() - _startTime));

        ------------------------------------------------
        -- Update Usage Counts for Protein Collections
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        CALL public.update_protein_collection_usage (
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update usage counts for protein collections',
               Extract(epoch from (clock_timestamp() - _startTime));
    End If;

    If _updateGeneralStatistics Then

        ------------------------------------------------
        -- Make sure t_general_statistics contains the required categories and labels
        ------------------------------------------------

        _startTime := CURRENT_TIMESTAMP;

        CREATE TEMP TABLE Tmp_StatEntries (
            Category text NOT NULL,
            Label text NOT NULL,
            SQL text NOT NULL,
            UseDecimal boolean NOT NULL DEFAULT false,
            UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
        );

        INSERT INTO Tmp_StatEntries (Category, Label, SQL, UseDecimal)
        VALUES ('Job_Count', 'All',          'SELECT COUNT(job) FROM t_analysis_job;', false),
               ('Job_Count', 'Last 7 days',  'SELECT COUNT(job) FROM t_analysis_job WHERE created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', false),
               ('Job_Count', 'Last 30 days', 'SELECT COUNT(job) FROM t_analysis_job WHERE created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', false),
               ('Job_Count', 'New',          'SELECT COUNT(job) FROM t_analysis_job WHERE job_state_id = 1;', false),

               ('Campaign_Count', 'All',          'SELECT COUNT(campaign_id) FROM t_campaign;', false),
               ('Campaign_Count', 'Last 7 days',  'SELECT COUNT(campaign_id) FROM t_campaign WHERE created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', false),
               ('Campaign_Count', 'Last 30 days', 'SELECT COUNT(campaign_id) FROM t_campaign WHERE created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', false),

               ('CellCulture_Count', 'All',          'SELECT COUNT(biomaterial_id) FROM t_biomaterial;', false),
               ('CellCulture_Count', 'Last 7 days',  'SELECT COUNT(biomaterial_id) FROM t_biomaterial WHERE Created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', false),
               ('CellCulture_Count', 'Last 30 days', 'SELECT COUNT(biomaterial_id) FROM t_biomaterial WHERE Created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', false),

               ('Dataset_Count', 'All',          'SELECT COUNT(dataset_id) FROM t_dataset;', false),
               ('Dataset_Count', 'Last 7 days',  'SELECT COUNT(dataset_id) FROM t_dataset WHERE created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', false),
               ('Dataset_Count', 'Last 30 days', 'SELECT COUNT(dataset_id) FROM t_dataset WHERE created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', false),

               ('Experiment_Count', 'All',          'SELECT COUNT(exp_id) FROM t_experiments;', false),
               ('Experiment_Count', 'Last 7 days',  'SELECT COUNT(exp_id) FROM t_experiments WHERE created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', false),
               ('Experiment_Count', 'Last 30 days', 'SELECT COUNT(exp_id) FROM t_experiments WHERE created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', false),

               ('Organism_Count', 'All',          'SELECT COUNT(organism_id) FROM t_organisms;', false),
               ('Organism_Count', 'Last 7 days',  'SELECT COUNT(organism_id) FROM t_organisms WHERE created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', false),
               ('Organism_Count', 'Last 30 days', 'SELECT COUNT(organism_id) FROM t_organisms WHERE created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', false),

               ('RawDataTB', 'All',          'SELECT Round(SUM(Coalesce(file_size_bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM t_dataset;', true),
               ('RawDataTB', 'Last 7 days',  'SELECT Round(SUM(Coalesce(file_size_bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM t_dataset WHERE created > CURRENT_TIMESTAMP - INTERVAL ''2 days'';', true),
               ('RawDataTB', 'Last 30 days', 'SELECT Round(SUM(Coalesce(file_size_bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM t_dataset WHERE created > CURRENT_TIMESTAMP - INTERVAL ''30 days'';', true);

        ------------------------------------------------
        -- Use the queries in Tmp_StatEntries to update t_general_statistics
        ------------------------------------------------

        RAISE INFO '';

        FOR _statEntry IN
            SELECT Category,
                   Label,
                   SQL,
                   UseDecimal
            FROM Tmp_StatEntries
            ORDER BY UniqueID
        LOOP
            If _previewSql Then
                RAISE INFO '%', _statEntry.SQL;
                CONTINUE;
            End If;

            ------------------------------------------------
            -- Run the query in _statEntry.Sql; store the value for _total in t_general_statistics
            ------------------------------------------------

            If Not _statEntry.UseDecimal Then
                EXECUTE _statEntry.Sql
                INTO _totalDec;

                _value := Coalesce(_totalDec, 0)::text;

            Else

                EXECUTE _statEntry.Sql
                INTO _total;

                _value := Coalesce(_total, 0)::text;

            End If;

            If Exists (SELECT entry_id FROM t_general_statistics WHERE category = _statEntry.Category AND label = _statEntry.Label) Then
                UPDATE t_general_statistics
                SET value = _value, last_affected = CURRENT_TIMESTAMP
                WHERE category = _statEntry.Category AND
                      label = _statEntry.Label AND
                      value IS DISTINCT FROM _value;
            Else
                INSERT INTO t_general_statistics (
                    category,
                    label,
                    value,
                    last_affected
                )
                VALUES (_statEntry.Category, _statEntry.Label, _value, CURRENT_TIMESTAMP);
            End If;

        END LOOP;

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update values in t_general_statistics',
               Extract(epoch from (clock_timestamp() - _startTime));

    End If;

    If _updateJobRequestStatistics Then

        _startTime := CURRENT_TIMESTAMP;

        UPDATE t_analysis_job_request target
        SET job_count = StatsQ.JobCount
        FROM (SELECT AJR.request_id,
                     SUM(CASE WHEN AJ.job IS NULL THEN 0
                              ELSE 1
                         END) AS JobCount
              FROM t_analysis_job_request AJR
                   INNER JOIN t_users U
                     ON AJR.user_id = U.user_id
                   INNER JOIN t_analysis_job_request_state AJRS
                     ON AJR.request_state_id = AJRS.request_state_id
                   INNER JOIN t_organisms Org
                     ON AJR.organism_id = Org.organism_id
                   LEFT OUTER JOIN t_analysis_job AJ
                     ON AJR.request_id = AJ.request_id
              GROUP BY AJR.request_id
             ) StatsQ
        WHERE target.request_id = StatsQ.request_id AND
              target.job_count IS DISTINCT FROM StatsQ.JobCount;

        INSERT INTO Tmp_Update_Stats (Task, Runtime_Seconds)
        SELECT 'Update job counts in t_analysis_job_request',
               Extract(epoch from (clock_timestamp() - _startTime));
    End If;

    If _showRuntimeStats Then

        RAISE INFO '';

        FOR _statInfo IN
            SELECT Entry_ID, Task, Runtime_Seconds::numeric
            FROM Tmp_Update_Stats
            UNION
            SELECT 15 AS Entry_ID,
                   'Total runtime' AS Task,
                   (SUM(Runtime_Seconds))::numeric AS Runtime_Seconds
            FROM Tmp_Update_Stats
            ORDER BY Entry_ID
        LOOP
            RAISE INFO '%: % seconds', _statInfo.Task, Round(_statInfo.Runtime_Seconds, 1);
        END LOOP;

    End If;

    DROP TABLE Tmp_Update_Stats;

    If _updateGeneralStatistics Then
        DROP TABLE Tmp_StatEntries;
    End If;
END
$$;


ALTER PROCEDURE public.update_cached_statistics(INOUT _message text, INOUT _returncode text, IN _previewsql boolean, IN _updateparamsettingsfilecounts boolean, IN _updategeneralstatistics boolean, IN _updatejobrequeststatistics boolean, IN _showruntimestats boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_statistics(INOUT _message text, INOUT _returncode text, IN _previewsql boolean, IN _updateparamsettingsfilecounts boolean, IN _updategeneralstatistics boolean, IN _updatejobrequeststatistics boolean, IN _showruntimestats boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_statistics(INOUT _message text, INOUT _returncode text, IN _previewsql boolean, IN _updateparamsettingsfilecounts boolean, IN _updategeneralstatistics boolean, IN _updatejobrequeststatistics boolean, IN _showruntimestats boolean) IS 'UpdateCachedStatistics';

