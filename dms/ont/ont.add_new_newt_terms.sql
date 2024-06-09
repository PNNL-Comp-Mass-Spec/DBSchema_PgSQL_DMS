--
-- Name: add_new_newt_terms(text, boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_newt_terms(_sourcetable text DEFAULT 'T_Tmp_NEWT'::text, _infoonly boolean DEFAULT true, _previewdeleteextras boolean DEFAULT true) RETURNS TABLE(item_type public.citext, entry_id integer, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, rank public.citext, parent_term_id public.citext, parent_term_name public.citext, grandparent_term_id public.citext, grandparent_term_name public.citext, common_name public.citext, synonym public.citext, mnemonic public.citext, entered timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds/updates NEWT terms in ont.t_cv_newt
**
**      The source table for t_cv_newt must have these columns:
**        term_pk
**        term_name
**        identifier             (integer)
**        is_leaf
**        rank
**        parent_term_name
**        parent_term_id         (integer)
**        grandparent_term_name
**        grandparent_term_id    (integer)
**        common_name
**        synonym
**        mnemonic
**
**  Arguments:
**    _sourceTable          Source table name; if an empty string, only update the Children column in ont.t_cv_newt
**    _infoOnly             When true, preview updates (ignored if _sourceTable is an empty string)
**    _previewDeleteExtras  When true, preview the rows that would be deleted from t_cv_newt (ignored if _infoOnly is true)
**
**  Example usage:
**        SELECT * FROM add_new_newt_terms(_infoOnly => true);
**        SELECT * FROM add_new_newt_terms(_infoOnly => false, _previewDeleteExtras => true);
**        SELECT * FROM add_new_newt_terms(_infoOnly => false, _previewDeleteExtras => false);
**
**        -- Update the Children column in ont.t_cv_newt
**        SELECT * FROM add_new_newt_terms('');
**
**  Downloading and processing UniProt taxonomy terms
**  - Use FileZilla (or WinSCP) to connect to ftp.uniprot.org
**  - Navigate to /pub/databases/uniprot/current_release/rdf
**  - Download file `taxonomy.rdf.xz`
**  - Use 7-Zip to extract the .rdf file
**  - Process the `.rdf` file using the RDF Taxonomy Converter
**    - https://github.com/PNNL-Comp-Mass-Spec/RDF-Taxonomy-Converter
**    - RDF_Taxonomy_Converter.exe taxonomy.rdf /O:taxonomy_info_pg.txt /Postgres
**  - Upload file taxonomy_info_pg.txt to the Linux server, storing at /tmp/
**  - Create the table to import the data into, use the COPY command to populate ont.t_tmp_newt, then query this function as shown above
**
**    CREATE TABLE ont.t_tmp_newt (
**        term_pk text,
**        term_name text,
**        identifier int,
**        is_leaf int,
**        rank text,
**        parent_term_name text NULL,
**        parent_term_id int NULL,
**        grandparent_term_name text NULL,
**        grandparent_term_id int NULL,
**        common_name text NULL,
**        synonym text NULL,
**        mnemonic text NULL
**    );
**
**    COPY ont.t_tmp_newt FROM '/tmp/taxonomy_info_pg.txt' WITH (FORMAT TEXT, HEADER, DELIMITER E'\t');
**
**  Auth:   mem
**  Date:   06/07/2024 mem - Initial Version (based on add_new_envo_terms)
**          06/08/2024 mem - Add missing updates for columns common_name, synonym, and mnemonic
**                         - Populate column children in ont.t_cv_newt
**
*****************************************************/
DECLARE
    _importData boolean;
    _sourceSchema citext := '';
    _message text;
    _s text := '';

    _matchCount int;
    _updateCount int;
    _insertCount int;
    _deleteCount int;
    _invalidTerm record;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceTable         := Trim(Coalesce(_sourceTable, ''));
    _infoOnly            := Coalesce(_infoOnly, true);
    _previewDeleteExtras := Coalesce(_previewDeleteExtras, true);

    If _sourceTable = '' Then
        _importData := false;
        _infoOnly := false;
    Else
        _importData := true;
    End If;

    If _importData Then
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
                   '0'::citext AS identifier,
                   '0'::citext AS is_leaf,
                   ''::citext AS rank,
                   ''::citext AS parent_term_id,
                   ''::citext AS parent_term_name,
                   ''::citext AS grandparent_term_id,
                   ''::citext AS grandparent_term_name,
                   ''::citext AS common_name,
                   ''::citext AS synonym,
                   ''::citext AS mnemonic,
                   CURRENT_TIMESTAMP::timestamp AS entered
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

        RAISE INFO '';
        RAISE INFO 'Importing from %.%', _sourceSchema, _sourceTable;

        ---------------------------------------------------
        -- Populate a temporary table with the source data
        -- We do this so we can keep track of which rows match existing entries
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_SourceData (
            entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            term_pk citext,
            term_name citext,
            identifier int,
            is_leaf int,
            rank citext,
            parent_term_name citext NULL,
            parent_term_id int NULL,
            grandparent_term_name citext NULL,
            grandparent_term_id int NULL,
            common_name citext NULL,
            synonym citext NULL,
            mnemonic citext NULL,
            matches_existing boolean
        );

        _s := ' INSERT INTO Tmp_SourceData ('
              '     term_pk, term_name, identifier, is_leaf, rank,'
              '     parent_term_name, parent_term_id,'
              '     grandparent_term_name, grandparent_term_id,'
              '     common_name, synonym, mnemonic,'
              '     matches_existing)'
              ' SELECT'
              '   term_pk, term_name, identifier, is_leaf, rank,'
              '   parent_term_name, parent_term_id,'
              '   grandparent_term_name, grandparent_term_id,'
              '   common_name, synonym, mnemonic,'
              '   false AS matches_existing'
              ' FROM %I.%I'
              ' WHERE parent_term_name <> '''' AND term_pk SIMILAR TO ''%%NEWT1''';

        RAISE INFO 'SQL to populate Tmp_SourceData:';
        RAISE INFO '%', format(_s, _sourceSchema, _sourceTable);

        EXECUTE format(_s, _sourceSchema, _sourceTable);

        ---------------------------------------------------
        -- Replace empty Grandparent term IDs and names with NULL
        ---------------------------------------------------

        UPDATE Tmp_SourceData t
        SET grandparent_term_id = NULL,
            grandparent_term_name = NULL
        WHERE Coalesce(t.grandparent_term_id, 0) = 0 AND
              Coalesce(t.grandparent_term_name, '') = '' AND
              (NOT t.grandparent_term_id IS NULL OR NOT t.grandparent_term_name IS NULL);

        ---------------------------------------------------
        -- Change empty strings to nulls in columns common_name, synonym, and mnemonic
        -- Change nulls to empty strings in the rank column
        ---------------------------------------------------

        UPDATE Tmp_SourceData t
        SET common_name = CASE WHEN t.common_name = '' THEN NULL ELSE t.common_name END,
            synonym     = CASE WHEN t.synonym = ''     THEN NULL ELSE t.synonym END,
            mnemonic    = CASE WHEN t.mnemonic = ''    THEN NULL ELSE t.mnemonic END,
            rank        = COALESCE(t.rank, '');

        ---------------------------------------------------
        -- Set matches_existing to true for rows that match an existing row in ont.t_cv_newt
        ---------------------------------------------------

        UPDATE Tmp_SourceData t
        SET matches_existing = true
        FROM ont.t_cv_newt CVN
        WHERE CVN.term_pk = t.term_pk AND
              CVN.parent_term_id = t.parent_term_id AND
              NOT CVN.grandparent_term_id IS DISTINCT FROM t.grandparent_term_id;

        SELECT COUNT(s.identifier)
        INTO _matchCount
        FROM Tmp_SourceData s
        WHERE s.matches_existing;

        RAISE INFO '% rows in % match rows in ont.t_cv_newt', _matchCount, _sourceTable;
    End If;

    If _importData And Not _infoOnly Then
        ---------------------------------------------------
        -- Update existing rows
        ---------------------------------------------------

        UPDATE ont.t_cv_newt t
        SET term_name = s.term_name,
            identifier = s.identifier,
            is_leaf = s.is_leaf,
            rank = s.rank,
            parent_term_name = s.parent_term_name,
            grandparent_term_id = s.grandparent_term_id,
            grandparent_term_name = s.grandparent_term_name,
            common_name = s.common_name,
            synonym = s.synonym,
            mnemonic = s.mnemonic,
            updated = CURRENT_TIMESTAMP
        FROM (SELECT d.term_pk, d.term_name, d.identifier, d.is_leaf, d.rank,
                     d.parent_term_name, d.parent_term_id,
                     d.grandparent_term_name, d.grandparent_term_id,
                     d.common_name, d.synonym, d.mnemonic
               FROM Tmp_SourceData d
               WHERE d.matches_existing) AS s
        WHERE t.term_pk = s.term_pk AND
              t.parent_term_id = s.parent_term_id AND
              NOT t.grandparent_term_id IS DISTINCT FROM s.grandparent_term_id AND
              (t.term_name  <> s.term_name OR
               t.identifier <> s.identifier OR
               t.is_leaf    <> s.is_leaf OR
               t.rank                  IS DISTINCT FROM s.rank OR
               t.parent_term_name      IS DISTINCT FROM s.parent_term_name OR
               t.grandparent_term_name IS DISTINCT FROM s.grandparent_term_name OR
               t.common_name           IS DISTINCT FROM s.common_name OR
               t.synonym               IS DISTINCT FROM s.synonym OR
               t.mnemonic              IS DISTINCT FROM s.mnemonic
              );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Updated % rows in ont.t_cv_newt using %', _updateCount, _sourceTable;

        ---------------------------------------------------
        -- Add new rows
        ---------------------------------------------------

        INSERT INTO ont.t_cv_newt (
            term_pk, term_name, identifier, is_leaf, rank,
            parent_term_name, parent_term_id,
            grandparent_term_name, grandparent_term_id,
            common_name, synonym, mnemonic
        )
        SELECT s.term_pk, s.term_name, s.identifier, s.is_leaf, s.rank,
               s.parent_term_name, s.parent_term_id,
               s.grandparent_term_name, s.grandparent_term_id,
               s.common_name, s.synonym, s.mnemonic
        FROM Tmp_SourceData s
        WHERE NOT s.matches_existing
        ORDER BY s.identifier;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        RAISE INFO 'Added % new rows to ont.t_cv_newt using %', _insertCount, _sourceTable;

        ---------------------------------------------------
        -- Look for identifiers with invalid term names
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_InvalidTermNames (
            entry_id   int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            identifier int NOT NULL,
            term_name  citext NOT NULL
        );

        CREATE TEMP TABLE Tmp_IDsToDelete (
            entry_id int NOT NULL
        );

        CREATE INDEX IX_Tmp_IDsToDelete ON Tmp_IDsToDelete (entry_id);

        RAISE INFO 'Populate table Tmp_InvalidTermNames';

        INSERT INTO Tmp_InvalidTermNames (identifier, term_name)
        SELECT UniqueQTarget.identifier,
               UniqueQTarget.term_name AS Invalid_Term_Name_to_Delete
        FROM (SELECT DISTINCT t.identifier, t.term_name
              FROM ont.t_cv_newt t
              GROUP BY t.identifier, t.term_name
             ) UniqueQTarget
             LEFT OUTER JOIN
                 (SELECT DISTINCT Tmp_SourceData.identifier, Tmp_SourceData.term_name
                  FROM Tmp_SourceData
                 ) UniqueQSource
               ON UniqueQTarget.identifier = UniqueQSource.identifier AND
                  UniqueQTarget.term_name  = UniqueQSource.term_name
        WHERE UniqueQTarget.identifier IN (SELECT LookupQ.identifier
                                           FROM (SELECT DISTINCT cvnewt.identifier, cvnewt.term_name
                                                 FROM ont.t_cv_newt cvnewt
                                                 GROUP BY cvnewt.identifier, cvnewt.term_name) LookupQ
                                           GROUP BY LookupQ.identifier
                                           HAVING (COUNT(*) > 1)) AND
              UniqueQSource.identifier IS NULL;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If FOUND Then
            RAISE INFO 'Added % rows to Tmp_InvalidTermNames', _insertCount;
        Else
            RAISE INFO 'No invalid term names were found';
        End If;

        If Exists (SELECT t.entry_id FROM Tmp_InvalidTermNames t) Then

            RETURN QUERY
            SELECT 'Extra term name to delete'::citext AS item_type,
                   t.entry_id,
                   ''::citext AS term_pk,
                   t.term_name,
                   t.identifier::citext,
                   '0'::citext AS is_leaf,
                   ''::citext AS rank,
                   ''::citext AS parent_term_id,
                   ''::citext AS parent_term_name,
                   ''::citext AS grandparent_term_id,
                   ''::citext AS grandparent_term_name,
                   ''::citext AS common_name,
                   ''::citext AS synonym,
                   ''::citext AS mnemonic,
                   CURRENT_TIMESTAMP::timestamp AS entered
            FROM Tmp_InvalidTermNames t;

            INSERT INTO Tmp_IDsToDelete (entry_id)
            SELECT target.entry_id
            FROM ont.t_cv_newt target
                 INNER JOIN Tmp_InvalidTermNames source
                   ON target.identifier = source.identifier AND
                      target.term_name = source.term_name;

            If _previewDeleteExtras Then
                RETURN QUERY
                SELECT 'To be deleted'::citext AS item_type,
                       t.entry_id,
                       t.term_pk,
                       t.term_name,
                       t.identifier::citext,
                       t.is_leaf::citext,
                       t.rank,
                       t.parent_term_id::citext,
                       t.parent_term_name,
                       t.grandparent_term_id::citext,
                       t.grandparent_term_name,
                       t.common_name,
                       t.synonym,
                       t.mnemonic,
                       t.entered::timestamp
                FROM ont.t_cv_newt t
                WHERE t.entry_id IN (SELECT s.entry_id
                                     FROM Tmp_IDsToDelete s);

            Else

                FOR _invalidTerm In
                    SELECT t.identifier, t.term_name
                    FROM Tmp_InvalidTermNames t
                LOOP

                    If Exists (SELECT t.identifier
                               FROM ont.t_cv_newt t
                               WHERE t.identifier = _invalidTerm.identifier AND
                                     NOT t.entry_id IN (SELECT d.entry_id FROM Tmp_IDsToDelete d))
                    Then
                        -- Safe to delete
                        DELETE FROM ont.t_cv_newt t
                        WHERE t.identifier = _invalidTerm.Identifier AND
                              t.term_name = _invalidTerm.term_name;
                        --
                        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                        RAISE INFO 'Deleted % row(s) for ID % and term %', _deleteCount, _invalidTerm.identifier, _invalidTerm.term_name;
                    Else
                        -- Not safe to delete
                        RETURN QUERY
                        SELECT 'Warning'::citext AS item_type,
                               0 AS Entry_ID,
                               'Not deleting since since no entries would remain for this ID' AS term_pk,
                               _invalidTerm.term_name,
                               _invalidTerm.identifier::citext,
                               '0'::citext AS is_leaf,
                               ''::citext AS rank,
                               ''::citext AS parent_term_id,
                               ''::citext AS parent_term_name,
                               ''::citext AS grandparent_term_id,
                               ''::citext AS grandparent_term_name,
                               ''::citext AS common_name,
                               ''::citext AS synonym,
                               ''::citext AS mnemonic,
                               CURRENT_TIMESTAMP::timestamp AS entered;
                    End If;

                END LOOP;
            End If;
        End If;

        DROP TABLE Tmp_InvalidTermNames;
        DROP TABLE Tmp_IDsToDelete;

    ElsIf _importData And _infoOnly Then

        ---------------------------------------------------
        -- Preview existing rows that would be updated
        ---------------------------------------------------

        RETURN QUERY
        SELECT 'Existing item to update'::citext AS item_type,
               t.entry_id,
               t.term_pk,
               (CASE WHEN t.term_name  = s.term_name  THEN t.term_name             ELSE format('%s --> %s', t.term_name,  s.term_name)  END)::citext AS term_name,
               (CASE WHEN t.identifier = s.identifier THEN t.identifier::citext    ELSE format('%s --> %s', t.identifier, s.identifier) END)::citext AS identifier,
               (CASE WHEN t.is_leaf = s.is_leaf       THEN format('%s', t.is_leaf) ELSE format('%s --> %s', t.is_leaf, s.is_leaf)       END)::citext AS is_leaf,
               (CASE WHEN t.rank = s.rank             THEN t.rank                  ELSE format('%s --> %s', Coalesce(t.rank, 'NULL'), Coalesce(s.rank, 'NULL')) END)::citext AS rank,
               t.parent_term_id::citext,
               (CASE WHEN t.parent_term_name = s.parent_term_name THEN t.parent_term_name                ELSE format('%s --> %s', t.parent_term_name, s.parent_term_name) END)::citext AS parent_term_name,
               t.grandparent_term_id::citext,
               (CASE WHEN t.grandparent_term_name = s.grandparent_term_name THEN t.grandparent_term_name ELSE format('%s --> %s', Coalesce(t.grandparent_term_name, 'NULL'), Coalesce(s.grandparent_term_name, 'NULL')) END)::citext AS grandparent_term_name,
               (CASE WHEN t.common_name = s.common_name                     THEN t.common_name           ELSE format('%s --> %s', Coalesce(t.common_name, 'NULL'),           Coalesce(s.common_name, 'NULL'))           END)::citext AS common_name,
               (CASE WHEN t.synonym = s.synonym                             THEN t.synonym               ELSE format('%s --> %s', Coalesce(t.synonym, 'NULL'),               Coalesce(s.synonym, 'NULL'))               END)::citext AS synonym,
               (CASE WHEN t.mnemonic = s.mnemonic                           THEN t.mnemonic              ELSE format('%s --> %s', Coalesce(t.mnemonic, 'NULL'),              Coalesce(s.mnemonic, 'NULL'))              END)::citext AS mnemonic,
               t.entered::timestamp
        FROM ont.t_cv_newt AS t
            INNER JOIN Tmp_SourceData AS s
              ON t.term_pk = s.term_pk AND
                 t.parent_term_id = s.parent_term_id AND
                 NOT t.grandparent_term_id IS DISTINCT FROM s.grandparent_term_id
        WHERE s.matches_existing AND
              (t.term_name  <> s.term_name OR
               t.identifier <> s.identifier OR
               t.is_leaf    <> s.is_leaf OR
               t.rank                  IS DISTINCT FROM s.rank OR
               t.parent_term_name      IS DISTINCT FROM s.parent_term_name OR
               t.grandparent_term_name IS DISTINCT FROM s.grandparent_term_name OR
               t.common_name           IS DISTINCT FROM s.common_name OR
               t.synonym               IS DISTINCT FROM s.synonym OR
               t.mnemonic              IS DISTINCT FROM s.mnemonic
              )
        UNION
        SELECT 'New item to add'::citext AS item_type,
               0 AS entry_id,
               s.term_pk,
               s.term_name,
               s.identifier::citext,
               s.is_leaf::citext,
               s.rank,
               s.parent_term_id::citext,
               s.parent_term_name,
               s.grandparent_term_id::citext,
               s.grandparent_term_name,
               s.common_name,
               s.synonym,
               s.mnemonic,
               CURRENT_TIMESTAMP::timestamp AS entered
        FROM Tmp_SourceData s
        WHERE NOT matches_existing;

    End If;

    If _importData Then
        DROP TABLE Tmp_SourceData;
    End If;

    If Not _infoOnly Then
        RAISE INFO 'Updating Children counts in ont.t_cv_newt';

        UPDATE ont.t_cv_newt Target
        SET children = SourceQ.Children
        FROM (SELECT CVN.parent_term_id, COUNT(*) AS Children
              FROM ont.t_cv_newt CVN
              GROUP BY CVN.parent_term_id
             ) SourceQ
        WHERE Target.identifier = SourceQ.parent_term_id AND
              Target.children <> SourceQ.Children;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Updated Children count for % % in ont.t_cv_newt',
                   _updateCount,
                   public.check_plural(_updateCount, 'row', 'rows');

        -- Change Children to 0 for any entries that no longer have children
        UPDATE ont.t_cv_newt Target
        SET Children = 0
        WHERE Target.Children > 0 AND
              NOT EXISTS (SELECT CVN.parent_term_id
                          FROM ont.t_cv_newt CVN
                          WHERE Target.identifier = CVN.parent_term_id);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Set Children to 0 for % % in ont.t_cv_newt',
                   _updateCount,
                   public.check_plural(_updateCount, 'row', 'rows');
    End If;

END
$$;


ALTER FUNCTION ont.add_new_newt_terms(_sourcetable text, _infoonly boolean, _previewdeleteextras boolean) OWNER TO d3l243;

