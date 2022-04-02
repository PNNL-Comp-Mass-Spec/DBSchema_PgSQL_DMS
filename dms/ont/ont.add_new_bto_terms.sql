--
-- Name: add_new_bto_terms(public.citext, integer, integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_bto_terms(_sourcetable public.citext DEFAULT 'T_Tmp_BTO'::public.citext, _infoonly integer DEFAULT 1, _previewdeleteextras integer DEFAULT 1) RETURNS TABLE(item_type public.citext, entry_id integer, term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, synonyms public.citext, parent_term_id public.citext, parent_term_name public.citext, grandparent_term_id public.citext, grandparent_term_name public.citext, entered timestamp without time zone, updated timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new BTO terms to T_CV_BTO
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
**    _previewDeleteExtras   Set to 1 to preview deleting extra terms; 0 to actually delete them
**
**  Auth:   mem
**  Date:   08/24/2017 mem - Initial Version
**          04/01/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sourceSchema citext := '';
    _myRowCount int := 0;
    _s text := '';
    _entryID int := 0;
    _invalidTerm record;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceTable := Coalesce(_sourceTable, '');
    _infoOnly := Coalesce(_infoOnly, 1);
    _previewDeleteExtras := Coalesce(_previewDeleteExtras, 1);

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
               0 As entry_id,
               ''::citext As term_pk,
               t.Message As term_name,
               ''::citext As identifier,
               '0'::citext As is_leaf,
               ''::citext As synonyms,
               ''::citext As parent_term_id,
               ''::citext As parent_term_name,
               ''::citext As grandparent_term_id,
               ''::citext As grandparent_term_name,
               current_timestamp::timestamp As entered,
               NULL::timestamp As updated
        FROM Tmp_CandidateTables t;

        DROP TABLE Tmp_CandidateTables;
        Return;
    End If;

    -- Make sure the schema name and table name are properly capitalized
    SELECT Schema_Name, Table_Name
    INTO _sourceSchema, _sourceTable
    FROM Tmp_CandidateTables
    WHERE Table_Exists
    LIMIT 1;

    DROP TABLE Tmp_CandidateTables;

    RAISE info 'Importing from %.%', _sourceSchema, _sourceTable;

    ---------------------------------------------------
    -- Populate a temporary table with the source data
    -- We do this so we can keep track of which rows match existing entries
    ---------------------------------------------------

    CREATE TEMP TABLE IF NOT EXISTS Tmp_SourceData (
        term_pk citext,
        term_name citext,
        identifier citext,
        is_leaf int,
        synonyms citext,
        parent_term_name citext null,
        parent_term_id citext null,
        grandparent_term_name citext null,
        grandparent_term_id citext null,
        matches_existing int,
        entry_id int primary key generated always as identity
    );

    -- Since we used "CREATE TEMP TABLE IF NOT EXISTS" we could TRUNCATE here to assure that it is empty
    -- However, since we end this function with DROP TABLE, the truncation is not required
    -- TRUNCATE TABLE Tmp_Taxonomy;

    _s := '';
    _s := _s || ' INSERT INTO Tmp_SourceData';
    _s := _s || ' SELECT term_pk, term_name, identifier, is_leaf, synonyms,';
    _s := _s || '   parent_term_name, parent_term_id,';
    _s := _s || '   grandparent_term_name, grandparent_term_id, 0 as matches_existing';
    _s := _s || ' FROM %I.%I';
    _s := _s || ' WHERE parent_term_name <> '''' ';

    EXECUTE format(_s, _sourceSchema, _sourceTable);

    ---------------------------------------------------
    -- Replace empty Grandparent term IDs and names with NULL
    ---------------------------------------------------
    --
    UPDATE Tmp_SourceData t
    SET grandparent_term_id = NULL,
        grandparent_term_name = NULL
    WHERE Coalesce(t.grandparent_term_id, '') = '' AND
          Coalesce(t.grandparent_term_name, '') = '' AND
          (t.grandparent_term_id = '' OR t.grandparent_term_name = '');

    ---------------------------------------------------
    -- Set matches_existing to 1 for rows that match an existing row in ont.t_cv_bto
    ---------------------------------------------------
    --
    UPDATE Tmp_SourceData t
    SET matches_existing = 1
    FROM ont.t_cv_bto s
    WHERE s.Term_PK = t.Term_PK AND
          s.Parent_term_ID = t.Parent_term_ID AND
          Coalesce(s.grandparent_term_id, '') = Coalesce(t.grandparent_term_id, '');


    If _infoOnly = 0 Then
    -- <a1>

        ---------------------------------------------------
        -- Update existing rows
        ---------------------------------------------------
        --
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
               WHERE d.matches_existing = 1) as s
        WHERE t.term_pk = s.term_pk AND
              t.parent_term_id = s.parent_term_id AND
              Coalesce(t.grandparent_term_id, '') = Coalesce(s.grandparent_term_id, '') AND
              (
                t.term_name <> s.term_name OR
                t.identifier <> s.identifier OR
                t.is_leaf <> s.is_leaf OR
                t.synonyms <> s.synonyms OR
                t.parent_term_name <> s.parent_term_name OR
                Coalesce( NULLIF(t.grandparent_term_name, s.grandparent_term_name),
                          NULLIF(s.grandparent_term_name, t.grandparent_term_name)) IS Not Null
              );
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        RAISE INFO 'Updated % rows in ont.t_cv_bto using %', Cast(_myRowCount as varchar(9)), _sourceTable;

        ---------------------------------------------------
        -- Add new rows
        ---------------------------------------------------
        --
        INSERT INTO ont.t_cv_bto (term_pk, term_name, identifier, is_leaf, synonyms,
                                  parent_term_name, parent_term_id,
                                  grandparent_term_name, grandparent_term_id)
        SELECT s.term_pk, s.term_name, s.identifier, s.is_leaf, s.synonyms,
               s.parent_term_name, s.parent_term_id,
               s.grandparent_term_name, s.grandparent_term_id
        FROM Tmp_SourceData s
        WHERE s.matches_existing = 0;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        RAISE INFO 'Added % new rows to ont.t_cv_bto using %', Cast(_myRowCount as varchar(9)), _sourceTable;

        ---------------------------------------------------
        -- Look for identifiers with invalid term names
        ---------------------------------------------------
        --
        CREATE TEMP TABLE IF NOT EXISTS Tmp_InvalidTermNames (
            entry_id   int PRIMARY KEY GENERATED ALWAYS As IDENTITY,
            identifier citext not null,
            term_name  citext not null
        );

        CREATE TEMP TABLE IF NOT EXISTS Tmp_IDsToDelete (
            entry_id int not null
        );

        CREATE INDEX IX_Tmp_IDsToDelete ON Tmp_IDsToDelete (entry_id);

        INSERT INTO Tmp_InvalidTermNames( identifier,
                                          term_name )
        SELECT UniqueQTarget.identifier,
               UniqueQTarget.term_name As Invalid_Term_Name_to_Delete
        FROM ( SELECT DISTINCT t.identifier, t.term_name FROM ont.t_cv_bto t GROUP BY t.identifier, t.term_name ) UniqueQTarget
             LEFT OUTER JOIN
             ( SELECT DISTINCT Tmp_SourceData.identifier, Tmp_SourceData.term_name FROM Tmp_SourceData ) UniqueQSource
               ON UniqueQTarget.identifier = UniqueQSource.identifier AND
                  UniqueQTarget.term_name = UniqueQSource.term_name
        WHERE UniqueQTarget.identifier IN ( SELECT LookupQ.identifier
                                             FROM ( SELECT DISTINCT cvbto.identifier, cvbto.term_name
                                                    FROM ont.t_cv_bto cvbto
                                                    GROUP BY cvbto.identifier, cvbto.term_name ) LookupQ
                                             GROUP BY LookupQ.identifier
                                             HAVING (COUNT(*) > 1) ) AND
              UniqueQSource.identifier IS NULL;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If Found Then
            RAISE INFO 'Added % rows to Tmp_InvalidTermNames', Cast(_myRowCount as varchar(9));
        Else
            RAISE INFO 'No invalid term names were found';
        End If;

        If Exists (Select * From Tmp_InvalidTermNames) Then
        -- <b>
            RETURN QUERY
            SELECT 'Extra term name to delete'::citext As Item_Type,
                   s.entry_id,
                   ''::citext as term_pk,
                   s.term_name,
                   s.identifier,
                   '0'::citext As is_leaf,
                   ''::citext As synonyms,
                   ''::citext As parent_term_id,
                   ''::citext As parent_term_name,
                   ''::citext As grandparent_term_id,
                   ''::citext As grandparent_term_name,
                   current_timestamp::timestamp As entered,
                   NULL::timestamp As updated
            FROM Tmp_InvalidTermNames s;

            INSERT INTO Tmp_IDsToDelete (entry_id)
            SELECT target.entry_id
            FROM ont.t_cv_bto target
                 INNER JOIN Tmp_InvalidTermNames source
                   ON target.identifier = source.identifier AND
                      target.term_name = source.term_name;

            If _previewDeleteExtras > 0 Then
                RETURN QUERY
                SELECT 'To be deleted'::citext as Item_Type,
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
                WHERE t.entry_id IN ( SELECT s.entry_id
                                      FROM Tmp_IDsToDelete s);

            Else
            -- <c>

                For _invalidTerm In
                    SELECT s.identifier, s.term_name
                    FROM Tmp_InvalidTermNames s
                Loop

                    If Exists (Select *
                               FROM ont.t_cv_bto t
                               WHERE t.identifier = _invalidTerm.identifier AND
                                     Not t.entry_id IN (Select d.entry_id FROM Tmp_IDsToDelete d)) Then
                        -- Safe to delete
                        DELETE FROM ont.t_cv_bto t
                        WHERE t.identifier = _invalidTerm.Identifier AND
                              t.term_name = _invalidTerm.term_name;
                        --
                        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                        RAISE INFO 'Deleted % row(s) for ID % and term %', Cast(_myRowCount as varchar(9)), _invalidTerm.identifier, _invalidTerm.term_name;
                    Else
                        -- Not safe to delete
                        RETURN QUERY
                        SELECT 'Warning'::citext As Item_Type,
                               0 As Entry_ID,
                               'Not deleting since since no entries would remain for this ID' as term_pk,
                               _invalidTerm.term_name,
                               _invalidTerm.identifier,
                               '0'::citext As is_leaf,
                               ''::citext As synonyms,
                               ''::citext As parent_term_id,
                               ''::citext As parent_term_name,
                               ''::citext As grandparent_term_id,
                               ''::citext As grandparent_term_name,
                               current_timestamp::timestamp As entered,
                               null::timestamp As updated;

                    End If;

                End Loop; -- </d>
            End If; -- </c>
        End If; -- </b>

        DROP TABLE Tmp_InvalidTermNames;
        DROP TABLE Tmp_IDsToDelete;

        ---------------------------------------------------
        -- Update the Children counts
        ---------------------------------------------------
        --
        UPDATE ont.t_cv_bto t
        SET children = StatsQ.children
        FROM ( SELECT s.parent_term_id, COUNT(*) As children
               FROM ont.t_cv_bto s
               GROUP BY s.parent_term_ID ) StatsQ
        WHERE StatsQ.parent_term_id = t.identifier AND
              Coalesce(t.Children, 0) <> StatsQ.Children;

        -- Change counts to null if no children
        --
        UPDATE ont.t_cv_bto t
        SET children = NULL
        WHERE Not t.identifier in (
                SELECT s.parent_term_id
                FROM ont.t_cv_bto s
                GROUP BY s.parent_term_ID) AND
              Not t.Children IS NULL;

    Else
    -- <a2>
        ---------------------------------------------------
        -- Preview existing rows that would be updated
        ---------------------------------------------------
        --
        RETURN QUERY
        SELECT 'Existing item to update'::citext as Item_Type,
               t.entry_id,
               t.term_pk,
               (CASE WHEN t.term_name = s.term_name THEN t.term_name ELSE t.term_name || ' --> ' || s.term_name END)::citext As term_name,
               (CASE WHEN t.identifier = s.identifier THEN t.identifier ELSE t.identifier || ' --> ' || s.identifier END)::citext as identifier,
               (CASE WHEN t.is_leaf = s.is_leaf THEN Cast(t.is_leaf As text) ELSE Cast(t.is_leaf As text) || ' --> ' || Cast(s.is_leaf As text) END)::citext As is_leaf,
               (CASE WHEN t.synonyms = s.synonyms THEN t.synonyms ELSE t.synonyms || ' --> ' || s.synonyms END)::citext synonyms,
               t.parent_term_id::citext,
               (CASE WHEN t.parent_term_name = s.parent_term_name THEN t.parent_term_name ELSE t.parent_term_name || ' --> ' || s.parent_term_name END)::citext As parent_term_name,
               t.grandparent_term_id::citext,
               (CASE WHEN t.grandparent_term_name = s.grandparent_term_name THEN t.grandparent_term_name ELSE Coalesce(t.grandparent_term_name, 'NULL') || ' --> ' || Coalesce(s.grandparent_term_name, 'NULL') END)::citext As grandparent_term_name,
               t.entered::timestamp,
               t.updated::timestamp
        FROM ont.t_cv_bto As t
            INNER JOIN Tmp_SourceData As s
              ON t.term_pk = s.term_pk AND
                 t.parent_term_id = s.parent_term_id AND
                 Coalesce(t.grandparent_term_id, '') = Coalesce(s.grandparent_term_id, '')
        WHERE s.matches_existing = 1 AND
              ( (t.term_name <> s.term_name) OR
                (t.identifier <> s.identifier) OR
                (t.is_leaf <> s.is_leaf) OR
                (t.synonyms <> s.synonyms) OR
                (t.parent_term_name <> s.parent_term_name) OR
                (Coalesce(NULLIF(t.grandparent_term_name, s.grandparent_term_name),
                        NULLIF(s.grandparent_term_name, t.grandparent_term_name)) IS Not Null)
               )
        UNION
        SELECT 'New item to add'::citext as Item_Type,
               0 As entry_id,
               s.term_pk,
               s.term_name,
               s.identifier,
               s.is_leaf::citext,
               s.synonyms,
               s.parent_term_id,
               s.parent_term_name,
               s.grandparent_term_id,
               s.grandparent_term_name,
               current_timestamp::timestamp As entered,
               NULL::timestamp As updated
        FROM Tmp_SourceData s
        WHERE matches_existing = 0;

    End If; -- </a2>

    -- If not dropped here, the temporary table will persist until the calling session ends
    DROP TABLE Tmp_SourceData;
END
$$;


ALTER FUNCTION ont.add_new_bto_terms(_sourcetable public.citext, _infoonly integer, _previewdeleteextras integer) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_bto_terms(_sourcetable public.citext, _infoonly integer, _previewdeleteextras integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_bto_terms(_sourcetable public.citext, _infoonly integer, _previewdeleteextras integer) IS 'AddNewBTOTerms';

