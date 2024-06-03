--
-- Name: add_new_bto_terms(text, boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_bto_terms(_sourcetable text DEFAULT 'T_Tmp_BTO'::text, _infoonly boolean DEFAULT true, _previewdeleteextras boolean DEFAULT true) RETURNS TABLE(item_type public.citext, entry_id integer, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, synonyms public.citext, parent_term_id public.citext, parent_term_name public.citext, grandparent_term_id public.citext, grandparent_term_name public.citext, entered timestamp without time zone, updated timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new BTO terms to t_cv_bto
**
**      The source table must have columns:
**        term_pk
**        term_name
**        identifier
**        is_leaf
**        synonyms
**        parent_term_name
**        parent_term_id
**        grandparent_term_name
**        grandparent_term_id
**
**  Arguments:
**    _previewDeleteExtras   Set to true to preview deleting extra terms; false to actually delete them
**
**  Auth:   mem
**  Date:   08/24/2017 mem - Initial Version
**          04/01/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly and _previewDeleteExtras from integer to boolean
**          05/12/2023 mem - Rename variables
**          05/22/2023 mem - Capitalize reserved words
**          05/28/2023 mem - Simplify string concatenation
**          05/29/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(s.entry_id) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/21/2024 mem - Change data type of argument _sourceTable to text
**
*****************************************************/
DECLARE
    _sourceSchema citext := '';
    _updateCount int;
    _deleteCount int;
    _s text := '';
    _invalidTerm record;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceTable         := Trim(Coalesce(_sourceTable, ''));
    _infoOnly            := Coalesce(_infoOnly, true);
    _previewDeleteExtras := Coalesce(_previewDeleteExtras, true);

    CREATE TEMP TABLE Tmp_CandidateTables AS
    SELECT Table_to_Find, Schema_Name, Table_Name, Table_Exists, Message
    FROM resolve_table_name(_sourceTable);

    If Not Exists (SELECT Table_to_Find FROM Tmp_CandidateTables WHERE Table_Exists) Then
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
               ''::citext AS synonyms,
               ''::citext AS parent_term_id,
               ''::citext AS parent_term_name,
               ''::citext AS grandparent_term_id,
               ''::citext AS grandparent_term_name,
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
        synonyms citext,
        parent_term_name citext NULL,
        parent_term_id citext NULL,
        grandparent_term_name citext NULL,
        grandparent_term_id citext NULL,
        matches_existing int,
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    _s := ' INSERT INTO Tmp_SourceData'
          ' SELECT term_pk, term_name, identifier, is_leaf, synonyms,'
          '   parent_term_name, parent_term_id,'
          '   grandparent_term_name, grandparent_term_id, 0 AS matches_existing'
          ' FROM %I.%I'
          ' WHERE parent_term_name <> '''' ';

    EXECUTE format(_s, _sourceSchema, _sourceTable);

    ---------------------------------------------------
    -- Replace empty Grandparent term IDs and names with NULL
    ---------------------------------------------------

    UPDATE Tmp_SourceData t
    SET grandparent_term_id = NULL,
        grandparent_term_name = NULL
    WHERE Coalesce(t.grandparent_term_id, '') = '' AND
          Coalesce(t.grandparent_term_name, '') = '' AND
          (t.grandparent_term_id = '' OR t.grandparent_term_name = '');

    ---------------------------------------------------
    -- Set matches_existing to 1 for rows that match an existing row in ont.t_cv_bto
    ---------------------------------------------------

    UPDATE Tmp_SourceData t
    SET matches_existing = 1
    FROM ont.t_cv_bto s
    WHERE s.Term_PK = t.Term_PK AND
          s.Parent_term_ID = t.Parent_term_ID AND
          Coalesce(s.grandparent_term_id, '') = Coalesce(t.grandparent_term_id, '');


    If Not _infoOnly Then

        ---------------------------------------------------
        -- Update existing rows
        ---------------------------------------------------

        UPDATE ont.t_cv_bto t
        SET term_name = s.term_name,
            identifier = s.identifier,
            is_leaf = s.is_leaf,
            synonyms = s.synonyms,
            parent_term_name = s.parent_term_name,
            grandparent_term_id = s.grandparent_term_id,
            grandparent_term_name = s.grandparent_term_name,
            updated = CURRENT_TIMESTAMP
        FROM (SELECT d.term_pk, d.term_name, d.identifier, d.is_leaf, d.synonyms,
                     d.parent_term_name, d.parent_term_id,
                     d.grandparent_term_name, d.grandparent_term_id
               FROM Tmp_SourceData d
               WHERE d.matches_existing = 1) AS s
        WHERE t.term_pk = s.term_pk AND
              t.parent_term_id = s.parent_term_id AND
              Coalesce(t.grandparent_term_id, '') = Coalesce(s.grandparent_term_id, '') AND
              ( t.term_name <> s.term_name OR
                t.identifier <> s.identifier OR
                t.is_leaf <> s.is_leaf OR
                t.synonyms <> s.synonyms OR
                t.parent_term_name <> s.parent_term_name OR
                t.grandparent_term_name IS DISTINCT FROM s.grandparent_term_name
              );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Updated % rows in ont.t_cv_bto using %', _updateCount, _sourceTable;

        ---------------------------------------------------
        -- Add new rows
        ---------------------------------------------------

        INSERT INTO ont.t_cv_bto (term_pk, term_name, identifier, is_leaf, synonyms,
                                  parent_term_name, parent_term_id,
                                  grandparent_term_name, grandparent_term_id)
        SELECT s.term_pk, s.term_name, s.identifier, s.is_leaf, s.synonyms,
               s.parent_term_name, s.parent_term_id,
               s.grandparent_term_name, s.grandparent_term_id
        FROM Tmp_SourceData s
        WHERE s.matches_existing = 0;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Added % new rows to ont.t_cv_bto using %', _updateCount, _sourceTable;

        ---------------------------------------------------
        -- Look for identifiers with invalid term names
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_InvalidTermNames (
            entry_id   int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            identifier citext NOT NULL,
            term_name  citext NOT NULL
        );

        CREATE TEMP TABLE Tmp_IDsToDelete (
            entry_id int NOT NULL
        );

        CREATE INDEX IX_Tmp_IDsToDelete ON Tmp_IDsToDelete (entry_id);

        INSERT INTO Tmp_InvalidTermNames (identifier, term_name)
        SELECT UniqueQTarget.identifier,
               UniqueQTarget.term_name AS Invalid_Term_Name_to_Delete
        FROM (SELECT DISTINCT t.identifier, t.term_name
              FROM ont.t_cv_bto t
              GROUP BY t.identifier, t.term_name
             ) UniqueQTarget
             LEFT OUTER JOIN
                 (SELECT DISTINCT Tmp_SourceData.identifier, Tmp_SourceData.term_name
                  FROM Tmp_SourceData
                 ) UniqueQSource
               ON UniqueQTarget.identifier = UniqueQSource.identifier AND
                  UniqueQTarget.term_name = UniqueQSource.term_name
        WHERE UniqueQTarget.identifier IN (SELECT LookupQ.identifier
                                           FROM (SELECT DISTINCT cvbto.identifier, cvbto.term_name
                                                 FROM ont.t_cv_bto cvbto
                                                 GROUP BY cvbto.identifier, cvbto.term_name) LookupQ
                                           GROUP BY LookupQ.identifier
                                           HAVING (COUNT(*) > 1)) AND
              UniqueQSource.identifier IS NULL;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If FOUND Then
            RAISE INFO 'Added % rows to Tmp_InvalidTermNames', _updateCount;
        Else
            RAISE INFO 'No invalid term names were found';
        End If;

        If Exists (SELECT entry_id FROM Tmp_InvalidTermNames) Then

            RETURN QUERY
            SELECT 'Extra term name to delete'::citext AS Item_Type,
                   s.entry_id,
                   ''::citext AS term_pk,
                   s.term_name,
                   s.identifier,
                   '0'::citext AS is_leaf,
                   ''::citext AS synonyms,
                   ''::citext AS parent_term_id,
                   ''::citext AS parent_term_name,
                   ''::citext AS grandparent_term_id,
                   ''::citext AS grandparent_term_name,
                   current_timestamp::timestamp AS entered,
                   NULL::timestamp AS updated
            FROM Tmp_InvalidTermNames s;

            INSERT INTO Tmp_IDsToDelete (entry_id)
            SELECT target.entry_id
            FROM ont.t_cv_bto target
                 INNER JOIN Tmp_InvalidTermNames source
                   ON target.identifier = source.identifier AND
                      target.term_name = source.term_name;

            If _previewDeleteExtras Then
                RETURN QUERY
                SELECT 'To be deleted'::citext AS Item_Type,
                       t.entry_id,
                       t.term_pk,
                       t.term_name,
                       t.identifier,
                       t.is_leaf::citext,
                       t.synonyms,
                       t.parent_term_id,
                       t.parent_term_name,
                       t.grandparent_term_id,
                       t.grandparent_term_name,
                       t.entered::timestamp,
                       t.updated::timestamp
                FROM ont.t_cv_bto t
                WHERE t.entry_id IN (SELECT s.entry_id
                                     FROM Tmp_IDsToDelete s);

            Else

                FOR _invalidTerm In
                    SELECT s.identifier, s.term_name
                    FROM Tmp_InvalidTermNames s
                LOOP

                    If Exists (Select *
                               FROM ont.t_cv_bto t
                               WHERE t.identifier = _invalidTerm.identifier AND
                                     Not t.entry_id IN (Select d.entry_id FROM Tmp_IDsToDelete d)) Then
                        -- Safe to delete
                        DELETE FROM ont.t_cv_bto t
                        WHERE t.identifier = _invalidTerm.Identifier AND
                              t.term_name = _invalidTerm.term_name;
                        --
                        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                        RAISE INFO 'Deleted % row(s) for ID % and term %', _deleteCount, _invalidTerm.identifier, _invalidTerm.term_name;
                    Else
                        -- Not safe to delete
                        RETURN QUERY
                        SELECT 'Warning'::citext AS Item_Type,
                               0 AS Entry_ID,
                               'Not deleting since since no entries would remain for this ID' AS term_pk,
                               _invalidTerm.term_name,
                               _invalidTerm.identifier,
                               '0'::citext AS is_leaf,
                               ''::citext AS synonyms,
                               ''::citext AS parent_term_id,
                               ''::citext AS parent_term_name,
                               ''::citext AS grandparent_term_id,
                               ''::citext AS grandparent_term_name,
                               current_timestamp::timestamp AS entered,
                               null::timestamp AS updated;

                    End If;

                END LOOP;
            End If;
        End If;

        DROP TABLE Tmp_InvalidTermNames;
        DROP TABLE Tmp_IDsToDelete;

        ---------------------------------------------------
        -- Update the Children counts
        ---------------------------------------------------

        UPDATE ont.t_cv_bto t
        SET children = StatsQ.children
        FROM (SELECT s.parent_term_id, COUNT(s.entry_id) AS children
              FROM ont.t_cv_bto s
              GROUP BY s.parent_term_ID) StatsQ
        WHERE StatsQ.parent_term_id = t.identifier AND
              Coalesce(t.Children, 0) <> StatsQ.Children;

        -- Change counts to null if no children

        UPDATE ont.t_cv_bto t
        SET children = NULL
        WHERE NOT t.identifier IN (
                SELECT s.parent_term_id
                FROM ont.t_cv_bto s
                GROUP BY s.parent_term_ID) AND
              NOT t.Children IS NULL;

    Else

        ---------------------------------------------------
        -- Preview existing rows that would be updated
        ---------------------------------------------------

        RETURN QUERY
        SELECT 'Existing item to update'::citext AS Item_Type,
               t.entry_id,
               t.term_pk,
               (CASE WHEN t.term_name  = s.term_name  THEN t.term_name       ELSE format('%s --> %s', t.term_name,  s.term_name)  END)::citext AS term_name,
               (CASE WHEN t.identifier = s.identifier THEN t.identifier      ELSE format('%s --> %s', t.identifier, s.identifier) END)::citext AS identifier,
               (CASE WHEN t.is_leaf = s.is_leaf THEN format('%s', t.is_leaf) ELSE format('%s --> %s', t.is_leaf, s.is_leaf)       END)::citext AS is_leaf,
               (CASE WHEN t.synonyms = s.synonyms THEN t.synonyms            ELSE format('%s --> %s', t.synonyms, s.synonyms)     END)::citext AS synonyms,
               t.parent_term_id::citext,
               (CASE WHEN t.parent_term_name = s.parent_term_name THEN t.parent_term_name                ELSE format('%s --> %s', t.parent_term_name, s.parent_term_name) END)::citext AS parent_term_name,
               t.grandparent_term_id::citext,
               (CASE WHEN t.grandparent_term_name = s.grandparent_term_name THEN t.grandparent_term_name ELSE format('%s --> %s', Coalesce(t.grandparent_term_name, 'NULL'), Coalesce(s.grandparent_term_name, 'NULL')) END)::citext AS grandparent_term_name,
               t.entered::timestamp,
               t.updated::timestamp
        FROM ont.t_cv_bto AS t
            INNER JOIN Tmp_SourceData AS s
              ON t.term_pk = s.term_pk AND
                 t.parent_term_id = s.parent_term_id AND
                 Coalesce(t.grandparent_term_id, '') = Coalesce(s.grandparent_term_id, '')
        WHERE s.matches_existing = 1 AND
              ( t.term_name <> s.term_name OR
                t.identifier <> s.identifier OR
                t.is_leaf <> s.is_leaf OR
                t.synonyms <> s.synonyms OR
                t.parent_term_name <> s.parent_term_name OR
                t.grandparent_term_name IS DISTINCT FROM s.grandparent_term_name
               )
        UNION
        SELECT 'New item to add'::citext AS Item_Type,
               0 AS entry_id,
               s.term_pk,
               s.term_name,
               s.identifier,
               s.is_leaf::citext,
               s.synonyms,
               s.parent_term_id,
               s.parent_term_name,
               s.grandparent_term_id,
               s.grandparent_term_name,
               current_timestamp::timestamp AS entered,
               NULL::timestamp AS updated
        FROM Tmp_SourceData s
        WHERE matches_existing = 0;

    End If;

    DROP TABLE Tmp_SourceData;
END
$$;


ALTER FUNCTION ont.add_new_bto_terms(_sourcetable text, _infoonly boolean, _previewdeleteextras boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_bto_terms(_sourcetable text, _infoonly boolean, _previewdeleteextras boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_bto_terms(_sourcetable text, _infoonly boolean, _previewdeleteextras boolean) IS 'AddNewBTOTerms';

