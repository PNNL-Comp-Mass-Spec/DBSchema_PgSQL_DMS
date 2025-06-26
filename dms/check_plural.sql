--
-- Name: check_plural(integer, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

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

--
-- Name: check_plural(text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.check_plural(_itemlist text DEFAULT ''::text, _textifoneitem text DEFAULT 'item'::text, _textifzeroormultiple text DEFAULT 'items'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return _textIfOneItem if _count is 1; otherwise, returns _textIfZeroOrMultiple
**
**  Arguments:
**    _itemList                 Comma separated list of items
**    _textIfOneItem            Text to return if _itemList does not have a comma
**    _textIfZeroOrMultiple     Text to return if _itemList has a comma
**
**  Auth:   mem
**  Date:   06/25/2025 mem - Overloaded version function check_plural() that accepts an integer
**
*****************************************************/
BEGIN
    If Coalesce(_itemList, '') LIKE '%,%' OR Coalesce(_itemList, '') = '' Then
        RETURN _textIfZeroOrMultiple;
    Else
        RETURN _textIfOneItem;
    End If;
END
$$;


ALTER FUNCTION public.check_plural(_itemlist text, _textifoneitem text, _textifzeroormultiple text) OWNER TO d3l243;

