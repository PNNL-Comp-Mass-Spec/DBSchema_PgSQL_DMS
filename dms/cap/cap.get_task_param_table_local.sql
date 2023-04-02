--
-- Name: get_task_param_table_local(integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_param_table_local(_job integer) RETURNS TABLE(job integer, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns a table of the capture task job parameters stored locally in t_task_parameters
**
**  Auth:   grk
**  Date:   06/07/2010
**          04/04/2011 mem - Updated to only query T_Job_Parameters
**          06/24/2022 mem - Ported to PostgreSQL
**          06/26/2022 mem - Renamed from get_task_param_table_local to get_task_param_table_local
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          04/02/2023 mem - Rename procedure and functions
**
*****************************************************/
DECLARE
    _message citext;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- The following demonstrates how we could use XPath to query the XML for one or more parameters
    --
    -- The XML we are querying looks like:
    --   <Param Section="JobParameters" Name="Created" Value="Mar 28 2022 11:11AM"/>
    --   <Param Section="JobParameters" Name="Dataset_ID" Value="1016870"/>
    --   <Param Section="JobParameters" Name="Storage_Server_Name" Value="proto-4"/>
    --   <Param Section="JobParameters" Name="TransferDirectoryPath" Value="\\proto-4\DMS3_Xfer\"/>
    ---------------------------------------------------

    /*
    -- Obtain all of the parameters, with one row per parameter, for example:
    --   '<Param Section="JobParameters" Name="Dataset_ID" Value="1016870"/>'
    --   '<Param Section="JobParameters" Name="Storage_Server_Name" Value="proto-4"/>'
    --
    SELECT unnest(xpath('//params/Param', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM cap.t_task_parameters
           WHERE job = _job
         ) Src;

    -- Obtain a single parameter:
    --   '<Param Section="JobParameters" Name="Storage_Server_Name" Value="proto-4"/>'
    --
    SELECT unnest(xpath('//params/Param[@Name="Storage_Server_Name"]', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM cap.t_task_parameters
           WHERE job = _job
         ) Src;

    -- Obtain the parameter value:
    --   'proto-4'
    --
    SELECT unnest(xpath('//params/Param[@Name="Storage_Server_Name"]/@Value', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM cap.t_task_parameters
           WHERE job = _job
         ) Src;

    */

    ---------------------------------------------------
    -- Convert the XML job parameters into a table
    -- We must surround the job parameter XML with <params></params> so that the XML will be rooted, as required by XMLTABLE()
    ---------------------------------------------------
    --
    RETURN QUERY
    SELECT _job AS Job, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || TaskParams.parameters::text || '</params>')::xml as rooted_xml
               FROM cap.t_task_parameters TaskParams
               WHERE TaskParams.job = _job
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

    RETURN;

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

    RETURN QUERY
    SELECT _job AS Job, 'Error_Message'::citext, _message::citext;
END
$$;


ALTER FUNCTION cap.get_task_param_table_local(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_param_table_local(_job integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_param_table_local(_job integer) IS 'GetJobParamTableLocal';

