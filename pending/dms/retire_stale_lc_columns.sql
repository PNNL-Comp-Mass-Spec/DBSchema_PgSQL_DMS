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
**  Return values: 0:  success, otherwise, error code
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
    --
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
        --
        UPDATE Tmp_LCColumns
        SET Most_Recent_Dataset = LookupQ.Dataset_Name
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
        WHERE Tmp_LCColumns.ID = LookupQ.DS_LC_Column_ID;

    End If;

    -----------------------------------------------------------
    -- Next find LC columns created at least 2 years ago that have never been used with a dataset
    -----------------------------------------------------------
    --
    INSERT INTO Tmp_LCColumns (lc_column_id, Last_Used)
    SELECT LCCol.lc_column_id, LCCol.created as Last_Used
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
    --
    DELETE FROM Tmp_LCColumns
    WHERE lc_column_id IN ( SELECT lc_column_id
                            FROM t_lc_column
                            WHERE (lc_column IN ('unknown', 'No_Column', 'DI', 'Infuse')) )

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -----------------------------------------------------------
        -- Preview the columns that would be retired
        -----------------------------------------------------------
        --
        SELECT LCCol.lc_column_id,
               LCCol.lc_column,
               Src.Last_Used,
               Src.Most_Recent_Dataset,
               LCCol.created,
               LCCol.comment,
               LCCol.packing_mfg,
               LCCol.packing_type,
         LCCol.particle_size,
               LCCol.particle_type,
               LCCol.column_inner_dia,
               LCCol.column_outer_dia
        FROM t_lc_column LCCol
             INNER JOIN Tmp_LCColumns Src
               ON LCCol.lc_column_id = Src.lc_column_id
        ORDER BY  Src.Last_Used, LCCol.lc_column_id

    Else
        -----------------------------------------------------------
        -- Change the LC Column state to 3=Retired
        -----------------------------------------------------------
        --
        UPDATE t_lc_column
        SET column_state_id = 3
        WHERE lc_column_id IN ( SELECT lc_column_id
                                FROM Tmp_LCColumns Filter );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Retired %s %s that have not been used in at last %s months',
                        _updateCount, public.check_plural(_updateCount, 'LC column', 'LC columns'), _usedThresholdMonths);

            Call post_log_entry ('Normal', _message, 'Retire_Stale_LC_Columns');
        End If;

    End If;

    DROP TABLE Tmp_LCColumns;
END
$$;

COMMENT ON PROCEDURE public.retire_stale_lc_columns IS 'RetireStaleLCColumns';
