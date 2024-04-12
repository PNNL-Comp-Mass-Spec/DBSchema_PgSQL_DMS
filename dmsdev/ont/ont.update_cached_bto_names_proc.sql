--
-- Name: update_cached_bto_names_proc(boolean, text, text); Type: PROCEDURE; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE ont.update_cached_bto_names_proc(IN _infoonly boolean, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls function ont.update_cached_bto_names() to update cached BTO identifiers and names
**
**      Used by timetable task "Update cached tissue names"
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   03/28/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _task citext;
    _deleteCount int = 0;
    _newCount int = 0;
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly     := Coalesce(_infoOnly, true);

    CREATE TEMP TABLE Tmp_UpdateResults (
        task citext,
        identifier citext,
        term_name citext
    );

    INSERT INTO Tmp_UpdateResults (
        task,
        identifier,
        term_name
    )
    SELECT task, identifier, term_name
    FROM ont.update_cached_bto_names (_infoOnly => _infoOnly);

    If Not FOUND Then
        _message := 'Function ont.update_cached_bto_names() did not return any results';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        DROP TABLE Tmp_UpdateResults;
        RETURN;
    End If;

    SELECT task
    INTO _task
    FROM Tmp_UpdateResults
    WHERE task LIKE '%already up-to-date%';

    If FOUND Then
        _message = _task;
        RAISE INFO '%', _message;

        DROP TABLE Tmp_UpdateResults;
        RETURN;
    End If;

    If _infoOnly Then
        SELECT COUNT(*)
        INTO _deleteCount
        FROM Tmp_UpdateResults
        WHERE task = 'Delete from cache';

        SELECT COUNT(*)
        INTO _newCount
        FROM Tmp_UpdateResults
        WHERE task = 'Add to cache';

        _message := format('Would add %s new %s and delete %s %s',
                           _newCount, public.check_plural(_newCount, 'term', 'terms'),
                           _deleteCount, public.check_plural(_deleteCount, 'term', 'terms'));
    Else
        SELECT identifier
        INTO _message
        FROM Tmp_UpdateResults
        LIMIT 1;
    End If;

    RAISE INFO '%', _message;

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


ALTER PROCEDURE ont.update_cached_bto_names_proc(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

