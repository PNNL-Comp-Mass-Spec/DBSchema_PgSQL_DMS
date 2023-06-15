--
-- Name: auto_update_dataset_separation_type(integer, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_update_dataset_separation_type(IN _startdatasetid integer, IN _enddatasetid integer, IN _infoonly boolean DEFAULT true, IN _verbose boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Possibly update the separation type for the specified datasets,
**      based on the current separation type name and acquisition length
**
**  Arguments:
**    _startDatasetId   Starting dataset ID
**    _endDatasetId     Ending dataset ID
**    _infoOnly         When true, show info messages
**    _verbose          When _infoOnly is true, set this to true to view additional messages
**
**  Auth:   mem
**  Date:   10/09/2020
**          06/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetInfo record;
    _optimalSeparationType text;
    _updateCount int;
    _datasetsProcessed int = 0;
    _datasetsUpdated int = 0;
    _previewData record;
    _infoData text;
    _updateInfo record;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
BEGIN
    _message := '';
    _returnCode := '';

    _startDatasetId := Coalesce(_startDatasetId, 0);
    _endDatasetId := Coalesce(_endDatasetId, 0);
    _infoOnly := Coalesce(_infoOnly, true);
    _verbose := Coalesce(_verbose, false);

    ---------------------------------------------------
    -- Create a temporary table to track update stats
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UpdateStats (
        SeparationType text,
        UpdatedSeparationType text,
        UpdateCount int,
        SortID int null
    );

    CREATE UNIQUE INDEX IX_TmpUpdateStats ON Tmp_UpdateStats (SeparationType, UpdatedSeparationType);

    If _infoOnly Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Loop through the datasets
    ---------------------------------------------------

    FOR _datasetInfo IN
        SELECT dataset_id AS DatasetId,
               dataset AS DatasetName,
               separation_type AS SeparationType,
               acq_length_minutes AS acqLengthMinutes
        FROM t_dataset
        WHERE dataset_id BETWEEN _startDatasetId AND _endDatasetId
        ORDER BY dataset_id
    LOOP

        If _infoOnly And _verbose Then
            RAISE INFO 'Processing separation type %, acq length % minutes, for dataset %', _datasetInfo.SeparationType, _datasetInfo.AcqLengthMinutes, _datasetInfo.DatasetName;
        End If;

        -- Note that auto_update_separation_type will not change the separation type if the acquisition length is 5 minutes or less
        CALL public.auto_update_separation_type (
                _datasetInfo.SeparationType,
                _datasetInfo.AcqLengthMinutes,
                _optimalSeparationType => _optimalSeparationType);      -- Output

        If _datasetInfo.SeparationType <> _optimalSeparationType Then
            If _infoOnly Then
                RAISE INFO '%Would update separation type from % to % for dataset %',
                           CASE WHEN _verbose THEN '  ' ELSE '' END,
                           _datasetInfo.SeparationType, _optimalSeparationType, _datasetInfo.DatasetName;
            Else
                UPDATE t_dataset
                SET separation_type = _optimalSeparationType
                WHERE dataset_id = _datasetInfo.DatasetId;
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
                SET UpdateCount = _updateCount + 1
                WHERE SeparationType = _datasetInfo.SeparationType AND
                      UpdatedSeparationType = _optimalSeparationType;
            End If;

        End If;

        _datasetsProcessed := _datasetsProcessed + 1;
    END LOOP;

    If _infoOnly Then
        RAISE INFO '';
    End If;

    RAISE INFO 'Examined % datasets', _datasetsProcessed;

    If Not Exists (SELECT * FROM Tmp_UpdateStats) Then
        RAISE INFO 'No separation type updates are required';

        DROP TABLE Tmp_UpdateStats;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate the SortID column
    ---------------------------------------------------

    UPDATE Tmp_UpdateStats
    SET SortID = SortQ.SortID
    FROM ( SELECT SeparationType,
                  UpdatedSeparationType,
                  ROW_NUMBER() OVER ( ORDER BY SeparationType, UpdatedSeparationType ) AS SortID
           FROM Tmp_UpdateStats
         ) SortQ
    WHERE Tmp_UpdateStats.SeparationType = SortQ.SeparationType AND
          Tmp_UpdateStats.UpdatedSeparationType = SortQ.UpdatedSeparationType;

    ---------------------------------------------------
    -- Show the update stats
    ---------------------------------------------------

    RAISE INFO '';

    _formatSpecifier := '%-35s %-35s %-12s';

    _infoHead := format(_formatSpecifier,
                        'Separation_Type',
                        'Updated_Separation_Type',
                        'Update_Count'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                    '-------------------------------------------------------',
                                    '-------------------------------------------------------',
                                    '------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT SeparationType, UpdatedSeparationType, UpdateCount
        FROM Tmp_UpdateStats
        ORDER BY SortID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.SeparationType,
                            _previewData.UpdatedSeparationType,
                            _previewData.UpdateCount
                        );

        RAISE INFO '%', _infoData;

    END LOOP;

    If Not _infoOnly Then
        ---------------------------------------------------
        -- Log the update stats
        ---------------------------------------------------

        FOR _updateInfo IN
            SELECT SeparationType,
                   UpdatedSeparationType,
                   UpdateCount
            FROM Tmp_UpdateStats
            ORDER BY SortID
        LOOP
            _message := format('Changed separation type from %s to %s for %s %s',
                                _updateInfo.SeparationType,
                                _updateInfo.UpdatedSeparationType,
                                _updateInfo.UpdateCount,
                                public.check_plural(_updateInfo.UpdateCount, 'dataset', 'datasets'));

            CALL post_log_entry ('Normal', _message, 'Auto_Update_Dataset_Separation_Type');

            _datasetsUpdated := _datasetsUpdated + _updateInfo.UpdateCount;
        END LOOP;

        SELECT COUNT(*)
        INTO _updateCount
        FROM Tmp_UpdateStats;

        If _updateCount > 1 Then
            _message := format('Changed separation type for %s datasets', _datasetsUpdated);
        End If;

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_UpdateStats;
END
$$;


ALTER PROCEDURE public.auto_update_dataset_separation_type(IN _startdatasetid integer, IN _enddatasetid integer, IN _infoonly boolean, IN _verbose boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_update_dataset_separation_type(IN _startdatasetid integer, IN _enddatasetid integer, IN _infoonly boolean, IN _verbose boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_update_dataset_separation_type(IN _startdatasetid integer, IN _enddatasetid integer, IN _infoonly boolean, IN _verbose boolean, INOUT _message text, INOUT _returncode text) IS 'AutoUpdateDatasetSeparationType';

