--
-- Name: get_analysis_tool_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_analysis_tool_id(_toolname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets toolID for given analysis tool name
**
**  Return values: tool id if found, otherwise 0
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          10/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _toolID int;
BEGIN
    SELECT analysis_tool_id
    INTO _toolID
    FROM t_analysis_tool
    WHERE analysis_tool = _toolName::citext;

    If FOUND Then
        RETURN _toolID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_analysis_tool_id(_toolname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_analysis_tool_id(_toolname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_analysis_tool_id(_toolname text) IS 'GetAnalysisToolID';

