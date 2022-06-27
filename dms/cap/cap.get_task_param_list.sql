--
-- Name: get_task_param_list(integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_param_list(_job integer) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Converts XML parameters for given capture task job into text surrounded by HTML tags <pre> and </pre>
**
**      Additionally, each parameter will end with <br>,
**      producing a table-style layout on the Capture Jobs Detail Report
**
**  Return value: delimited list
**
**  Auth:   grk
**  Date:   01/27/2010
**          06/24/2022 mem - Ported to PostgreSQL
**          06/26/2022 mem - Renamed from get_job_param_list to get_task_param_list
**
*****************************************************/
DECLARE
    _result citext;
    _sqlState text;
    _message text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    If _job Is Null Then
        Return '';
    End If;

    -- The XMLTABLE function can convert XML into a table, however you must have a root node
    -- If a root node is not present, the error shown is:
    --   ERROR: could not parse XML document
    --   Detail: line 1: Extra content at the end of the document
    --
    -- The following adds a root node then converts the XML into a table
    -- Next, string_agg() is used to concatenate the fields
    --
    SELECT string_agg(
        'Section="' || XmlQ.section ||
        '" Name="' || XmlQ.name ||
        '" Value="' || XmlQ.value || '"', '<br>' ORDER BY XmlQ.section, XmlQ.name)
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

    Return  '<pre>' || _result || '</pre>';

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Error converting XML job parameters to text using XMLTABLE() for job %s: %s',
                _job, _exceptionMessage);

    RAISE Warning '%', _message;
    RAISE warning '%', _exceptionContext;

    Call post_log_entry ('Error', _message, 'get_task_param_list', 'cap');

    -- Use text parsing to convert the XML job parameters
    --
    SELECT
        '<pre>' || parameters::text || '</pre>'
    INTO _result
    FROM cap.t_task_parameters
    WHERE job = _job;

    -- Replace the XML tags with HTML tags
    --
    _result := REPLACE(_result, '<Param', '');
    _result := REPLACE(_result, '/>', '<br>');

    Return _result;
END
$$;


ALTER FUNCTION cap.get_task_param_list(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_param_list(_job integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_param_list(_job integer) IS 'GetJobParamList';

