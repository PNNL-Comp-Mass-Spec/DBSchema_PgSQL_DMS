--
-- Name: check_plural(integer, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.check_plural(_count integer DEFAULT 0, _textifoneitem text DEFAULT 'item'::text, _textifzeroormultiple text DEFAULT 'items'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return _textIfOneItem if _count is 1; otherwise, returns _textIfZeroOrMultiple
**
**  Arguments:
**    _count                    Item count
**    _textIfOneItem            Text to return if item count is one
**    _textIfZeroOrMultiple     Text to return if item count is zero or more than one
**
**  Auth:   mem
**  Date:   03/05/2013 mem - Initial release
**          03/29/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**
*****************************************************/
BEGIN
    If Coalesce(_count, 0) = 1 Then
        RETURN _textIfOneItem;
    Else
        RETURN _textIfZeroOrMultiple;
    End If;
END
$$;


ALTER FUNCTION public.check_plural(_count integer, _textifoneitem text, _textifzeroormultiple text) OWNER TO d3l243;

--
-- Name: FUNCTION check_plural(_count integer, _textifoneitem text, _textifzeroormultiple text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.check_plural(_count integer, _textifoneitem text, _textifzeroormultiple text) IS 'CheckPlural';

