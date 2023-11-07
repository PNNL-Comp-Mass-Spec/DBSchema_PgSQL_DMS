--
-- Name: get_factor_crosstab_by_factor_id(refcursor, boolean, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_factor_crosstab_by_factor_id(IN _results refcursor DEFAULT '_results'::refcursor, IN _generatesqlonly boolean DEFAULT false, INOUT _crosstabsql text DEFAULT ''::text, INOUT _factornamelist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Returns the factors defined by the FactorID entries in temporary table Tmp_FactorItems
**      (which must be created by the calling procedure)
**
**      CREATE TEMPORARY TABLE Tmp_FactorItems (
**          FactorID int
**      );
**
**  Arguments:
**    _results          Output: RefCursor for viewing the results
**    _generateSQLOnly  When true, generate the SQL required to return the results, but don't actually return the results
**    _crossTabSql      Output: Crosstab SQL
**    _factorNameList   Output: comma-separated list of factor names
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.get_factor_crosstab_by_factor_id (
**                      _generateSQLOnly => false
**               );
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**      DO
**      LANGUAGE plpgsql
**      $block$
**      DECLARE
**          _results refcursor := '_results'::refcursor;
**          _crossTabSql text;
**          _factorNameList text;
**          _message text;
**          _returnCode text;
**          _currentRow record;
**      BEGIN
**          CALL public.get_factor_crosstab_by_factor_id (
**                      _results => _results,
**                      _generateSQLOnly => false,
**                      _crossTabSql => _crossTabSql,
**                      _factorNameList => _factorNameList,
**                      _message => _message,
**                      _returnCode => _returnCode
**                );
**
**          RAISE INFO '';
**          RAISE INFO 'Crosstab SQL: %', _crossTabSql;
**          RAISE INFO 'Factor names: %', _factorNameList;
**
**          If Exists (SELECT name FROM pg_cursors WHERE name = '_results') Then
**              RAISE INFO 'Cursor has data';
**
**              WHILE true
**              LOOP
**                  FETCH NEXT FROM _results
**                  INTO _currentRow;
**
**                  If Not FOUND Then
**                      EXIT;
**                  End If;
**
**                  RAISE INFO 'Type %, Request %, BioRep %, Sample %, Time %',
**                              _currentRow.type,
**                              _currentRow.target_id,
**                              _currentRow."BioRep",
**                              _currentRow."Sample",
**                              _currentRow."Time";
**              END LOOP;
**          Else
**              RAISE INFO 'Cursor is not open';
**          End If;
**      END
**      $block$;
**
**  Auth:   mem
**  Date:   02/18/2010
**          02/19/2010 grk - Tweaked logic that creates _factorNameList
**          07/14/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _factorNameAndTypeList text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _generateSQLOnly := Coalesce(_generateSQLOnly, false);
    _crossTabSql     := '';
    _factorNameList  := '';

    If Not Exists (SELECT * FROM Tmp_FactorItems) Then
        _crossTabSql := 'SELECT type, target_id FROM t_factor WHERE 1 = 2';

        If _generateSQLOnly Then
            RAISE INFO '%', _crossTabSql;
        Else
            _message := 'Tmp_FactorItems is empty; nothing to return';
            RAISE WARNING '%', _message;

            -- Return an empty table
            Open _results For
                EXECUTE _crossTabSql;
        End If;

        RETURN;
    End If;

    -----------------------------------------
    -- Determine the factor names defined by the factor entries in Tmp_FactorItems
    -- Use %I to quote any factor names that have a space or capital letters
    -----------------------------------------

    SELECT string_agg(format('%I', FactorName), ', ' ORDER BY FactorName)
    INTO _factorNameList
    FROM ( SELECT Src.name AS FactorName
           FROM t_factor Src
                INNER JOIN Tmp_FactorItems I
                  ON Src.factor_id = I.FactorID
           GROUP BY Src.name
         ) GroupingQ;

    SELECT string_agg(format('%I text', GroupQ.name), ', ' ORDER BY GroupQ.name)
    INTO _factorNameAndTypeList
    FROM ( SELECT Src.name
           FROM t_factor Src
                INNER JOIN Tmp_FactorItems I
                  ON Src.factor_id = I.FactorID
           GROUP BY Src.name) GroupQ;

    -- This will have a comma separated list of factor names, for example: 'BioRep, Sample, Time'
    _factorNameList := Trim(Coalesce(_factorNameList, ''));

    -- This will have a comma separated list of factor names and the data type to use, for example: 'BioRep text, Sample text, Time text'
    _factorNameAndTypeList := Trim(Coalesce(_factorNameAndTypeList, ''));

    -----------------------------------------
    -- Populate a temporary table with target IDs and target type names
    -----------------------------------------

    DROP TABLE IF EXISTS Tmp_Target_Items;

    CREATE TEMPORARY TABLE Tmp_Target_Items (
        target_id int,
        type text
    );

    INSERT INTO Tmp_Target_Items (target_id, type)
    SELECT Src.target_id, src.type
    FROM t_factor Src
         INNER JOIN Tmp_FactorItems I
           ON Src.factor_id = I.FactorID
    GROUP BY Src.target_id, src.type;

    -----------------------------------------
    -- Return the factors, displayed as a crosstab (PivotTable)
    -----------------------------------------

    _crossTabSql := format(' SELECT TargetItems.type, TargetItems.target_id, %s', _factorNameList)    ||
                           ' FROM crosstab(''SELECT Src.Target_ID, '
                                                   'Src.Name, '
                                                   'Src.Value '
                                            'FROM t_factor Src '
                                                 'INNER JOIN Tmp_FactorItems I '
                                                   'ON Src.Factor_ID = I.FactorID '
                                            'ORDER BY 1,2'', '                                          ||
                                           format('$$SELECT unnest(''{%s}''::text[])$$', _factorNameList) ||
                                           ') AS ct (target_id int,'                           ||
                                           format(' %s)', _factorNameAndTypeList) ||
                                 ' INNER JOIN Tmp_Target_Items TargetItems'
                                     ' ON ct.target_id = TargetItems.target_id';

    -- Example contents of _crossTabSql
    --
    -- SELECT TargetItems.type, TargetItems.target_id, "BioRep", "Sample", "Time"
    -- FROM crosstab('SELECT Src.Target_ID, Src.Name, Src.Value
    --                FROM t_factor Src
    --                     INNER JOIN Tmp_FactorItems I
    --                       ON Src.Factor_ID = I.FactorID
    --                ORDER BY 1,2',
    --                $$SELECT unnest('{"BioRep", "Sample", "Time"}'::text[])$$)
    --                AS ct (target_id int,
    --                       "BioRep" text,
    --                       "Sample" text,
    --                       "Time" text)
    --      INNER JOIN Tmp_Target_Items TargetItems
    --        ON ct.target_id = TargetItems.target_id

    If _generateSQLOnly Then
        RAISE INFO '%', _crossTabSql;
    ELSE
        Open _results For
            EXECUTE _crossTabSql;
    End If;

END
$_$;


ALTER PROCEDURE public.get_factor_crosstab_by_factor_id(IN _results refcursor, IN _generatesqlonly boolean, INOUT _crosstabsql text, INOUT _factornamelist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_factor_crosstab_by_factor_id(IN _results refcursor, IN _generatesqlonly boolean, INOUT _crosstabsql text, INOUT _factornamelist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_factor_crosstab_by_factor_id(IN _results refcursor, IN _generatesqlonly boolean, INOUT _crosstabsql text, INOUT _factornamelist text, INOUT _message text, INOUT _returncode text) IS 'GetFactorCrosstabByFactorID';

