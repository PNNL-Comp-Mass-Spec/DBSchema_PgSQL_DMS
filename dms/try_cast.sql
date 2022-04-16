--
-- Name: try_cast(text, anyelement); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.try_cast(_in text, INOUT _out anyelement) RETURNS anyelement
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
/****************************************************
**
**  Desc:   Tries to convert parameter _in to the data type of the _out parameter
**
**          If successful, _out will contain the converted value
**          If unsuccessful, _out will contain the original value (i.e., the default value)
**
**  Example usage:
**      select _out from try_cast('2343', 0);                       -- 2343
**      select _out from try_cast('2343.53', 0);                    -- 0
**      select _out from try_cast('2343.53', 0.0);                  -- 2343.53
**      select _out from try_cast('test', 0);                       -- 0
**      select _out from try_cast('test', 5);                       -- 5
**      select _out from try_cast('true', false);                   -- true
**      select _out from try_cast('na', false);                     -- false
**      select _out from try_cast(null, 0);                         -- NULL
**      select _out from try_cast('2022-01-01', NULL::timestamp);   -- 2022-01-01
**      select _out from try_cast('2022-01-01', CURRENT_DATE);      -- 2022-01-01
**      select _out from try_cast('invalid', CURRENT_DATE);         -- 2022-04-15
**
**  Auth:   Erwin Brandstetter
**  Date:   04/15/2022 mem - Initial version, from https://dba.stackexchange.com/a/203986/122858
**
*****************************************************/
BEGIN
    EXECUTE format('SELECT %L::%s', _in, pg_typeof(_out))
    INTO _out;
EXCEPTION
    WHEN OTHERS THEN
        -- do nothing: _out already has the default value
END
$$;


ALTER FUNCTION public.try_cast(_in text, INOUT _out anyelement) OWNER TO d3l243;

