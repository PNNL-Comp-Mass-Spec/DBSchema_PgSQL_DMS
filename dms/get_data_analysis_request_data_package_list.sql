--
-- Name: get_data_analysis_request_data_package_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_data_analysis_request_data_package_list(_dataanalysisrequestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of data package IDs associated with the given data analysis request
**
**  Arguments:
**    _dataAnalysisRequestID    Data analysis request ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   10/11/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(data_pkg_id::text, ', ' ORDER BY data_pkg_id)
    INTO _result
    FROM t_data_analysis_request_data_package_ids
    WHERE request_id = _dataAnalysisRequestID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_data_analysis_request_data_package_list(_dataanalysisrequestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_data_analysis_request_data_package_list(_dataanalysisrequestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_data_analysis_request_data_package_list(_dataanalysisrequestid integer) IS 'GetDataAnalysisRequestDataPackageList';

