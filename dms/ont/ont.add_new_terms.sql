--
-- Name: add_new_terms(text, boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.add_new_terms(_ontologyname text DEFAULT 'PSI'::text, _infoonly boolean DEFAULT false, _previewsql boolean DEFAULT false) RETURNS TABLE(term_pk public.citext, term_name public.citext, identifier public.citext, is_leaf public.citext, parent_term_name public.citext, parent_term_id public.citext, grandparent_term_name public.citext, grandparent_term_id public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new ontology terms to the ontology-specific table
**      For example, if _ontologyName is 'BTO', will append data to table ont.t_cv_bto
**      Does not update existing items
**
**      The data source is v_term_lineage, which queries t_ontology, t_term, and t_term_relationship
**
**  Arguments:
**    _ontologyName   Examples: BTO, MS, MOD, or PRIDE; used to find identifiers
**    _infoOnly       When true, preview updates
**    _previewSql     When true, preview the SQL (but do not execute it)
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          04/04/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          10/05/2022 mem - When querying ont.v_newt_terms, cast Identifier to citext
**          10/06/2022 mem - Add exception handler and instructions for updating the backing sequence for the entry_id field in ont.t_cv_newt
**          05/12/2023 mem - Rename variables
**          05/23/2023 mem - Use format() for string concatenation
**          05/25/2023 mem - Show a custom message if _ontologyName is BTO, ENVO, or MS
**                         - Reduce nesting
**          05/30/2023 mem - Use format() for string concatenation
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/21/2024 mem - Change data type of argument _ontologyName to text
**          06/08/2024 mem - No longer process NEWT info; instead, use add_new_newt_terms
**
*****************************************************/
DECLARE
    _warningMessage text := '';
    _insertCount int;
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
    _errorMessage text := '';
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _ontologyName := Trim(Coalesce(_ontologyName, ''));
    _infoOnly     := Coalesce(_infoOnly, false);
    _previewsql   := Coalesce(_previewSql, false);

    ---------------------------------------------------
    -- Ontology PSI is superseded by PSI_MS
    -- Do not allow processing of the 'PSI' ontology
    ---------------------------------------------------

    If _ontologyName::citext = 'PSI' Then
        _warningMessage := 'Ontology PSI is superseded by MS (aka PSI_MS); creation of table T_CV_PSI is not allowed';

    ElsIf _ontologyName::citext In ('BTO', 'ENVO', 'MS', 'NEWT') Then
        _warningMessage := format('Use function "ont.add_new_%s_terms" to add %s terms', Lower(_ontologyName), _ontologyName);

    ElsIf Not Exists (SELECT ontology FROM ont.v_term_lineage WHERE ontology = _ontologyName::citext) Then
        _warningMessage := format('Invalid ontology name: %s; not found in ont.v_term_lineage', _ontologyName);

    End If;

    If _warningMessage <> '' Then
        RETURN QUERY
        SELECT 'Warning'::citext AS term_pk,
               _warningMessage::citext AS term_name,
               ''::citext AS identifier,
               '0'::citext AS is_leaf,
               ''::citext AS parent_term_name,
               ''::citext AS parent_term_id,
               ''::citext AS grandparent_term_name,
               ''::citext AS grandparent_term_id;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Look for the target table
    ---------------------------------------------------

    _targetSchema := 'ont';
    _targetTable  := format('t_cv_%s', Lower(_ontologyName));

    CREATE TEMP TABLE Tmp_CandidateTables AS
    SELECT Table_to_Find, Schema_Name, Table_Name, Table_Exists, Message
    FROM resolve_table_name(format('%s.%s', _targetSchema, _targetTable));

    If Exists (SELECT Table_to_Find FROM Tmp_CandidateTables WHERE Table_Exists) Then
        -- Make sure the target name is properly capitalized
        SELECT Schema_Name, Table_Name
        INTO _targetSchema, _targetTable
        FROM Tmp_CandidateTables
        WHERE Table_Exists
        LIMIT 1;

        _targetTableWithSchema := format('%s.%s', _targetSchema, _targetTable);
    Else
        -- Table not found; create it

        _targetTableWithSchema := format('%s.%s', _targetSchema, _targetTable);

        _s := 'CREATE TABLE %I.%I ('
                 ' entry_id int NOT NULL GENERATED ALWAYS AS IDENTITY,'
                 ' term_pk citext NOT NULL,'
                 ' term_name citext NOT NULL,'
                 ' identifier citext NOT NULL,'
                 ' is_leaf smallint NOT NULL,'
                 ' parent_term_name citext NOT NULL,'
                 ' parent_term_id citext NOT NULL,'
                 ' grandparent_term_name citext,'
                 ' grandparent_term_id citext,'
                 ' entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,' ||
          format(' CONSTRAINT pk_%s PRIMARY KEY (entry_id)', _targetTable)                  ||
              '); ';

        If _previewSql Then
            RAISE INFO '%', format(_s, _targetSchema, _targetTable);
        Else
            EXECUTE format(_s, _targetSchema, _targetTable);
        End If;

        _s := format('CREATE INDEX ix_%s_term_name             ON %s USING btree (term_name); ', _targetTable, _targetTableWithSchema)                      ||
              format('CREATE INDEX ix_%s_identifier            ON %s USING btree (identifier) INCLUDE (term_name); ', _targetTable, _targetTableWithSchema) ||
              format('CREATE INDEX ix_%s_parent_term_name      ON %s USING btree (parent_term_name); ', _targetTable, _targetTableWithSchema)               ||
              format('CREATE INDEX ix_%s_grandparent_term_name ON %s USING btree (grandparent_term_name);', _targetTable, _targetTableWithSchema);

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

    /*
     * Deprecated in June 2024; instead, use ont.add_new_newt_terms

    If _ontologyName::citext = 'NEWT' Then
        -- NEWT identifiers do not start with NEWT
        -- Query v_newt_terms
        -- Insert data into 'ont.t_cv_newt' (defined by _targetTableWithSchema)

        _sourceTable := 'ont.v_newt_terms';

        _insertSql := format('INSERT INTO %s (term_pk, term_name, identifier, is_leaf, parent_term_name, parent_term_id, grandparent_term_name, grandparent_term_id)', _targetTableWithSchema);

        -- Old
        -- _s :=        ' SELECT DISTINCT term_pk, term_name, identifier, is_leaf, parent_term_name, Parent_term_Identifier, ' ||
        --                              'grandparent_term_name, grandparent_term_identifier'                                  ||
        --      format(' FROM %s', _sourceTable)                                                                              ||
        --      format(' WHERE NOT parent_term_identifier IS NULL AND NOT identifier IN (SELECT identifier::citext FROM %s)', _targetTableWithSchema);

        _s := format('SELECT DISTINCT s.term_pk, s.term_name, s.identifier%s', CASE WHEN _infoOnly Then '::citext, ' Else '::int, ' END)                ||
              format(                's.is_leaf, s.parent_term_name, s.Parent_term_Identifier, s.grandparent_term_name, s.grandparent_term_identifier') ||
              format(' FROM %s s', _sourceTable)                                                                                                        ||
              format('      LEFT OUTER JOIN %s t', _targetTableWithSchema)                                                                              ||
                     '        ON s.identifier::int = t.identifier'
                     ' WHERE NOT s.parent_term_identifier IS NULL AND'
                     '       t.identifier IS NULL';

    End If;
    */

    -- Identifiers start with the ontology name
    -- Directly query v_term_lineage

    _sourceTable := 'ont.v_term_lineage';

    _insertSql := format('INSERT INTO %s (term_pk, term_name, identifier, is_leaf, parent_term_name, parent_term_id, grandparent_term_name, grandparent_term_id)', _targetTableWithSchema);

    _s :=        'SELECT DISTINCT s.term_pk, s.term_name, s.identifier, s.is_leaf, '
                          's.parent_term_name, s.parent_term_Identifier, s.grandparent_term_name, s.grandparent_term_identifier' ||
         format(' FROM (SELECT * FROM %s', _sourceTable)                                                                         ||
         format(' WHERE ontology = ''%s'' AND is_obsolete = 0 AND NOT parent_term_identifier IS NULL) s', _ontologyName)         ||
         format(' LEFT OUTER JOIN (SELECT identifier, parent_term_id, grandparent_term_id FROM %s) t', _targetTableWithSchema)   ||
                         ' ON s.identifier = t.identifier AND'
                            ' s.parent_term_identifier = t.parent_term_id AND '
                            ' Coalesce(s.grandparent_term_identifier, '''') = Coalesce(t.grandparent_term_id, '''')'
                ' WHERE t.identifier IS NULL;';

    ---------------------------------------------------
    -- Add or preview new terms
    ---------------------------------------------------

    If _infoOnly Then
        If _previewSql Then
            RAISE INFO '%', _s;
        Else
            -- Preview new terms
            _s := Replace(_s, 's.is_leaf', 's.is_leaf::citext');

            RETURN QUERY
            Execute _s;
        End If;

        RETURN;
    End If;

    If _previewSql Then
        RAISE INFO '% %', _insertSql, _s;
        RETURN;
    End If;

    BEGIN
        -- Add new terms
        Execute format('%s %s', _insertSql, _s);
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _insertCount > 0 Then
            RAISE INFO 'Added % new rows to % for ontology % using %', _insertCount, _targetTableWithSchema, Upper(_ontologyName), _sourceTable;
        Else
            RAISE INFO 'All rows for ontology % are already in %', Upper(_ontologyName), _targetTableWithSchema;
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
            If _targetTable::citext = 't_cv_newt' Then
                _s := 'Use the following query to update the next value for the sequence behind the entry_id field in the target table: SELECT setval(''ont.t_cv_newt_entry_id_seq'', (SELECT MAX(entry_id) FROM ont.t_cv_newt));';
            Else
                _s := format('Use the following query to look for a backing sequence behind an Identity column in the target table: SELECT * FROM pg_catalog.pg_sequences WHERE sequencename LIKE ''%s%'';', _targetTable);
            End If;
        Else
            _s := '';
        End If;

        RETURN QUERY
        SELECT 'Exception'::citext AS term_pk,
               _errorMessage::citext AS term_name,
               _s::citext AS identifier,
               '0'::citext AS is_leaf,
               ''::citext AS parent_term_name,
               ''::citext AS parent_term_id,
               ''::citext AS grandparent_term_name,
               ''::citext AS grandparent_term_id;

        RETURN;
    END;

END
$$;


ALTER FUNCTION ont.add_new_terms(_ontologyname text, _infoonly boolean, _previewsql boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_new_terms(_ontologyname text, _infoonly boolean, _previewsql boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.add_new_terms(_ontologyname text, _infoonly boolean, _previewsql boolean) IS 'AddNewTerms';

