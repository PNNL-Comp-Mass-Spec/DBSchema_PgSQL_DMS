--
CREATE OR REPLACE PROCEDURE public.store_project_usage_stats
(
    _windowDays int = 7,
    _endDate timestamp = null,
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Stores new stats in T_Project_Usage_Stats,
**      tracking the number of datasets and user-initiated analysis jobs
**      run within the specified date range
**
**      This procedure is called weekly at 3 am on Friday morning
**      to auto-update the stats
**
**  Arguments:
**    _endDate   End date/time; if null, uses the current date/time
**
**  Auth:   mem
**  Date:   12/18/2015 mem - Initial version
**          05/06/2016 mem - Now tracking experiments
**          02/24/2017 mem - Update the Merge logic to join on Proposal_User
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**          05/16/2022 mem - Add renamed proposal type 'Resource Owner'
**          05/18/2022 mem - Add Capacity, Partner, and Staff Time proposal types
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _startDate timestamp;
    _endDateYear int;
    _endDateWeek int;
BEGIN
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _windowDays := Coalesce(_windowDays, 7);
    If (_windowDays < 1) Then
        _windowDays := 1;
    End If;

    _endDate := Coalesce(_endDate, CURRENT_TIMESTAMP);
    _infoOnly := Coalesce(_infoOnly, false);

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
        StartDate timestamp NOT NULL,
        EndDate timestamp NOT NULL,
        TheYear int NOT NULL,
        WeekOfYear int NOT NULL,
        Proposal_ID text NULL,
        work_package text NULL,
        Proposal_Active int NOT NULL,
        Project_Type_ID int NOT NULL,
        Samples int not NULL,
        Datasets int not NULL,
        Jobs int not NULL,
        EUS_UsageType int NOT NULL,
        Proposal_Type text NULL,
        Proposal_User text NULL,
        Instrument_First text NULL,
        Instrument_Last text NULL,
        JobTool_First text NULL,
        JobTool_Last text NULL,
    )

    -----------------------------------------
    -- Find datasets run within the date range
    -----------------------------------------
    --
    INSERT INTO Tmp_Project_Usage_Stats( StartDate,
                                         EndDate,
                                         TheYear,
                                         WeekOfYear,
                                         Proposal_ID,
                                         work_package,
                                         Proposal_Active,
                                         Project_Type_ID,
                                         Samples,
                                         Datasets,
                                         Jobs,
                                         EUS_UsageType,
                                         Proposal_Type,
                                         Proposal_User,
                                         Instrument_First,
                                         Instrument_Last,
                                         JobTool_First,
                                         JobTool_Last )
    SELECT _startdate AS StartDate,
           _endDate AS EndDate,
           _endDateYear AS TheYear,
           _endDateWeek AS WeekOfYear,
           EUSPro.Proposal_ID,
           RR.work_package,
           CASE
               WHEN CURRENT_TIMESTAMP >= EUSPro.Proposal_Start_Date AND
                    CURRENT_TIMESTAMP <= EUSPro.Proposal_End_Date THEN 1
               ELSE 0
           END AS Proposal_Active,
           CASE
               WHEN EUSPro.Proposal_Type IN ('Resource Owner') THEN 1                                             -- Resource Owner
               WHEN EUSPro.Proposal_Type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public') THEN 2    -- Proprietary
               WHEN EUSPro.Proposal_Type IN ('Capacity') THEN 4                                                   -- Capacity (replaces Proprietary Public)
               WHEN EUSPro.Proposal_Type IN ('Partner') THEN 5                                                    -- Partner
               WHEN EUSPro.Proposal_Type IN ('Staff Time') THEN 6                                                 -- Staff Time
               WHEN EUSPro.Proposal_Type NOT IN ('Capacity', 'Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner', 'Staff Time') THEN 3  -- EMSL_User
               ELSE 0                                                                                             -- Unknown
           END AS Project_Type_ID,
           0 AS Samples,
           COUNT(*) AS Datasets,
           0 AS Jobs,
           RR.eus_usage_type_id AS EUS_UsageType,
           EUSPro.proposal_type,
           MIN(EUSUsers.name_fm) AS Proposal_User,
           MIN(InstName.instrument) AS Instrument_First,
           MAX(InstName.instrument) AS Instrument_Last,
           Cast(NULL AS text) AS JobTool_First,
           Cast(NULL AS text) AS JobTool_Last
    FROM t_instrument_name InstName
         INNER JOIN t_dataset DS
                    INNER JOIN t_requested_run RR
                      ON DS.dataset_id = RR.dataset_id
           ON InstName.instrument_id = DS.instrument_id
         LEFT OUTER JOIN t_eus_users EUSUsers
                         INNER JOIN t_requested_run_eus_users RRUsers
                           ON EUSUsers.person_id = RRUsers.eus_person_id
           ON RR.request_id = RRUsers.request_id
         LEFT OUTER JOIN t_eus_proposals EUSPro
           ON RR.eus_proposal_id = EUSPro.proposal_id
    WHERE DS.created BETWEEN _startDate AND _endDate
    GROUP BY EUSPro.proposal_id, RR.work_package, RR.eus_usage_type_id, EUSPro.Proposal_Type,
             EUSPro.proposal_start_date, EUSPro.proposal_end_date
    ORDER BY COUNT(*) DESC

    -----------------------------------------
    -- Find user-initiated analysis jobs started within the date range
    -- Store in t_project_usage_stats via a merge
    -----------------------------------------
    --
    MERGE INTO Tmp_Project_Usage_Stats AS t
    USING ( SELECT _startdate AS StartDate,
                   _endDate AS EndDate,
                   _endDateYear AS TheYear,
                   _endDateWeek AS WeekOfYear,
                   EUSPro.Proposal_ID,
                   RR.work_package,
                   CASE
                       WHEN CURRENT_TIMESTAMP >= EUSPro.Proposal_Start_Date AND
                            CURRENT_TIMESTAMP <= EUSPro.Proposal_End_Date THEN 1
                       ELSE 0
                   END AS Proposal_Active,
                   CASE
                       WHEN EUSPro.Proposal_Type IN ('Resource Owner') THEN 1                                             -- Resource Owner
                       WHEN EUSPro.Proposal_Type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public') THEN 2    -- Proprietary
                       WHEN EUSPro.Proposal_Type IN ('Capacity') THEN 4                                                   -- Capacity (replaces Proprietary Public)
                       WHEN EUSPro.Proposal_Type IN ('Partner') THEN 5                                                    -- Partner
                       WHEN EUSPro.Proposal_Type IN ('Staff Time') THEN 6                                                 -- Staff Time
                       WHEN EUSPro.Proposal_Type NOT IN ('Capacity', 'Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner', 'Staff Time') THEN 3  -- EMSL_User
                       ELSE 0                                                                                             -- Unknown
                   END AS Project_Type_ID,
                   0 AS Samples,
                   0 AS Datasets,
                   COUNT(*) AS Jobs,
                   RR.eus_usage_type_id AS EUS_UsageType,
                   EUSPro.proposal_type,
                   MIN(EUSUsers.name_fm) AS Proposal_User,
                   MIN(InstName.instrument) AS Instrument_First,
                   MAX(InstName.instrument) AS Instrument_Last,
                   MIN(AnTool.analysis_tool) AS JobTool_First,
                   MAX(AnTool.analysis_tool) AS JobTool_Last
             FROM t_instrument_name InstName
                  INNER JOIN t_dataset DS
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
                    ON InstName.instrument_id = DS.instrument_id
                  LEFT OUTER JOIN t_eus_users EUSUsers
                                  INNER JOIN t_requested_run_eus_users RRUsers
                                    ON EUSUsers.person_id = RRUsers.eus_person_id
                    ON RR.request_id = RRUsers.request_id
                  LEFT OUTER JOIN t_eus_proposals EUSPro
                    ON RR.eus_proposal_id = EUSPro.proposal_id
             GROUP BY EUSPro.Proposal_ID, RR.work_package, RR.eus_usage_type_id, EUSPro.Proposal_Type,
                      EUSPro.proposal_start_date, EUSPro.proposal_end_date
          ) AS s
    ON (t.TheYear = s.TheYear AND
        t.WeekOfYear = s.WeekOfYear AND
        Coalesce(t.proposal_id, 0) = Coalesce(s.proposal_id, 0) AND
        t.work_package = s.work_package AND
        t.EUS_UsageType = s.EUS_UsageType AND
        Coalesce(t.Proposal_User, '') = Coalesce(s.Proposal_User, ''))
    WHEN MATCHED AND t.Jobs IS DISTINCT FROM s.Jobs THEN
        UPDATE SET
            Jobs = s.Jobs,
            JobTool_First = s.JobTool_First,
            JobTool_Last = s.JobTool_Last
    WHEN NOT MATCHED THEN
        INSERT (StartDate, EndDate, TheYear, WeekOfYear, proposal_id,
                work_package, Proposal_Active, Project_Type_ID,
                Samples, datasets, Jobs, EUS_UsageType, proposal_type, Proposal_User,
                Instrument_First, Instrument_Last,
                JobTool_First, JobTool_Last)
        VALUES (s.StartDate, s.EndDate, s.TheYear, s.WeekOfYear, s.proposal_id,
                s.work_package, s.Proposal_Active, s.Project_Type_ID,
                s.Samples, s.datasets, s.Jobs, s.EUS_UsageType, s.proposal_type, s.Proposal_User,
                s.Instrument_First, s.Instrument_Last,
                s.JobTool_First, s.JobTool_Last);

    -----------------------------------------
    -- Find experiments (samples) prepared within the date range
    -- Store in t_project_usage_stats via a merge
    -----------------------------------------
    --
    MERGE INTO Tmp_Project_Usage_Stats AS t
    USING ( SELECT _startdate AS StartDate,
                   _endDate AS EndDate,
                   _endDateYear AS TheYear,
                   _endDateWeek AS WeekOfYear,
                   EUSPro.Proposal_ID,
                   SPR.Work_Package_Number,
                   CASE
                       WHEN CURRENT_TIMESTAMP >= EUSPro.Proposal_Start_Date AND
                            CURRENT_TIMESTAMP <= EUSPro.Proposal_End_Date THEN 1
                       ELSE 0
                   END AS Proposal_Active,
                   CASE
                       WHEN EUSPro.Proposal_Type IN ('Resource Owner') THEN 1                                             -- Resource Owner
                       WHEN EUSPro.Proposal_Type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public') THEN 2    -- Proprietary
                       WHEN EUSPro.Proposal_Type IN ('Capacity') THEN 4                                                   -- Capacity (replaces Proprietary Public)
                       WHEN EUSPro.Proposal_Type IN ('Partner') THEN 5                                                    -- Partner
                       WHEN EUSPro.Proposal_Type IN ('Staff Time') THEN 6                                                 -- Staff Time
                       WHEN EUSPro.Proposal_Type NOT IN ('Capacity', 'Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner', 'Staff Time') THEN 3  -- EMSL_User
                       ELSE 0                                                                                             -- Unknown
                   END AS Project_Type_ID,
                   COUNT(DISTINCT exp_id) AS Samples,
                   0 AS Datasets,
                   0 AS Jobs,
                   UsageType.prep_request_id AS EUS_UsageType,
                   EUSPro.proposal_type,
                   MIN(EUSUsers.name_fm) AS Proposal_User,
                   '' AS Instrument_First,
                   '' AS Instrument_Last,
                   '' AS JobTool_First,
                   '' AS JobTool_Last
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
                     EUSPro.proposal_type, SPR.eus_user_id, UsageType.prep_request_id
         ) AS s
    ON (t.TheYear = s.TheYear AND
        t.WeekOfYear = s.WeekOfYear AND
        Coalesce(t.proposal_id, 0) = Coalesce(s.proposal_id, 0) AND
        t.work_package = s.work_package AND
        t.eus_usage_type = s.eus_usage_type AND
        Coalesce(t.Proposal_User, '') = Coalesce(s.Proposal_User, ''))
    WHEN MATCHED AND t.Samples IS DISTINCT FROM s.Samples THEN
        UPDATE SET
            Samples = s.Samples
    WHEN NOT MATCHED THEN
        INSERT(StartDate, EndDate, TheYear, WeekOfYear, proposal_id,
              work_package, Proposal_Active, Project_Type_ID,
              Samples, Datasets, Jobs, eus_usage_type, proposal_type, Proposal_User,
              Instrument_First, Instrument_Last,
              JobTool_First, JobTool_Last)
        VALUES(s.StartDate, s.EndDate, s.TheYear, s.WeekOfYear, s.proposal_id,
               s.work_package, s.Proposal_Active, s.Project_Type_ID,
               s.Samples, s.Datasets, s.Jobs, s.eus_usage_type, s.proposal_type, s.Proposal_User,
               s.Instrument_First, s.Instrument_Last,
               s.JobTool_First, s.JobTool_Last);

    If _infoOnly Then

        -- ToDo: Show this data using RAISE INFO

        SELECT Stats.Entry_ID,
               Stats.StartDate,
               Stats.EndDate,
               Stats.TheYear,
               Stats.WeekOfYear,
               Stats.proposal_id,
               Stats.work_package,
               Stats.Proposal_Active,
               ProjectTypes.project_type_name,
               Stats.Samples,
               Stats.Datasets,
               Stats.Jobs,
               EUSUsage.eus_usage_type AS UsageType,
               Stats.proposal_type,
               Stats.Proposal_User,
               Proposals.title AS Proposal_Title,
               Stats.Instrument_First,
               Stats.Instrument_Last,
               Stats.JobTool_First,
               Stats.JobTool_Last,
               Cast(Proposals.proposal_start_date AS date) AS Proposal_Start_Date,
               Cast(Proposals.proposal_end_date AS date) AS Proposal_End_Date
        FROM Tmp_Project_Usage_Stats Stats
             INNER JOIN t_project_usage_types ProjectTypes
               ON Stats.project_type_id = ProjectTypes.project_type_id
             INNER JOIN t_eus_usage_type EUSUsage
               ON Stats.EUS_UsageType = EUSUsage.eus_usage_type_id
             LEFT OUTER JOIN t_eus_proposals Proposals
               ON Stats.proposal_id = Proposals.proposal_id
        ORDER BY Datasets DESC, Jobs DESC, Samples Desc

    Else
        DELETE FROM t_project_usage_stats
        WHERE the_year = _endDateYear AND
              week_of_year = _endDateWeek AND
              Cast(end_date AS date) = Cast(_endDate AS date)

        INSERT INTO t_project_usage_stats( start_date,
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
                                           job_tool_last )
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
        ORDER BY datasets DESC, jobs DESC

    End If;

    DROP TABLE Tmp_Project_Usage_Stats(
END
$$;

COMMENT ON PROCEDURE public.store_project_usage_stats IS 'StoreProjectUsageStats';
