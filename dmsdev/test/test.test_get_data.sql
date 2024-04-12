--
-- Name: test_get_data(integer, refcursor, refcursor, text, text); Type: PROCEDURE; Schema: test; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE test.test_get_data(IN _itemid integer, INOUT _resultsa refcursor DEFAULT '_resultsa'::refcursor, INOUT _resultsb refcursor DEFAULT '_resultsb'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Test procedure demonstrating how to return multiple result sets using cursors
**
**  Arguments:
**    _itemID       Item ID to mention in _message
**    _resultsA     Output: cursor for retrieving result set 1
**    _resultsB     Output: cursor for retrieving result set 2
**    _message      Status message
**    _returnCode   Return code
**
**  Use this to view the data returned by the _results cursors
**
**      BEGIN;
**          CALL test.test_get_data (5);
**          FETCH ALL FROM _resultsa;
**          FETCH ALL FROM _resultsb;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**/
BEGIN
    _message := 'Test message for item ' || COALESCE(_itemID, 0);
    _returnCode := '';

  Open _resultsA For
    SELECT *
    FROM (VALUES (1,2,3, 'fruit', current_timestamp - INTERVAL '5 seconds'),
                 (4,5,6, 'veggie', current_timestamp)) AS t(a,b,c,d,e);

  Open _resultsB For
    SELECT *
    FROM (VALUES ('one'), ('two'), ('three'), ('four')) AS p(name);

END;
$$;


ALTER PROCEDURE test.test_get_data(IN _itemid integer, INOUT _resultsa refcursor, INOUT _resultsb refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

