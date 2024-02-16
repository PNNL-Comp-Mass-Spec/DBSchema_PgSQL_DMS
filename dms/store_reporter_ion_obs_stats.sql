--
-- Name: store_reporter_ion_obs_stats(integer, text, integer, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_reporter_ion_obs_stats(IN _job integer, IN _reporterion text, IN _topnpct integer, IN _observationstatstopnpct text, IN _medianintensitiestopnpct text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the reporter ion observation stats in T_Reporter_Ion_Observation_Rates for the specified analysis job
**
**  Arguments:
**    _job                          Analysis job number
**    _reporterIon                  Reporter ion name, corresponding to the "label" column in t_sample_labelling_reporter_ions (e.g. iTRAQ8 or TMT18)
**    _topNPct                      Percent of data (by decreasing intensity) that was used to compute the stats
**    _observationStatsTopNPct      Comma-separated list of observation stats, by channel
**    _medianIntensitiesTopNPct     Comma-separated list of median intensity values, by channel
**    _message                      Status message
**    _returnCode                   Return code
**    _infoOnly                     When true, preview updates
**
**  Auth:   mem
**  Date:   07/30/2020 mem - Initial version
**          07/31/2020 mem - Use "WITH EXECUTE AS OWNER" to allow for inserting data into T_Reporter_Ion_Observation_Rates using sp_executesql
**                         - Without this, svc-dms reports 'INSERT permission was denied'
**          08/12/2020 mem - Replace _observationStatsAll with _medianIntensitiesTopNPct
**          05/25/2023 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list_ordered for a comma-separated list
**
*****************************************************/
DECLARE
    _datasetID int := 0;
    _sqlInsert text := '';
    _sqlValues text := '';
    _channelStart int;
    _channelEnd int;
    _channel int := 1;
    _channelName text;
    _observationRateTopNPctText text;
    _medianIntensityText text;
    _observationRateTopNPct real;
    _medianIntensity int;
    _sql text;
    _formatString text;
BEGIN

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job                      := Coalesce(_job, 0);
    _infoOnly                 := Coalesce(_infoOnly, false);
    _topNPct                  := Coalesce(_topNPct, 0);
    _medianIntensitiesTopNPct := Trim(Coalesce(_medianIntensitiesTopNPct, ''));
    _observationStatsTopNPct  := Trim(Coalesce(_observationStatsTopNPct, ''));

    ---------------------------------------------------
    -- Make sure _job is defined in t_analysis_job
    -- In addition, validate _datasetID
    ---------------------------------------------------

    SELECT dataset_id
    INTO _datasetID
    FROM t_analysis_job
    WHERE job = _job;

    If Not FOUND Then
        _message := format('job not found in t_analysis_job: %s', _job);
        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------------
    -- Validate the reporter ion
    -----------------------------------------------

    If Not Exists (SELECT label FROM t_sample_labelling_reporter_ions WHERE label = _reporterIon) Then
        _message := format('Unrecognized reporter ion name: %s; for standard reporter ion names, see https://dms2.pnl.gov/sample_label_reporter_ions/report', _reporterIon);
        CALL post_log_entry ('Error', _message, 'Store_Reporter_Ion_Obs_Stats', _duplicateEntryHoldoffHours => 1);
        _returnCode := 'U5202';
        RETURN;
    End If;

    -----------------------------------------------
    -- Populate temporary tables with the data in _observationStatsTopNPct and _medianIntensitiesTopNPct
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_RepIonObsStatsTopNPct (
        Channel int Not Null,
        Observation_Rate text,
        Observation_Rate_Value real Null
    );

    CREATE TEMP TABLE Tmp_RepIonIntensities (
        Channel int Not Null,
        Median_Intensity text,
        Median_Intensity_Value int Null
    );

    INSERT INTO Tmp_RepIonObsStatsTopNPct (Channel, Observation_Rate)
    SELECT Entry_ID, Value
    FROM public.parse_delimited_list_ordered(_observationStatsTopNPct);

    INSERT INTO Tmp_RepIonIntensities (Channel, Median_Intensity)
    SELECT Entry_ID, Value
    FROM public.parse_delimited_list_ordered(_medianIntensitiesTopNPct);

    -----------------------------------------------
    -- Construct the SQL insert statements
    -----------------------------------------------

    _sqlInsert := 'INSERT INTO t_reporter_ion_observation_rates (job, dataset_id, reporter_ion, top_n_pct';

    _sqlValues := format('VALUES (%s, %s, ''%s'', %s', _job, _datasetID, _reporterIon, _topNPct);

    -----------------------------------------------
    -- Process the values for each channel
    -----------------------------------------------

    SELECT MIN(Channel), MAX(Channel)
    INTO _channelStart, _channelEnd
    FROM Tmp_RepIonObsStatsTopNPct;

    FOR _channel IN _channelStart .. _channelEnd
    LOOP
        SELECT Observation_Rate
        INTO _observationRateTopNPctText
        FROM Tmp_RepIonObsStatsTopNPct
        WHERE Channel = _channel
        LIMIT 1;

        SELECT Median_Intensity
        INTO _medianIntensityText
        FROM Tmp_RepIonIntensities
        WHERE Channel = _channel
        LIMIT 1;

        If _observationRateTopNPctText Is Null And _medianIntensityText Is Null Then
            RAISE WARNING 'Channel % not found in Tmp_RepIonObsStatsTopNPct or Tmp_RepIonIntensities; this is unexected', _channel;
            CONTINUE;
        End If;

        If _observationRateTopNPctText Is Null Then
            RAISE WARNING 'Channel % not found in Tmp_RepIonObsStatsTopNPct; this is unexected', _channel;
           _observationRateTopNPctText = '0';
        End If;

        If _medianIntensityText Is Null Then
            RAISE WARNING 'Channel % not found in Tmp_RepIonIntensities; this is unexected', _channel;
           _medianIntensityText = '0';
        End If;

        -- Verify that observation rates are numeric
        _observationRateTopNPct := public.try_cast(_observationRateTopNPctText, null::real);
        _medianIntensity        := public.try_cast(_medianIntensityText,        null::int);

        If _observationRateTopNPct Is Null Then
            _message := format('Observation rate %s is not numeric (Tmp_RepIonObsStatsTopNPct); aborting', _observationRateTopNPctText);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_RepIonObsStatsTopNPct;
            DROP TABLE Tmp_RepIonIntensities;

            _returnCode := 'U5205';
            RETURN;
        End If;

        If _medianIntensity Is Null Then
            _message := format('Intensity value %s is not an integer (Tmp_RepIonIntensities); aborting', _medianIntensityText);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_RepIonObsStatsTopNPct;
            DROP TABLE Tmp_RepIonIntensities;

            _returnCode := 'U5206';
            RETURN;
        End If;

        -- Append the channel column names to _sqlInsert, for example:
        -- , Channel3, Channel3_Median_Intensity

        _channelName := format('Channel%s', _channel);
        _sqlInsert := format('%s, %s, %s_Median_Intensity', _sqlInsert, _channelName, _channelName);

        -- Append the observation rate and median intensity values

        _sqlValues := format('%s, %s, %s', _sqlValues, _observationRateTopNPctText, _medianIntensityText);

        -- Store the values (only required if _infoOnly is nonzero)
        If _infoOnly Then
            UPDATE Tmp_RepIonObsStatsTopNPct
            SET Observation_Rate_Value = _observationRateTopNPct
            WHERE Channel = _channel;

            UPDATE Tmp_RepIonIntensities
            SET Median_Intensity_Value = _medianIntensity
            WHERE Channel = _channel;
        End If;

    END LOOP;

    _sqlInsert := format('%s)', _sqlInsert);
    _sqlValues := format('%s)', _sqlValues);

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        _formatString := '%-10s %-12s %-10s %-31s %-16s';

        RAISE INFO '';

        RAISE INFO '%', format(_formatString,
                                'Job',
                                'Reporter_Ion',
                                'Channel',
                                'Observation_Rate_Value_TopNPct',
                                'Median_Intensity');

        FOR _channel IN _channelStart .. _channelEnd
        LOOP
            SELECT ObsStats.Observation_Rate_Value,
                   Intensities.Median_Intensity_Value
            INTO _observationRateTopNPct, _medianIntensity
            FROM Tmp_RepIonObsStatsTopNPct ObsStats
                 INNER JOIN Tmp_RepIonIntensities Intensities
                   ON ObsStats.Channel = Intensities.Channel
            WHERE ObsStats.Channel = _channel;

            RAISE INFO '%', format(_formatString, _job, _reporterIon, _channel, _observationRateTopNPct, _medianIntensity);
        END LOOP;

        RAISE INFO '';
        RAISE INFO '%', _sqlInsert;
        RAISE INFO '%', _sqlValues;

        DROP TABLE Tmp_RepIonObsStatsTopNPct;
        DROP TABLE Tmp_RepIonIntensities;

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update t_reporter_ion_observation_rates using dynamic SQL
    -----------------------------------------------

    If Exists (SELECT job FROM t_reporter_ion_observation_rates WHERE job = _job) Then
        DELETE FROM t_reporter_ion_observation_rates WHERE job = _job;
    End If;

    _sql := format('%s %s', _sqlInsert, _sqlValues);
    EXECUTE _sql;

    _message := 'Reporter Ion Observation Rates stored';

    DROP TABLE Tmp_RepIonObsStatsTopNPct;
    DROP TABLE Tmp_RepIonIntensities;
END
$$;


ALTER PROCEDURE public.store_reporter_ion_obs_stats(IN _job integer, IN _reporterion text, IN _topnpct integer, IN _observationstatstopnpct text, IN _medianintensitiestopnpct text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE store_reporter_ion_obs_stats(IN _job integer, IN _reporterion text, IN _topnpct integer, IN _observationstatstopnpct text, IN _medianintensitiestopnpct text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_reporter_ion_obs_stats(IN _job integer, IN _reporterion text, IN _topnpct integer, IN _observationstatstopnpct text, IN _medianintensitiestopnpct text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'StoreReporterIonObsStats';

