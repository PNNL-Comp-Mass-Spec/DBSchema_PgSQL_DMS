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
**      Sets the purge priority to 2 for datasets acquired on external instruments
**
**  Auth:   mem
**  Date:   04/09/2014
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
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
    --

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

        -- ToDo: Preview the data using RAISE INFO

        SELECT InstName.instrument AS Instrument,
               DS.dataset AS Dataset,
               DS.created AS Dataset_Created,
               DA.purge_priority AS Purge_Priority,
               DA.instrument_data_purged AS Instrument_Data_Purged
        FROM t_dataset DS
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
             INNER JOIN t_dataset_archive DA
               ON DS.dataset_id = DA.dataset_id
             INNER JOIN Tmp_DatasetsToUpdate U
               ON DS.dataset_id = U.dataset_id;

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
