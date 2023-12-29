--
-- Name: trim_schema_change_log_source_data(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trim_schema_change_log_source_data(_infolevel integer DEFAULT 1) RETURNS TABLE(schema_change_log_id integer, entered timestamp without time zone, schema_name public.citext, object_name public.citext, version_rank integer, function_name public.citext, function_source public.citext, source_length_current integer, source_length_new integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For objects with more than three entries in t_schema_change_log,
**      trim data in the function_source column for the the entries
**      older than the first three entries (for each object),
**      shortening the data to the first 100 characters.
**
**      In addition, condense duplicate log entries, i.e. instances of
**      the same object and same command being logged multiple times with the same timestamp.
**      This was observed when foreign data tables were imported using "IMPORT FOREIGN SCHEMA".
**
**  Arguments:
**    _infoLevel        When 0, remove the extra rows from t_schema_change_log
**                      When 1, show objects with rows that would be trimmed
**                      When 2, show all rows
**
**  Example usage:
**      SELECT COUNT(*) FROM trim_schema_change_log_source_data(1);
**
**      SELECT * FROM trim_schema_change_log_source_data(1);
**      SELECT * FROM trim_schema_change_log_source_data(0);
**
**  Auth:   mem
**  Date:   07/30/2022 mem - Initial version
**          07/31/2022 mem - Remove duplicate entries (same object, command, and entry time)
**          12/23/2022 mem - Rename parameter to _infoLevel
**          04/27/2023 mem - Use boolean for data type name
**          05/12/2023 mem - Rename variables
**          05/31/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _duplicateCount int;
    _updateCount int;
    _deleteCount int;
    _message text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _infoLevel := Coalesce(_infoLevel, 1);

    ------------------------------------------------
    -- Create a temporary table to hold the rank data
    ------------------------------------------------

    CREATE TEMP TABLE T_Tmp_SchemaChangeLogRank
    (
        schema_change_log_id int,
        version_rank int,
        current_source_length int,
        trim_data boolean Null
    );

    INSERT INTO T_Tmp_SchemaChangeLogRank (schema_change_log_id, version_rank, current_source_length)
    SELECT RankQ.schema_change_log_id, RankQ.version_rank, RankQ.current_source_length
    FROM ( SELECT SCL.schema_change_log_id,
                  char_length(SCL.function_source) as current_source_length,
                  row_number() OVER ( PARTITION BY SCL.schema_name, SCL.object_name
                                      ORDER BY SCL.schema_change_log_id DESC ) AS version_rank
           FROM t_schema_change_log SCL
           WHERE NOT SCL.function_source IS NULL) RankQ;

    UPDATE T_Tmp_SchemaChangeLogRank target
    SET trim_data = true
    WHERE target.version_rank > 3 And target.current_source_length > 100;

    If _infoLevel > 0 Then
        RETURN QUERY
        SELECT SCL.schema_change_log_id,
               SCL.entered,
               SCL.schema_name,
               SCL.object_name,
               RankQ.version_rank,
               SCL.function_name,
               SCL.function_source,
               char_length(SCL.function_source) as source_length_current,
               CASE WHEN RankQ.version_rank > 3 THEN
                        CASE WHEN char_length(SCL.function_source) > 100 THEN 100
                             ELSE char_length(SCL.function_source)
                        END
                    ELSE char_length(SCL.function_source)
               END As source_length_new
        FROM t_schema_change_log SCL
             INNER JOIN
                (SELECT DISTINCT L.schema_name AS schema_name, L.object_name as object_name
                 FROM T_Tmp_SchemaChangeLogRank SCLR
                      INNER JOIN t_schema_change_log L
                      ON SCLR.schema_change_log_id = L.schema_change_log_id
                 WHERE SCLR.trim_data = true Or _infoLevel > 1) FilterQ
               ON SCL.schema_name = FilterQ.schema_name AND
                  SCL.object_name = FilterQ.object_name
             INNER JOIN
               T_Tmp_SchemaChangeLogRank RankQ
                 ON SCL.schema_change_log_id = RankQ.schema_change_log_id
        ORDER BY SCL.schema_name, SCL.object_name, SCL.schema_change_log_id;

        -- Look for duplicate entries (see below for more info)
        SELECT COUNT(*)
        INTO _duplicateCount
        FROM ( SELECT RankQ.schema_change_log_id,
                      row_number() OVER ( PARTITION BY RankQ.schema_name, RankQ.object_name, RankQ.command_tag, RankQ.entered
                                          ORDER BY RankQ.schema_change_log_id ) AS DupeRank
               FROM t_schema_change_log RankQ) FilterQ
        WHERE FilterQ.DupeRank > 1;

        If _duplicateCount > 0 Then
            -- This will append a row to the result set
            RETURN QUERY
            SELECT 0 As schema_change_log_id,
                   LocalTimestamp As entered,
                   'Note'::citext As schema_name,
                   format('Condensed %s duplicate %s, having the same object name, object type, and entry time',
                          _duplicateCount, public.check_plural(_duplicateCount, 'row', 'rows'))::citext AS object_name,
                   1 As version_rank,
                   ''::citext As function_name,
                   ''::citext As function_source,
                   0 As source_length_old,
                   0 As source_length_new;
        End If;

        DROP TABLE T_Tmp_SchemaChangeLogRank;
        RETURN;
    End If;

    UPDATE t_schema_change_log target
    SET function_source = left(target.function_source, 100)
    FROM T_Tmp_SchemaChangeLogRank RankQ
    WHERE RankQ.trim_data = true AND
          target.schema_change_log_id = RankQ.schema_change_log_id;

    GET DIAGNOSTICS _updateCount = ROW_COUNT;
    _message := format('Trimmed function_source for %s %s', _updateCount, public.check_plural(_updateCount, 'row', 'rows'));

    If _updateCount > 0 Then
        RAISE INFO '%', _message;

        RETURN QUERY
        SELECT SCL.schema_change_log_id,
               SCL.entered,
               SCL.schema_name,
               SCL.object_name,
               RankQ.version_rank,
               SCL.function_name,
               SCL.function_source,
               RankQ.current_source_length as source_length_old,
               char_length(SCL.function_source) as source_length_new
        FROM t_schema_change_log SCL
             INNER JOIN
                (SELECT DISTINCT L.schema_name AS schema_name, L.object_name as object_name
                 FROM T_Tmp_SchemaChangeLogRank SCLR
                      INNER JOIN t_schema_change_log L
                      ON SCLR.schema_change_log_id = L.schema_change_log_id
                 WHERE SCLR.trim_data = true) FilterQ
               ON SCL.schema_name = FilterQ.schema_name AND
                  SCL.object_name = FilterQ.object_name
             INNER JOIN
               T_Tmp_SchemaChangeLogRank RankQ
                 ON SCL.schema_change_log_id = RankQ.schema_change_log_id
        ORDER BY SCL.schema_name, SCL.object_name, SCL.schema_change_log_id;
    Else
        RETURN QUERY
        SELECT 0 As schema_change_log_id,
               LocalTimestamp As entered,
               'Note'::citext As schema_name,
               'Did not find any objects that have more than three entries and function source longer than 100 characters'::citext As object_name,
               1 As version_rank,
               ''::citext As function_name,
               ''::citext As function_source,
               0 As source_length_old,
               0 As source_length_new;
    End If;

    -- When foreign tables are created using "IMPORT FOREIGN SCHEMA", duplicate entries get logged to t_schema_change_log
    -- Condense the duplicates by grouping on schema, object, command_tag, and entry time,
    -- then removing all but the first entry

    DELETE FROM t_schema_change_log target
    WHERE target.schema_change_log_id IN
          ( SELECT FilterQ.schema_change_log_id
            FROM ( SELECT RankQ.schema_change_log_id,
                          row_number() OVER ( PARTITION BY RankQ.schema_name, RankQ.object_name, RankQ.command_tag, RankQ.entered
                                              ORDER BY RankQ.schema_change_log_id ) AS DupeRank
                   FROM t_schema_change_log RankQ) FilterQ
            WHERE FilterQ.DupeRank > 1 );

    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        _message := public.append_to_text(_message,
                                          format('Condensed %s duplicate %s, having the same object name, object type, and entry time',
                                                 _deleteCount, public.check_plural(_deleteCount, 'row','rows')));

        -- This will append a row to the result set
        RETURN QUERY
        SELECT 0 As schema_change_log_id,
               LocalTimestamp As entered,
               'Note'::citext As schema_name,
               format('Condensed %s duplicate s, having the same object name, object type, and entry time', _deleteCount, public.check_plural(_deleteCount, 'row','rows'))::citext AS object_name,
               1 As version_rank,
               ''::citext As function_name,
               ''::citext As function_source,
               0 As source_length_old,
               0 As source_length_new;
    End If;

    DROP TABLE T_Tmp_SchemaChangeLogRank;
END
$$;


ALTER FUNCTION public.trim_schema_change_log_source_data(_infolevel integer) OWNER TO d3l243;

