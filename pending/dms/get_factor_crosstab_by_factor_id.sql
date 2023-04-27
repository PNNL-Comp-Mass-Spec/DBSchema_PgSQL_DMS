--
CREATE OR REPLACE PROCEDURE public.get_factor_crosstab_by_factor_id
(
    _results refcursor DEFAULT '_results'::refcursor,
    _generateSQLOnly boolean = false,
    INOUT _crossTabSql text = '',
    INOUT _factorNameList text = '',
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the factors defined by the FactorID entries
**      in temporary table Tmp_FactorItems (which must be
**      created by the calling procedure)
**
**      CREATE Table Tmp_FactorItems (
**          FactorID int
**      )
**
**      Results are returned by the RefCursor argument since the number of factors will affect the number of columns in the results
**
**  Arguments:
**    _generateSQLOnly   If true, generates the SQL required to return the results, but doesn't actually return the results
**
**  Auth:   mem
**  Date:   02/18/2010
**          02/19/2010 grk - tweaked logic that creates _factorNameList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _generateSQLOnly := Coalesce(_generateSQLOnly, false);
    _crossTabSql := '';
    _factorNameList := '';
    _message := '';

    If Not Exists (SELECT * FROM Tmp_FactorItems) Then
        _crossTabSql := 'SELECT type, target_id FROM t_factor WHERE 1 = 2';

        If _generateSQLOnly = 0 Then
            -- Return an empty table

            -- ToDo: return the results using the RefCursor _results

            RETURN QUERY
            EXECUTE _crossTabSql;

            _message := 'Tmp_FactorItems is empty; nothing to return';
        End If;
    Else

        -----------------------------------------
        -- Determine the factor names defined by the factor entries in Tmp_FactorItems
        -----------------------------------------
        --

        SELECT string_agg('"' || FactorName || '"', ', ')
        INTO _factorNameList
        FROM ( SELECT Src.name AS FactorName
               FROM t_factor Src
                    INNER JOIN Tmp_FactorItems I
                      ON Src.factor_id = I.factor_id
               GROUP BY Src.name ) GroupingQ

        -----------------------------------------
        -- Return the factors, displayed as a crosstab (PivotTable)
        -----------------------------------------
        --
        _crossTabSql := '';
        _crossTabSql := _crossTabSql || ' SELECT PivotResults.type, PivotResults.target_id,' || _factorNameList;
        _crossTabSql := _crossTabSql || ' FROM (SELECT Src.type, Src.target_id, Src.name, Src.Value';
        _crossTabSql := _crossTabSql ||       ' FROM  t_factor Src INNER JOIN Tmp_FactorItems I ON Src.factor_id = I.factor_id';
        _crossTabSql := _crossTabSql ||       ') AS DataQ';
        _crossTabSql := _crossTabSql ||       ' PIVOT (';
        _crossTabSql := _crossTabSql ||       '   MAX(value) FOR name IN ( ' || _factorNameList || ' ) ';
        _crossTabSql := _crossTabSql ||       ' ) AS PivotResults';

        -- ToDo: return the results using the RefCursor _results

        If _generateSQLOnly Then
            RETURN QUERY
            SELECT _crossTabSql;
        ELSE
            RETURN QUERY
            EXECUTE _crossTabSql;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE public.get_factor_crosstab_by_factor_id IS 'GetFactorCrosstabByFactorID';
