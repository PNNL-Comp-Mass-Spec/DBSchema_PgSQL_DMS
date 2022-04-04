--
-- Name: add_new_terms(public.citext, integer, integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_terms(_ontologyname public.citext DEFAULT 'PSI'::public.citext, _infoonly integer DEFAULT 0, _previewsql integer DEFAULT 0) RETURNS TABLE(term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, parent_term_name public.citext, parent_term_id public.citext, grandparent_term_name public.citext, grandparent_term_id public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new ontology terms to the ontology-specific table
**      For example, if _ontologyName is 'NEWT', will append data to table ont.t_cv_newt
**
**      Does not update existing items
**
**  Arguments:
**    _ontologyName   Examples: NEWT, MS, MOD, or PRIDE; used to find identifiers
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          04/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _errorMessage text := '';
    _myRowCount int := 0;
    _sourceTable text;
    _targetSchema text := '';
    _targetTable text := '';
    _targetTableWithSchema text := '';
    _insertSql text := '';
    _s text := '';
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _ontologyName := Coalesce(_ontologyName, '');
    _infoOnly := Coalesce(_infoOnly, 0);
    _previewSql := Coalesce(_previewSql, 0);

    ---------------------------------------------------
    -- Validate the ontology name
    ---------------------------------------------------
    --
    If Not Exists (select * from ont.v_term_lineage where ontology = _ontologyName) Then
        _errorMessage := 'Invalid ontology name: ' || _ontologyName || '; not found in ont.v_term_lineage';
    End If;

    ---------------------------------------------------
    -- Ontology PSI is superseded by PSI_MS
    -- Do not allow processing of the 'PSI' ontology
    ---------------------------------------------------
    --
    If _ontologyName = 'PSI' Then
        _errorMessage := 'Ontology PSI is superseded by MS (aka PSI_MS); creation of table T_CV_PSI is not allowed';
    End If;

    If _errorMessage <> '' Then
        RETURN QUERY
        SELECT 'Warning'::citext As term_pk,
               _errorMessage::citext As term_name,
               ''::citext As identifier,
               '0'::citext As is_leaf,
               ''::citext As parent_term_name,
               ''::citext As parent_term_id,
               ''::citext As grandparent_term_name,
               ''::citext As grandparent_term_id;

        Return;
    End If;

    ---------------------------------------------------
    -- Look for the target table
    ---------------------------------------------------

    _targetSchema := 'ont';
    _targetTable  := 't_cv_' || lower(_ontologyName);

    CREATE TEMP TABLE Tmp_CandidateTables AS
    SELECT Table_to_Find, Schema_Name, Table_Name, Table_Exists, Message
    FROM resolve_table_name(_targetSchema || '.' || _targetTable);

    If Exists (SELECT * FROM Tmp_CandidateTables WHERE Table_Exists) Then
        -- Make sure the target name is properly capitalized
        SELECT Schema_Name, Table_Name
        INTO _targetSchema, _targetTable
        FROM Tmp_CandidateTables
        WHERE Table_Exists
        LIMIT 1;

        _targetTableWithSchema := _targetSchema || '.' || _targetTable;
    Else
        -- Table not found; create it

        _targetTableWithSchema := _targetSchema || '.' || _targetTable;

        _s := '';
        _s := _s || ' CREATE TABLE %I.%I (';
        _s := _s ||     ' entry_id int NOT NULL GENERATED ALWAYS AS IDENTITY,';
        _s := _s ||     ' term_pk citext NOT NULL,';
        _s := _s ||     ' term_name citext NOT NULL,';
        _s := _s ||     ' identifier citext NOT NULL,';
        _s := _s ||     ' is_leaf smallint NOT NULL,';
        _s := _s ||     ' parent_term_name citext NOT NULL,';
        _s := _s ||     ' parent_term_id citext NOT NULL,';
        _s := _s ||     ' grandparent_term_name citext,';
        _s := _s ||     ' grandparent_term_id citext,';
        _s := _s ||     ' entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,';
        _s := _s ||     ' CONSTRAINT pk_' || _targetTable || ' PRIMARY KEY (entry_id)';
        _s := _s || ' )';

        If _previewSql = 1                 Then
            RAISE INFO '%', format(_s, _targetSchema, _targetTable);
        Else
            EXECUTE format(_s, _targetSchema, _targetTable);
        End If;

        _s := '';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_term_name ON ' || _targetTableWithSchema || ' USING btree (term_name); ';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_identifier ON ' || _targetTableWithSchema || ' USING btree (identifier) INCLUDE (term_name); ';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_parent_term_name ON ' || _targetTableWithSchema || ' USING btree (parent_term_name); ';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_grandparent_term_name ON ' || _targetTableWithSchema || ' USING btree (grandparent_term_name);';

        If _previewSql = 1 Then
            RAISE INFO '%', _s;
        Else
            EXECUTE _s;
        End If;

    End If;

    DROP TABLE Tmp_CandidateTables;

    ---------------------------------------------------
    -- Construct the Insert Into and Select SQL
    ---------------------------------------------------
    --
    If _ontologyName = 'NEWT' Then
        -- NEWT identifiers do not start with NEWT
        -- Query v_newt_terms (which in turn queries V_Term_Lineage)

        _sourceTable := 'ont.v_newt_terms';

        _insertSql := ' INSERT INTO ' || _targetTableWithSchema || ' ( term_pk, term_name, identifier, is_leaf, parent_term_name, parent_term_id,  grandparent_term_name,  grandparent_term_id )';
        _s := '';
        _s := _s || ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, parent_term_name, Parent_term_Identifier, grandparent_term_name, grandparent_term_identifier';
        _s := _s || ' FROM ' || _sourceTable;
        _s := _s || ' WHERE NOT parent_term_identifier Is Null AND NOT identifier IN ( SELECT identifier FROM ' || _targetTableWithSchema || ' )';

    Else
        -- Other identifiers do start with the ontology name
        -- Directly query v_term_lineage

        _sourceTable := 'ont.v_term_lineage';

        _insertSql := ' INSERT INTO ' || _targetTableWithSchema || ' ( term_pk, term_name, identifier, is_leaf, parent_term_name, parent_term_id,  grandparent_term_name,  grandparent_term_id )';
        _s := '';
        _s := _s || ' SELECT DISTINCT s.term_pk, s.term_name, s.identifier, s.is_leaf, ';
        _s := _s ||                 ' s.parent_term_name, s.parent_term_Identifier, s.grandparent_term_name, s.grandparent_term_identifier';
        _s := _s || ' FROM ( SELECT * FROM ' || _sourceTable || '';
        _s := _s ||        ' WHERE ontology =''' || _ontologyName || ''' AND is_obsolete = 0 AND NOT parent_term_identifier IS NULL ) s';
        _s := _s ||      ' LEFT OUTER JOIN ( SELECT identifier, parent_term_id, grandparent_term_id FROM ' || _targetTableWithSchema || ' ) t';
        _s := _s ||          ' ON s.identifier = t.identifier AND';
        _s := _s ||             ' s.parent_term_identifier = t.parent_term_id AND ';
        _s := _s ||             ' Coalesce(s.grandparent_term_identifier, '''') = Coalesce(t.grandparent_term_id, '''')';
        _s := _s || ' WHERE t.identifier is null;';

    End If;

    ---------------------------------------------------
    -- Add or preview new terms
    ---------------------------------------------------
    --
    If _infoOnly = 0 Then
        If _previewSql = 1 Then
            RAISE INFO '%', _insertSql || _s;
        Else
            -- Add new terms
            Execute  _insertSql || _s;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount > 0 Then
                RAISE INFO 'Added % new rows to % for ontology % using %', Cast(_myRowCount as varchar(9)), _targetTableWithSchema, upper(_ontologyName), _sourceTable;
            Else
                RAISE INFO 'All rows for ontology % are already in %', upper(_ontologyName), _targetTableWithSchema;
            End If;
        End If;
    Else
        If _previewSql = 1 Then
            RAISE INFO '%', _s;
        Else
            -- Preview new terms
            _s := replace(_s, 's.is_leaf', 's.is_leaf::citext');

            RETURN QUERY
            Execute _s;
        End If;
    End If;

END
$$;


ALTER FUNCTION ont.add_new_terms(_ontologyname public.citext, _infoonly integer, _previewsql integer) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_terms(_ontologyname public.citext, _infoonly integer, _previewsql integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_terms(_ontologyname public.citext, _infoonly integer, _previewsql integer) IS 'AddNewTerms';

