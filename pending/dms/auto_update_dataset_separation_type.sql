--
CREATE OR REPLACE PROCEDURE public.auto_update_dataset_separation_type
(
    _startDatasetId int,
    _endDatasetId int,
    _infoOnly boolean = true,
    _verbose boolean = false
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Possibly update the separation type for the specified datasets,
**      based on the current separation type name and acquisition length
**
**  Arguments:
**    _infoOnly     When true, show info messages
**    _verbose      When _infoOnly is true, set this to true to view additional messages
**
**  Auth:   mem
**  Date:   10/09/2020
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetInfo record;
    _datasetsProcessed int;
    _updateInfo record;
BEGIN
    _message := '';
    _returnCode:= '';

    _startDatasetId := Coalesce(_startDatasetId, 0);
    _endDatasetId := Coalesce(_endDatasetId, 0);
    _infoOnly := Coalesce(_infoOnly, true);
    _verbose := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temporary table to track update stats
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UpdateStats (
        SeparationType text,
        UpdatedSeparationType text,
        UpdateCount int,
        SortID int null
    )

    CREATE UNIQUE INDEX IX_TmpUpdateStats ON Tmp_UpdateStats (SeparationType, UpdatedSeparationType);

    ---------------------------------------------------
    -- Loop through the datasets
    ---------------------------------------------------
    --
    FOR _datasetInfo IN
        SELECT dataset_id As DatasetId,
               dataset As DatasetName,
               separation_type As SeparationType,
               acq_length_minutes As acqLengthMinutes
        FROM t_dataset
        WHERE dataset_id >= _startDatasetId
        ORDER BY dataset_id
    LOOP

        If _infoOnly And _verbose Then
            RAISE INFO '';
            RAISE INFO 'Processing separation type %, acq length % minutes, for dataset %', _datasetInfo.SeparationType, _datasetInfo.AcqLengthMinutes, _datasetInfo.DatasetName;
        End If;

        Call auto_update_separation_type (_datasetInfo.SeparationType, _datasetInfo.AcqLengthMinutes, _optimalSeparationType => _optimalSeparationType);

        If _datasetInfo.SeparationType <> _optimalSeparationType Then
            If _infoOnly Then
                RAISE INFO 'Would update separation type from % to % for dataset %', _datasetInfo.SeparationType, _optimalSeparationType, _datasetInfo.DatasetName;
            Else
                Update t_dataset
                Set separation_type = _optimalSeparationType
                Where dataset_id = _datasetInfo.DatasetId
            End If;

            SELECT UpdateCount
            INTO _updateCount
            FROM Tmp_UpdateStats
            WHERE SeparationType = _datasetInfo.SeparationType AND
                  UpdatedSeparationType = _optimalSeparationType;

            If Not FOUND Then
                INSERT INTO Tmp_UpdateStats (SeparationType, UpdatedSeparationType, UpdateCount)
                VALUES (_datasetInfo.SeparationType, _optimalSeparationType, 1);
            Else
                UPDATE Tmp_UpdateStats
                Set UpdateCount = _updateCount + 1
                WHERE SeparationType = _datasetInfo.SeparationType AND
                      UpdatedSeparationType = _optimalSeparationType;
            End If;

        End If;

        _datasetsProcessed := _datasetsProcessed + 1;

        If _datasetInfo.DatasetID >= _endDatasetId Then
            -- Break out of the For loop
            EXIT;
        End If;

    END LOOP;

    RAISE INFO 'Examined % datasets', _datasetsProcessed;

    ---------------------------------------------------
    -- Populate the SortID column
    ---------------------------------------------------
    --
    UPDATE Tmp_UpdateStats
    SET SortID = SortingQ.SortID
    FROM Tmp_UpdateStats

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_UpdateStats
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_UpdateStats.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT SeparationType,
                             UpdatedSeparationType,
                             ROW_NUMBER() OVER ( ORDER BY SeparationType, UpdatedSeparationType ) AS
                               SortID
                      FROM Tmp_UpdateStats ) SortingQ

                      /********************************************************************************
                      ** This UPDATE query includes the target table name in the FROM clause
                      ** The WHERE clause needs to have a self join to the target table, for example:
                      **   UPDATE Tmp_UpdateStats
                      **   SET ...
                      **   FROM source
                      **   WHERE source.id = Tmp_UpdateStats.id;
                      ********************************************************************************/

                                             ToDo: Fix this query

           ON Tmp_UpdateStats.SeparationType = SortingQ.SeparationType AND
              Tmp_UpdateStats.UpdatedSeparationType = SortingQ.UpdatedSeparationType

    ---------------------------------------------------
    -- Show the update stats
    ---------------------------------------------------
    --

    -- ToDo: Show this data using RAISE INFO
    --
    SELECT SeparationType, UpdatedSeparationType, UpdateCount
    FROM Tmp_UpdateStats
    ORDER BY SortID

    If Not _infoOnly Then
        ---------------------------------------------------
        -- Log the update stats
        ---------------------------------------------------
        --

        FOR _updateInfo IN
            SELECT SeparationType,
                   UpdatedSeparationType,
                   UpdateCount
            FROM Tmp_UpdateStats
            ORDER BY SortID
        LOOP
            _message := format('Changed separation type from %s to %s for %s %s',
                                _updateInfo.SeparationType,
                                _updateInfo.OptimalSeparationType
                                _updateInfo.UpdateCount
                                public.check_plural(_updateInfo.UpdateCount, 'dataset', 'datasets');

            Call post_log_entry ('Normal', _message, 'Auto_Update_Dataset_Separation_Type');

        END LOOP;

    End If;

    DROP TABLE Tmp_UpdateStats;
END
$$;

COMMENT ON PROCEDURE public.auto_update_dataset_separation_type IS 'AutoUpdateDatasetSeparationType';
