--
CREATE OR REPLACE PROCEDURE public.set_external_dataset_purge_priority
(
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Set the purge priority to 2 for datasets acquired on external instruments
**
**  Arguments:
**    _infoOnly     When true, preview updates
**
**  Auth:   mem
**  Date:   04/09/2014
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _infoOnly := Coalesce(_infoOnly, false);

    CREATE TEMP TABLE Tmp_DatasetsToUpdate
    (
        Dataset_ID int not null
    )

    CREATE UNIQUE INDEX IX_Tmp_DatasetsToUpdate ON Tmp_DatasetsToUpdate (Dataset_ID);

    ---------------------------------------------------
    -- Update the purge priority for datasets acquired on offsite instruments
    -- However, compare the purge_holdoff_date to 45 days before the current date to skip newer datasets
    ---------------------------------------------------

    INSERT INTO Tmp_DatasetsToUpdate (dataset_id)
    SELECT DS.dataset_id
    FROM t_dataset DS
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_dataset_archive DA
           ON DS.dataset_id = DA.dataset_id
    WHERE DA.instrument_data_purged = 0 AND
          DA.purge_priority = 3 AND
          InstName.operations_role = 'Offsite' AND
          DA.purge_holdoff_date < CURRENT_TIMESTAMP - INTERVAL '45 days';

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-25s %-80s %-20s %-14s %-22s';

        _infoHead := format(_formatSpecifier,
                            'Instrument',
                            'Dataset',
                            'Dataset_Created',
                            'Purge_Priority',
                            'Instrument_Data_Purged'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------',
                                     '--------------',
                                     '----------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT InstName.Instrument,
                   DS.Dataset,
                   public.timestamp_text(DS.created) AS Dataset_Created,
                   DA.Purge_Priority,
                   DA.Instrument_Data_Purged
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN t_dataset_archive DA
                   ON DS.dataset_id = DA.dataset_id
                 INNER JOIN Tmp_DatasetsToUpdate U
                   ON DS.dataset_id = U.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Instrument,
                                _previewData.Dataset,
                                _previewData.Dataset_Created,
                                _previewData.Purge_Priority,
                                _previewData.Instrument_Data_Purged
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        UPDATE t_dataset_archive
        SET purge_priority = 2
        FROM Tmp_DatasetsToUpdate U
        WHERE DA.dataset_id = U.Dataset_ID;
    End If;

    DROP TABLE Tmp_DatasetsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.set_external_dataset_purge_priority IS 'SetExternalDatasetPurgePriority';
