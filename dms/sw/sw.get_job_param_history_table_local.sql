--
-- Name: get_job_param_history_table_local(integer); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_param_history_table_local(_job integer) RETURNS TABLE(job integer, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a table of the job parameters stored locally in t_job_parameters_history
**
**  Auth:   mem
**  Date:   01/12/2012
**          04/11/2022 mem - Use varchar(4000) when populating the table
**          06/26/2022 mem - Ported to PostgreSQL
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
    -- See function get_job_param_table_local for additional examples
    ---------------------------------------------------

    /*
    -- Obtain a specific parameter value:
    --   '\\proto-8\QEHFX03\2022_2\'
    --
    SELECT unnest(xpath('//params/Param[@Name="DatasetStoragePath"]/@Value', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM sw.t_job_parameters_history
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
        FROM ( SELECT ('<params>' || JobParams.parameters::text || '</params>')::xml as rooted_xml
               FROM sw.t_job_parameters_history JobParams
               WHERE JobParams.job = _job
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
                _job, _exceptionMessage);

    RAISE Warning '%', _message;
    RAISE Warning '%', _exceptionContext;

    Call post_log_entry ('Error', _message, 'get_job_param_history_table_local', 'cap');

    -- In theory the error message could be returned using the following, but this doesn't work
    --   RETURN QUERY
    --   SELECT _job AS Job, 'Error_Message'::citext, _message::citext;
END
$$;


ALTER FUNCTION sw.get_job_param_history_table_local(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_param_history_table_local(_job integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_param_history_table_local(_job integer) IS 'GetJobParamHistoryTableLocal';

