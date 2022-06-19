--
-- Name: get_analysis_tool_allowed_dataset_type_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_analysis_tool_allowed_dataset_type_list(_analysistoolid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of allowed dataset types
**      for the given analysis tool
**
**  Return value: comma separated list
**
**  Auth:   mem
**  Date:   12/18/2009
**          06/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(Dataset_Type, ', ' ORDER BY Dataset_Type)
    INTO _result
    FROM t_analysis_tool_allowed_dataset_type
    WHERE analysis_tool_id = _analysisToolID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_analysis_tool_allowed_dataset_type_list(_analysistoolid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_analysis_tool_allowed_dataset_type_list(_analysistoolid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_analysis_tool_allowed_dataset_type_list(_analysistoolid integer) IS 'GetAnalysisToolAllowedDSTypeList';

