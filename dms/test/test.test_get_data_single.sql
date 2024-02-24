--
-- Name: test_get_data_single(integer, refcursor, text, text); Type: PROCEDURE; Schema: test; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE test.test_get_data_single(IN _itemid integer, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Test procedure demonstrating how to return a result set using a cursor
**
**  Arguments:
**    _itemID       Item ID to mention in _message
**    _results      Output: cursor for retrieving resuls
**    _message      Status message
**    _returnCode   Return code
**
**  Use this to view the data returned by the _results cursors
**
**      BEGIN;
**          CALL test.test_get_data_single (5);
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**/
BEGIN
    _message := 'Test message for item ' || COALESCE(_itemID, 0);
    _returnCode := '';

  Open _results For
    SELECT *
    FROM (VALUES (1,2,3, 'fruit', current_timestamp - INTERVAL '5 seconds'),
                 (4,5,6, 'veggie', current_timestamp)) AS t(a,b,c,d,e);

END;
$$;


ALTER PROCEDURE test.test_get_data_single(IN _itemid integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

