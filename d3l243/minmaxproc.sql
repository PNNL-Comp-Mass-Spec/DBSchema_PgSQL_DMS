--
-- Name: minmaxproc(integer, integer, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.minmaxproc(a integer, b integer, c integer, INOUT min integer, INOUT max integer)
    LANGUAGE plpgsql
    AS $$
/******************
**
**  Desc: This procedure finds the min and max values of three integers
**
******************/
DECLARE
    _minvalue integer;
BEGIN
    _minvalue := least(a, b, c);
    min := _minvalue;
    max := greatest(a, b, c);
END
$$;


ALTER PROCEDURE public.minmaxproc(a integer, b integer, c integer, INOUT min integer, INOUT max integer) OWNER TO d3l243;

--
-- Name: PROCEDURE minmaxproc(a integer, b integer, c integer, INOUT min integer, INOUT max integer); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON PROCEDURE public.minmaxproc(a integer, b integer, c integer, INOUT min integer, INOUT max integer) TO readaccess;

