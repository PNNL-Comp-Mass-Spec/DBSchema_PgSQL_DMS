--
CREATE OR REPLACE PROCEDURE public.make_factor_crosstab_sql
(
    _colList text,
    INOUT _sql text,
    _viewName text = 'V_Requested_Run_Unified_List'
)
RETURNS text
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns dynamic SQL for a requested run factors crosstab query
**
**      The calling function must create and populate temporary table Tmp_RequestIDs
**          CREATE TEMP TABLE Tmp_RequestIDs (
**              Request int
**          );
**
**      It must also CREATE TEMP TABLE Tmp_Factors, but this function will populate it
**          CREATE TEMP TABLE Tmp_Factors
**              FactorID int,
**              FactorName text NULL
**          );

**  Arguments:
**    _colList      Columns to include in the crosstab, for example: ' ''x'' as sel, batch_id, experiment, dataset, name, status, request'
**    _sql          Output: crosstab SQL
**    _viewName     View to use; should be V_Requested_Run_Unified_List or V_Requested_Run_Unified_List_Ex
**
**  Auth:   grk
**  Date:   03/22/2010
**          03/22/2010 grk - initial release
**          10/19/2022 mem - Combined make_factor_crosstab_sql and make_factor_crosstab_sql_ex
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _crossTabSql text;
    _factorNameList text;
BEGIN

    INSERT INTO Tmp_RequestIDs( Request )
    SELECT Value
    FROM public.parse_delimited_integer_list ( _requestIdList, ',' );

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    -----------------------------------------

    -- If none of the members of this batch has entries in T_Factors, Tmp_Factors will be empty (that's OK)
    -- Factor names in T_Factor should not be empty, but exclude empty strings for safety

    INSERT INTO Tmp_Factors( FactorID, FactorName )
    SELECT Src.factor_id, Src.name
    FROM t_factor Src INNER JOIN
         Tmp_RequestIDs ON Src.target_id = Tmp_RequestIDs.Request
    WHERE Src.type= 'Run_Request' AND
          Trim(Src.Name) <> '';

    -----------------------------------------
    -- Determine the factor names defined by the
    -- factor entries in Tmp_Factors
    -----------------------------------------

    SELECT string_agg(format('"%s"', Src.name), ', ' ORDER BY Src.name)
    INTO _factorNameList
    FROM t_factor Src
        INNER JOIN Tmp_Factors I
        ON Src.factor_id = I.FactorID
    GROUP BY Src.name;

    -----------------------------------------
    -- SQL for factors as crosstab (PivotTable)
    -----------------------------------------
    --
    _crossTabSql := '';
    _crossTabSql := _crossTabSql || ' SELECT PivotResults.type, PivotResults.target_id,' || _factorNameList;
    _crossTabSql := _crossTabSql || ' FROM (SELECT Src.type, Src.target_id, Src.name, Src.Value';
    _crossTabSql := _crossTabSql ||       ' FROM t_factor Src INNER JOIN Tmp_Factors I ON Src.factor_id = I.FactorID';
    _crossTabSql := _crossTabSql ||       ') AS DataQ';
    _crossTabSql := _crossTabSql ||       ' PIVOT (';
    _crossTabSql := _crossTabSql ||       '   MAX(value) FOR name IN ( ' || _factorNameList || ' ) ';
    _crossTabSql := _crossTabSql ||       ' ) AS PivotResults';

    -----------------------------------------
    -- Build dynamic SQL for make_factor_crosstab
    -----------------------------------------
    --
    _factorNameList := Coalesce(_factorNameList, '');
    _sql := '';
    _sql := _sql || 'SELECT ' || _colList || ' ';

    If _factorNameList <> '' Then
        _sql := _sql || ', ' || _factorNameList;
    End If;

    _sql := _sql || ' FROM ( SELECT * FROM ' || _viewName || ' Src WHERE Src.Request IN (SELECT Request FROM Tmp_RequestIDs) ';
    _sql := _sql || ' ) UQ ';

    If _factorNameList <> '' Then
        _sql := _sql || ' LEFT OUTER JOIN (' || _crossTabSql || ') CrosstabQ ON UQ.Request = CrossTabQ.TargetID';
    End If;

    RETURN _sql;
END
$$;

COMMENT ON PROCEDURE public.make_factor_crosstab_sql IS 'MakeFactorCrosstabSQL';
