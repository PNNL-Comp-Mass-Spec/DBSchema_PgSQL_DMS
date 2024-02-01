--
-- Name: cache_instruments_with_qc_metrics(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.cache_instruments_with_qc_metrics(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Cache the names of instruments that have data in table t_dataset_qc
**
**      Used by the SMAQC website when it constructs the list of available instruments
**      https://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/VOrbi05/
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   11/04/2015 mem - Initial version
**          01/30/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------
    -- Validate the inputs
    ----------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    CREATE TEMP TABLE Tmp_Instruments (
        Instrument_ID int NOT NULL
    );

    ----------------------------------------
    -- Cache the instrument IDs for datasets that have data in t_dataset_qc
    ----------------------------------------

    INSERT INTO Tmp_Instruments (instrument_id)
    SELECT DISTINCT DS.instrument_id
    FROM t_dataset_qc DQC
         INNER JOIN t_dataset DS
           ON DQC.dataset_id = DS.dataset_id;

    If _infoOnly Then
        -- Show the instrument names and IDs

        RAISE INFO '';

        _formatSpecifier := '%-30s %-13s';

        _infoHead := format(_formatSpecifier,
                            'Instrument_Name',
                            'Instrument_ID'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------------------------',
                                     '-------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Inst.instrument,
                   Inst.instrument_id
            FROM t_instrument_name Inst
                 INNER JOIN Tmp_Instruments
                   ON Inst.instrument_id = Tmp_Instruments.instrument_id
            ORDER BY Inst.instrument
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Instrument,
                                _previewData.Instrument_ID
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Instruments;
        RETURN;
    End If;

    ----------------------------------------
    -- Update t_dataset_qc_instruments
    ----------------------------------------

    MERGE INTO t_dataset_qc_instruments AS target
    USING ( SELECT Inst.instrument, Inst.instrument_id
            FROM t_instrument_name Inst
                 INNER JOIN Tmp_Instruments
                   ON Inst.instrument_id = Tmp_Instruments.instrument_id
          ) AS source
    ON (target.instrument = source.instrument)
    WHEN MATCHED AND target.instrument_id <> source.instrument_id THEN
        UPDATE SET
            instrument_id = source.instrument_id,
            last_updated = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (instrument, instrument_id, last_updated)
        VALUES (source.instrument, source.instrument_id, CURRENT_TIMESTAMP);

    -- Delete rows in t_dataset_qc_instruments where the instrument is not in Tmp_Instruments or t_instrument_name

    DELETE FROM t_dataset_qc_instruments target
    WHERE NOT EXISTS ( SELECT Inst.instrument
                       FROM t_instrument_name Inst
                            INNER JOIN Tmp_Instruments
                              ON Inst.instrument_id = Tmp_Instruments.instrument_id
                       WHERE Inst.Instrument = target.instrument
                     );

    DROP TABLE Tmp_Instruments;
END
$$;


ALTER PROCEDURE public.cache_instruments_with_qc_metrics(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE cache_instruments_with_qc_metrics(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.cache_instruments_with_qc_metrics(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'CacheInstrumentsWithQCMetrics';

