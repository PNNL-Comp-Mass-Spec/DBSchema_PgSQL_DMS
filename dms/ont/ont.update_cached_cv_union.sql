--
-- Name: update_cached_cv_union(boolean, text, text); Type: PROCEDURE; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE ont.update_cached_cv_union(IN _previewsql boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates data in ont.t_cv_union_cached
**
**      Source tables are those used by view ont.v_cv_union
**      - ont.t_cv_bto
**      - ont.t_cv_envo
**      - ont.t_cv_cl
**      - ont.t_cv_go
**      - ont.t_cv_mi
**      - ont.t_cv_mod
**      - ont.t_cv_ms
**      - ont.t_cv_newt
**      - ont.t_cv_pride
**      - ont.t_cv_doid;
**
**  Arguments:
**    _previewSql     When true, show the SQL that would be used to update ont.t_cv_union_cached
**    _message        Status message
**    _returnCode     Return code
**
**  Auth:   mem
**  Date:   06/10/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _sourceInfo record;
    _sql text;
    _identifier text;
    _parentTermID text;
    _grandparentTermID text;
    _mergeCount int;
    _deleteCount int;
    _rowsUpdated int := 0;
    _statusMsg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _previewSql := Coalesce(_previewSql, true);

        RAISE INFO '';

        If _previewSql Then
            RAISE INFO 'Previewing SQL to update ont.t_cv_union_cached';
        Else
            RAISE INFO 'Updating ont.t_cv_union_cached';
        End If;

        ---------------------------------------------------
        -- Process the tables referenced by view ont.v_cv_union
        ---------------------------------------------------

        CREATE TEMP TABLE T_Tmp_CV_Tables (
            Ontology text,
            Table_Name text
        );

        INSERT INTO T_Tmp_CV_Tables (Ontology, Table_Name)
        VALUES ('BTO',     'ont.t_cv_bto'),
               ('ENVO',    'ont.t_cv_envo'),
               ('CL',      'ont.t_cv_cl'),
               ('GO',      'ont.t_cv_go'),
               ('PSI-MI',  'ont.t_cv_mi'),
               ('PSI-Mod', 'ont.t_cv_mod'),
               ('PSI-MS',  'ont.t_cv_ms'),
               ('NEWT',    'ont.t_cv_newt'),
               ('PRIDE',   'ont.t_cv_pride'),
               ('DOID',    'ont.t_cv_doid');

        FOR _sourceInfo IN
            SELECT Ontology, Table_Name
            FROM T_Tmp_CV_Tables
        LOOP
            RAISE INFO '';
            RAISE INFO 'Caching data for %', _sourceInfo.Ontology;

            If _sourceInfo.Ontology = 'NEWT' Then
                -- Cast to citext since identifiers in t_cv_newt are integers
                _identifier        := 'Src.identifier::citext';
                _parentTermID      := 'Src.parent_term_id::citext';
                _grandparentTermID := 'Src.grandparent_term_id::citext';
            Else
                _identifier        := 'Src.identifier';
                _parentTermID      := 'Src.parent_term_id';
                _grandparentTermID := 'Src.grandparent_term_id';
            End If;

            _sql := ' MERGE INTO ont.t_cv_union_cached AS t'
                    ' USING (SELECT ''' || _sourceInfo.Ontology || ''' AS source,'
                    '               Src.term_pk,'
                    '               Src.term_name,'
                    '               ' || _identifier || ','
                    '               Src.is_leaf,'
                    '               Src.parent_term_name,'
                    '               ' || _parentTermID || ','
                    '               Src.grandparent_term_name,'
                    '               ' || _grandparentTermID || ''
                    '         FROM ' || _sourceInfo.Table_Name || ' AS Src'
                    '        ) AS s'
                    ' ON (t.source              = s.source AND'
                    '     t.term_pk             = s.term_pk AND'
                    '     t.parent_term_id      = s.parent_term_id AND'
                    '     Coalesce(t.grandparent_term_id, '''') = Coalesce(s.grandparent_term_id, ''''))'
                    ' WHEN MATCHED AND'
                    '      (t.term_name             IS DISTINCT FROM s.term_name OR'
                    '       t.identifier            IS DISTINCT FROM s.identifier OR'
                    '       t.is_leaf               IS DISTINCT FROM s.is_leaf OR'
                    '       t.parent_term_name      IS DISTINCT FROM s.parent_term_name OR'
                    '       t.grandparent_term_name IS DISTINCT FROM s.grandparent_term_name'
                    '      ) THEN'
                    '     UPDATE SET'
                    '         term_name             = s.term_name,'
                    '         identifier            = s.identifier,'
                    '         is_leaf               = s.is_leaf,'
                    '         parent_term_name      = s.parent_term_name,'
                    '         grandparent_term_name = s.grandparent_term_name'
                    ' WHEN NOT MATCHED THEN'
                    '     INSERT (source,'
                    '             term_pk,'
                    '             term_name,'
                    '             identifier,'
                    '             is_leaf,'
                    '             parent_term_name,'
                    '             parent_term_id,'
                    '             grandparent_term_name,'
                    '             grandparent_term_id)'
                    '     VALUES (s.source,'
                    '             s.term_pk,'
                    '             s.term_name,'
                    '             s.identifier,'
                    '             s.is_leaf,'
                    '             s.parent_term_name,'
                    '             s.parent_term_id,'
                    '             s.grandparent_term_name,'
                    '             s.grandparent_term_id)'
                    ';';

            If _previewSQL Then
                RAISE INFO '%', _sql;
            Else
                EXECUTE _sql;

                GET DIAGNOSTICS _mergeCount = ROW_COUNT;
                _rowsUpdated := _rowsUpdated + _mergeCount;

                If _mergeCount > 0 Then
                    _statusMsg := format('Added/updated %s %s for %s',
                                         _mergeCount,
                                         public.check_plural(_mergeCount, 'row', 'rows'),
                                         _sourceInfo.Ontology);
                    RAISE INFO '%', _statusMsg;
                End If;
            End If;

            -- Delete extra rows from the target table
            _sql := ' DELETE FROM ont.t_cv_union_cached target'
                    ' WHERE target.source = ''' || _sourceInfo.Ontology || ''' AND'
                    '       NOT EXISTS (SELECT Src.term_pk'
                    '                   FROM ' || _sourceInfo.Table_Name || ' Src'
                    '                   WHERE Src.term_pk             = target.term_pk AND'
                    '                         ' || _parentTermID || ' = target.parent_term_id AND'
                    '                         Coalesce(' || _grandparentTermID || ', '''') = Coalesce(target.grandparent_term_id, '''')'
                    '                  );';

            If _previewSQL Then
                RAISE INFO '%', _sql;
            Else
                EXECUTE _sql;

                GET DIAGNOSTICS _deleteCount = ROW_COUNT;
                _rowsUpdated := _rowsUpdated + _deleteCount;

                If _deleteCount > 0 Then
                    _statusMsg := format('Deleted %s extra %s for %s',
                                         _deleteCount,
                                         public.check_plural(_deleteCount, 'row', 'rows'),
                                         _sourceInfo.Ontology);
                    RAISE INFO '%', _statusMsg;
                End If;
            End If;

        End Loop;

        If Not _previewSql Then
            If _rowsUpdated = 0 Then
                _message := 'Cached names in ont.t_cv_union_cached are already up-to-date';
            Else
                _message := format('Updated %s %s in ont.t_cv_union_cached', _rowsUpdated, public.check_plural(_rowsUpdated, 'row', 'rows'));
            End If;

            RAISE INFO '%', _message;
        End If;

        DROP TABLE T_Tmp_CV_Tables;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS T_Tmp_CV_Tables;
END
$$;


ALTER PROCEDURE ont.update_cached_cv_union(IN _previewsql boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

