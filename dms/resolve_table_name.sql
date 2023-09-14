--
-- Name: resolve_table_name(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.resolve_table_name(_tabletofind text) RETURNS TABLE(table_to_find public.citext, schema_name public.citext, table_name public.citext, table_exists boolean, message public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for the specified table
**      If _tableToFind does not contain a schema, looks for the named table in any schema
**
**      Returns a table that includes the schema and name of any matching table(s)
**      Names will be properly capitalized if found
**      If the table is not found, Table_Exists will be 0 and a Message will be included
**
**  Arguments:
**    _tableToFind   Table name to find (with or without schema)
**
**  Auth:   mem
**  Date:   04/01/2022 mem - Initial Version
**          05/22/2023 mem - Capitalize reserved words
**          05/30/2023 mem - Use format() for string concatenation
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _tableSchema citext := '';
    _tableName citext := '';
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _tableToFind := Trim(Coalesce(_tableToFind, ''));

    If _tableToFind Like '%.%' Then
        -- Includes schema and name
        SELECT split_part(_tableToFind, '.', 1) INTO _tableSchema;
        SELECT split_part(_tableToFind, '.', 2) INTO _tableName;

        RETURN QUERY
        SELECT _tableToFind::citext,
               schemaname::citext,
               tablename::citext,
               True As Table_Exists,
               ''::citext
        FROM pg_tables
        WHERE schemaname::citext = _tableSchema And tablename::citext = _tableName;

        If FOUND Then
            RETURN;
        End If;

        RETURN QUERY
        SELECT _tableToFind::citext,
               _tableSchema,
               _tableName,
               false As Table_Exists,
               format('Table not found in the given schema: %s', _tableToFind)::citext;
    Else
        If Exists (SELECT * FROM pg_tables WHERE tablename::citext = _tableToFind::citext) Then
            RETURN QUERY
            SELECT _tableToFind::citext,
                   schemaname::citext,
                   tablename::citext,
                   True As Table_Exists,
                   ''::citext
            FROM pg_tables
            WHERE tablename::citext = _tableToFind::citext;

            RETURN;
        End If;

        RETURN QUERY
        SELECT _tableToFind::citext,
               ''::citext,
               _tableToFind::citext,
               false As Table_Exists,
               format('Table not found in any schema: %s', _tableToFind)::citext;
    End If;

END
$$;


ALTER FUNCTION public.resolve_table_name(_tabletofind text) OWNER TO d3l243;

