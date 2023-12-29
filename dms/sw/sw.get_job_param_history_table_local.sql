--
-- Name: get_job_param_history_table_local(integer); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_param_history_table_local(_job integer) RETURNS TABLE(job integer, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table of the job parameters stored locally in t_job_parameters_history
**
**  Auth:   mem
**  Date:   01/12/2012
**          04/11/2022 mem - Use varchar(4000) when populating the table
**          06/26/2022 mem - Ported to PostgreSQL
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          11/15/2022 mem - Add second example query
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
    -- See function get_job_param_table_local for additional examples
    ---------------------------------------------------

    /*
    -- \\proto-3\QEHFX01\2022_1\
    --
    SELECT unnest(xpath('//params/Param[@Name="DatasetStoragePath"]/@Value', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM sw.t_job_parameters_history
           WHERE job = 2014771
         ) Src;

    -- \\proto-3\DMS3_Xfer\
    --
    SELECT ((xpath('//params/Param[@Name = "TransferFolderPath"]/@Value', rooted_xml))[1])::text
    FROM ( SELECT ('<root>' || parameters::text || '</root>')::xml as rooted_xml
           FROM sw.t_job_parameters_history
           WHERE job = 2014771) FilterQ;

    */

    ---------------------------------------------------
    -- Convert the XML job parameters into a table
    -- We must surround the job parameter XML with <params></params> so that the XML will be rooted, as required by XMLTABLE()
    ---------------------------------------------------

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
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    format('get job history parameters for job %s', _job),
                    _logError => true);

    RETURN QUERY
    SELECT _job AS Job, 'Error_Message'::citext, _message::citext;
END
$$;


ALTER FUNCTION sw.get_job_param_history_table_local(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_param_history_table_local(_job integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_param_history_table_local(_job integer) IS 'GetJobParamHistoryTableLocal';

