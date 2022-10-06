--
-- Name: add_new_terms(public.citext, boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_terms(_ontologyname public.citext DEFAULT 'PSI'::public.citext, _infoonly boolean DEFAULT false, _previewsql boolean DEFAULT false) RETURNS TABLE(term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, parent_term_name public.citext, parent_term_id public.citext, grandparent_term_name public.citext, grandparent_term_id public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new ontology terms to the ontology-specific table
**      For example, if _ontologyName is 'NEWT', will append data to table ont.t_cv_newt
**      Does not update existing items
**
**      For NEWT, the data source is ont.v_newt_terms (which queries v_term_lineage)
**      For other ontologies, the data source is v_term_lineage
**
**      In both cases, v_term_lineage queries t_ontology, t_term, and t_term_relationship
**
**  Arguments:
**    _ontologyName   Examples: NEWT, MS, MOD, or PRIDE; used to find identifiers
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          04/04/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          10/05/2022 mem - When querying ont.v_newt_terms, cast Identifier to citext
**          10/06/2022 mem - Add exception handler and instructions for updating the backing sequence for the entry_id field in ont.t_cv_newt
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

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _ontologyName := Coalesce(_ontologyName, '');
    _infoOnly := Coalesce(_infoOnly, false);
    _previewsql := Coalesce(_previewSql, false);

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

        RETURN;
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

        If _previewSql Then
            RAISE INFO '%', format(_s, _targetSchema, _targetTable);
        Else
            EXECUTE format(_s, _targetSchema, _targetTable);
        End If;

        _s := '';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_term_name ON ' || _targetTableWithSchema || ' USING btree (term_name); ';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_identifier ON ' || _targetTableWithSchema || ' USING btree (identifier) INCLUDE (term_name); ';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_parent_term_name ON ' || _targetTableWithSchema || ' USING btree (parent_term_name); ';
        _s := _s || ' CREATE INDEX ix_' || _targetTable || '_grandparent_term_name ON ' || _targetTableWithSchema || ' USING btree (grandparent_term_name);';

        If _previewSql Then
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
        -- Insert data into 'ont.t_cv_newt' (defined by _targetTableWithSchema)

        _sourceTable := 'ont.v_newt_terms';

        _insertSql := ' INSERT INTO ' || _targetTableWithSchema || ' ( term_pk, term_name, identifier, is_leaf, parent_term_name, parent_term_id, grandparent_term_name, grandparent_term_id )';

        /*
         * Old
        _s := '';
        _s := _s || ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, parent_term_name, Parent_term_Identifier, grandparent_term_name, grandparent_term_identifier';
        _s := _s || ' FROM ' || _sourceTable;
        _s := _s || ' WHERE NOT parent_term_identifier Is Null AND NOT identifier IN ( SELECT identifier::citext FROM ' || _targetTableWithSchema || ' )';
        */

        _s := '';
        _s := _s || ' SELECT DISTINCT s.term_pk, s.term_name, s.identifier' || CASE WHEN _infoOnly Then '::citext,' Else '::int,' END;
        _s := _s ||                  's.is_leaf, s.parent_term_name, s.Parent_term_Identifier, s.grandparent_term_name, s.grandparent_term_identifier';
        _s := _s || ' FROM ' || _sourceTable || ' s';
        _s := _s || '      LEFT OUTER JOIN ' || _targetTableWithSchema || ' t';
        _s := _s || '        ON s.identifier::int = t.identifier';
        _s := _s || ' WHERE NOT s.parent_term_identifier Is Null AND';
        _s := _s || '       t.identifier is null';

    Else
        -- Other identifiers do start with the ontology name
        -- Directly query v_term_lineage

        _sourceTable := 'ont.v_term_lineage';

        _insertSql := ' INSERT INTO ' || _targetTableWithSchema || ' ( term_pk, term_name, identifier, is_leaf, parent_term_name, parent_term_id, grandparent_term_name, grandparent_term_id )';
        _s := '';
        _s := _s || ' SELECT DISTINCT s.term_pk, s.term_name, s.identifier, s.is_leaf, ';
        _s := _s ||                 ' s.parent_term_name, s.parent_term_Identifier, s.grandparent_term_name, s.grandparent_term_identifier';
        _s := _s || ' FROM ( SELECT * FROM ' || _sourceTable || '';
        _s := _s ||        ' WHERE ontology = ''' || _ontologyName || ''' AND is_obsolete = 0 AND NOT parent_term_identifier IS NULL ) s';
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
    If Not _infoOnly Then
        If _previewSql Then
            RAISE INFO '%', _insertSql || _s;
        Else

           BEGIN
                -- Add new terms
                Execute  _insertSql || _s;
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _myRowCount > 0 Then
                    RAISE INFO 'Added % new rows to % for ontology % using %', _myRowCount, _targetTableWithSchema, upper(_ontologyName), _sourceTable;
                Else
                    RAISE INFO 'All rows for ontology % are already in %', upper(_ontologyName), _targetTableWithSchema;
                End If;

            EXCEPTION
                WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS
                        _sqlState         = returned_sqlstate,
                        _exceptionMessage = message_text,
                        _exceptionDetail  = pg_exception_detail,
                        _exceptionContext = pg_exception_context;

                _errorMessage := local_error_handler (
                                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                                    format('Appending new rows to table %s', _targetTableWithSchema),
                                    _logError => false);

                If _errorMessage Like '%duplicate key value violates unique constraint%' Then
                    If _targetTable::citext = 't_cv_newt'::citext Then
                        _s := 'Use the following query to update the next value for the sequence behind the entry_id field in the target table: SELECT setval(''ont.t_cv_newt_entry_id_seq'', (SELECT MAX(entry_id) FROM ont.t_cv_newt));';
                    Else
                        _s := 'Use the following query to look for a backing sequence behind an Identity column in the target table: SELECT * FROM pg_catalog.pg_sequences WHERE sequencename LIKE ''' || _targetTable || '%'';';
                    End If;
                Else
                    _s := '';
                End If;

                RETURN QUERY
                SELECT 'Exception'::citext As term_pk,
                       _errorMessage::citext As term_name,
                       _s::citext As identifier,
                       '0'::citext As is_leaf,
                       ''::citext As parent_term_name,
                       ''::citext As parent_term_id,
                       ''::citext As grandparent_term_name,
                       ''::citext As grandparent_term_id;

                RETURN;
            END;

        End If;
    Else
        If _previewSql Then
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


ALTER FUNCTION ont.add_new_terms(_ontologyname public.citext, _infoonly boolean, _previewsql boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_terms(_ontologyname public.citext, _infoonly boolean, _previewsql boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_terms(_ontologyname public.citext, _infoonly boolean, _previewsql boolean) IS 'AddNewTerms';

