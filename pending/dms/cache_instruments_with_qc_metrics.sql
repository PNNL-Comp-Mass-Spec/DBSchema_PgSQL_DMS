--
CREATE OR REPLACE PROCEDURE public.cache_instruments_with_qc_metrics
(
    _infoOnly boolean = false,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Caches the names of Instruments that have data in table T_Dataset_QC
**
**      Used by the SMAQC website when it constructs the list of available instruments
**      http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/VOrbi05/
**
**  Auth:   mem
**  Date:   11/04/2015 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _infoOnly := Coalesce(_infoOnly, false);

    CREATE TEMP TABLE Tmp_Instruments (Instrument_ID int NOT NULL)

    ----------------------------------------
    -- First cache the instrument IDs in a temporary table
    -- Limiting to datasets that have data in t_dataset_qc
    ----------------------------------------

    INSERT INTO Tmp_Instruments (instrument_id)
    SELECT DISTINCT DS.instrument_id
    FROM t_dataset_qc DQC
         INNER JOIN t_dataset DS
           ON DQC.dataset_id = DS.dataset_id
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        SELECT Inst.instrument, Inst.instrument_id
        FROM t_instrument_name Inst
             INNER JOIN Tmp_Instruments
               ON Inst.instrument_id = Tmp_Instruments.instrument_id

    Else
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
        WHERE NOT EXISTS (
            SELECT Inst.instrument
            FROM t_instrument_name Inst
                 INNER JOIN Tmp_Instruments
                   ON Inst.instrument_id = Tmp_Instruments.instrument_id
            WHERE Inst.Instrument = target.instrument
        );

    End If;

    DROP TABLE Tmp_Instruments;
END
$$;

COMMENT ON PROCEDURE public.cache_instruments_with_qc_metrics IS 'CacheInstrumentsWithQCMetrics';
