--
-- Name: store_project_usage_stats(integer, timestamp without time zone, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_project_usage_stats(IN _windowdays integer DEFAULT 7, IN _enddate timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store new stats in t_project_usage_stats, tracking the number of datasets and
**      user-initiated analysis jobs created within the specified date range
**
**      This procedure is called weekly at 3 am on Friday morning to auto-update the stats
**
**  Arguments:
**    _windowDays   Number of days prior to _endDate (or the current date) to examine
**    _endDate      End date/time; if null, uses the current date/time
**    _infoOnly     When true, preview the new stats
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   12/18/2015 mem - Initial version
**          05/06/2016 mem - Now tracking experiments
**          02/24/2017 mem - Update the Merge logic to join on Proposal_User
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**          05/16/2022 mem - Add renamed proposal type 'Resource Owner'
**          05/18/2022 mem - Add Capacity, Partner, and Staff Time proposal types
**          02/24/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _startDate timestamp;
    _endDateYear int;
    _endDateWeek int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _windowDays := Coalesce(_windowDays, 7);
    _endDate    := Coalesce(_endDate, CURRENT_TIMESTAMP);
    _infoOnly   := Coalesce(_infoOnly, false);

    If _windowDays < 1 Then
        _windowDays := 1;
    End If;

    -- Round _endDate backward to the nearest hour
    _endDate := date_trunc('hour', _endDate);

    _startDate := _endDate - make_interval(days => _windowDays);

    _endDateYear := date_part('year', _endDate);
    _endDateWeek := date_part('week', _endDate);

    -----------------------------------------
    -- Create a temporary table
    -----------------------------------------

    CREATE TEMP TABLE Tmp_Project_Usage_Stats(
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Start_Date timestamp NOT NULL,
        End_Date timestamp NOT NULL,
        The_Year int NOT NULL,
        Week_Of_Year int NOT NULL,
        Proposal_ID text NULL,
        Work_Package text NULL,
        Proposal_Active int NOT NULL,
        Project_Type_ID int NOT NULL,
        Samples int NOT NULL,
        Datasets int NOT NULL,
        Jobs int NOT NULL,
        EUS_Usage_Type_ID int NOT NULL,
        Proposal_Type text NULL,
        Proposal_User text NULL,
        Instrument_First text NULL,
        Instrument_Last text NULL,
        Job_Tool_First text NULL,
        Job_Tool_Last text NULL
    );

    -----------------------------------------
    -- Find datasets run within the date range
    -----------------------------------------

    INSERT INTO Tmp_Project_Usage_Stats (
        Start_Date,
        End_Date,
        The_Year,
        Week_Of_Year,
        Proposal_ID,
        work_package,
        Proposal_Active,
        Project_Type_ID,
        Samples,
        Datasets,
        Jobs,
        EUS_Usage_Type_ID,
        Proposal_Type,
        Proposal_User,
        Instrument_First,
        Instrument_Last,
        Job_Tool_First,
        Job_Tool_Last
    )
    SELECT _startdate   AS Start_Date,
           _endDate     AS End_Date,
           _endDateYear AS The_Year,
           _endDateWeek AS Week_Of_Year,
           EUSPro.Proposal_ID,
           RR.work_package,
           CASE
               WHEN CURRENT_TIMESTAMP >= EUSPro.Proposal_Start_Date AND
                    CURRENT_TIMESTAMP <= EUSPro.Proposal_End_Date
               THEN 1
               ELSE 0
           END AS Proposal_Active,
           CASE
               WHEN EUSPro.Proposal_Type IN ('Resource Owner') THEN 1                                             -- Resource Owner
               WHEN EUSPro.Proposal_Type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public') THEN 2    -- Proprietary
               WHEN EUSPro.Proposal_Type IN ('Capacity') THEN 4                                                   -- Capacity (replaces Proprietary Public)
               WHEN EUSPro.Proposal_Type IN ('Partner') THEN 5                                                    -- Partner
               WHEN EUSPro.Proposal_Type IN ('Staff Time') THEN 6                                                 -- Staff Time
               WHEN NOT EUSPro.Proposal_Type IN ('Capacity', 'Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner', 'Staff Time') THEN 3  -- EMSL_User
               ELSE 0                                                                                             -- Unknown
           END AS Project_Type_ID,
           0 AS Samples,
           COUNT(DS.dataset_id) AS Datasets,
           0 AS Jobs,
           RR.eus_usage_type_id,
           EUSPro.proposal_type,
           MIN(EUSUsers.name_fm) AS Proposal_User,
           MIN(InstName.instrument) AS Instrument_First,
           MAX(InstName.instrument) AS Instrument_Last,
           null::text AS Job_Tool_First,
           null::text AS Job_Tool_Last
    FROM t_instrument_name InstName
         INNER JOIN t_dataset DS
           ON InstName.instrument_id = DS.instrument_id
         INNER JOIN t_requested_run RR
           ON DS.dataset_id = RR.dataset_id
         LEFT OUTER JOIN t_eus_users EUSUsers
                         INNER JOIN t_requested_run_eus_users RRUsers
                           ON EUSUsers.person_id = RRUsers.eus_person_id
           ON RR.request_id = RRUsers.request_id
         LEFT OUTER JOIN t_eus_proposals EUSPro
           ON RR.eus_proposal_id = EUSPro.proposal_id
    WHERE DS.created BETWEEN _startDate AND _endDate
    GROUP BY EUSPro.proposal_id, RR.work_package, RR.eus_usage_type_id, EUSPro.Proposal_Type,
             EUSPro.proposal_start_date, EUSPro.proposal_end_date
    ORDER BY COUNT(DS.dataset_id) DESC;

    -----------------------------------------
    -- Find user-initiated analysis jobs started within the date range
    -- Store in t_project_usage_stats via a merge
    -----------------------------------------

    MERGE INTO Tmp_Project_Usage_Stats AS t
    USING (SELECT _startdate AS Start_Date,
                  _endDate AS End_Date,
                  _endDateYear AS The_Year,
                  _endDateWeek AS Week_Of_Year,
                  EUSPro.Proposal_ID,
                  RR.work_package,
                  CASE
                      WHEN CURRENT_TIMESTAMP >= EUSPro.Proposal_Start_Date AND
                           CURRENT_TIMESTAMP <= EUSPro.Proposal_End_Date
                      THEN 1
                      ELSE 0
                  END AS Proposal_Active,
                  CASE
                      WHEN EUSPro.Proposal_Type IN ('Resource Owner') THEN 1                                             -- Resource Owner
                      WHEN EUSPro.Proposal_Type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public') THEN 2    -- Proprietary
                      WHEN EUSPro.Proposal_Type IN ('Capacity') THEN 4                                                   -- Capacity (replaces Proprietary Public)
                      WHEN EUSPro.Proposal_Type IN ('Partner') THEN 5                                                    -- Partner
                      WHEN EUSPro.Proposal_Type IN ('Staff Time') THEN 6                                                 -- Staff Time
                      WHEN NOT EUSPro.Proposal_Type IN ('Capacity', 'Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner', 'Staff Time') THEN 3  -- EMSL_User
                      ELSE 0                                                                                             -- Unknown
                  END AS Project_Type_ID,
                  0 AS Samples,
                  0 AS Datasets,
                  COUNT(J.job) AS Jobs,
                  RR.eus_usage_type_id,
                  EUSPro.proposal_type,
                  MIN(EUSUsers.name_fm) AS Proposal_User,
                  MIN(InstName.instrument) AS Instrument_First,
                  MAX(InstName.instrument) AS Instrument_Last,
                  MIN(AnTool.analysis_tool) AS Job_Tool_First,
                  MAX(AnTool.analysis_tool) AS Job_Tool_Last
           FROM t_instrument_name InstName
                INNER JOIN t_dataset DS
                  ON InstName.instrument_id = DS.instrument_id
                INNER JOIN t_requested_run RR
                  ON DS.dataset_id = RR.dataset_id
                INNER JOIN t_analysis_job J
                  ON J.dataset_id = DS.dataset_id AND
                     J.start BETWEEN _startDate AND _endDate
                INNER JOIN t_analysis_job_request AJR
                  ON AJR.request_id = J.request_id AND
                     AJR.request_id > 1
                INNER JOIN t_analysis_tool AnTool
                  ON J.analysis_tool_id = AnTool.analysis_tool_id
                LEFT OUTER JOIN t_eus_users EUSUsers
                                INNER JOIN t_requested_run_eus_users RRUsers
                                  ON EUSUsers.person_id = RRUsers.eus_person_id
                  ON RR.request_id = RRUsers.request_id
                LEFT OUTER JOIN t_eus_proposals EUSPro
                  ON RR.eus_proposal_id = EUSPro.proposal_id
           GROUP BY EUSPro.Proposal_ID, RR.work_package, RR.eus_usage_type_id, EUSPro.Proposal_Type,
                     EUSPro.proposal_start_date, EUSPro.proposal_end_date
          ) AS s
    ON (t.The_Year = s.The_Year AND
        t.Week_Of_Year = s.Week_Of_Year AND
        t.proposal_id = s.proposal_id AND
        t.work_package = s.work_package AND
        t.eus_usage_type_id = s.eus_usage_type_id AND
        Coalesce(t.Proposal_User, '') = Coalesce(s.Proposal_User, ''))
    WHEN MATCHED AND t.Jobs IS DISTINCT FROM s.Jobs THEN
        UPDATE SET
            Jobs           = s.Jobs,
            Job_Tool_First = s.Job_Tool_First,
            Job_Tool_Last  = s.Job_Tool_Last
    WHEN NOT MATCHED THEN
        INSERT (start_date, end_date, the_year, week_of_year, proposal_id,
                work_package, proposal_active, project_type_id,
                samples, datasets, jobs, eus_usage_type_id, proposal_type, proposal_user,
                instrument_first, instrument_last,
                job_tool_first, job_tool_last)
        VALUES (s.Start_Date, s.End_Date, s.The_Year, s.Week_Of_Year, s.Proposal_ID,
                s.Work_Package, s.Proposal_Active, s.Project_Type_ID,
                s.Samples, s.Datasets, s.Jobs, s.EUS_Usage_Type_ID, s.Proposal_Type, s.Proposal_User,
                s.Instrument_First, s.Instrument_Last,
                s.Job_Tool_First, s.Job_Tool_Last);

    -----------------------------------------
    -- Find experiments (samples) prepared within the date range
    -- Store in t_project_usage_stats via a merge
    -----------------------------------------

    MERGE INTO Tmp_Project_Usage_Stats AS t
    USING (SELECT _startdate AS Start_Date,
                  _endDate AS End_Date,
                  _endDateYear AS The_Year,
                  _endDateWeek AS Week_Of_Year,
                  EUSPro.Proposal_ID,
                  SPR.Work_Package,
                  CASE
                      WHEN CURRENT_TIMESTAMP >= EUSPro.Proposal_Start_Date AND
                           CURRENT_TIMESTAMP <= EUSPro.Proposal_End_Date
                      THEN 1
                      ELSE 0
                  END AS Proposal_Active,
                  CASE
                      WHEN EUSPro.Proposal_Type IN ('Resource Owner') THEN 1                                             -- Resource Owner
                      WHEN EUSPro.Proposal_Type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public') THEN 2    -- Proprietary
                      WHEN EUSPro.Proposal_Type IN ('Capacity') THEN 4                                                   -- Capacity (replaces Proprietary Public)
                      WHEN EUSPro.Proposal_Type IN ('Partner') THEN 5                                                    -- Partner
                      WHEN EUSPro.Proposal_Type IN ('Staff Time') THEN 6                                                 -- Staff Time
                      WHEN NOT EUSPro.Proposal_Type IN ('Capacity', 'Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner', 'Staff Time') THEN 3  -- EMSL_User
                      ELSE 0                                                                                             -- Unknown
                  END AS Project_Type_ID,
                  COUNT(DISTINCT exp_id) AS Samples,
                  0 AS Datasets,
                  0 AS Jobs,
                  UsageType.eus_usage_type_id,
                  EUSPro.proposal_type,
                  MIN(EUSUsers.name_fm) AS Proposal_User,
                  '' AS Instrument_First,
                  '' AS Instrument_Last,
                  '' AS Job_Tool_First,
                  '' AS Job_Tool_Last
           FROM t_sample_prep_request SPR
                INNER JOIN t_eus_proposals EUSPro
                  ON SPR.eus_proposal_id = EUSPro.proposal_id
                INNER JOIN t_eus_usage_type UsageType
                  ON SPR.eus_usage_type = UsageType.eus_usage_type
                LEFT OUTER JOIN t_experiments
                  ON SPR.prep_request_id = t_experiments.sample_prep_request_id
                LEFT OUTER JOIN t_eus_users AS EUSUsers
                  ON SPR.eus_user_id = EUSUsers.person_id
           WHERE t_experiments.created BETWEEN _startDate and _endDate
           GROUP BY EUSPro.proposal_id, SPR.work_package, EUSPro.proposal_start_date, EUSPro.Proposal_End_Date,
                    EUSPro.proposal_type, SPR.eus_user_id, UsageType.eus_usage_type_id
         ) AS s
    ON (t.The_Year = s.The_Year AND
        t.Week_Of_Year = s.Week_Of_Year AND
        t.proposal_id = s.proposal_id AND
        t.work_package = s.work_package AND
        t.eus_usage_type_ID = s.eus_usage_type_ID AND
        Coalesce(t.Proposal_User, '') = Coalesce(s.Proposal_User, ''))
    WHEN MATCHED AND t.Samples IS DISTINCT FROM s.Samples THEN
        UPDATE SET
            Samples = s.Samples
    WHEN NOT MATCHED THEN
        INSERT (start_date, end_date, the_year, week_of_year, proposal_id,
                work_package, proposal_active, project_type_id,
                samples, datasets, jobs, eus_usage_type_id, proposal_type, proposal_user,
                instrument_first, instrument_last,
                job_tool_first, job_tool_last)
        VALUES (s.Start_Date, s.End_Date, s.The_Year, s.Week_Of_Year, s.Proposal_ID,
                s.Work_Package, s.Proposal_Active, s.Project_Type_ID,
                s.Samples, s.Datasets, s.Jobs, s.EUS_Usage_Type_ID, s.Proposal_Type, s.Proposal_User,
                s.Instrument_First, s.Instrument_Last,
                s.Job_Tool_First, s.Job_Tool_Last);

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-10s %-20s %-20s %-5s %-12s %-11s %-12s %-15s %-19s %-8s %-8s %-8s %-15s %-35s %-35s %-80s %-25s %-25s %-35s %-35s %-14s %-14s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'Start_Date',
                            'End_Date',
                            'Year',
                            'Week_of_Year',
                            'Proposal_ID',
                            'Work_Package',
                            'Proposal_Active',
                            'Project_Type_Name',
                            'Samples',
                            'Datasets',
                            'Jobs',
                            'Usage_Type',
                            'Proposal_Type',
                            'Proposal_User',
                            'Proposal_Title',
                            'Instrument_First',
                            'Instrument_Last',
                            'Job_Tool_First',
                            'Job_Tool_Last',
                            'Proposal_Start',
                            'Proposal_End'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------',
                                     '--------------------',
                                     '-----',
                                     '------------',
                                     '-----------',
                                     '------------',
                                     '---------------',
                                     '-------------------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '---------------',
                                     '-----------------------------------',
                                     '-----------------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '-------------------------',
                                     '-------------------------',
                                     '-----------------------------------',
                                     '-----------------------------------',
                                     '--------------',
                                     '--------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Stats.Entry_ID,
                   public.timestamp_text(Stats.Start_Date) AS Start_Date,
                   public.timestamp_text(Stats.End_Date) AS End_Date,
                   Stats.The_Year,
                   Stats.Week_Of_Year,
                   Stats.Proposal_ID,
                   Stats.Work_Package,
                   Stats.Proposal_Active,
                   ProjectTypes.Project_Type_Name,
                   Stats.Samples,
                   Stats.Datasets,
                   Stats.Jobs,
                   EUSUsage.eus_usage_type AS Usage_Type,
                   Stats.Proposal_Type,
                   Stats.Proposal_User,
                   Left(Replace(Proposals.title, E'\n', ' '), 79) AS Proposal_Title,
                   Stats.Instrument_First,
                   Stats.Instrument_Last,
                   Stats.Job_Tool_First,
                   Stats.Job_Tool_Last,
                   Proposals.proposal_start_date::date AS Proposal_Start,
                   Proposals.proposal_end_date::date   AS Proposal_End
            FROM Tmp_Project_Usage_Stats Stats
                 INNER JOIN t_project_usage_types ProjectTypes
                   ON Stats.project_type_id = ProjectTypes.project_type_id
                 INNER JOIN t_eus_usage_type EUSUsage
                   ON Stats.EUS_Usage_Type_ID = EUSUsage.eus_usage_type_id
                 LEFT OUTER JOIN t_eus_proposals Proposals
                   ON Stats.proposal_id = Proposals.proposal_id
            ORDER BY Datasets DESC, Jobs DESC, Samples DESC
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.Start_Date,
                                _previewData.End_Date,
                                _previewData.The_Year,
                                _previewData.Week_of_Year,
                                _previewData.Proposal_ID,
                                _previewData.Work_Package,
                                _previewData.Proposal_Active,
                                _previewData.Project_Type_Name,
                                _previewData.Samples,
                                _previewData.Datasets,
                                _previewData.Jobs,
                                _previewData.Usage_Type,
                                _previewData.Proposal_Type,
                                _previewData.Proposal_User,
                                _previewData.Proposal_Title,
                                _previewData.Instrument_First,
                                _previewData.Instrument_Last,
                                _previewData.Job_Tool_First,
                                _previewData.Job_Tool_Last,
                                _previewData.Proposal_Start,
                                _previewData.Proposal_End
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Project_Usage_Stats;
        RETURN;
    End If;

    DELETE FROM t_project_usage_stats
    WHERE the_year       = _endDateYear AND
          week_of_year   = _endDateWeek AND
          end_date::date = _endDate::date;

    INSERT INTO t_project_usage_stats (
        start_date,
        end_date,
        the_year,
        week_of_year,
        proposal_id,
        work_package,
        proposal_active,
        project_type_id,
        samples,
        datasets,
        jobs,
        eus_usage_type_id,
        proposal_type,
        proposal_user,
        instrument_first,
        instrument_last,
        job_tool_first,
        job_tool_last
    )
    SELECT start_date,
           end_date,
           the_year,
           week_of_year,
           proposal_id,
           work_package,
           proposal_active,
           project_type_id,
           samples,
           datasets,
           jobs,
           eus_usage_type_id,
           proposal_type,
           proposal_user,
           instrument_first,
           instrument_last,
           job_tool_first,
           job_tool_last
    FROM Tmp_Project_Usage_Stats
    ORDER BY datasets DESC, jobs DESC;

    DROP TABLE Tmp_Project_Usage_Stats;
END
$$;


ALTER PROCEDURE public.store_project_usage_stats(IN _windowdays integer, IN _enddate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_project_usage_stats(IN _windowdays integer, IN _enddate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_project_usage_stats(IN _windowdays integer, IN _enddate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'StoreProjectUsageStats';

