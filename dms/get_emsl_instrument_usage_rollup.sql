--
-- Name: get_emsl_instrument_usage_rollup(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_emsl_instrument_usage_rollup(_year integer, _month integer) RETURNS TABLE(emsl_inst_id integer, dms_instrument public.citext, month integer, day integer, proposal public.citext, usage public.citext, minutes integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Desc:
**      Outputs contents of EMSL instrument usage report table as rollup
**      This function is used by the CodeIgniter instance at https://prismsupport.pnl.gov/dms2ws/
**
**      Example URL:
**      https://prismsupport.pnl.gov/dms2ws/instrument_usage_report/rollup/2019/03
**
**      See also /files1/www/html/prismsupport/dms2ws/application/controllers/Instrument_usage_report.php
**
**  Auth:   grk
**  Date:   09/11/2012 grk - initial release
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Use Dataset_ID instead of ID
**          03/17/2022 mem - Only return rows where Dataset_ID_Acq_Overlap is Null
**          06/20/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          04/20/2023 mem - Cast to float8 for clarity
**
*****************************************************/
DECLARE
    _continue boolean;
BEGIN
    -- Table for processing runs and intervals for reporting month
    --
    CREATE TEMP TABLE Tmp_T_Working
    (
        Dataset_ID int null,
        EMSL_Inst_ID int null,
        DMS_Instrument text null,
        Type text null,             -- Dataset or Interval
        Proposal text null,
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
        Remaining_Duration_Seconds int null
    );

    -- Intermediate storage for report entries
    --
    CREATE TEMP TABLE Tmp_T_Report_Accumulation
    (
        Start timestamp,
        Duration_Seconds int,
        Month int,
        Day int,
        EMSL_Inst_ID int,
        DMS_Instrument citext,
        Proposal citext,
        Usage citext
    );

    -- Import entries from EMSL instrument usage table
    -- for given month and year into working table
    --
    INSERT INTO Tmp_T_Working
    ( Dataset_ID,
      EMSL_Inst_ID,
      DMS_Instrument,
      Type,
      Proposal,
      Usage,
      Run_or_Interval_Start,
      Duration_Seconds,
      Year,
      Month
    )
    SELECT InstUsage.dataset_id,
           InstUsage.emsl_inst_id,
           InstName.instrument AS DMS_Instrument,
           InstUsage.type,
           InstUsage.proposal,
           InstUsageType.usage_type AS Usage,
           InstUsage.start,
           InstUsage.minutes * 60 AS Duration_Seconds,
           InstUsage.year,
           InstUsage.month
    FROM t_emsl_instrument_usage_report InstUsage
         INNER JOIN t_instrument_name InstName
           ON InstUsage.dms_inst_id = InstName.instrument_id
         LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
    WHERE InstUsage.year = _year AND
          InstUsage.month = _month AND
          InstUsage.dataset_id_acq_overlap Is Null;

    _continue := true;

    -- While loop to pull records out of working table
    -- into accumulation table, allowing for durations that
    -- cross daily boundaries
    --
    WHILE _continue
    LOOP

        -- Update working table with end times
        --
        UPDATE  Tmp_T_Working AS W
        SET     Day = Extract(day from W.Run_or_Interval_Start),
                Run_or_Interval_End =                 W.Run_or_Interval_Start + make_interval(secs => W.Duration_Seconds),
                Day_at_Run_End =   Extract(day   from W.Run_or_Interval_Start + make_interval(secs => W.Duration_Seconds)),
                Month_at_Run_End = Extract(month from W.Run_or_Interval_Start + make_interval(secs => W.Duration_Seconds)),
                End_Of_Day =            date_trunc('day', W.Run_or_Interval_Start) + Interval '1 day' - Interval '1 millisecond',
                Beginning_Of_Next_Day = date_trunc('day', W.Run_or_Interval_Start) + Interval '1 day';
        --
        UPDATE  Tmp_T_Working AS W
        SET     Duration_Seconds_In_Current_Day =               extract(epoch FROM (End_Of_Day - W.Run_or_Interval_Start)),
                Remaining_Duration_Seconds = Duration_Seconds - extract(epoch FROM (End_Of_Day - W.Run_or_Interval_Start));

        -- Copy usage records that do not span more than one day
        -- from working table to accumulation table, they are ready for report
        --
        INSERT INTO Tmp_T_Report_Accumulation (
            EMSL_Inst_ID,
            DMS_Instrument,
            Proposal,
            Usage,
            Start,
            --Minutes,
            Duration_Seconds,
            Month,
            Day
        )
        SELECT  W.EMSL_Inst_ID,
                W.DMS_Instrument,
                W.Proposal,
                W.Usage,
                W.Run_or_Interval_Start,
                W.Duration_Seconds,
                W.Month,
                W.Day
        FROM Tmp_T_Working W
        WHERE W.Day = W.Day_at_Run_End AND
              W.Month = W.Month_at_Run_End;

        -- Remove report entries from working table
        -- whose duration does not cross daily boundary
        --
        DELETE FROM Tmp_T_Working
        WHERE Remaining_Duration_Seconds < 0;

        -- Copy report entries into accumulation table for
        -- remaining durations (cross daily boundaries)
        -- using only duration time contained inside daily boundary
        --
        INSERT INTO Tmp_T_Report_Accumulation (
            EMSL_Inst_ID,
            DMS_Instrument,
            Proposal,
            Usage,
            Start,
            Duration_Seconds,
            Month,
            Day
        )
        SELECT
            W.EMSL_Inst_ID,
            W.DMS_Instrument,
            W.Proposal,
            W.Usage,
            W.Run_or_Interval_Start,
            W.Duration_Seconds_In_Current_Day AS Duration_Seconds,
            W.Month,
            W.Day
        FROM Tmp_T_Working W;

        -- Update start time and duration of entries in working table
        --
        UPDATE Tmp_T_Working
        SET Run_or_Interval_Start = Beginning_Of_Next_Day,
            Duration_Seconds = Remaining_Duration_Seconds,
            Day = NULL,
            Run_or_Interval_End = NULL,
            Day_at_Run_End = NULL,
            End_Of_Day = NULL,
            Beginning_Of_Next_Day = NULL,
            Duration_Seconds_In_Current_Day = NULL,
            Remaining_Duration_Seconds = NULL;

        -- We are done when there is nothing left to process in working table
        --
        If Not Exists (SELECT * FROM Tmp_T_Working) Then
            _continue := false;
        End If;

    END LOOP;

    ----------------------------------------------------
    -- Return the contents of Tmp_T_Report_Accumulation
    ----------------------------------------------------

    RETURN QUERY
    SELECT Src.EMSL_Inst_ID,
           Src.DMS_Instrument::citext,
           Src.Month,
           Src.Day,
           Src.Proposal::citext,
           Src.Usage::citext,
           CEILING(SUM(Src.Duration_Seconds)::float8 / 60)::int AS Minutes
    FROM Tmp_T_Report_Accumulation AS Src
    GROUP BY Src.EMSL_Inst_ID,
             Src.DMS_Instrument,
             Src.Proposal,
             Src.Usage,
             Src.Month,
             Src.Day
    ORDER BY Src.EMSL_Inst_ID,
             Src.DMS_Instrument,
             Src.Month,
             Src.Day,
             Minutes DESC;

    DROP TABLE Tmp_T_Working;
    DROP TABLE Tmp_T_Report_Accumulation;
END
$$;


ALTER FUNCTION public.get_emsl_instrument_usage_rollup(_year integer, _month integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_emsl_instrument_usage_rollup(_year integer, _month integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_emsl_instrument_usage_rollup(_year integer, _month integer) IS 'GetEMSLInstrumentUsageRollup';

