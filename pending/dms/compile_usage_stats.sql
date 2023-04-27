--
CREATE OR REPLACE FUNCTION public.compile_usage_stats()
RETURNS TABLE (
    schema text,
    tables int,
    rows int,
    columns int,
    cells int,
    spaceUsageMB numeric
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Counts the number of tables, rows, columns, and cells in each schema
**
**  Auth:   mem
**  Date:   03/28/2008
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN


    -- ToDo: Convert this to PostgreSQl


    ---------------------------------------------------
    -- Obtain the stats using 3 system tables and the view V_Table_Size_Summary
    ---------------------------------------------------

    SELECT COUNT(DISTINCT LookupQ.Table_Name),
           SUM(TSS.Table_Row_Count),
           SUM(LookupQ.ColumnCount),
           SUM(LookupQ.ColumnCount::bigint * TSS.Table_Row_Count::bigint),
           SUM(Space_Used_MB)
    INTO _tables, _rows, _columns, _cells, _spaceUsageMB
    FROM (  SELECT T.Name AS Table_Name, COUNT(*) AS ColumnCount
            FROM sys.columns C INNER JOIN
                 sys.objects O ON C.Object_ID = O.Object_ID INNER JOIN
                 sys.tables T ON T.Name = O.Name
            WHERE (T.Name <> 'dtproperties')
            GROUP BY T.Name
         ) LookupQ INNER JOIN
         V_Table_Size_Summary TSS ON LookupQ.Table_Name = TSS.Table_Name

    If _displayStats Then
        RAISE INFO 'DB: %, Tables: %, Rows: %, Columns: %, Cells: %, Space Usage: % MB',
        SELECT DB_Name() as DBName,
                _tables AS Tables,
                _rows As Rows,
                _columns AS Columns,
                _cells As Cells,
                _spaceUsageMB As SpaceUsageMB
    End If;

END
$$;

COMMENT ON PROCEDURE public.compile_usage_stats IS 'CompileUsageStats';

