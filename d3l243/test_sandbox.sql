--
-- Name: test_sandbox(integer, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.test_sandbox(a integer, b integer, c integer, INOUT _min integer)
    LANGUAGE plpgsql
    AS $$
/******************
**
**  Desc: Testing sandbox
**
******************/
DECLARE
    _minvalue integer;
    _rowcount integer;
    _firstName text;
BEGIN
    _minvalue := least(a, b, c);
    GET DIAGNOSTICS _rowcount = ROW_COUNT;
    RAISE INFO 'Rowcount: %', _rowcount;

    _min := _minvalue;

    PERFORM _firstName = first_name
    FROM people
    WHERE last_name like 'f%';
    GET DIAGNOSTICS _rowcount = ROW_COUNT;
    RAISE INFO 'Rowcount: %', _rowcount;

    CREATE TEMP TABLE tmpCustomers(customer_id INT);

    INSERT INTO tmpCustomers (customer_id) VALUES (5), (6), (7);
    GET DIAGNOSTICS _rowcount = ROW_COUNT;
    RAISE INFO 'Rows inserted into tmpCustomers: %', _rowcount;

    DROP TABLE tmpCustomers;
END
$$;


ALTER PROCEDURE public.test_sandbox(a integer, b integer, c integer, INOUT _min integer) OWNER TO d3l243;

