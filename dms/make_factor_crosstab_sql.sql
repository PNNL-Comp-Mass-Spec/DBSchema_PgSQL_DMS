--
-- Name: make_factor_crosstab_sql(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.make_factor_crosstab_sql(_collist text, _viewname text DEFAULT 'V_Requested_Run_Unified_List'::text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
**      It must also create temp table Tmp_Factors, but this function will populate it
**          CREATE TEMP TABLE Tmp_Factors
**              FactorID int,
**              FactorName citext NULL
**          );
**
**  Arguments:
**    _colList      Columns to include in the crosstab, for example: ' ''x'' as sel, batch_id, experiment, dataset, name, status, request'
**    _viewName     View to use; should be V_Requested_Run_Unified_List or V_Requested_Run_Unified_List_Ex
**    _sql          Output: crosstab SQL
**
**  Auth:   grk
**  Date:   03/22/2010
**          03/22/2010 grk - Initial release
**          10/19/2022 mem - Combined make_factor_crosstab_sql and make_factor_crosstab_sql_ex
**          11/11/2022 mem - Exclude unnamed factors when querying T_Factor
**          07/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _factorNameList text;
    _factorNameAndTypeList text;
    _crossTabSql text;
    _sql text;
BEGIN
    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _colList := Trim(Coalesce(_colList, ''));
    _viewName := Trim(Coalesce(_viewName, ''));
    _sql := '';

    If Not Exists (SELECT * FROM Tmp_RequestIDs) Then
        RAISE WARNING 'Temporary table Tmp_RequestIDs is empty; nothing to do';
        RETURN '';
    End If;

    If _colList = '' Then
        RAISE WARNING '_colList is empty; unable to continue';
        RETURN '';
    End If;

    If _viewName = '' Then
        RAISE WARNING '_viewName is empty; unable to continue';
        RETURN '';
    End If;

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    -----------------------------------------

    -- If none of the members of this batch has entries in T_Factors, Tmp_Factors will be empty (that's OK)
    -- Factor names in T_Factor should not be empty, but exclude empty strings for safety

    INSERT INTO Tmp_Factors( FactorID, FactorName )
    SELECT Src.factor_id, Src.name
    FROM t_factor Src
         INNER JOIN Tmp_RequestIDs
           ON Src.target_id = Tmp_RequestIDs.Request
    WHERE Src.type = 'Run_Request' AND
          Trim(Src.Name) <> '';

    -----------------------------------------------------------------------------
    -- Determine the factor names defined by the factor entries in Tmp_Factors
    -- Use %I to quote any factor names that have a space or capital letters
    -----------------------------------------------------------------------------

    SELECT string_agg(format('%I', GroupQ.name), ', ' ORDER BY GroupQ.name)
    INTO _factorNameList
    FROM ( SELECT Src.name
           FROM t_factor Src
                INNER JOIN Tmp_Factors I
                  ON Src.factor_id = I.FactorID
           GROUP BY Src.name) GroupQ;

    SELECT string_agg(format('%I text', GroupQ.name), ', ' ORDER BY GroupQ.name)
    INTO _factorNameAndTypeList
    FROM ( SELECT Src.name
           FROM t_factor Src
                INNER JOIN Tmp_Factors I
                  ON Src.factor_id = I.FactorID
           GROUP BY Src.name) GroupQ;

    -- This will have a comma separated list of factor names, for example: 'BioRep, Sample, Time'
    _factorNameList := Coalesce(_factorNameList, '');

    -- This will have a comma separated list of factor names and the data type to use, for example: 'BioRep text, Sample text, Time text'
    _factorNameAndTypeList := Coalesce(_factorNameAndTypeList, '');

    If _factorNameList <> '' Then
        -- Create the SQL for displaying the factors as a crosstab (aka PivotTable)

        _crossTabSql := format(' SELECT Target_ID, %s', _factorNameList)    ||
                               ' FROM crosstab(''SELECT Src.Target_ID, '
                                                       'Src.Name, '
                                                       'Src.Value '
                                                'FROM t_factor Src '
                                                     'INNER JOIN Tmp_Factors I '
                                                       'ON Src.Factor_ID = I.FactorID '
                                                'ORDER BY 1,2'', '                                            ||
                                               format('$$SELECT unnest(''{%s}''::text[])$$', _factorNameList) ||
                                               ') AS ct (Target_ID int,'                                      ||
                                               format(' %s)', _factorNameAndTypeList);

        -- SQL Server equivalent code
        --
        -- _crossTabSql := format(' SELECT PivotResults.target_id, %s', _factorNameList)         ||
        --                        ' FROM (SELECT Src.type, Src.target_id, Src.name, Src.Value'
        --                              ' FROM t_factor Src INNER JOIN Tmp_Factors I ON Src.factor_id = I.FactorID'
        --                              ') AS DataQ'
        --                              ' PIVOT ('                                                                  ||
        --                       format('   MAX(value) FOR name IN ( %s ) ', _factorNameList)                       ||
        --                              ' ) AS PivotResults';


        -- Example contents of _crossTabSql for PostgreSQL
        --
        -- SELECT Target_ID, "BioRep", "Sample", "Time"
        -- FROM crosstab('SELECT Src.Target_ID, Src.Name, Src.Value
        --                FROM t_factor Src
        --                     INNER JOIN Tmp_Factors I
        --                       ON Src.Factor_ID = I.FactorID
        --                ORDER BY 1,2',
        --                $$SELECT unnest('{"BioRep", "Sample", "Time"}'::text[])$$)
        --                AS ct ( Target_ID int,
        --                        "BioRep" text,
        --                        "Sample" text,
        --                        "Time" text)

        -- Example contents of _crossTabSql for SQL Server
        --
        -- SELECT PivotResults.Type, PivotResults.TargetID, [BioRep], [Sample], [Time]
        -- FROM (SELECT Src.Type, Src.TargetID, Src.Name, Src.Value
        --       FROM T_Factor Src
        --            INNER JOIN #FACTORS I
        --              ON Src.FactorID = I.FactorID
        --      ) AS DataQ
        --      PIVOT ( MAX(Value) FOR Name IN ( [BioRep], [Sample], [Time] )
        --            ) AS PivotResults

    End If;

    -----------------------------------------
    -- Build dynamic SQL to obtain the data
    -----------------------------------------

    _sql := format('SELECT %s', _colList);

    If _factorNameList <> '' Then
        _sql := format('%s, %s', _sql, _factorNameList);
    End If;

    _sql := format('%s FROM ( SELECT Src.* FROM %s Src WHERE Src.Request IN (SELECT Request FROM Tmp_RequestIDs)) UQ', _sql, _viewName);

    If _factorNameList <> '' Then
        _sql := format('%s LEFT OUTER JOIN (%s) CrosstabQ ON UQ.Request = CrossTabQ.Target_ID', _sql, _crossTabSql);
    End If;

    -- Example contents of _sql
    --
    -- SELECT 'x' As sel, batch_id, name, status, dataset_id, request, block, run_order, "BioRep", "Sample", "Time"
    -- FROM ( SELECT Src.*
    --       FROM V_Requested_Run_Unified_List Src
    --       WHERE Src.Request IN (SELECT Request FROM Tmp_RequestIDs)
    --     ) UQ
    --     LEFT OUTER JOIN (
    --       SELECT Target_ID, "BioRep", "Sample", "Time"
    --       FROM crosstab('SELECT Src.Target_ID, Src.Name, Src.Value
    --                      FROM t_factor Src
    --                           INNER JOIN Tmp_Factors I
    --                             ON Src.Factor_ID = I.FactorID
    --                      ORDER BY 1,2',
    --                     $$SELECT unnest('{"BioRep", "Sample", "Time"}'::text[])$$) AS ct (Target_ID int, "BioRep" text, "Sample" text, "Time" text)
    --                     ) CrosstabQ ON UQ.Request = CrossTabQ.Target_ID

    RETURN _sql;
END
$_$;


ALTER FUNCTION public.make_factor_crosstab_sql(_collist text, _viewname text) OWNER TO d3l243;

--
-- Name: FUNCTION make_factor_crosstab_sql(_collist text, _viewname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.make_factor_crosstab_sql(_collist text, _viewname text) IS 'MakeFactorCrosstabSQL';

