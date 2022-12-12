--
-- Name: get_dataset_instrument_runtime(timestamp without time zone, timestamp without time zone, public.citext, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_instrument_runtime(_startinterval timestamp without time zone, _endinterval timestamp without time zone, _instrument public.citext DEFAULT 'VOrbiETD04'::public.citext, _options public.citext DEFAULT 'Show All'::public.citext) RETURNS TABLE(seq integer, id integer, dataset public.citext, state public.citext, rating public.citext, duration integer, "interval" integer, time_start timestamp without time zone, time_end timestamp without time zone, request integer, eus_proposal public.citext, eus_usage public.citext, eus_proposal_type public.citext, work_package public.citext, lc_column public.citext, instrument public.citext, campaign_id integer, fraction_emsl_funded numeric, campaign_proposals public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns list of datasets and acquisition time information for given instrument
**
**  Arguments:
**     _startInterval   Start date (will be converted to the first day of the month)
**     _endInterval     End date (will be converted to the first day of the next month)
**     _instrument      Instrument name
**     _options         'Show All', 'No Intervals', 'Intervals Only', or 'Long Intervals'
**
**  Auth:   grk
**  Date:   05/26/2011 grk - initial release
**          12/02/2011 mem - Added several Campaign-related columns: Campaign_ID, Fraction_EMSL_Funded, and Campaign_Proposals
**          01/31/2012 grk - Added Interval column to output and made separate interval rows an option
**          02/06/2012 grk - Added _endIntervalEOD padding to pick up trailing interval
**          02/07/2012 grk - Added anchoring of long intervals to beginning and end of month.
**          02/15/2012 mem - Now using T_Dataset.Acq_Length_Minutes
**          06/08/2012 grk - added lookup for _maxNormalInterval
**          04/05/2017 mem - Compute Fraction_EMSL_Funded using EUS usage type (previously computed using CM_Fraction_EMSL_Funded, which is estimated by the user for each campaign)
**          05/16/2022 mem - Add renamed proposal type 'Resource Owner'
**          05/18/2022 mem - Treat additional proposal types as not EMSL funded
**          06/19/2022 mem - Ported to PostgreSQL
**          12/09/2022 mem - Change data type of column Fraction_EMSL_Funded to numeric
**
*****************************************************/
DECLARE
    _maxNormalInterval int;
    _includeAcquisitions int := 1;
    _includeIncrements int := 1;
    _includeStats int := 1;
    _seqIncrement int := 2;
    _seqOffset int := 0;
    _longIntervalsOnly int := 0;
    _anchorIntervalsToMonth int := 0;
    _firstDayOfStartingMonth timestamp;
    _firstDayOfTrailingMonth timestamp;
    _endIntervalEOD timestamp;
    _endSeq int;
    _maxSeq int;
    _startOfNext timestamp;
    _endOfPrevious timestamp;
    _interval int;
    _index int;
    _earliestStart timestamp;
BEGIN
    ---------------------------------------------------
    -- Set up flags that control content
    -- according to selected options
    ---------------------------------------------------

    _anchorIntervalsToMonth := 1;

    If _options = 'Show All' Then
        _includeAcquisitions := 1;
        _includeIncrements := 1;
        _includeStats := 1;
        _longIntervalsOnly := 0;
        _seqIncrement := 2;
    End If;

    If _options = 'No Intervals' Then
        _includeAcquisitions := 1;
        _includeIncrements := 0;
        _includeStats := 0;
        _longIntervalsOnly := 0;
        _seqIncrement := 2;
    End If;

    If _options = 'Intervals Only' Then
        _includeAcquisitions := 0;
        _includeIncrements := 1;
        _includeStats := 0;
        _longIntervalsOnly := 0;
        _seqIncrement := 2;
    End If;
    --
    If _options = 'Long Intervals' Then
        _includeAcquisitions := 0;
        _includeIncrements := 1;
        _includeStats := 0;
        _longIntervalsOnly := 1;
        _seqIncrement := 2;
    End If;

    ---------------------------------------------------
    -- Set up dates for beginning and end of month anchors
    -- (anchor is fake dataset with zero duration)
    ---------------------------------------------------

    _firstDayOfStartingMonth := date_trunc('month', _startInterval);
    _firstDayOfTrailingMonth := date_trunc('month', _endInterval) + Interval '1 month';

    ---------------------------------------------------
    -- Create table to hold the intervals
    ---------------------------------------------------

    Create Temp Table Tmp_TX (
        Seq int primary key,
        ID int,
        Dataset citext,
        State citext,
        Rating citext,
        Duration int NULL,
        "interval" int NULL,
        Time_Start timestamp,
        Time_End timestamp,
        Request int,
        EUS_Proposal citext,
        EUS_Usage citext,
        EUS_Proposal_Type citext,
        Work_Package citext,
        LC_Column citext,
        Instrument citext,
        Campaign_ID int,
        Fraction_EMSL_Funded numeric(3, 2),
        Campaign_Proposals citext
    );

    ---------------------------------------------------
    -- Check arguments
    ---------------------------------------------------

    If _startInterval Is Null OR _endInterval Is Null OR Coalesce(_instrument, '') = '' Then
        INSERT INTO Tmp_TX
        (
            Seq,
            ID,
            Dataset,
            Time_Start,
            Time_End,
            Duration,
            Instrument,
            "interval"
        ) VALUES (
            1, 0, 'Bad arguments: specify start and end date, plus instrument name', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0, '', 0
        );

        RETURN Query
        Select *
        From Tmp_TX;

        Drop Table Tmp_TX;
        Return;
    End If;

    ---------------------------------------------------
    -- Update _endIntervalEOD to span thru 23:59:59.999
    -- on the end day
    ---------------------------------------------------

    _endIntervalEOD := date_trunc('day', _endInterval) + Interval '86399 seconds' + Interval '999 milliseconds';

    ---------------------------------------------------
    -- Optionally set up anchor for start of month
    ---------------------------------------------------

    If _anchorIntervalsToMonth = 1 Then
        _seqOffset := 2;
        INSERT INTO Tmp_TX
        (
            Seq,
            ID,
            Dataset,
            Time_Start,
            Time_End,
            Duration,
            Instrument,
            "interval"
        ) VALUES (
            1, 0, 'Anchor', _firstDayOfStartingMonth, _firstDayOfStartingMonth, 0, _instrument, 0
        );
    Else
        _endIntervalEOD := _endInterval + Interval '1 day';
    End If;

    ---------------------------------------------------
    -- Get datasets for instrument within time window
    -- in order based on acquisition start time
    ---------------------------------------------------

    INSERT INTO Tmp_TX
    (
        Seq,
        ID,
        dataset,
        Time_Start,
        Time_End,
        Duration,
        instrument,
        "interval"
    )
    SELECT
        (_seqIncrement * ((ROW_NUMBER() OVER(ORDER BY t_dataset.acq_time_start ASC)) - 1) + 1) + _seqOffset,
        t_dataset.dataset_id,
        t_dataset.dataset,
        t_dataset.acq_time_start,
        t_dataset.acq_time_end,
        t_dataset.acq_length_minutes,
        _instrument,
        0
    FROM
        t_dataset
        INNER JOIN t_instrument_name ON t_dataset.instrument_id = t_instrument_name.instrument_id
    WHERE
        _startInterval <= t_dataset.acq_time_start AND t_dataset.acq_time_start <= _endIntervalEOD AND
        t_instrument_name.instrument = _instrument;

    ---------------------------------------------------
    -- Optionally set up anchor for end of month
    ---------------------------------------------------

    SELECT MAX(Tmp_TX.Seq) + 2
    INTO _endSeq
    FROM Tmp_TX ;

    If _anchorIntervalsToMonth = 1 Then
        INSERT INTO Tmp_TX
        (
            Seq,
            ID,
            Dataset,
            Time_Start,
            Time_End,
            Duration,
            Instrument,
            "interval"
        ) VALUES (
            _endSeq, 0, 'Anchor', _firstDayOfTrailingMonth, _firstDayOfTrailingMonth, 0, _instrument, 0
        );
    End If;

    ---------------------------------------------------
    -- Calculate inter-run intervals and update dataset rows
    -- and (optionally) insert interval rows between dataset rows
    ---------------------------------------------------

    SELECT MAX(Tmp_TX.Seq)
    INTO _maxSeq
    FROM Tmp_TX;

    _index := 1;

    WHILE _index < _maxSeq Loop
        SELECT Tmp_TX.Time_Start
        INTO _startOfNext
        FROM Tmp_TX
        WHERE Tmp_TX.Seq = _index + _seqIncrement;

        SELECT Tmp_TX.Time_End
        INTO _endOfPrevious
        FROM Tmp_TX
        WHERE Tmp_TX.Seq = _index;

        _interval := Coalesce(
                        CASE WHEN _startOfNext <= _endOfPrevious
                             THEN 0
                             ELSE round(extract(epoch FROM (_startOfNext - _endOfPrevious)) / 60.0)::int
                        END, 0);

        UPDATE Tmp_TX
        SET "interval" = _interval
        WHERE Tmp_TX.Seq = _index;

        INSERT INTO Tmp_TX ( Seq, ID, Dataset, Time_Start, Time_End, Duration, Instrument )
        VALUES (_index + 1, 0, 'Interval', _endOfPrevious, _startOfNext, _interval, _instrument );

        _index := _index + _seqIncrement;
    End Loop;

    ---------------------------------------------------
    -- Remove extraneous entries caused by padded end date
    ---------------------------------------------------

    DELETE FROM Tmp_TX
    WHERE Tmp_TX.Time_Start >= _endIntervalEOD;

/*
        ---------------------------------------------------
        -- Overall time stats
        ---------------------------------------------------
        If _includeStats = 1 Then
            Declare _latestFinish timestamp,
                    _totalMinutes int,
                    _acquisitionMinutes int,
                    _normalIntervalMinutes int,
                    _longIntervalMinutes int,
                    _s text;

            SELECT MIN(Time_Start) INTO _earliestStart FROM Tmp_TX;
            SELECT MAX(Time_End)   INTO _latestFinish  FROM Tmp_TX;

            _totalMinutes := round(extract(epoch FROM (_latestFinish - _earliestStart)) / 60.0)::int;

            SELECT SUM(Coalesce(Duration, 0))
            INTO _acquisitionMinutes
            FROM Tmp_TX
            WHERE ID <> 0;

            SELECT SUM (Coalesce(Duration, 0))
            INTO _normalIntervalMinutes
            FROM Tmp_TX
            WHERE ID = 0 AND Duration < _maxNormalInterval;

            SELECT SUM (Coalesce(Duration, 0))
            INTO _longIntervalMinutes
            FROM Tmp_TX
            WHERE ID = 0 AND Duration >= _maxNormalInterval;

            _s := 'total:' || _totalMinutes::text ||
            _s := ', normal acquisition:' || (Coalesce(_acquisitionMinutes, 0) + Coalesce(_normalIntervalMinutes, 0))::text ||
            _s := ', long intervals:' || _longIntervalMinutes::text;

            INSERT INTO Tmp_TX (Seq, Dataset)
            VALUES (0, _s);
        End If;
*/

    If _includeAcquisitions = 1 Then
        ---------------------------------------------------
        -- Fill in more information about datasets
        -- if acquisition rows are included in output
        ---------------------------------------------------

        UPDATE Tmp_TX
        SET
            State = DSN.dataset_state ,
            Rating = DRN.dataset_rating ,
            LC_Column = 'C:' || LC.lc_column ,
            Request = RR.request_id ,
            Work_Package = RR.work_package ,
            EUS_Proposal = RR.eus_proposal_id ,
            EUS_Usage = EUT.eus_usage_type ,
            EUS_Proposal_Type = EUP.proposal_type ,
            Campaign_ID  = C.Campaign_ID,
            -- Fraction_EMSL_Funded = C.CM_Fraction_EMSL_Funded,   -- Campaign based estimation of fraction EMSL funded; this has been replaced by the following case statement
            Fraction_EMSL_Funded =
               CASE
               WHEN Coalesce(EUP.Proposal_Type, 'PROPRIETARY') IN ('Capacity', 'Partner',
                                                                   'Proprietary', 'Proprietary Public', 'Proprietary_Public',
                                                                   'Resource Owner', 'Staff Time')
                    THEN 0
                    ELSE 1
               END,
            Campaign_Proposals = C.eus_proposal_list
        FROM
            t_dataset DS INNER JOIN
            t_experiments E ON DS.exp_id = E.exp_id INNER JOIN
            t_campaign C ON E.campaign_id = C.campaign_id INNER JOIN
            t_dataset_state_name DSN ON DS.dataset_state_id = DSN.dataset_state_id INNER JOIN
            t_dataset_rating_name DRN ON DS.dataset_rating_id = DRN.dataset_rating_id  INNER JOIN
            t_lc_column LC ON DS.lc_column_id = LC.lc_column_id LEFT OUTER JOIN
            t_requested_run RR ON DS.dataset_id = RR.dataset_id LEFT OUTER JOIN
            t_eus_usage_type EUT ON RR.eus_usage_type_id = EUT.eus_usage_type_id LEFT OUTER JOIN
            t_eus_proposals EUP ON RR.eus_proposal_id = EUP.proposal_id
        WHERE DS.Dataset_ID = Tmp_TX.ID;
    End If;

    ---------------------------------------------------
    -- Optionally remove acquistion rows
    ---------------------------------------------------

    If _includeAcquisitions = 0 Then
        DELETE FROM Tmp_TX
        WHERE NOT Tmp_TX.Dataset = 'Interval';
    End If;

    ---------------------------------------------------
    -- Optionally remove all intervals
    ---------------------------------------------------

    If _includeIncrements = 0 Then
        DELETE FROM Tmp_TX
        WHERE Tmp_TX.Dataset = 'Interval';
    End If;

    ---------------------------------------------------
    -- Optionally remove normal intervals
    ---------------------------------------------------

    If _longIntervalsOnly = 1 Then
        _maxNormalInterval := get_long_interval_threshold();

        DELETE FROM Tmp_TX
        WHERE Tmp_TX.Dataset = 'Interval' AND Tmp_TX.Duration <= _maxNormalInterval;
    End If;

    RETURN Query
    Select *
    From Tmp_TX;

    Drop Table Tmp_TX;
END
$$;


ALTER FUNCTION public.get_dataset_instrument_runtime(_startinterval timestamp without time zone, _endinterval timestamp without time zone, _instrument public.citext, _options public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_instrument_runtime(_startinterval timestamp without time zone, _endinterval timestamp without time zone, _instrument public.citext, _options public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_instrument_runtime(_startinterval timestamp without time zone, _endinterval timestamp without time zone, _instrument public.citext, _options public.citext) IS 'GetDatasetInstrumentRuntime';

