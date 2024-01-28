--
-- Name: get_emsl_instrument_usage_daily_details(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_emsl_instrument_usage_daily_details(_year integer, _month integer) RETURNS TABLE(emsl_inst_id integer, instrument public.citext, type public.citext, start timestamp without time zone, minutes integer, proposal public.citext, usage public.citext, users public.citext, operator public.citext, comment public.citext, year integer, month integer, id integer, id_acq_overlap integer, seq integer, updated timestamp without time zone, updated_by public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Output contents of EMSL instrument usage report table as a daily rollup, including rows with Dataset_ID_Acq_Overlap
**      This function is used by the CodeIgniter instance at http://prismsupport.pnl.gov/dms2ws/
**
**      Example URL:
**      https://prismsupport.pnl.gov/dms2ws/instrument_usage_report/dailydetails/2020/03
**
**      See also /files1/www/html/prismsupport/dms2ws/application/controllers/Instrument_usage_report.php
**
**  Auth:   grk
**  Date:   09/15/2015 grk - Initial release, modeled after GetEMSLInstrumentUsageDaily
**          10/20/2015 grk - Added users to output
**          02/10/2016 grk - Added rollup of comments and operators
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/09/2020 mem - Truncate the concatenated comment if over 4090 characters long
**          04/18/2020 mem - Update to show dataset details for all datasets that are not Maintenance runs
**                         - Saved as new UDF named GetEMSLInstrumentUsageDailyDetails
**          04/27/2020 mem - Populate the Seq column using Seq values in T_EMSL_Instrument_Usage_Report
**          03/17/2022 mem - Add ID_Acq_Overlap (from Dataset_ID_Acq_Overlap) to the output
**          06/20/2022 mem - Ported to PostgreSQL
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          10/22/2022 mem - Directly pass value to function argument
**          04/20/2023 mem - Cast to float8 for clarity
**          05/31/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _continue boolean;
BEGIN
    -- Table for processing runs and intervals for reporting month

    CREATE TEMP TABLE Tmp_T_Working
    (
        Dataset_ID int null,
        EMSL_Inst_ID int null,
        DMS_Instrument text null,
        Type text null,             -- Dataset or Interval
        Proposal text null,
        Users citext null,
        Usage text null,
        Run_or_Interval_Start timestamp null,
        Run_or_Interval_End timestamp null,
        End_Of_Day timestamp null,
        Year int null,
        Month int null,
        Day int null,
        Day_at_Run_End int null,
        Month_at_Run_End int null,
        Beginning_Of_Next_Day timestamp null,
        Duration_Seconds int null,
        Duration_Seconds_In_Current_Day int null,
        Remaining_Duration_Seconds int null,
        Dataset_ID_Acq_Overlap int null,
        Comment text null,
        Operator int null,
        Seq int null
    );

    -- Intermediate storage for report entries

    CREATE TEMP TABLE Tmp_T_Report_Accumulation
    (
        Start timestamp,
        Duration_Seconds int,
        Month int,
        Day int,
        Dataset_ID int,
        EMSL_Inst_ID int,
        DMS_Instrument citext,
        Proposal citext,
        Usage citext,
        Year int null,
        Type citext,
        Users citext null,
        Operator citext null,        -- Could be a comma-separated list of Operator IDs
        Dataset_ID_Acq_Overlap int null,
        Comment citext null,
        Seq int null
    );

    -- Import entries from EMSL instrument usage table
    -- for given month and year into working table

    INSERT INTO Tmp_T_Working
    ( Dataset_ID,
      EMSL_Inst_ID,
      DMS_Instrument,
      Type,
      Proposal,
      Usage,
      Users,
      Run_or_Interval_Start,
      Duration_Seconds,
      Year,
      Month,
      Dataset_ID_Acq_Overlap,
      Comment,
      Operator,
      Seq
    )
    SELECT InstUsage.dataset_id,
           InstUsage.emsl_inst_id,
           InstName.instrument AS DMS_Instrument,
           InstUsage.type,
           InstUsage.proposal,
           InstUsageType.usage_type AS Usage,
           InstUsage.users,
           InstUsage.start,
           InstUsage.minutes * 60 AS Duration_Seconds,
           InstUsage.year,
           InstUsage.month,
           InstUsage.dataset_id_acq_overlap,
           InstUsage.comment,
           InstUsage.operator,
           InstUsage.seq
    FROM t_emsl_instrument_usage_report InstUsage
         INNER JOIN t_instrument_name InstName
           ON InstUsage.dms_inst_id = InstName.instrument_id
         LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
    WHERE InstUsage.year  = _year AND
          InstUsage.month = _month;

    _continue := true;

    -- While loop to pull records out of working table
    -- into accumulation table
    --
    -- For datasets that start on one day and end on another day (i.e. are mid-acquisition at midnight)
    -- we will copy those datasets into Tmp_T_Report_Accumulation twice (or three times if the run lasts 3 days)
    -- This is done so that we can accurately record instrument usage time on the first day, plus the additional time used on the second day
    --
    -- For example, if a dataset is 30 minutes long and is started at 11:40 pm on April 17,
    -- this dataset will be listed in Tmp_T_Report_Accumulation as:
    --  a. starting at 11:40 pm on April 17 and lasting 20 minutes
    --  b. starting at 12:00 am on April 18 and lasting 10 minutes

    WHILE _continue
    LOOP

        -- Update working table with end times

        UPDATE Tmp_T_Working AS W
        SET Day                   = Extract(day   from W.Run_or_Interval_Start),
            Run_or_Interval_End   =                    W.Run_or_Interval_Start + make_interval(secs => W.Duration_Seconds),
            Day_at_Run_End        = Extract(day   from W.Run_or_Interval_Start + make_interval(secs => W.Duration_Seconds)),
            Month_at_Run_End      = Extract(month from W.Run_or_Interval_Start + make_interval(secs => W.Duration_Seconds)),
            End_Of_Day            = date_trunc('day', W.Run_or_Interval_Start) + Interval '1 day' - Interval '1 millisecond',
            Beginning_Of_Next_Day = date_trunc('day', W.Run_or_Interval_Start) + Interval '1 day';

        UPDATE  Tmp_T_Working AS W
        SET     Duration_Seconds_In_Current_Day =               extract(epoch FROM (End_Of_Day - W.Run_or_Interval_Start)),
                Remaining_Duration_Seconds = Duration_Seconds - extract(epoch FROM (End_Of_Day - W.Run_or_Interval_Start));

        -- Copy usage records that do not span more than one day
        -- from working table to accumulation table

        INSERT INTO Tmp_T_Report_Accumulation (
            EMSL_Inst_ID,
            DMS_Instrument,
            Proposal,
            Usage,
            Users,
            Start,
            --Minutes,
            Duration_Seconds,
            Year,
            Month,
            Day,
            Dataset_ID,
            Type,
            Dataset_ID_Acq_Overlap,
            Comment,
            Operator,
            Seq
        )
        SELECT W.EMSL_Inst_ID,
               W.DMS_Instrument,
               W.Proposal,
               W.Usage,
               W.Users,
               W.Run_or_Interval_Start,
               W.Duration_Seconds,
               W.Year,
               W.Month,
               W.Day,
               W.Dataset_ID,
               W.Type,
               W.Dataset_ID_Acq_Overlap,
               W.Comment,
               W.Operator::text,
               W.Seq
        FROM Tmp_T_Working W
        WHERE W.Day   = W.Day_at_Run_End AND
              W.Month = W.Month_at_Run_End;

        -- Remove the usage records that we just copied into Tmp_T_Report_Accumulation

        DELETE FROM Tmp_T_Working W
        WHERE W.Day   = W.Day_at_Run_End AND
              W.Month = W.Month_at_Run_End;

        -- Also remove any rows that have a negative value for RemainingDurationSeconds
        -- This will be true for any datasets that were started in the evening on the last day of the month
        -- and were still acquiring data when we reached midnight and entered a new month

        DELETE FROM Tmp_T_Working W
        WHERE W.Remaining_Duration_Seconds < 0;

        -- Copy report entries into accumulation table for
        -- remaining durations (datasets that cross daily boundaries)
        -- using only duration time contained inside the daily boundary

        INSERT INTO Tmp_T_Report_Accumulation (
            EMSL_Inst_ID,
            DMS_Instrument,
            Proposal,
            Usage,
            Users,
            Start,
            Duration_Seconds,
            Year,
            Month,
            Day,
            Dataset_ID,
            Type,
            Dataset_ID_Acq_Overlap,
            Comment,
            Operator,
            Seq
        )
        SELECT W.EMSL_Inst_ID,
               W.DMS_Instrument,
               W.Proposal,
               W.Usage,
               W.Users,
               W.Run_or_Interval_Start,
               W.Duration_Seconds_In_Current_Day AS Duration_Seconds,
               W.Year,
               W.Month,
               W.Day,
               W.Dataset_ID,
               W.Type,
               W.Dataset_ID_Acq_Overlap,
               W.Comment,
               W.Operator::text,
               W.Seq
        FROM Tmp_T_Working W;

        -- Update start time and duration of entries in working table

        UPDATE Tmp_T_Working
        SET Run_or_Interval_Start = Beginning_Of_Next_Day,
            Duration_Seconds = Remaining_Duration_Seconds,
            Day = NULL,
            Run_or_Interval_End = NULL,
            Day_at_Run_End = NULL,
            Month_at_Run_End = NULL,
            End_Of_Day = NULL,
            Beginning_Of_Next_Day = NULL,
            Duration_Seconds_In_Current_Day = NULL,
            Remaining_Duration_Seconds = NULL;

        -- We are done when there is nothing left to process in working table

        If Not Exists (SELECT * FROM Tmp_T_Working) Then
            _continue := false;
        End If;

    END LOOP;

    ----------------------------------------------------
    -- Rollup comments and update the accumulation table
    -- Only do this rollup for rows where the usage is 'AVAILABLE', 'BROKEN', or 'MAINTENANCE'
    ----------------------------------------------------

    UPDATE Tmp_T_Report_Accumulation
    SET Comment = CASE WHEN char_length(GroupQ.Comment) > 4090
                       THEN format('%s ...', Substring(GroupQ.Comment, 1, 4090))
                       ELSE GroupQ.Comment
                  END
    FROM ( SELECT DistinctQ.EMSL_Inst_ID,
                  DistinctQ.DMS_Instrument,
                  DistinctQ.Type,
                  DistinctQ.Proposal,
                  DistinctQ.Usage,
                  DistinctQ.Users,
                  DistinctQ.Year,
                  DistinctQ.Month,
                  DistinctQ.Day,
                  string_agg(DistinctQ.Comment, ',' Order By DistinctQ.Comment) AS Comment
           FROM (SELECT DISTINCT Src.EMSL_Inst_ID,
                                 Src.DMS_Instrument,
                                 Src.Type,
                                 Src.Proposal,
                                 Src.Usage,
                                 Src.Users,
                                 Src.Year,
                                 Src.Month,
                                 Src.Day,
                                 Src.Comment
                FROM Tmp_T_Report_Accumulation Src
                WHERE Src.Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')) AS DistinctQ
           GROUP BY DistinctQ.EMSL_Inst_ID,
                    DistinctQ.DMS_Instrument,
                    DistinctQ.Type,
                    DistinctQ.Proposal,
                    DistinctQ.Usage,
                    DistinctQ.Users,
                    DistinctQ.Year,
                    DistinctQ.Month,
                    DistinctQ.Day
           ) AS GroupQ
        WHERE Tmp_T_Report_Accumulation.EMSL_Inst_ID = GroupQ.EMSL_Inst_ID AND
              Tmp_T_Report_Accumulation.DMS_Instrument = GroupQ.DMS_Instrument AND
              Tmp_T_Report_Accumulation.Type = GroupQ.Type AND
              Tmp_T_Report_Accumulation.Proposal = GroupQ.Proposal AND
              Tmp_T_Report_Accumulation.Usage = GroupQ.Usage AND
              Tmp_T_Report_Accumulation.Users = GroupQ.Users AND
              Tmp_T_Report_Accumulation.Year = GroupQ.Year AND
              Tmp_T_Report_Accumulation.Month = GroupQ.Month AND
              Tmp_T_Report_Accumulation.Day = GroupQ.Day;

    -- Rollup operators and add to the accumulation table

    UPDATE Tmp_T_Report_Accumulation
    SET Operator = GroupQ.Operator
    FROM ( SELECT DistinctQ.EMSL_Inst_ID,
                  DistinctQ.DMS_Instrument,
                  DistinctQ.Type,
                  DistinctQ.Proposal,
                  DistinctQ.Usage,
                  DistinctQ.Users,
                  DistinctQ.Year,
                  DistinctQ.Month,
                  DistinctQ.Day,
                  string_agg(DistinctQ.Operator, ',' Order By DistinctQ.Operator) AS Operator
           FROM (SELECT DISTINCT Src.EMSL_Inst_ID,
                                 Src.DMS_Instrument,
                                 Src.Type,
                                 Src.Proposal,
                                 Src.Usage,
                                 Src.Users,
                                 Src.Year,
                                 Src.Month,
                                 Src.Day,
                                 Src.Operator
                FROM Tmp_T_Report_Accumulation Src
                WHERE Src.Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')) AS DistinctQ
           GROUP BY DistinctQ.EMSL_Inst_ID,
                    DistinctQ.DMS_Instrument,
                    DistinctQ.Type,
                    DistinctQ.Proposal,
                    DistinctQ.Usage,
                    DistinctQ.Users,
                    DistinctQ.Year,
                    DistinctQ.Month,
                    DistinctQ.Day
           ) AS GroupQ
    WHERE Tmp_T_Report_Accumulation.EMSL_Inst_ID = GroupQ.EMSL_Inst_ID AND
          Tmp_T_Report_Accumulation.DMS_Instrument = GroupQ.DMS_Instrument AND
          Tmp_T_Report_Accumulation.Type = GroupQ.Type AND
          Tmp_T_Report_Accumulation.Proposal = GroupQ.Proposal AND
          Tmp_T_Report_Accumulation.Usage = GroupQ.Usage AND
          Tmp_T_Report_Accumulation.Users = GroupQ.Users AND
          Tmp_T_Report_Accumulation.Year = GroupQ.Year AND
          Tmp_T_Report_Accumulation.Month = GroupQ.Month AND
          Tmp_T_Report_Accumulation.Day = GroupQ.Day;

    ----------------------------------------------------
    -- Return the contents of Tmp_T_Report_Accumulation
    ----------------------------------------------------

    -- First return non-maintenance datasets
    -- Include each dataset as a separate row

    RETURN QUERY
    SELECT Src.EMSL_Inst_ID,
           Src.DMS_Instrument::citext AS Instrument,
           Src.Type::citext,
           MIN(Src.Start) AS Start,
           CEILING(SUM(Src.Duration_Seconds)::float8 / 60)::int AS Minutes,
           Src.Proposal::citext,
           Src.Usage::citext,
           Src.Users::citext,
           Src.Operator::citext,
           Src.Comment::citext,
           Src.Year,
           Src.Month,
           Src.Dataset_ID,
           Src.Dataset_ID_Acq_Overlap,
           MIN(Src.Seq) as Seq,
           NULL::timestamp AS Updated,
           NULL::citext AS UpdatedBy
    FROM Tmp_T_Report_Accumulation Src
    WHERE NOT Src.Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')
    GROUP BY Src.EMSL_Inst_ID,
             Src.DMS_Instrument,
             Src.Type,
             Src.Proposal,
             Src.Usage,
             Src.Users,
             Src.Operator,
             Src.Comment,
             Src.Year,
             Src.Month,
             Src.Day,
             Src.Dataset_ID,
             Src.Dataset_ID_Acq_Overlap
    ORDER BY Src.EMSL_Inst_ID DESC,
             Src.DMS_Instrument DESC,
             Src.Month DESC,
             Src.Day ASC,
             MIN(Src.Start) ASC;

    -- Next return maintenance datasets, where we report one entry per day

    RETURN QUERY
    SELECT Src.EMSL_Inst_ID,
           Src.DMS_Instrument::citext AS Instrument,
           Src.Type::citext,
           MIN(Src.Start) AS Start,
           CEILING(SUM(Src.Duration_Seconds)::float8 / 60)::int AS Minutes,
           Src.Proposal::citext,
           Src.Usage::citext,
           Src.Users::citext,
           Src.Operator::citext,
           Src.Comment::citext,
           Src.Year,
           Src.Month,
           NULL::int AS Dataset_ID,             -- Store null since we're rolling up multiple rows
           NULL::int As Dataset_ID_Acq_Overlap,
           MIN(Src.Seq) as Seq,
           NULL::timestamp AS Updated,
           NULL::citext AS UpdatedBy
    FROM Tmp_T_Report_Accumulation Src
    WHERE Src.Usage IN ('AVAILABLE', 'BROKEN', 'MAINTENANCE')
    GROUP BY Src.EMSL_Inst_ID,
             Src.DMS_Instrument,
             Src.Type,
             Src.Proposal,
             Src.Usage,
             Src.Users,
             Src.Operator,
             Src.Comment,
             Src.Year,
             Src.Month,
             Src.Day
    ORDER BY Src.EMSL_Inst_ID DESC,
             Src.DMS_Instrument DESC,
             Src.Month DESC,
             MIN(Src.Start) ASC;

    DROP TABLE Tmp_T_Working;
    DROP TABLE Tmp_T_Report_Accumulation;
END
$$;


ALTER FUNCTION public.get_emsl_instrument_usage_daily_details(_year integer, _month integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_emsl_instrument_usage_daily_details(_year integer, _month integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_emsl_instrument_usage_daily_details(_year integer, _month integer) IS 'GetEMSLInstrumentUsageDailyDetails';

