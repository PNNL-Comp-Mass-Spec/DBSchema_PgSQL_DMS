--
-- Name: test_get_data(integer, text, refcursor, refcursor, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.test_get_data(IN _itemid integer, INOUT _message text DEFAULT ''::text, INOUT _result_one refcursor DEFAULT 'rs_resultone'::refcursor, INOUT _result_two refcursor DEFAULT 'rs_resulttwo'::refcursor, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    _message := 'Test message for item ' || COALESCE(_itemID, 0);
    _returnCode := '';

  open _result_one for
    SELECT *
    FROM (values (1,2,3, 'fruit', current_timestamp - INTERVAL '5 seconds'), (4,5,6, 'veggie', current_timestamp)) as t(a,b,c,d,e);

  open _result_two for
    SELECT *
    FROM (values ('one'), ('two'), ('three'), ('four')) as p(name);

END;
$$;


ALTER PROCEDURE public.test_get_data(IN _itemid integer, INOUT _message text, INOUT _result_one refcursor, INOUT _result_two refcursor, INOUT _returncode text) OWNER TO d3l243;

