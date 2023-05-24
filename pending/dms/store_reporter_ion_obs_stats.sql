--
CREATE OR REPLACE PROCEDURE public.store_reporter_ion_obs_stats
(
    _job int,
    _reporterIon text,
    _topNPct int,
    _observationStatsTopNPct text,
    _medianIntensitiesTopNPct text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the reporter ion observation stats in T_Reporter_Ion_Observation_Rates for the specified analysis job
**
**  Arguments:
**    _reporterIon                Reporter ion name, corresponding to T_Sample_Labelling_Reporter_Ions
**    _observationStatsTopNPct    Comma separated list of observation stats, by channel
**    _medianIntensitiesTopNPct   Comma separated list of median intensity values, by channel
**
**  Auth:   mem
**  Date:   07/30/2020 mem - Initial version
**          07/31/2020 mem - Use "WITH EXECUTE AS OWNER" to allow for inserting data into T_Reporter_Ion_Observation_Rates using sp_executesql
**                         - Without this, svc-dms reports 'INSERT permission was denied'
**          08/12/2020 mem - Replace _observationStatsAll with _medianIntensitiesTopNPct
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int := 0;
    _sqlInsert text := '';
    _sqlValues text := '';
    _channel int := 1;
    _channelName text;
    _rowCountObsRates int := 0;
    _rowCountIntensities int := 0;
    _continue boolean;
    _observationRateTopNPctText text;
    _medianIntensityText text;
    _observationRateTopNPct real;
    _medianIntensity int;
    _sql text
BEGIN
WITH EXECUTE AS OWNER

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job := Coalesce(_job, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    _topNPct := Coalesce(_topNPct, 0);
    _medianIntensitiesTopNPct := Coalesce(_medianIntensitiesTopNPct, '');
    _observationStatsTopNPct := Coalesce(_observationStatsTopNPct, '');

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

    If NOT EXISTS (SELECT * FROM t_sample_labelling_reporter_ions WHERE label = _reporterIon) Then
        _message := format('Unrecognized reporter ion name: %s; for standard reporter ion names, see https://dms2.pnl.gov/sample_label_reporter_ions/report', _reporterIon);
        CALL post_log_entry ('Error', _message, 'Store_Reporter_Ion_Obs_Stats', _duplicateEntryHoldoffHours => 1);
        _returnCode := 'U5202';
        RETURN;
    End If;

    -----------------------------------------------
    -- Populate temporary tables with the data in _observationStatsTopNPct and _medianIntensitiesTopNPct
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_RepIonObsStatsTopNPct
    (
        Channel int Not Null,
        Observation_Rate text,
        Observation_Rate_Value real Null,
    )

    CREATE TEMP TABLE Tmp_RepIonIntensities
    (
        Channel int Not Null,
        Median_Intensity text,
        Median_Intensity_Value int Null,
    )

    INSERT INTO Tmp_RepIonObsStatsTopNPct (Channel, Observation_Rate)
    SELECT Entry_ID, Value
    FROM public.parse_delimited_list_ordered(_observationStatsTopNPct, ',', 0)

    INSERT INTO Tmp_RepIonIntensities (Channel, Median_Intensity)
    SELECT Entry_ID, Value
    FROM public.parse_delimited_list_ordered(_medianIntensitiesTopNPct, ',', 0)

    -----------------------------------------------
    -- Construct the SQL insert statements
    -----------------------------------------------

    _sqlInsert := 'Insert Into t_reporter_ion_observation_rates (job,dataset_id,reporter_ion,TopNPct';

    _sqlValues := format('Values (%s, %s, ''%s'', %s)', _job, _datasetID, _reporterIon, _topNPct);
    _continue := true;

    WHILE _continue
    LOOP
        -- This While loop can probably be converted to a For loop; for example:
        --    FOR _itemName IN
        --        SELECT item_name
        --        FROM TmpSourceTable
        --        ORDER BY entry_id
        --    LOOP
        --        ...
        --    END LOOP

        SELECT Observation_Rate
        INTO _observationRateTopNPctText
        FROM Tmp_RepIonObsStatsTopNPct
        WHERE Channel = _channel
        LIMIT 1;
        --
        GET DIAGNOSTICS _rowCountObsRates = ROW_COUNT;

        SELECT Median_Intensity
        INTO _medianIntensityText
        FROM Tmp_RepIonIntensities
        WHERE Channel = _channel
        LIMIT 1;
        --
        GET DIAGNOSTICS _rowCountIntensities = ROW_COUNT;

        If _rowCountObsRates = 0 AND _rowCountIntensities = 0 Then
            _continue := false;
        Else
            If _rowCountObsRates = 0 Then
                _message := '_medianIntensitiesTopNPct has more values than _observationStatsTopNPct; aborting';
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_RepIonObsStatsTopNPct;
                DROP TABLE Tmp_RepIonIntensities;

                _returnCode := 'U5203';
                RETURN;
            End If;

            If _rowCountIntensities = 0 Then
                _message := '_observationStatsTopNPct has more values than _medianIntensitiesTopNPct; aborting';
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_RepIonObsStatsTopNPct;
                DROP TABLE Tmp_RepIonIntensities;

                _returnCode := 'U5204';
                RETURN;
            End If;

            -- Verify that observation rates are numeric
            _observationRateTopNPct := public.try_cast(_observationRateTopNPctText, null::real);
            _medianIntensity := public.try_cast(_medianIntensityText, null::int);

            If _observationRateTopNPct is Null Then
                _message := format('Observation rate %s is not numeric (Tmp_RepIonObsStatsTopNPct); aborting', _observationRateTopNPctText);
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_RepIonObsStatsTopNPct;
                DROP TABLE Tmp_RepIonIntensities;

                _returnCode := 'U5205';
                RETURN;
            End If;

            If _medianIntensity is Null Then
                _message := format('Intensity value %s is not an integer (Tmp_RepIonIntensities); aborting', _medianIntensityText);
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_RepIonObsStatsTopNPct;
                DROP TABLE Tmp_RepIonIntensities;

                _returnCode := 'U5206';
                RETURN;
            End If;

            -- Append the channel column names to _sqlInsert, for example:
            -- , Channel3, Channel3_Median_Intensity
            --
            _channelName := format('Channel%s', _channel);
            _sqlInsert := _sqlInsert ||  ', ' || _channelName || ', ' || _channelName || '_Median_Intensity';

            -- Append the observation rate and median intensity values
            --
            If _channel > 1 Then
                _sqlValues := _sqlValues || ', ';
            End If;

            _sqlValues := _sqlValues + _observationRateTopNPctText || ', ' || _medianIntensityText;

            -- Store the values (only required if _infoOnly is nonzero)
            If _infoOnly Then
                UPDATE Tmp_RepIonObsStatsTopNPct
                SET Observation_Rate_Value = _observationRateTopNPct
                WHERE Channel = _channel

                UPDATE Tmp_RepIonIntensities
                SET Median_Intensity_Value = _medianIntensity
                WHERE Channel = _channel
            End If;
        End If;

        _channel := _channel + 1;
    END LOOP;

    _sqlInsert := _sqlInsert || ')';
    _sqlValues := _sqlValues || ')';

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT _job AS Job,
               _reporterIon AS Reporter_Ion,
               ObsStats.Channel,
               ObsStats.Observation_Rate_Value AS Observation_Rate_Value_TopNPct,
               Intensities.Median_Intensity_Value AS Median_Intensity
        FROM Tmp_RepIonObsStatsTopNPct ObsStats
             INNER JOIN Tmp_RepIonIntensities Intensities
               ON ObsStats.Channel = Intensities.Channel
        ORDER BY ObsStats.Channel

        RAISE INFO '%', _sqlInsert;
        RAISE INFO '%', _sqlValues;

        DROP TABLE Tmp_RepIonObsStatsTopNPct;
        DROP TABLE Tmp_RepIonIntensities;

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update t_reporter_ion_observation_rates using dynamic SQL
    -----------------------------------------------
    --

    BEGIN

        If Exists (SELECT * FROM t_reporter_ion_observation_rates WHERE job = _job) Then
            DELETE FROM t_reporter_ion_observation_rates WHERE job = _job
        End If;

        _sql := _sqlInsert || ' ' || _sqlValues;
        EXECUTE _sql;

    END;

    _message := 'Reporter Ion Observation Rates stored';

    If char_length(_message) > 0 AND _infoOnly Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_RepIonObsStatsTopNPct;
    DROP TABLE Tmp_RepIonIntensities;
END
$$;

COMMENT ON PROCEDURE public.store_reporter_ion_obs_stats IS 'StoreReporterIonObsStats';
