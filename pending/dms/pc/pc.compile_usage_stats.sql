--
CREATE OR REPLACE PROCEDURE pc.compile_usage_stats
(
    _displayStats int = 1,
    INOUT _tables int = 0,
    INOUT _rows int = 0,
    INOUT _columns int = 0,
    INOUT _cells bigint = 0,
    INOUT _spaceUsageMB real = 0,
    _message text = '' OUTPUT
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Counts the number of tables, rows, columns, and cells in this database
**
**  Arguments:
**    _displayStats   If non-zero, then the values will be displayed as a ResultSet
**
**  Auth:   mem
**  Date:   03/28/2008
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _displayStats := Coalesce(_displayStats, 1);
    _tables := 0;
    _rows := 0;
    _columns := 0;
    _cells := 0;
    _spaceUsageMB := 0;
    _message := '';

    ---------------------------------------------------
    -- Obtain the stats using 3 system tables and the view V_Table_Size_Summary
    ---------------------------------------------------

    SELECT COUNT(DISTINCT LookupQ.Table_Name), INTO _tables
            _rows = SUM(TSS.Table_Row_Count),
            _columns = SUM(LookupQ.ColumnCount),
            _cells = SUM(Convert(bigint, LookupQ.ColumnCount) * Convert(bigint, TSS.Table_Row_Count)),
            _spaceUsageMB = SUM(Space_Used_MB)
    FROM (    SELECT T.[Name] AS Table_Name, COUNT(*) AS ColumnCount
            FROM sys.columns C INNER JOIN
                 sys.objects O ON C.Object_ID = O.Object_ID INNER JOIN
                 sys.tables T ON T.Name = O.Name
            WHERE (T.[Name] <> 'dtproperties')
            GROUP BY T.[Name]
         ) LookupQ INNER JOIN
         V_Table_Size_Summary TSS ON LookupQ.Table_Name = TSS.Table_Name

    If _displayStats <> 0 Then
        SELECT DB_Name() as DBName, ;
    End If;
                _tables AS [Tables],
                _rows As [Rows],
                _columns AS [Columns],
                _cells As [Cells],
                _spaceUsageMB As [SpaceUsageMB]

Done:

    Return _myError

END
$$;

COMMENT ON PROCEDURE pc.compile_usage_stats IS 'CompileUsageStats';
