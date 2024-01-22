--
-- Name: backfill_terms(text, text, boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.backfill_terms(_sourcetable text DEFAULT 't_cv_bto'::text, _namespace text DEFAULT 'BrendaTissueOBO'::text, _infoonly boolean DEFAULT true, _previewrelationshipupdates boolean DEFAULT true) RETURNS TABLE(item_type public.citext, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, updated timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new entries to tables ont.t_term and ont.t_term_relationship using the specified T_CV table
**
**      This is required after adding new information to a t_cv table,
**      e.g., after adding new BTO terms to ont.t_cv_bto using a .owl file
**
**      The Ontology Detail Report uses view ont.v_ontology_detail_report
**      and that view uses views ont.v_term and ont.v_term_lineage
**
**      View ont.v_term uses tables ont.t_ontology and ont.t_term
**      View ont.v_term_lineage uses tables ont.t_ontology, ont.t_term, and ont.t_term_relationship
**
**  Arguments:
**    _previewRelationshipUpdates   Set to true to preview adding/removing relationships; 0 to actually update relationships
**
**  Usage:
**      SELECT * FROM ont.backfill_terms  (
**          _sourceTable                => 'ont.t_cv_bto',
**          _namespace                  => 'BrendaTissueOBO',
**          _infoOnly                   => false,
**          _previewRelationshipUpdates => true);
**
**  Auth:   mem
**  Date:   08/24/2017 mem - Initial Version
**          03/28/2022 mem - Use new table names
**          04/05/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly and _previewRelationshipUpdates from integer to boolean
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Remove redundant parentheses
**          05/29/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(term_pk) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/21/2024 mem - Change data type of function arguments to text
**
*****************************************************/
DECLARE
    _sourceSchema citext;
    _sourceTableWithSchema citext;
    _updateCount int;
    _insertCount int;
    _deleteCount int;
    _s text := '';
    _ontologyID int := 0;
    _autoNumberStartID int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceTable                := Trim(Coalesce(_sourceTable, ''));
    _infoOnly                   := Coalesce(_infoOnly, true);
    _previewRelationshipUpdates := Coalesce(_previewRelationshipUpdates, true);

    ---------------------------------------------------
    -- Validate that the source table exists
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_CandidateTables AS
    SELECT Table_to_Find, Schema_Name, Table_Name, Table_Exists, Message
    FROM resolve_table_name(_sourceTable);

    If Not Exists (SELECT * FROM Tmp_CandidateTables WHERE Table_Exists) Then
        -- Message will be:
        -- Table not found in any schema: t_tmp_table
        --or
        -- Table not found in the given schema: ont.t_tmp_table

        RETURN QUERY
        SELECT 'Warning'::citext as Item_Type,
               ''::citext As term_pk,
               t.Message As term_name,
               ''::citext As identifier,
               '0'::citext As is_leaf,
               NULL::timestamp As updated
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

    _sourceTableWithSchema := format('%s.%s', _sourceSchema, _sourceTable);

    RAISE INFO 'Back filling ont.t_term and ont.t_term_relationship using %', _sourceTableWithSchema;

    ---------------------------------------------------
    -- Populate a temporary table with the source data
    -- We do this so we can keep track of which rows match existing entries
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_SourceData (
        entry_id int primary key generated always as identity,
        term_pk citext,
        term_name citext,
        identifier citext,
        is_leaf int,
        synonyms citext,                    -- Only used if the source is 'ont.t_cv_bto'
        parent_term_name citext null,
        parent_term_id citext null,
        grandparent_term_name citext null,
        grandparent_term_id citext null,
        matches_existing int
    );

    _s := ' INSERT INTO Tmp_SourceData( term_pk, term_name, identifier, is_leaf,'            ||
          CASE WHEN _sourceTableWithSchema = 'ont.t_cv_bto' THEN ' synonyms,' ELSE '' END    ||
                                      ' parent_term_name, Parent_term_ID,'                   ||
                                      ' grandparent_term_name, grandparent_term_id, matches_existing )' ||
          ' SELECT term_pk, term_name, identifier, is_leaf,'                                 ||
          CASE WHEN _sourceTableWithSchema = 'ont.t_cv_bto' THEN ' synonyms,' ELSE '' END    ||
                 ' parent_term_name, parent_term_id,'                                        ||
                 ' grandparent_term_name, grandparent_term_id, 0 AS matches_existing'        ||
          ' FROM %I.%I'                                                                      ||
          ' WHERE parent_term_name <> '''' ';

    Execute format(_s, _sourceSchema, _sourceTable);

    ---------------------------------------------------
    -- Set matches_existing to 1 for rows that match an existing row in ont.t_term
    ---------------------------------------------------

    UPDATE Tmp_SourceData
    SET matches_existing = 1
    FROM ont.t_term s
    WHERE s.term_pk = Tmp_SourceData.term_pk;

    ---------------------------------------------------
    -- Determine the ontology_id
    ---------------------------------------------------

    SELECT T.ontology_id
    INTO _ontologyID
    FROM Tmp_SourceData S
         INNER JOIN ont.t_term T
           ON S.term_pk = T.term_pk
    GROUP BY T.ontology_id
    ORDER BY COUNT(term_pk) DESC
    LIMIT 1;

    If Not _infoOnly Then

        ---------------------------------------------------
        -- Update existing rows
        ---------------------------------------------------

        UPDATE ont.t_term AS T
        SET term_name = s.term_name,
            identifier = s.identifier,
            is_leaf = s.is_leaf,
            updated = CURRENT_TIMESTAMP
        FROM (SELECT d.term_pk, d.term_name, d.identifier, MAX(d.is_leaf) AS is_leaf
               FROM Tmp_SourceData d
               WHERE d.matches_existing = 1
               GROUP BY d.term_pk, d.term_name, d.identifier ) as s
        WHERE t.term_pk = s.term_pk AND
              (
                t.term_name <> s.term_name OR
                t.identifier <> s.identifier OR
                t.is_leaf <> s.is_leaf
              );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Updated % rows in ont.t_term using %', _updateCount, _sourceTable;

        ---------------------------------------------------
        -- Add new rows
        ---------------------------------------------------

        INSERT INTO ont.t_term (term_pk, ontology_id, term_name, identifier, definition, namespace, is_obsolete, is_root_term, is_leaf)
        SELECT s.term_pk, _ontologyID, s.term_name, s.identifier, '' AS definition, _namespace, 0 AS is_obsolete, 0 AS i_root_term, Max(s.is_leaf)
        FROM Tmp_SourceData s
        WHERE s.matches_existing = 0
        GROUP BY s.term_pk, s.term_name, s.identifier;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        RAISE INFO 'Added % new rows to ont.t_term using %', _insertCount, _sourceTable;

        ---------------------------------------------------
        -- Add/update parent/child relationships
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_RelationshipsToAdd (
            entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            child_pk citext not null,
            parent_pk citext not null
        );

        CREATE TEMP TABLE Tmp_RelationshipsToDelete (
            relationship_id int not null
        );

        -- Find missing relationships

        INSERT INTO Tmp_RelationshipsToAdd (child_pk, parent_pk)
        SELECT DISTINCT SourceTable.term_pk AS child_pk,
                        ont.t_term.term_pk AS parent_pk
        FROM ont.t_cv_bto SourceTable
             INNER JOIN ont.t_term
               ON SourceTable.parent_term_id = ont.t_term.identifier
             LEFT OUTER JOIN ont.t_term_relationship R
               ON SourceTable.term_pk = R.subject_term_pk AND
                  ont.t_term.term_pk = R.object_term_pk
        WHERE ont.t_term.ontology_id = _ontologyID AND
              R.subject_term_pk IS NULL
        ORDER BY SourceTable.term_pk, ont.t_term.term_pk;

        -- Determine the smallest ID in table ont.t_term_relationship

        SELECT MIN(term_relationship_id) - 1
        INTO _autoNumberStartID
        FROM ont.t_term_relationship;

        IF _autoNumberStartID >= 0 Then
            _autoNumberStartID := -1;
        End If;

        If _previewRelationshipUpdates Then
            RETURN QUERY
            SELECT 'New relationship'::citext as Item_Type,
                   R.Child_PK As term_pk,
                   (format('New_Relationship_ID: %s', _autoNumberStartID - R.Entry_ID))::citext As term_name,
                   (format('Parent_PK: %s', R.Parent_PK))::citext As identifier,
                   'Predicate Name: inferred_is_a'::citext As is_leaf,
                   NULL::timestamp As updated
            FROM Tmp_RelationshipsToAdd R
            ORDER BY R.Entry_ID;
        Else
            -- Add missing relationships

            INSERT INTO ont.t_term_relationship( term_relationship_id,
                                           subject_term_pk,
                                           predicate_term_pk,
                                           object_term_pk,
                                           ontology_id )
            SELECT _autoNumberStartID - Entry_ID AS New_Relationship_ID,
                   Child_PK,
                   'inferred_is_a' AS Predicate_Name,
                   Parent_PK,
                   _ontologyID
            FROM Tmp_RelationshipsToAdd
            ORDER BY Entry_ID;
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            RAISE INFO 'Inserted % new parent/child relationships into table ont.t_term_relationship', _insertCount;
        End If;

        -- Find extra relationships

        INSERT INTO Tmp_RelationshipsToDelete( Relationship_ID )
        SELECT ont.t_term_relationship.term_relationship_id
        FROM ( SELECT DISTINCT SourceTable.identifier,
                               SourceTable.term_pk AS Child_PK,
                               SourceTable.parent_term_id,
                               ont.t_term.term_pk AS Parent_PK
               FROM ont.t_cv_bto SourceTable
                    INNER JOIN ont.t_term
                      ON SourceTable.parent_term_ID = ont.t_term.identifier
               WHERE ont.t_term.ontology_id = _ontologyID
             ) ValidRelationships
             RIGHT OUTER JOIN ont.t_term_relationship
               ON ValidRelationships.Child_PK = ont.t_term_relationship.subject_term_pk AND
                  ValidRelationships.Parent_PK = ont.t_term_relationship.object_term_pk
        WHERE ValidRelationships.parent_term_id IS NULL AND
              ont.t_term_relationship.ontology_id = _ontologyID;

        If _previewRelationshipUpdates Then
            RETURN QUERY
            SELECT 'Delete relationship'::citext as Item_Type,
                   R.subject_term_pk As term_pk,
                   (format('Term_Relationship_ID: ', R.term_relationship_id))::citext As term_name,
                   (format('Predicate_Term_PK: ', R.predicate_term_pk))::citext As identifier,
                   (format('Object_Term_PK:', R.object_term_pk))::citext As is_leaf,
                   NULL::timestamp As updated
            FROM ont.t_term_relationship R
            WHERE R.term_relationship_id IN (SELECT Relationship_ID FROM Tmp_RelationshipsToDelete);
        Else
            DELETE FROM ont.t_term_relationship
            WHERE term_relationship_id IN (SELECT Relationship_ID FROM Tmp_RelationshipsToDelete);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            RAISE INFO 'Deleted % parent/child relationships from table ont.t_term_relationship', _deleteCount;
        End If;

        DROP TABLE Tmp_RelationshipsToAdd;
        DROP TABLE Tmp_RelationshipsToDelete;

    Else
        ---------------------------------------------------
        -- Preview existing rows that would be updated
        ---------------------------------------------------

        RETURN QUERY
        SELECT 'Existing item to update'::citext as Item_Type,
               T.term_pk,
               (CASE WHEN T.term_name = S.term_name   THEN T.term_name       ELSE format('%s --> %s', T.term_name, S.term_name)   END)::citext term_name,
               (CASE WHEN T.identifier = S.identifier THEN T.identifier      ELSE format('%s --> %s', T.identifier, S.identifier) END)::citext identifier,
               (CASE WHEN T.is_leaf = S.is_leaf THEN format('%s', T.is_leaf) ELSE format('%s --> %s', T.is_leaf, S.is_leaf)       END)::citext is_leaf,
               T.updated
        FROM ont.t_term AS T
             INNER JOIN ( SELECT d.term_pk,
                                 d.term_name,
                                 d.identifier,
                                 MAX(d.is_leaf) AS is_leaf
                          FROM Tmp_SourceData d
                          WHERE d.matches_existing = 1
                          GROUP BY d.term_pk, d.term_name, d.identifier ) AS S
               ON T.term_pk = S.term_pk
        WHERE T.term_name <> S.term_name OR
              T.identifier <> S.identifier OR
              T.is_leaf <> S.is_leaf
        UNION
        SELECT 'New item to add'::citext as Item_Type,
               S.term_pk,
               S.term_name,
               S.identifier,
               Cast(Max(S.is_leaf) AS citext) as is_leaf,
               NULL::timestamp As updated
        FROM Tmp_SourceData AS S
        WHERE S.matches_existing = 0
        GROUP BY S.term_pk, S.term_name, S.identifier;

        ---------------------------------------------------
        -- Preview parents to add
        ---------------------------------------------------

        /*
        SELECT DISTINCT 'Missing parent/child relationship' as Relationship
                        SourceTable.identifier AS Child,
                        SourceTable.term_pk AS Child_PK,
                        SourceTable.parent_term_id AS Parent,
                        ont.t_term.term_pk AS Parent_PK
        FROM ont.t_cv_bto SourceTable
             INNER JOIN ont.t_term
               ON SourceTable.parent_term_ID = ont.t_term.identifier
             LEFT OUTER JOIN ont.t_term_relationship
               ON SourceTable.term_pk = ont.t_term_relationship.subject_term_pk AND
                  ont.t_term.term_pk = ont.t_term_relationship.object_term_pk
        WHERE ont.t_term.ontology_id = _ontologyID AND
              ont.t_term_relationship.subject_term_pk IS NULL
        ORDER BY SourceTable.identifier
        */
    End If;

    DROP TABLE Tmp_SourceData;
END
$$;


ALTER FUNCTION ont.backfill_terms(_sourcetable text, _namespace text, _infoonly boolean, _previewrelationshipupdates boolean) OWNER TO d3l243;

--
-- Name: FUNCTION backfill_terms(_sourcetable text, _namespace text, _infoonly boolean, _previewrelationshipupdates boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.backfill_terms(_sourcetable text, _namespace text, _infoonly boolean, _previewrelationshipupdates boolean) IS 'BackfillTerms';

