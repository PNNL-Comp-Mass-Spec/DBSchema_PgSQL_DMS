--
-- Name: try_cast(text, anyelement); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.try_cast(_in text, INOUT _out anyelement) RETURNS anyelement
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**
**  Desc:
**  	Tries to convert parameter _in to the data type of the _out parameter
**
**      If successful, _out will contain the converted value
**      If unsuccessful, _out will contain the original value (i.e., the default value)
**
**      Note: this function uses an exception handler to catch conversion errors, and thus it should not be used when performance is an issue
**
**  Example usage:
**      SELECT _out FROM try_cast('2343', 0);                       -- 2343
**      SELECT _out FROM try_cast('2343', null::int);               -- 2343
**      SELECT _out FROM try_cast('2343.53', 0);                    -- 0 since '2343.53'::int throws an exception, then this function returns 0
**      SELECT _out FROM try_cast('2343.53', 0.0);                  -- 2343.53
**      SELECT _out FROM try_cast('test', 0);                       -- 0 since 'test'::int throws an exception, then this function returns 0
**      SELECT _out FROM try_cast('test', 5);                       -- 5 since 'test'::int throws an exception, then this function returns 5
**      SELECT _out FROM try_cast('true', false);                   -- true
**      SELECT _out FROM try_cast('na', false);                     -- false since 'na'::boolean throws an exception, then this function returns false
**      SELECT _out FROM try_cast(0::text, false);                  -- false since '0'::boolean is false
**      SELECT _out FROM try_cast(1::text, false);                  -- true  since '1'::boolean is true
**      SELECT _out FROM try_cast(2::text, false);                  -- false since '2'::boolean throws an exception, then this function returns false
**      SELECT _out FROM try_cast(2::text, true);                   -- true  since '2'::boolean throws an exception,  then this function returns true
**      SELECT _out FROM try_cast(null, 0);                         -- null
**      SELECT _out FROM try_cast('2022-01-01', null::timestamp);   -- 2022-01-01
**      SELECT _out FROM try_cast('2022-01-01', CURRENT_DATE);      -- 2022-01-01
**      SELECT _out FROM try_cast('invalid', CURRENT_DATE);         -- The value of CURRENT_DATE (e.g. 2023-10-02), since 'invalid'::timestamp throws an exception
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

--
-- Name: try_cast(text, boolean, anyelement); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.try_cast(_in text, _nullifinvalid boolean, INOUT _out anyelement) RETURNS anyelement
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**
**  Desc:
**  	Tries to convert parameter _in to the data type of the _out parameter
**
**      If successful, _out will contain the converted value
**      If unsuccessful, _out will contain null if _nullIfInvalid is true, or the original value (i.e., the default value)
**
**      Note: this function uses an exception handler to catch conversion errors, and thus it should not be used when performance is an issue
**
**  Example usage:
**      SELECT _out FROM try_cast('2343', false, 0);                       -- 2343
**      SELECT _out FROM try_cast('2343', false, null::int);               -- 2343
**      SELECT _out FROM try_cast('2343.53', false, 0);                    -- 0    since '2343.53'::int throws an exception, then this function returns 0
**      SELECT _out FROM try_cast('2343.53', true,  0);                    -- null since '2343.53'::int throws an exception, but _nullIfInvalid is true, so this function returns null
**      SELECT _out FROM try_cast('2343.53', false, 0.0);                  -- 2343.53
**      SELECT _out FROM try_cast('test', false, 0);                       -- 0    since 'test'::int throws an exception, then this function returns 0
**      SELECT _out FROM try_cast('test', true,  0);                       -- null since 'test'::int throws an exception, but _nullIfInvalid is true
**      SELECT _out FROM try_cast('test', false, 5);                       -- 5    since 'test'::int throws an exception, then this function returns 5
**      SELECT _out FROM try_cast('true', false, false);                   -- true
**      SELECT _out FROM try_cast('na', false, false);                     -- false since 'na'::boolean throws an exception, then this function returns false
**      SELECT _out FROM try_cast('na', true,  false);                     -- null  since 'na'::boolean throws an exception, but _nullIfInvalid is true
**      SELECT _out FROM try_cast(0::text, false, false);                  -- false since '0'::boolean is false
**      SELECT _out FROM try_cast(1::text, false, false);                  -- true  since '1'::boolean is true
**      SELECT _out FROM try_cast(2::text, false, false);                  -- false since '2'::boolean throws an exception, then this function returns false
**      SELECT _out FROM try_cast(2::text, false, true);                   -- true  since '2'::boolean throws an exception, then this function returns true
**      SELECT _out FROM try_cast(2::text, true, true);                    -- null  since '2'::boolean throws an exception, but _nullIfInvalid is true
**      SELECT _out FROM try_cast(null, false, 0);                         -- null
**      SELECT _out FROM try_cast(null, true,  0);                         -- null
**      SELECT _out FROM try_cast('2022-01-01', false, null::timestamp);   -- 2022-01-01
**      SELECT _out FROM try_cast('2022-01-01', false, CURRENT_DATE);      -- 2022-01-01
**      SELECT _out FROM try_cast('invalid', false, CURRENT_DATE);         -- The value of CURRENT_DATE (e.g. 2023-10-02), since 'invalid'::timestamp throws an exception and _nullIfInvalid is false
**      SELECT _out FROM try_cast('invalid', true,  CURRENT_DATE);         -- null since 'invalid'::timestamp throws an exception, but _nullIfInvalid is true
**
**  Auth:   Erwin Brandstetter
**  Date:   04/15/2022 mem - Initial version, from https://dba.stackexchange.com/a/203986/122858
**          06/21/2022 mem - Create new function that overloads public.try_cast(), adding argument _nullIfInvalid
**
*****************************************************/
BEGIN
    EXECUTE format('SELECT %L::%s', _in, pg_typeof(_out))
    INTO _out;
EXCEPTION
    WHEN OTHERS THEN

        If _nullIfInvalid Then
            _out = null;
        Else
            -- do nothing: _out already has the default value
        End If;
END
$$;


ALTER FUNCTION public.try_cast(_in text, _nullifinvalid boolean, INOUT _out anyelement) OWNER TO d3l243;

