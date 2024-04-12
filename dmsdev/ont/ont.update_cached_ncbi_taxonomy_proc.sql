--
-- Name: update_cached_ncbi_taxonomy_proc(boolean, boolean, text, text); Type: PROCEDURE; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE ont.update_cached_ncbi_taxonomy_proc(IN _deleteextras boolean, IN _infoonly boolean, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls function ont.update_cached_ncbi_taxonomy() to update cached NCBI taxonomy values
**
**      Used by timetable task "Update cached NCBI taxonomy"
**
**  Arguments:
**    _deleteExtras     When true, delete extra rows from ont.t_ncbi_taxonomy_cached
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   03/25/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _task citext;
    _updatedTaxIdCount int;
    _newTaxIdCount int;
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _deleteExtras := Coalesce(_deleteExtras, true);
    _infoOnly     := Coalesce(_infoOnly, true);

    CREATE TEMP TABLE Tmp_UpdateResults (
        task citext,
        updated_tax_ids int,
        new_tax_ids int
    );

    INSERT INTO Tmp_UpdateResults (
        task,
        updated_tax_ids,
        new_tax_ids
    )
    SELECT task, updated_tax_ids, new_tax_ids
    FROM ont.update_cached_ncbi_taxonomy (_deleteExtras => _deleteExtras, _infoOnly => _infoOnly);

    If Not FOUND Then
        _message := 'Function ont.update_cached_ncbi_taxonomy() did not return any results';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
    Else
        SELECT task,
               updated_tax_ids,
               new_tax_ids
        INTO _task, _updatedTaxIdCount, _newTaxIdCount
        FROM Tmp_UpdateResults
        LIMIT 1;

        _message := format('%s: updated %s %s', _task, _updatedTaxIdCount, public.check_plural(_updatedTaxIdCount, 'taxonomy ID', 'taxonomy IDs'));

        If _newTaxIdCount > 0 Then
            _message := format('%s: added %s new %s', _message, _newTaxIdCount, public.check_plural(_newTaxIdCount, 'taxonomy ID', 'taxonomy IDs'));
        End If;

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_UpdateResults;
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

    DROP TABLE IF EXISTS Tmp_UpdateResults;
END;
$$;


ALTER PROCEDURE ont.update_cached_ncbi_taxonomy_proc(IN _deleteextras boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

