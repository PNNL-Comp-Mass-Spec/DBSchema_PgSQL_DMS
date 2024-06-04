--
-- Name: retire_stale_lc_columns(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.retire_stale_lc_columns(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Automatically retires (sets inactive) LC columns that have not been used recently
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   01/23/2015
**          02/22/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _usedThresholdMonths int;
    _unusedThresholdMonths int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs and define the thresholds
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    _usedThresholdMonths   := 9;
    _unusedThresholdMonths := 24;

    -----------------------------------------------------------
    -- Create a temporary table to track the columns to retire
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_LCColumns (
        ID int NOT NULL PRIMARY KEY,
        Last_Used timestamp NOT NULL,
        Most_Recent_Dataset text NULL
    );

    -----------------------------------------------------------
    -- Find LC columns that have been used with a dataset, but not in the last 9 months
    -----------------------------------------------------------

    INSERT INTO Tmp_LCColumns (ID, Last_Used)
    SELECT LCCol.lc_column_id, MAX(DS.created) AS Last_Used
    FROM t_lc_column LCCol
         INNER JOIN t_dataset DS
           ON LCCol.lc_column_id = DS.lc_column_ID
    WHERE LCCol.column_state_id <> 3 AND
          LCCol.created < CURRENT_TIMESTAMP - make_interval(months => _usedThresholdMonths) AND
          DS.created    < CURRENT_TIMESTAMP - make_interval(months => _usedThresholdMonths)
    GROUP BY LCCol.lc_column_id
    ORDER BY LCCol.lc_column_id;

    If Not FOUND Then
        _message := 'Did not find any stale LC columns to retire';
        RAISE INFO '%', _message;
        DROP TABLE Tmp_LCColumns;
        RETURN;
    End If;

    If _infoOnly Then

        -- Populate column Most_Recent_Dataset

        UPDATE Tmp_LCColumns
        SET Most_Recent_Dataset = LookupQ.dataset
        FROM (SELECT lc_column_ID,
                     dataset,
                     created
              FROM (SELECT lc_column_ID,
                           dataset,
                           created,
                           Row_Number() OVER (Partition BY lc_column_ID ORDER BY created DESC) AS DatasetRank
                    FROM t_dataset
                    WHERE lc_column_ID IN (SELECT ID FROM Tmp_LCColumns)
                   ) RankQ
              WHERE DatasetRank = 1
             ) LookupQ
        WHERE Tmp_LCColumns.ID = LookupQ.LC_Column_ID;

    End If;

    -----------------------------------------------------------
    -- Next find LC columns created at least 2 years ago that have never been used with a dataset
    -----------------------------------------------------------

    INSERT INTO Tmp_LCColumns (ID, Last_Used)
    SELECT LCCol.lc_column_id, LCCol.created AS Last_Used
    FROM t_lc_column LCCol
         LEFT OUTER JOIN t_dataset DS
           ON LCCol.lc_column_id = DS.lc_column_ID
    WHERE LCCol.column_state_id <> 3 AND
          LCCol.created < CURRENT_TIMESTAMP - make_interval(months => _unusedThresholdMonths) AND
          DS.dataset_id IS NULL
    ORDER BY LCCol.lc_column_id;

    -----------------------------------------------------------
    -- Remove certain columns that we don't want to auto-retire
    -----------------------------------------------------------

    DELETE FROM Tmp_LCColumns
    WHERE ID IN (SELECT lc_column_id
                 FROM t_lc_column
                 WHERE lc_column IN ('unknown', 'No_Column', 'DI', 'Infuse'));

    If Not Exists (SELECT ID FROM Tmp_LCColumns) Then
        _message := 'Did not find any stale LC columns to retire (after removing columns that should not be auto-retired)';
        RAISE INFO '%', _message;
        DROP TABLE Tmp_LCColumns;
        RETURN;
    End If;

    If _infoOnly Then

        -----------------------------------------------------------
        -- Preview the columns that would be retired
        -----------------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-12s %-30s %-11s %-80s %-11s %-70s %-35s %-25s %-13s %-13s %-16s %-16s';

        _infoHead := format(_formatSpecifier,
                            'LC_Column_ID',
                            'LC_Column',
                            'Last_Used',
                            'Most_Recent_Dataset',
                            'Created',
                            'Comment',
                            'Packing_Mfg',
                            'Packing_Type',
                            'Particle_Size',
                            'Particle_Type',
                            'Column_Inner_Dia',
                            'Column_Outer_Dia'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '------------------------------',
                                     '-----------',
                                     '--------------------------------------------------------------------------------',
                                     '-----------',
                                     '----------------------------------------------------------------------',
                                     '-----------------------------------',
                                     '-------------------------',
                                     '-------------',
                                     '-------------',
                                     '----------------',
                                     '----------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT LCCol.LC_Column_ID,
                   LCCol.LC_Column,
                   Src.Last_Used::date AS Last_Used,
                   Src.Most_Recent_Dataset,
                   LCCol.Created::date AS Created,
                   Left(LCCol.Comment, 70) AS Comment,
                   Left(LCCol.Packing_Mfg, 35) AS Packing_Mfg,
                   LCCol.Packing_Type,
                   LCCol.Particle_Size,
                   LCCol.Particle_Type,
                   LCCol.Column_Inner_Dia,
                   LCCol.Column_Outer_Dia
            FROM t_lc_column LCCol
                 INNER JOIN Tmp_LCColumns Src
                   ON LCCol.lc_column_id = Src.ID
            ORDER BY Src.Last_Used, LCCol.lc_column_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.LC_Column_ID,
                                _previewData.LC_Column,
                                _previewData.Last_Used,
                                _previewData.Most_Recent_Dataset,
                                _previewData.Created,
                                _previewData.Comment,
                                _previewData.Packing_Mfg,
                                _previewData.Packing_Type,
                                _previewData.Particle_Size,
                                _previewData.Particle_Type,
                                _previewData.Column_Inner_Dia,
                                _previewData.Column_Outer_Dia
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_LCColumns;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Change the LC Column state to 3=Retired
    -----------------------------------------------------------

    UPDATE t_lc_column Target
    SET column_state_id = 3
    WHERE EXISTS (SELECT 1
                  FROM Tmp_LCColumns
                  WHERE Target.lc_column_id = Tmp_LCColumns.ID);
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        _message := format('Retired %s %s that %s not been used in at last %s months',
                           _updateCount,
                           public.check_plural(_updateCount, 'LC column', 'LC columns'),
                           public.check_plural(_updateCount, 'has', 'have'),
                           _usedThresholdMonths);

        CALL post_log_entry ('Normal', _message, 'Retire_Stale_LC_Columns');

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_LCColumns;
END
$$;


ALTER PROCEDURE public.retire_stale_lc_columns(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE retire_stale_lc_columns(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.retire_stale_lc_columns(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'RetireStaleLCColumns';

