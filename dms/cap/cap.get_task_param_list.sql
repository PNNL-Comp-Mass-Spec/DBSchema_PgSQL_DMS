--
-- Name: get_task_param_list(integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_param_list(_job integer) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Convert XML parameters for given capture task job into text surrounded by HTML tags <pre> and </pre>
**
**      Additionally, each parameter will end with <br>,
**      producing a table-style layout on the Capture Jobs Detail Report
**
**  Return value: delimited list
**
**  Auth:   grk
**  Date:   01/27/2010
**          06/24/2022 mem - Ported to PostgreSQL
**          06/26/2022 mem - Renamed from get_task_param_list to get_task_param_list
**          06/28/2022 mem - Add <br> before </pre>
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          04/02/2023 mem - Rename procedure and functions
**          05/22/2023 mem - Capitalize reserved word
**          05/31/2023 mem - Use format() for string concatenation
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _result citext;

    _sqlState text;
    _message text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    If _job Is Null Then
        RETURN '';
    End If;

    -- The XMLTABLE function can convert XML into a table, however you must have a root node
    -- If a root node is not present, the error shown is:
    --   ERROR: could not parse XML document
    --   Detail: line 1: Extra content at the end of the document
    --
    -- The following adds a root node then converts the XML into a table
    -- Next, string_agg() is used to concatenate the fields
    --
    SELECT string_agg(format('Section="%s" Name="%s" Value="%s"', XmlQ.section, XmlQ.name, XmlQ.value), '<br>' ORDER BY XmlQ.section, XmlQ.name)
    INTO _result
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
               FROM cap.T_task_Parameters
               WHERE job = _job
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section text PATH '@Section',
                              name text PATH '@Name',
                              value text PATH '@Value')
         ) XmlQ;

    RETURN format('<pre>%s<br></pre>', _result);

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    format('XML parameter formatting for capture task job %s', _job),
                    _logError => true);

    -- Use text parsing to convert the XML job parameters
    --
    SELECT format('<pre>%s</pre>', parameters)
    INTO _result
    FROM cap.t_task_parameters
    WHERE job = _job;

    -- Replace the XML tags with HTML tags
    --
    _result := Replace(_result, '<Param', '');
    _result := Replace(_result, '/>', '<br>');

    RETURN _result;
END
$$;


ALTER FUNCTION cap.get_task_param_list(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_param_list(_job integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_param_list(_job integer) IS 'GetTaskParamList or GetJobParamList';

