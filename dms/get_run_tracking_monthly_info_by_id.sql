--
-- Name: get_run_tracking_monthly_info_by_id(integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_run_tracking_monthly_info_by_id(_eusinstrumentid integer, _year integer, _month integer, _options text DEFAULT ''::text) RETURNS TABLE(seq integer, id integer, dataset text, day integer, duration integer, "interval" integer, time_start timestamp without time zone, time_end timestamp without time zone, instrument text, comment_state text, comment text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return run tracking information for given EUS Instrument ID
**      Modeled after Get_Run_Tracking_Monthly_Info
**
**  Arguments:
**    _eusInstrumentId  EUS Instrument ID
**    _year             Year
**    _month            Month
**    _options          Reserved for future use
**
**  Auth:   mem
**  Date:   02/14/2012 mem - Initial release
**          04/27/2020 mem - Update data validation checks
**                         - Make several columns in the output table nullable
**          06/23/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          05/22/2023 mem - Capitalize reserved words
**          05/30/2023 mem - Replace * with specific column names when returning query results
**                         - Use format() for string concatenation
**          07/27/2023 mem - Add missing assignment to _firstRunSeq
**          08/28/2023 mem - Use new column name "dataset_id" when querying t_run_interval
**          08/29/2023 mem - Add missing table aliases
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _maxNormalInterval int;
    _message text := '';
    _instrumentIDFirst int;
    _firstDayOfStartingMonth timestamp;
    _firstDayOfTrailingMonth timestamp;
    _seqIncrement int := 1;
    _seqOffset int := 0;
    _firstRunSeq int;
    _lastRunSeq int;
    _firstStart timestamp;
    _initialGap int;
    _preceedingDataset record;
    _lastRunStart timestamp;
    _lastRunEnd timestamp;
    _lastRunInterval int;
BEGIN

    CREATE TEMP Table Tmp_TX (
        Seq int primary key,
        ID int NULL,
        Dataset text,
        Day int NULL,
        Duration int NULL,
        "interval" int NULL,
        Time_Start timestamp NULL,
        Time_End timestamp NULL,
        Instrument text NULL,
        Comment_State text NULL,
        Comment text NULL
    );

    ---------------------------------------------------
    -- Check arguments
    ---------------------------------------------------

    If Coalesce(_year, 0) = 0 Or Coalesce(_month, 0) = 0 Or Coalesce(_eusInstrumentId, 0) = 0 Then
        INSERT INTO Tmp_TX (Seq, Dataset)
        VALUES (1, 'Bad arguments');

        RETURN QUERY
        SELECT T.Seq, T.ID, T.Dataset, T.Day, T.Duration, T."interval",
               T.Time_Start, T.Time_End, T.Instrument,
               T.Comment_State, T.Comment
        FROM Tmp_TX T;

        DROP TABLE Tmp_TX;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate _eusInstrumentId
    ---------------------------------------------------

    SELECT InstName.instrument_id
    INTO _instrumentIDFirst
    FROM t_instrument_name AS InstName
         INNER JOIN t_emsl_dms_instrument_mapping AS InstMapping
           ON InstName.instrument_id = InstMapping.dms_instrument_id
    WHERE InstMapping.eus_instrument_id = _eusInstrumentId
    ORDER BY InstName.instrument
    LIMIT 1;

    If Coalesce(_instrumentIDFirst, 0) = 0 Then
        INSERT INTO Tmp_TX (Seq, Dataset)
        VALUES (1, format('Unrecognized EUS ID; no DMS instruments are mapped to EUS Instrument ID %s', _eusInstrumentId));

        RETURN QUERY
        SELECT T.Seq, T.ID, T.Dataset, T.Day, T.Duration, T."interval",
               T.Time_Start, T.Time_End, T.Instrument,
               T.Comment_State, T.Comment
        FROM Tmp_TX T;

        DROP TABLE Tmp_TX;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Set up dates for beginning and end of month
    ---------------------------------------------------

    _firstDayOfStartingMonth := make_date(_year, _month, 1);
    _firstDayOfTrailingMonth := _firstDayOfStartingMonth + Interval '1 month';

    ---------------------------------------------------
    -- Get datasets whose start time falls within month
    ---------------------------------------------------

    INSERT INTO Tmp_TX ( seq,
                         id,
                         dataset,
                         day,
                         time_Start,
                         time_end,
                         duration,
                         "interval",
                         instrument
                       )
    SELECT (_seqIncrement * ((Row_Number() OVER (ORDER BY TD.acq_time_start ASC)) - 1) + 1) + _seqOffset AS seq,
           TD.dataset_id AS id,
           TD.dataset AS dataset,
           Extract(day FROM TD.acq_time_start) AS day,
           TD.acq_time_start AS time_start,
           TD.acq_time_end AS time_end,
           TD.acq_length_minutes AS duration,
           TD.interval_to_next_ds AS "interval",
           _instrumentIDFirst AS Instrument
    FROM t_dataset AS TD
         INNER JOIN t_emsl_dms_instrument_mapping AS InstMapping
           ON TD.instrument_id = InstMapping.dms_instrument_id
    WHERE InstMapping.eus_instrument_id = _eusInstrumentId AND
          TD.acq_time_start >= _firstDayOfStartingMonth AND
          TD.acq_time_start <  _firstDayOfTrailingMonth
    ORDER BY TD.acq_time_start;

    ---------------------------------------------------
    -- Need to add some part of run or interval from
    -- preceding month if first run in month is not
    -- close to beginning of month
    ---------------------------------------------------

    SELECT MIN(Tmp_TX.seq), MAX(Tmp_TX.seq)
    INTO _firstRunSeq, _lastRunSeq
    FROM Tmp_TX;

    SELECT Tmp_TX.time_start
    INTO _firstStart
    FROM Tmp_TX
    WHERE Tmp_TX.seq = _firstRunSeq;

    -- The long interval threshold is 180 minutes
    _maxNormalInterval := public.get_long_interval_threshold();

    -- Get preceeding dataset (latest with starting time preceding this month)
    -- Use "extract(epoch ...) / 60.0" to get the difference in minutes between the two timestamps

    If extract(epoch FROM (_firstStart - _firstDayOfStartingMonth)) / 60.0 > _maxNormalInterval Then
        SELECT TD.dataset_id AS id,
               TD.dataset AS dataset,
               TD.acq_time_start AS start,
               TD.acq_time_end AS end,
               TD.acq_length_minutes AS duration,
               TD.interval_to_next_ds AS "interval"
        INTO _preceedingDataset
        FROM t_dataset AS TD
             INNER JOIN t_emsl_dms_instrument_mapping AS InstMapping
               ON TD.instrument_id = InstMapping.dms_instrument_id
        WHERE InstMapping.eus_instrument_id = _eusInstrumentId AND
              TD.acq_time_start < _firstDayOfStartingMonth AND
              TD.acq_time_start > _firstDayOfStartingMonth - Interval '90 days'
        ORDER BY TD.acq_time_start DESC
        LIMIT 1;

        _initialGap := extract(epoch FROM (_firstStart - _firstDayOfStartingMonth)) / 60.0;

        -- If preceeding dataset's end time is before start of month, zero the duration and truncate the interval,
        -- otherwise just truncate the duration

        If _precEnd < _firstDayOfStartingMonth Then
            _preceedingDataset.duration := 0;
            _preceedingDataset."interval" := _initialGap;
        Else
            _preceedingDataset.duration := extract(epoch FROM (_precStart - _firstDayOfStartingMonth)) / 60.0;
        End If;

        -- Add preceeding dataset record (with truncated duration/interval)
        -- at beginning of results

        INSERT INTO Tmp_TX ( seq,
                             dataset,
                             id,
                             day,
                             time_start,
                             time_end,
                             duration,
                             "interval",
                             instrument )
        VALUES( _firstRunSeq - 1,               -- seq
                _preceedingDataset.dataset,
                _preceedingDataset.id,
                1,                              -- Day of month
                _preceedingDataset.start,
                _preceedingDataset.end,
                _preceedingDataset.duration,
                _preceedingDataset."interval",
                _instrumentIDFirst);
    End If;

    ---------------------------------------------------
    -- Need to truncate part of last run or following
    -- interval that hangs over end of month
    ---------------------------------------------------

    -- If end of last run hangs over start of succeeding month,
    -- truncate duration and set interval to zero

    -- Otherwise, if interval hangs over succeeding month, truncate it

    SELECT Tmp_TX.time_start,
           Tmp_TX.time_end,
           Tmp_TX."interval"       -- Interval, in minutes
    INTO _lastRunStart, _lastRunEnd, _lastRunInterval
    FROM Tmp_TX
    WHERE Tmp_TX.seq = _lastRunSeq;

    If _lastRunEnd > _firstDayOfTrailingMonth Then
        UPDATE Tmp_TX
        SET "interval" = 0,
            duration = extract(epoch FROM (_firstDayOfTrailingMonth - _lastRunStart)) / 60.0
        WHERE Tmp_TX.Seq = _lastRunSeq;
    ElsIf _lastRunEnd + make_interval(mins => _lastRunInterval) > _firstDayOfTrailingMonth Then
        UPDATE Tmp_TX
        SET "interval" = extract(epoch FROM (_firstDayOfTrailingMonth - _lastRunEnd)) / 60.0
        WHERE Tmp_TX.Seq = _lastRunSeq;
    End If;

    ---------------------------------------------------
    -- Fill in interval comment information
    ---------------------------------------------------

    UPDATE Tmp_TX
    SET comment = I.comment,
        comment_state = CASE WHEN Coalesce(I.comment, '') = ''
                             THEN '-'
                             ELSE '+'
                        END
    FROM t_run_interval I
    WHERE Tmp_TX.ID = I.dataset_id;

    UPDATE Tmp_TX
    SET comment_state = 'x'
    WHERE Tmp_TX.comment_state IS NULL;

    RETURN QUERY
    SELECT T.Seq, T.ID, T.Dataset, T.Day, T.Duration, T."interval",
           T.Time_Start, T.Time_End, T.Instrument,
           T.Comment_State, T.Comment
    FROM Tmp_TX T;

    DROP TABLE Tmp_TX;
END
$$;


ALTER FUNCTION public.get_run_tracking_monthly_info_by_id(_eusinstrumentid integer, _year integer, _month integer, _options text) OWNER TO d3l243;

--
-- Name: FUNCTION get_run_tracking_monthly_info_by_id(_eusinstrumentid integer, _year integer, _month integer, _options text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_run_tracking_monthly_info_by_id(_eusinstrumentid integer, _year integer, _month integer, _options text) IS 'GetRunTrackingMonthlyInfoByID';

