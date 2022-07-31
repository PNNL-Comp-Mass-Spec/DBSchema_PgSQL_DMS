--
-- Name: trim_schema_change_log_source_data(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trim_schema_change_log_source_data(_infoonly integer DEFAULT 1) RETURNS TABLE(schema_change_log_id integer, entered timestamp without time zone, schema_name public.citext, object_name public.citext, version_rank integer, function_name public.citext, function_source public.citext, source_length_current integer, source_length_new integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For objects with more than three entries in t_schema_change_log,
**      trims data in the function_source column for the the entries
**      older than the first three entries (for each object),
**      shortening the data to the first 100 characters.
**
**  Arguments:
**    _infoOnly                 If 1, show objects with rows that would be trimmed
**                              If 2, show all rows
**  Auth:   mem
**  Date:   07/30/2022 mem - Initial version
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _infoonly := Coalesce(_infoonly, 1);

    ------------------------------------------------
    -- Create a temporary table to hold the rank data
    ------------------------------------------------

    CREATE TEMP TABLE T_Tmp_SchemaChangeLogRank
    (
        schema_change_log_id int,
        version_rank int,
        current_source_length int,
        trim_data bool Null
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

    If _infoOnly > 0 Then
        RETURN QUERY
        SELECT SCL.schema_change_log_id,
               SCL.entered,
               SCL.schema_name,
               SCL.object_name,
               RankQ.version_rank,
               SCL.function_name,
               SCL.function_source,
               char_length(SCL.function_source) as source_length_current,
               Case When RankQ.version_rank > 3 Then
                        Case When char_length(SCL.function_source) > 100 Then 100
                             Else char_length(SCL.function_source)
                        End
                    Else char_length(SCL.function_source)
               End As source_length_new
        FROM t_schema_change_log SCL
             INNER JOIN
                (SELECT DISTINCT L.schema_name AS schema_name, L.object_name as object_name
                 FROM T_Tmp_SchemaChangeLogRank SCLR
                      INNER JOIN t_schema_change_log L
                      ON SCLR.schema_change_log_id = L.schema_change_log_id
                 WHERE SCLR.trim_data = true Or _infoOnly > 1) FilterQ
               ON SCL.schema_name = FilterQ.schema_name AND
                  SCL.object_name = FilterQ.object_name
             INNER JOIN
               T_Tmp_SchemaChangeLogRank RankQ
                 ON SCL.schema_change_log_id = RankQ.schema_change_log_id
        ORDER BY SCL.schema_name, SCL.object_name, SCL.schema_change_log_id;
    Else
        UPDATE t_schema_change_log target
        SET function_source = left(target.function_source, 100)
        FROM T_Tmp_SchemaChangeLogRank RankQ
        WHERE RankQ.trim_data = true AND
              target.schema_change_log_id = RankQ.schema_change_log_id;

        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        _message = 'Trimmed function_source for ' || _myRowCount::text || ' row(s)';

        If _myRowCount > 0 Then
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
    End If;

    DROP TABLE T_Tmp_SchemaChangeLogRank;
END
$$;


ALTER FUNCTION public.trim_schema_change_log_source_data(_infoonly integer) OWNER TO d3l243;

