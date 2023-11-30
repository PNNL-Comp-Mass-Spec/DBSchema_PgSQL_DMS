--
CREATE OR REPLACE PROCEDURE public.retire_stale_lc_columns
(
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _usedThresholdMonths int := 9;
    _unusedThresholdMonths int := 24;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    -----------------------------------------------------------
    -- Create a temporary table to track the columns to retire
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_LCColumns (
        ID int not null primary key,
        Last_Used timestamp not null,
        Most_Recent_Dataset text null
    )

    -----------------------------------------------------------
    -- Find LC columns that have been used with a dataset, but not in the last 9 months
    -----------------------------------------------------------

    INSERT INTO Tmp_LCColumns (lc_column_id, Last_Used)
    SELECT LCCol.lc_column_id, MAX(DS.created) As Last_Used
    FROM t_lc_column LCCol
         INNER JOIN t_dataset DS
           ON LCCol.lc_column_id = DS.lc_column_ID
    WHERE LCCol.column_state_id <> 3 AND
          LCCol.created < CURRENT_TIMESTAMP - make_interval(months => _usedThresholdMonths) AND
          DS.created < CURRENT_TIMESTAMP - make_interval(months => _usedThresholdMonths)
    GROUP BY LCCol.lc_column_id
    ORDER BY LCCol.lc_column_id;

    If _infoOnly Then

        -- Populate column Most_Recent_Dataset

        UPDATE Tmp_LCColumns
        SET Most_Recent_Dataset = LookupQ.dataset
        FROM ( SELECT lc_column_ID,
                      dataset,
                      created
               FROM ( SELECT lc_column_ID,
                             dataset,
                             created,
                             Row_Number() OVER (Partition BY lc_column_ID ORDER BY created DESC ) AS DatasetRank
                       FROM t_dataset
                       WHERE lc_column_ID IN ( SELECT ID FROM Tmp_LCColumns )
                    ) RankQ
               WHERE DatasetRank = 1
               ) LookupQ
        WHERE Tmp_LCColumns.ID = LookupQ.LC_Column_ID;

    End If;

    -----------------------------------------------------------
    -- Next find LC columns created at least 2 years ago that have never been used with a dataset
    -----------------------------------------------------------

    INSERT INTO Tmp_LCColumns (lc_column_id, Last_Used)
    SELECT LCCol.lc_column_id, LCCol.created As Last_Used
    FROM t_lc_column LCCol
         LEFT OUTER JOIN t_dataset DS
           ON LCCol.lc_column_id = DS.lc_column_ID
    WHERE LCCol.column_state_id <> 3 AND
          LCCol.created < CURRENT_TIMESTAMP - make_interval(months => _unusedThresholdMonths) AND
          DS.dataset_id Is Null
    ORDER BY LCCol.lc_column_id;

    -----------------------------------------------------------
    -- Remove certain columns that we don't want to auto-retire
    -----------------------------------------------------------

    DELETE FROM Tmp_LCColumns
    WHERE lc_column_id IN ( SELECT lc_column_id
                            FROM t_lc_column
                            WHERE lc_column IN ('unknown', 'No_Column', 'DI', 'Infuse') );

    If _infoOnly Then

        -----------------------------------------------------------
        -- Preview the columns that would be retired
        -----------------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-12s %-30s %-20s %-80s %-20s %-50s %-25s %-25s %-13s %-13s %-16s %-16s';

        _infoHead := format(_formatSpecifier,
                            'LC_Column_ID',
                            'LC_Column',
                            'Src.Last_Used',
                            'Src.Most_Recent_Dataset',
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
                                     '--------------------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------',
                                     '--------------------------------------------------',
                                     '-------------------------',
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
                   Src.Last_Used,
                   Src.Most_Recent_Dataset,
                   public.timestamp_text(LCCol.Created) As Created,
                   LCCol.Comment,
                   LCCol.Packing_Mfg,
                   LCCol.Packing_Type,
                   LCCol.Particle_Size,
                   LCCol.Particle_Type,
                   LCCol.Column_Inner_Dia,
                   LCCol.Column_Outer_Dia
            FROM t_lc_column LCCol
                 INNER JOIN Tmp_LCColumns Src
                   ON LCCol.lc_column_id = Src.lc_column_id
            ORDER BY Src.Last_Used, LCCol.lc_column_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.LC_Column_ID,
                                _previewData.LC_Column,
                                _previewData.Src.Last_Used,
                                _previewData.Src.Most_Recent_Dataset,
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

    Else
        -----------------------------------------------------------
        -- Change the LC Column state to 3=Retired
        -----------------------------------------------------------

        UPDATE t_lc_column
        SET column_state_id = 3
        WHERE lc_column_id IN ( SELECT lc_column_id
                                FROM Tmp_LCColumns Filter );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Retired %s %s that have not been used in at last %s months',
                        _updateCount, public.check_plural(_updateCount, 'LC column', 'LC columns'), _usedThresholdMonths);

            CALL post_log_entry ('Normal', _message, 'Retire_Stale_LC_Columns');
        End If;

    End If;

    DROP TABLE Tmp_LCColumns;
END
$$;

COMMENT ON PROCEDURE public.retire_stale_lc_columns IS 'RetireStaleLCColumns';
