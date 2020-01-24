--
-- Name: test_temp_tables(integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE PROCEDURE public.test_temp_tables(_rowstoadd integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _rowcount integer;
    _rowsAdded integer;
BEGIN  
    CREATE TEMP TABLE tmpCustomers(customer_id INT);

    _rowsAdded := 0;
    
    While _rowsAdded < _rowsToAdd Loop
        INSERT INTO tmpCustomers (customer_id) VALUES (_rowsAdded + 1);
        GET DIAGNOSTICS _rowcount = ROW_COUNT;
    
        If _rowcount < 1 Then
            RAISE NOTICE 'Did not add a row to tmpCustomers';
        Else
            RAISE NOTICE 'Added one row to tmpCustomers';
        End If;
                    
        _rowsAdded := _rowsAdded + 1;

    End Loop;
    
    RAISE INFO 'Rows inserted into tmpCustomers: %', _rowsAdded;

    DROP TABLE tmpCustomers;
END
$$;


ALTER PROCEDURE public.test_temp_tables(_rowstoadd integer) OWNER TO d3l243;

