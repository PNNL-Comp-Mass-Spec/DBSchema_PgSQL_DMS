--
-- Name: add_new_ms_terms(text, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_ms_terms(_sourcetable text DEFAULT 'T_Tmp_PsiMS_2016June'::text, _infoonly boolean DEFAULT true) RETURNS TABLE(item_type public.citext, entry_id integer, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, parent_term_id public.citext, parent_term_name public.citext, parent_term_type public.citext, grandparent_term_id public.citext, grandparent_term_name public.citext, grandparent_term_type public.citext, entered timestamp without time zone, updated timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new PSI-MS terms to t_cv_ms
**
**      The source table must have columns:
**        term_pk
**        term_name
**        identifier
**        is_leaf
**        definition
**        comment
**        parent_term_type
**        parent_term_name
**        parent_term_id
**        grandparent_term_type
**        grandparent_term_name
**        grandparent_term_id
**
**  Auth:   mem
**  Date:   06/15/2016 mem - Initial Version
**          05/16/2018 mem - Add columns Parent_term_type and GrandParent_term_type
**          04/03/2022 mem - Ported to PostgreSQL
**          04/04/2022 mem - Update the merge query to support parent_term_type being null
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Capitalize keyword
**          05/25/2023 mem - Simplify call to RAISE INFO
**          05/29/2023 mem - Use format() for string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/21/2024 mem - Change data type of argument _sourceTable to text
**
*****************************************************/
DECLARE
    _sourceSchema citext := '';
    _matchCount int;
    _deleteCount int;
    _updateCount int;
    _insertCount int;
    _additionalRows int := 0;
    _s text := '';
    _deleteObsolete1 text := '';
    _deleteObsolete2 text := '';
    _invalidTerm record;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceTable := Trim(Coalesce(_sourceTable, ''));
    _infoOnly    := Coalesce(_infoOnly, true);

    CREATE TEMP TABLE Tmp_CandidateTables AS
    SELECT Table_to_Find, Schema_Name, Table_Name, Table_Exists, Message
    FROM resolve_table_name(_sourceTable);

    If Not Exists (SELECT * FROM Tmp_CandidateTables WHERE Table_Exists) Then
        -- Message will be:
        -- Table not found in any schema: t_tmp_table
        --or
        -- Table not found in the given schema: ont.t_tmp_table

        RETURN QUERY
        SELECT 'Warning'::citext AS Item_Type,
               0 AS entry_id,
               ''::citext AS term_pk,
               t.Message AS term_name,
               ''::citext AS identifier,
               '0'::citext AS is_leaf,
               ''::citext AS parent_term_id,
               ''::citext AS parent_term_name,
               ''::citext AS parent_term_type,
               ''::citext AS grandparent_term_id,
               ''::citext AS grandparent_term_name,
               ''::citext AS grandparent_term_type,
               current_timestamp::timestamp AS entered,
               NULL::timestamp AS updated
        FROM Tmp_CandidateTables t;

        DROP TABLE Tmp_CandidateTables;
        RETURN;
    End If;

    -- Make sure the schema name and table name are properly capitalized
    SELECT Schema_Name, Table_Name
    INTO _sourceSchema, _sourceTable
    FROM Tmp_CandidateTables
    WHERE Table_Exists
    LIMIT 1;

    DROP TABLE Tmp_CandidateTables;

    RAISE INFO 'Importing from %.%', _sourceSchema, _sourceTable;

    ---------------------------------------------------
    -- Populate a temporary table with the source data
    -- We do this so we can keep track of which rows match existing entries
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_SourceData (
        term_pk citext,
        term_name citext,
        identifier citext,
        is_leaf int,
        parent_term_type citext null,
        parent_term_name citext null,
        parent_term_id citext null,
        grandparent_term_type citext null,
        grandparent_term_name citext null,
        grandparent_term_id citext null,
        matches_existing int,
        entry_id int primary key generated always as identity
    );

    _s := ' INSERT INTO Tmp_SourceData'
          ' SELECT term_pk, term_name, identifier, is_leaf,'
          '   parent_term_type, parent_term_name, parent_term_id,'
          '   grandparent_term_type, grandparent_term_name, grandparent_term_id, 0 AS matches_existing'
          ' FROM %I.%I'
          ' WHERE Coalesce(parent_term_name, '''') <> '''' AND '
          '       Not Coalesce(Definition::citext, '''') SIMILAR TO ''Obsolete%%'' AND '
          '       Not Coalesce(Comment::citext, '''') SIMILAR TO ''Obsolete%%'' ';

    EXECUTE format(_s, _sourceSchema, _sourceTable);

    ---------------------------------------------------
    -- Replace empty Grandparent term IDs and names with NULL
    ---------------------------------------------------

    UPDATE Tmp_SourceData t
    SET grandparent_term_type = NULL,
        grandparent_term_id = NULL,
        grandparent_term_name = NULL
    WHERE Coalesce(t.grandparent_term_id, '') = '' AND
          Coalesce(t.grandparent_term_name, '') = '' AND
          (t.grandparent_term_id = '' OR t.grandparent_term_name = '');

    ---------------------------------------------------
    -- Set matches_existing to 1 for rows that match an existing row in ont.t_cv_ms
    ---------------------------------------------------

    UPDATE Tmp_SourceData t
    SET matches_existing = 1
    FROM ont.t_cv_ms s
    WHERE s.Term_PK = t.Term_PK AND
          s.Parent_term_ID = t.Parent_term_ID AND
          Coalesce(s.grandparent_term_id, '') = Coalesce(t.grandparent_term_id, '');

    ---------------------------------------------------
    -- Look for obsolete terms that need to be deleted
    ---------------------------------------------------

    _s := ' SELECT COUNT(*)'
          ' FROM ('
            ' SELECT s.term_pk, s.Comment, s.Definition'
            ' FROM %I.%I s INNER JOIN'
                 ' ont.t_cv_ms t ON s.term_pk = t.term_pk'
            ' WHERE (Coalesce(s.parent_term_name, '''') = '''') AND '
                  ' (s.Definition::citext SIMILAR TO ''Obsolete%%'' OR s.Comment::citext SIMILAR TO ''Obsolete%%'')'
            ' UNION'
            ' SELECT s.term_pk, s.Comment, s.Definition '
            ' FROM ont.t_cv_ms t INNER JOIN'
               ' (SELECT term_pk, parent_term_id, Comment::citext, Definition::citext'
                ' FROM %I.%I'
                ' WHERE Coalesce(parent_term_name, '''') <> '''' AND '
                      ' (Definition::citext SIMILAR TO ''obsolete%%'' OR Comment::citext SIMILAR TO ''obsolete%%'')'
                ' ) s '
                ' ON t.term_pk = s.term_pk AND '
                   ' t.parent_term_id = s.parent_term_id'
            ' ) LookupQ';

    EXECUTE format(_s, _sourceSchema, _sourceTable, _sourceSchema, _sourceTable)
    INTO _matchCount;

    If _matchCount > 0 Then
        ---------------------------------------------------
        -- Obsolete items found
        -- Construct SQL to delete them
        ---------------------------------------------------

        _s := ' DELETE FROM ont.t_cv_ms'
              ' USING ont.t_cv_ms t'
              '       INNER JOIN %I.%I s'
              '         ON s.term_pk = t.term_pk'
              ' WHERE Coalesce(s.parent_term_name, '''') = '''' AND  '
              '      (s.Definition::citext SIMILAR TO ''Obsolete%%'' OR s.Comment::citext SIMILAR TO ''Obsolete%%'')';

        _deleteObsolete1 := _s;

        _s := ' DELETE FROM ont.t_cv_ms'
              ' USING ont.t_cv_ms t'
              '       INNER JOIN'
                 ' (SELECT term_pk, parent_term_id'
                  ' FROM %I.%I'
                  ' WHERE Coalesce(parent_term_name, '''') <> '''' AND '
                        ' (Definition::citext SIMILAR TO ''obsolete%%'' OR Comment::citext SIMILAR TO ''obsolete%%'')'
                  ' ) ObsoleteTerms '
                  ' ON t.term_pk = ObsoleteTerms.term_pk AND '
                     ' t.parent_term_id = ObsoleteTerms.parent_term_id';

        _deleteObsolete2 := _s;
    End If;

    If Not _infoOnly Then

        If _deleteObsolete1 <> '' Or _deleteObsolete2 <> '' Then
            ---------------------------------------------------
            -- Delete obsolete entries
            ---------------------------------------------------

            EXECUTE format(_deleteObsolete1, _sourceSchema, _sourceTable);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            EXECUTE format(_deleteObsolete2, _sourceSchema, _sourceTable);
            --
            GET DIAGNOSTICS _additionalRows = ROW_COUNT;

            _deleteCount := _deleteCount + _additionalRows;

            RAISE INFO 'Deleted % obsolete rows in ont.t_cv_ms based on entries in %', _deleteCount, _sourceTable;
        End If;


        ---------------------------------------------------
        -- Update existing rows
        ---------------------------------------------------

        UPDATE ont.t_cv_ms t
        SET term_name = s.term_name,
            identifier = s.identifier,
            is_leaf = s.is_leaf,
            parent_term_type = s.parent_term_type,
            parent_term_name = s.parent_term_name,
            grandparent_term_id = s.grandparent_term_id,
            grandparent_term_type = s.grandparent_term_type,
            grandparent_term_name = s.grandparent_term_name,
            updated = CURRENT_TIMESTAMP
        FROM (SELECT d.term_pk, d.term_name, d.identifier, d.is_leaf,
                     d.parent_term_type, d.parent_term_name, d.parent_term_id,
                     d.grandparent_term_type, d.grandparent_term_name, d.grandparent_term_id
               FROM Tmp_SourceData d
               WHERE d.matches_existing = 1) AS s
        WHERE t.term_pk = s.term_pk AND
              t.parent_term_id = s.parent_term_id AND
              Coalesce(t.grandparent_term_id, '') = Coalesce(s.grandparent_term_id, '') AND
              (
                t.term_name <> s.term_name OR
                t.identifier <> s.identifier OR
                t.is_leaf <> s.is_leaf OR
                Coalesce( NULLIF(t.parent_term_type, s.parent_term_type),
                          NULLIF(s.parent_term_type, t.parent_term_type)) IS Not Null OR
                t.parent_term_name <> s.parent_term_name OR
                Coalesce( NULLIF(t.grandparent_term_type, s.grandparent_term_type),
                          NULLIF(s.grandparent_term_type, t.grandparent_term_type)) IS Not Null OR
                Coalesce( NULLIF(t.grandparent_term_name, s.grandparent_term_name),
                          NULLIF(s.grandparent_term_name, t.grandparent_term_name)) IS Not Null
              );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Updated % rows in ont.t_cv_ms using %', _updateCount, _sourceTable;

        ---------------------------------------------------
        -- Add new rows
        ---------------------------------------------------

        INSERT INTO ont.t_cv_ms (term_pk, term_name, identifier, is_leaf,
                                  parent_term_type, parent_term_name, parent_term_id,
                                  grandparent_term_type, grandparent_term_name, grandparent_term_id)
        SELECT s.term_pk, s.term_name, s.identifier, s.is_leaf,
               s.parent_term_type, s.parent_term_name, s.parent_term_id,
               s.grandparent_term_type, s.grandparent_term_name, s.grandparent_term_id
        FROM Tmp_SourceData s
        WHERE s.matches_existing = 0;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        RAISE INFO 'Added % new rows to ont.t_cv_ms using %', _insertCount, _sourceTable;

    Else
        -- _infoOnly is true

        If _deleteObsolete1 <> '' Or _deleteObsolete2 <> '' Then
            RAISE INFO '-- Delete Obsolete rows';
            RAISE INFO '%', format(_deleteObsolete1, _sourceSchema, _sourceTable);
            RAISE INFO '%', format(_deleteObsolete2, _sourceSchema, _sourceTable);

            _s := ' SELECT ''Obsolete term to delete''::citext AS Item_Type,'
                          ' 0 AS entry_id,'
                          ' s.term_pk::citext AS term_pk,'
                          ' s.term_name::citext AS term_name,'
                          ' s.identifier::citext AS identifier,'
                          ' s.is_leaf::citext AS is_leaf,'
                          ' s.parent_term_id::citext AS parent_term_id,'
                          ' s.parent_term_name::citext AS parent_term_name,'
                          ' s.parent_term_type::citext AS parent_term_type,'
                          ' s.grandparent_term_id::citext AS grandparent_term_id,'
                          ' s.grandparent_term_name::citext AS grandparent_term_name,'
                          ' s.grandparent_term_type::citext AS grandparent_term_type,'
                          ' current_timestamp::timestamp AS entered,'
                          ' NULL::timestamp AS updated'
                 ' FROM %I.%I s INNER JOIN'
                      ' ont.t_cv_ms t ON s.term_pk = t.term_pk'
                 ' WHERE (s.Definition::citext SIMILAR TO ''Obsolete%%'' OR s.Comment::citext SIMILAR TO ''Obsolete%%'')';

            RETURN QUERY
            EXECUTE format(_s, _sourceSchema, _sourceTable);

        End If;

        ---------------------------------------------------
        -- Preview existing rows that would be updated
        ---------------------------------------------------

        RETURN QUERY
        SELECT 'Existing item to update'::citext AS Item_Type,
               t.entry_id,
               t.term_pk::citext AS term_pk,
               (CASE WHEN t.term_name  = s.term_name  THEN t.term_name       ELSE format('%s --> %s', t.term_name,  s.term_name)  END)::citext AS term_name,
               (CASE WHEN t.identifier = s.identifier THEN t.identifier      ELSE format('%s --> %s', t.identifier, s.identifier) END)::citext AS identifier,
               (CASE WHEN t.is_leaf = s.is_leaf THEN format('%s', t.is_leaf) ELSE format('%s --> %s', t.is_leaf, s.is_leaf)       END)::citext AS is_leaf,
               (CASE WHEN t.parent_term_type = s.parent_term_type THEN t.parent_term_type ELSE format('%s --> %s', Coalesce(t.parent_term_type, 'NULL'), Coalesce(s.parent_term_type, 'NULL')) END)::citext AS parent_term_type,
               (CASE WHEN t.parent_term_name = s.parent_term_name THEN t.parent_term_name ELSE format('%s --> %s', t.parent_term_name, s.parent_term_name) END)::citext AS parent_term_name,
               t.parent_term_id::citext,
               (CASE WHEN t.grandparent_term_type = s.grandparent_term_type THEN t.grandparent_term_type ELSE format('%s --> %s', Coalesce(t.grandparent_term_type, 'NULL'), Coalesce(s.grandparent_term_type, 'NULL')) END)::citext AS grandparent_term_type,
               (CASE WHEN t.grandparent_term_name = s.grandparent_term_name THEN t.grandparent_term_name ELSE format('%s --> %s', Coalesce(t.grandparent_term_name, 'NULL'), Coalesce(s.grandparent_term_name, 'NULL')) END)::citext AS grandparent_term_name,
               t.grandparent_term_id::citext,
               t.entered::timestamp,
               t.updated::timestamp
        FROM ont.t_cv_ms AS t
            INNER JOIN Tmp_SourceData AS s
              ON t.term_pk = s.term_pk AND
                 t.parent_term_id = s.parent_term_id AND
                 Coalesce(t.grandparent_term_id, '') = Coalesce(s.grandparent_term_id, '')
        WHERE s.matches_existing = 1 AND
              ( (t.term_name <> s.term_name) OR
                (t.identifier <> s.identifier) OR
                (t.is_leaf <> s.is_leaf) OR
                (t.parent_term_name <> s.parent_term_name) OR
                (Coalesce(NULLIF(t.grandparent_term_name, s.grandparent_term_name),
                        NULLIF(s.grandparent_term_name, t.grandparent_term_name)) IS Not Null)
               )
        UNION
        SELECT 'New item to add'::citext AS Item_Type,
               0 AS entry_id,
               s.term_pk::citext,
               s.term_name::citext,
               s.identifier::citext,
               s.is_leaf::citext,
               s.parent_term_type::citext,
               s.parent_term_name::citext,
               s.parent_term_id::citext,
               s.grandparent_term_type::citext,
               s.grandparent_term_name::citext,
               s.grandparent_term_id::citext,
               current_timestamp::timestamp AS entered,
               NULL::timestamp AS updated
        FROM Tmp_SourceData s
        WHERE matches_existing = 0;

    End If;

    DROP TABLE Tmp_SourceData;
END
$$;


ALTER FUNCTION ont.add_new_ms_terms(_sourcetable text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_ms_terms(_sourcetable text, _infoonly boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_ms_terms(_sourcetable text, _infoonly boolean) IS 'AddNewMSTerms';

