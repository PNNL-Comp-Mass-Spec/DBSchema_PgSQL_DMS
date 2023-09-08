--
-- Name: condense_integer_list_to_ranges(boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.condense_integer_list_to_ranges(_debugmode boolean DEFAULT false) RETURNS TABLE(category text, valuelist text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given a list of integers in a temporary table, condenses
**      the list into a comma and dash separated list
**
**      Leverages code from Dwain Camps
**      https://www.simple-talk.com/sql/database-administration/condensing-a-delimited-list-of-integers-in-sql-server/
**
**  The calling procedure must create a temporary table with category names and integer values
**
**      CREATE TEMP TABLE Tmp_ValuesByCategory (
**          Category text,
**          Value int             -- Null values will be ignored
**      );
**
**  Example commands:
**
**      INSERT INTO Tmp_ValuesByCategory
**      VALUES ('Job', 100),
**             ('Job', 101),
**             ('Job', 102),
**             ('Job', 114),
**             ('Job', 115),
**             ('Job', 118);
**             ('Dataset', 500),
**             ('Dataset', 505),
**             ('Dataset', 506),
**             ('Dataset', 507),
**             ('Dataset', 508),
**             ('Dataset', 512);
**
**      SELECT * FROM condense_integer_list_to_ranges(false);
**
**  Example results:
**
**      Category  ValueList
**      --------  ---------------------
**      Job       100-102, 114-115, 118
**      Dataset   500, 505-508, 512
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial version
**          12/29/2022 mem - Ported to PostgreSQL
**          06/07/2023 mem - Add Order By to string_agg()
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _categoryRange record;
BEGIN
    ----------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------

    _debugMode := Coalesce(_debugMode, false);

    If Not Exists (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_ValuesByCategory'
    ) Then
        RAISE WARNING 'Source data not found: temporary table Tmp_ValuesByCategory does not exist';
        RETURN;
    End If;

    ----------------------------------------------------
    -- Validate the temporary table
    ----------------------------------------------------

    UPDATE Tmp_ValuesByCategory V
    SET Category = ''
    WHERE V.Category IS NULL;

    CREATE TEMP TABLE Tmp_ValueCategories (
        Category text
    );

    ----------------------------------------------------
    -- Process the data
    ----------------------------------------------------

    INSERT INTO Tmp_ValueCategories (Category)
    SELECT V.Category
    FROM Tmp_ValuesByCategory V
    GROUP BY V.Category;

    RETURN QUERY
    WITH Islands AS (
        SELECT RankQ.Category, MIN(RankQ.Value) AS StartValue, MAX(RankQ.Value) AS EndValue
        FROM (
            SELECT V.Category,
                   V.Value,
                   V.Value - ROW_NUMBER() OVER (PARTITION BY V.Category ORDER BY V.Value) AS rn  -- This column represents the 'staggered rows'
            FROM Tmp_ValuesByCategory V
            WHERE Not V.Value Is Null
            ) RankQ
        GROUP BY RankQ.Category, RankQ.rn
    )
    SELECT ValueListQ.Category, ValueListQ.ValueList
    FROM (
        SELECT RangeQ.Category, string_agg(RangeQ.ValueList, ', ' ORDER BY RangeQ.ValueList) ValueList
        FROM (
            SELECT a.category, CASE WHEN b.StartValue = b.EndValue THEN b.StartValue::text ELSE format('%s-%s', b.StartValue,b.EndValue) END As ValueList
            FROM Tmp_ValueCategories a INNER JOIN Islands b ON a.Category = b.Category
            ORDER BY b.StartValue) RangeQ
        GROUP BY RangeQ.Category) ValueListQ;

    If _debugMode Then
        FOR _categoryRange IN
            SELECT RankQ.Category, MIN(RankQ.Value) AS StartValue, MAX(RankQ.Value) AS EndValue
            FROM (
                SELECT V.Category,
                       V.Value,
                       V.Value - ROW_NUMBER() OVER (PARTITION BY V.Category ORDER BY V.Value) AS rn
                FROM Tmp_ValuesByCategory V
                WHERE Not V.Value Is Null) RankQ
            GROUP BY RankQ.Category, RankQ.rn
            ORDER BY RankQ.Category, RankQ.rn
        LOOP
            RAISE INFO 'Category %, values % to %', _categoryRange.Category, _categoryRange.StartValue, _categoryRange.EndValue;
        END LOOP;

    End If;

    DROP TABLE Tmp_ValueCategories;
END
$$;


ALTER FUNCTION public.condense_integer_list_to_ranges(_debugmode boolean) OWNER TO d3l243;

--
-- Name: FUNCTION condense_integer_list_to_ranges(_debugmode boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.condense_integer_list_to_ranges(_debugmode boolean) IS 'CondenseIntegerListToRanges';

