--
-- Name: get_job_param_table_local(integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_job_param_table_local(_jobnumber integer) RETURNS TABLE(job integer, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns a table of the job parameters stored locally in T_Job_Parameters
**
**  Auth:   grk
**  Date:   06/07/2010
**          04/04/2011 mem - Updated to only query T_Job_Parameters
**          06/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message citext;
    _sqlState text;
    _exceptionMessage citext;
    _exceptionContext citext;
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
    SELECT unnest(xpath('//params/Param[@Name="Storage_Server_Name"]', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM cap.T_task_Parameters
           WHERE job = _jobNumber
         ) Src;

    -- Obtain a single parameter:
    --   '<Param Section="JobParameters" Name="Storage_Server_Name" Value="proto-4"/>'
    SELECT unnest(xpath('//params/Param[@Name="Storage_Server_Name"]', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM cap.T_task_Parameters
           WHERE job = _jobNumber
         ) Src;

    -- Obtain the parameter value:
    -- 'proto-4'
    SELECT unnest(xpath('//params/Param[@Name="Storage_Server_Name"]/@Value', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM cap.T_task_Parameters
           WHERE job = _jobNumber
         ) Src;

    */

    ---------------------------------------------------
    -- Convert the XML job parameters into a table
    ---------------------------------------------------
    --
    RETURN QUERY
    SELECT _jobNumber AS Job, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || TaskParams.parameters::text || '</params>')::xml as rooted_xml
               FROM cap.t_task_parameters TaskParams
               WHERE TaskParams.job = _jobNumber
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Error converting XML job parameters to text using XMLTABLE() for job %s: %s',
                _jobNumber, _exceptionMessage);

    RAISE Warning '%', _message;
    RAISE Warning '%', _exceptionContext;

    Call post_log_entry ('Error', _message, 'get_job_param_table_local', 'cap');

    -- In theory the error message could be returned using the following, but this doesn't work
    --   RETURN QUERY
    --   SELECT _jobNumber AS Job, 'Error_Message'::citext, _message::citext;
END
$$;


ALTER FUNCTION cap.get_job_param_table_local(_jobnumber integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_param_table_local(_jobnumber integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_job_param_table_local(_jobnumber integer) IS 'GetJobParamTableLocal';

