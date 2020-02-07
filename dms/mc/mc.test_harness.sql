--
-- Name: test_harness(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.test_harness() RETURNS TABLE(manager_name text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    _managerNameList TEXT := 'Pub-10-1, Pub-10-2, Pub-11-[1-5], Pub-12%';
    _message TEXT;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    DROP TABLE IF EXISTS TmpManagerList;

    CREATE TEMP TABLE TmpManagerList (
        manager_name text NOT NULL
     );

    CALL mc.ParseManagerNameList(_managerNameList, _removeUnknownManagers := 0, _message := _message);

    RAISE INFO '%', _message;

    RETURN Query
        SELECT * FROM TmpManagerList;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error calling udf_parse_delimited_list: ' || _exceptionMessage;

    RAISE Info '%', _message;
    RAISE Info 'Exception context; %', _exceptionContext;

    RAISE Exception '%, code %; see the output for context', _message, _sqlstate;

End
$$;


ALTER FUNCTION public.test_harness() OWNER TO d3l243;

