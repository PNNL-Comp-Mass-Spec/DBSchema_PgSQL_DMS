--
-- Name: tinyint_to_enabled_disabled(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.tinyint_to_enabled_disabled(_value integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the text 'Disabled' if _value is 0 or null, otherwise returns 'Enabled'
**
**  Auth:   mem
**  Date:   11/14/2012 mem - Initial version
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    RETURN CASE
               WHEN Coalesce(_value, 0) = 0 THEN 'Disabled'
               ELSE 'Enabled'
           END;
END
$$;


ALTER FUNCTION public.tinyint_to_enabled_disabled(_value integer) OWNER TO d3l243;

--
-- Name: FUNCTION tinyint_to_enabled_disabled(_value integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.tinyint_to_enabled_disabled(_value integer) IS 'TinyintToEnabledDisabled';

