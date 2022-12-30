--
-- Name: condense_integer_list_to_ranges(boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.condense_integer_list_to_ranges(IN _debugmode boolean DEFAULT false)
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
**  The calling procedure must create two temporary tables
**  The Tmp_ValuesByCategory table must be populated with the integers
**
**      CREATE TEMP TABLE Tmp_ValuesByCategory (
**          Category text,
**          Value int Not null
**      );
**
**      CREATE TEMP TABLE Tmp_Condensed_Data (
**          Category text,
**          ValueList text
**      );
**
**  Example data:
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
**      After calling this procedure, Tmp_Condensed_Data will have:
**          Category  ValueList
**          Job       100-102, 114-115, 118
**          Job       100-102, 114-115, 118
**          Dataset   500, 505-508, 512
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial version
**          12/29/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _categoryRange record;
    _categoryRangeList record;
BEGIN
    ----------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------

    _debugMode := Coalesce(_debugMode, false);

    If Not EXISTS (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_ValuesByCategory'
    ) Then
        RAISE WARNING 'Source data not found: temporary table Tmp_ValuesByCategory does not exist';
        RETURN;
    End If;

    If Not EXISTS (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_Condensed_Data'
    ) Then
        RAISE WARNING 'Target table Tmp_Condensed_Data not found: cannot store the results';
        RETURN;
    End If;

    ----------------------------------------------------
    -- Validate the temporary tables
    ----------------------------------------------------
    --
    UPDATE Tmp_ValuesByCategory
    SET Category = ''
    WHERE Category IS NULL;

    TRUNCATE TABLE Tmp_Condensed_Data;

    ----------------------------------------------------
    -- Process the data
    ----------------------------------------------------
    --
    INSERT INTO Tmp_Condensed_Data (Category, ValueList)
    SELECT Category, ''
    FROM Tmp_ValuesByCategory
    GROUP BY Category;

    WITH Islands AS (
        SELECT RankQ.Category, MIN(RankQ.Value) AS StartValue, MAX(RankQ.Value) AS EndValue
        FROM (
            SELECT Category,
                   Value,
                   Value - ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Value) AS rn  -- This column represents the 'staggered rows'
            FROM Tmp_ValuesByCategory) RankQ
        GROUP BY RankQ.Category, RankQ.rn
    )
    UPDATE Tmp_Condensed_Data
    SET ValueList = RangeListQ.RangeList
    FROM (
        SELECT RangeQ.Category, string_agg(RangeQ.ValueList, ', ') RangeList
        FROM (
            SELECT a.category, Case When b.StartValue = b.EndValue Then b.StartValue::text Else format('%s-%s', b.StartValue,b.EndValue) End as ValueList
            FROM Tmp_Condensed_Data a INNER JOIN Islands b ON a.Category = b.Category
            ORDER BY b.StartValue) RangeQ
        GROUP BY RangeQ.Category) RangeListQ
    WHERE Tmp_Condensed_Data.Category = RangeListQ.Category;

    If _debugMode Then
        FOR _categoryRange IN
            SELECT RankQ.Category, MIN(RankQ.Value) AS StartValue, MAX(RankQ.Value) AS EndValue
            FROM (
                SELECT Category,
                       Value,
                       Value - ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Value) AS rn
                FROM Tmp_ValuesByCategory) RankQ
            GROUP BY RankQ.Category, RankQ.rn
            ORDER BY RankQ.Category, RankQ.rn
        LOOP
            RAISE INFO 'Category %, values % to %', _categoryRange.Category, _categoryRange.StartValue, _categoryRange.EndValue;
        END LOOP;

        FOR _categoryRangeList IN
            SELECT Category, ValueList
            FROM Tmp_Condensed_Data
            ORDER BY Category
        LOOP
            RAISE INFO 'Category %, ranges %', _categoryRangeList.Category, _categoryRangeList.ValueList;
        END LOOP;
    End If;

END
$$;


ALTER PROCEDURE public.condense_integer_list_to_ranges(IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE condense_integer_list_to_ranges(IN _debugmode boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.condense_integer_list_to_ranges(IN _debugmode boolean) IS 'CondenseIntegerListToRanges';

