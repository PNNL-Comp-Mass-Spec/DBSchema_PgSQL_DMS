--
-- Name: get_instrument_run_datasets(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_run_datasets(_mostrecentweeks integer DEFAULT 4, _instrument text DEFAULT 'Lumos03'::text) RETURNS TABLE(seq integer, id integer, dataset text, state text, rating text, duration integer, time_start timestamp without time zone, time_end timestamp without time zone, request integer, eus_proposal text, eus_usage text, work_package text, lc_column text, instrument text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns list of datasets and acquisition time information for given instrument
**
**  Auth:   grk
**  Date:   09/04/2010 grk - Initial release
**          02/15/2012 mem - Now using T_Dataset.Acq_Length_Minutes
**          06/21/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          05/22/2023 mem - Capitalize reserved word
**          05/29/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _maxSeq int;
    _startOfNext timestamp;
    _endOfPrevious timestamp;
    _interval int;
    _index int;
    _earliestStart timestamp;
    _latestFinish timestamp;
    _totalMinutes int;
    _acquisitionMinutes int;
    _normalIntervalMinutes int;
    _longIntervalMinutes int;
    _s text := '';
BEGIN
    ---------------------------------------------------
    -- Create table to hold the datasets
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_TX (
        Seq int primary key,
        ID int,
        Dataset text,
        State text,
        Rating text,
        Duration int NULL,
        Time_Start timestamp,
        Time_End timestamp,
        Request int,
        EUS_Proposal text,
        EUS_Usage text,
        Work_Package text,
        LC_Column text,
        Instrument text
    );

    IF Coalesce(_mostRecentWeeks, 0) = 0 OR Coalesce(_instrument, '') = '' Then
        INSERT INTO Tmp_TX (Seq, ID, Dataset) VALUES (0, 0, 'Bad arguments');

        RETURN QUERY
        SELECT *
        FROM Tmp_TX;

        DROP TABLE Tmp_TX;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Get datasets for instrument within time window
    -- in order based on acquisition start time
    ---------------------------------------------------

    INSERT INTO Tmp_TX
    (
        Seq,
        ID,
        Dataset,
        Time_Start,
        Time_End,
        Duration,
        Instrument
    )
    SELECT
        2 * ((ROW_NUMBER() OVER(ORDER BY DS.acq_time_start ASC)) - 1) + 1,
        DS.dataset_id AS ID,
        DS.dataset AS Dataset,
        DS.acq_time_start AS Time_Start,
        DS.acq_time_end AS Time_End,
        DS.acq_length_minutes AS Duration,
        InstName.instrument
    FROM
        t_dataset DS
        INNER JOIN t_instrument_name InstName ON DS.instrument_id = InstName.instrument_id
    WHERE DS.acq_time_start > CURRENT_TIMESTAMP - make_interval(weeks => _mostRecentWeeks) AND
          InstName.instrument = _instrument;

    ---------------------------------------------------
    -- Create inter-run interval rows between dataset rows
    ---------------------------------------------------

    SELECT MAX(Tmp_TX.Seq)
    INTO _maxSeq
    FROM Tmp_TX;

    _index := 1;

    WHILE _index < _maxSeq
    LOOP
        SELECT Tmp_TX.Time_Start
        INTO _startOfNext
        FROM Tmp_TX
        WHERE Tmp_TX.Seq = _index + 2;

        SELECT Tmp_TX.Time_End
        INTO _endOfPrevious
        FROM Tmp_TX
        WHERE Tmp_TX.Seq = _index;

        _interval := CASE WHEN _startOfNext <= _endOfPrevious
                          THEN 0
                          ELSE Coalesce(
                            Round(extract(epoch FROM (_startOfNext - _endOfPrevious)) / 60.0)::int
                            , 0)
                          END ;

        INSERT INTO Tmp_TX ( Seq, ID, Dataset, Time_Start, Time_End, Duration, Instrument )
        VALUES (_index + 1, 0, 'Interval', _endOfPrevious, _startOfNext, _interval, _instrument );

        _index := _index + 2;
    END LOOP;

    ---------------------------------------------------
    -- overall time stats
    ---------------------------------------------------

    SELECT MIN(Tmp_TX.Time_Start), MAX(Tmp_TX.Time_End)
    INTO _earliestStart, _latestFinish
    FROM Tmp_TX;

    _totalMinutes := Round(extract(epoch FROM (_latestFinish - _earliestStart)) / 60.0)::int;

    SELECT SUM(Coalesce(Tmp_TX.Duration, 0))
    INTO _acquisitionMinutes
    FROM Tmp_TX
    WHERE Tmp_TX.ID <> 0;

    SELECT SUM(Coalesce(Tmp_TX.Duration, 0))
    INTO _normalIntervalMinutes
    FROM Tmp_TX
    WHERE Tmp_TX.ID = 0 AND Tmp_TX.Duration < 10;

    SELECT SUM(Coalesce(Tmp_TX.Duration, 0))
    INTO _longIntervalMinutes
    FROM Tmp_TX
    WHERE Tmp_TX.ID = 0 AND Tmp_TX.Duration >= 10;

    _s := format('total:%s, normal acquisition:%s, long intervals:%s',
                    _totalMinutes,
                    Coalesce(_acquisitionMinutes, 0) + Coalesce(_normalIntervalMinutes, 0),
                    _longIntervalMinutes);

    INSERT INTO Tmp_TX (Seq, Dataset)
    VALUES (0, _s);

    ---------------------------------------------------
    -- Fill in more information about datasets
    ---------------------------------------------------

    UPDATE Tmp_TX
    SET State = LookupQ.dataset_state,
        Rating = LookupQ.dataset_rating,
        lc_column = format('C:%s', LookupQ.lc_column),
        Request = LookupQ.request_id,
        Work_Package = LookupQ.work_package,
        EUS_Proposal = LookupQ.eus_proposal_id,
        EUS_Usage = LookupQ.eus_usage_type
    FROM ( SELECT t_dataset.dataset_id,
                  t_dataset_state_name.dataset_state,
                  t_dataset_rating_name.dataset_rating,
                  t_lc_column.lc_column,
                  t_requested_run.request_id ,
                  t_requested_run.work_package,
                  t_requested_run.eus_proposal_id,
                  t_eus_usage_type.eus_usage_type
           FROM t_dataset
                INNER JOIN t_dataset_state_name
                  ON t_dataset.dataset_state_id = t_dataset_state_name.dataset_state_id
                INNER JOIN t_dataset_rating_name
                  ON t_dataset.dataset_rating_id = t_dataset_rating_name.dataset_rating_id
                INNER JOIN t_lc_column
                  ON t_dataset.lc_column_id = t_lc_column.lc_column_id
                LEFT OUTER JOIN t_requested_run
                  ON t_dataset.dataset_id = t_requested_run.dataset_id
                LEFT OUTER JOIN t_eus_usage_type
                  ON t_requested_run.eus_usage_type_id = t_eus_usage_type.eus_usage_type_id ) LookupQ
    WHERE Tmp_TX.ID = LookupQ.Dataset_ID;

    RETURN QUERY
    SELECT *
    FROM Tmp_TX;

    DROP TABLE Tmp_TX;
END
$$;


ALTER FUNCTION public.get_instrument_run_datasets(_mostrecentweeks integer, _instrument text) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_run_datasets(_mostrecentweeks integer, _instrument text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_run_datasets(_mostrecentweeks integer, _instrument text) IS 'GetInstrumentRunDatasets';

