--
-- Name: get_job_param_table_local(integer); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_param_table_local(_job integer) RETURNS TABLE(job integer, section public.citext, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table of the job parameters stored locally in either sw.t_job_parameters or sw.t_job_parameters_history
**
**  Arguments:
**    _job      Job number
**
**  Auth:   grk
**  Date:   06/07/2010
**          04/04/2011 mem - Updated to only query t_job_parameters
**          06/26/2022 mem - Ported to PostgreSQL
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          06/13/2023 mem - Add section name column to the output table
**                         - Look for the job in sw.t_job_parameters_history if not found in sw.t_job_parameters
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _xmlParameters xml;
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
    --   <Param Section="JobParameters" Name="DatasetID" Value="1042743" />
    --   <Param Section="JobParameters" Name="DatasetNum" Value="QC_Mam_19_01-run02_31May22_Remus_WBEH-22-04-09" />
    --   <Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\QEHFX03\2022_2\" />
    --   <Param Section="JobParameters" Name="ToolName" Value="MASIC_Finnigan" />
    --   <Param Section="PeptideSearch" Name="ParamFileName" Value="LTQ-FT_10ppm_2014-08-06.xml" />
    ---------------------------------------------------

    /*
    -- Obtain all of the parameters, with one row per parameter, for example:
    --   '<Param Section="JobParameters" Name="DatasetID" Value="1042743"/>'
    --   '<Param Section="JobParameters" Name="DatasetFolderName" Value="QC_Mam_19_01-run02_31May22_Remus_WBEH-22-04-09"/>'
    --   '<Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\QEHFX03\2022_2\"/>'

    SELECT unnest(xpath('//params/Param', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM sw.t_job_parameters
           WHERE job = _job
         ) Src;

    -- Obtain a single parameter:
    --   '<Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\QEHFX03\2022_2\"/>'

    SELECT unnest(xpath('//params/Param[@Name="DatasetStoragePath"]', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM sw.t_job_parameters
           WHERE job = _job
         ) Src;

    -- Obtain the parameter value:
    --   '\\proto-8\QEHFX03\2022_2\'

    SELECT unnest(xpath('//params/Param[@Name="DatasetStoragePath"]/@Value', rooted_xml))::text
    FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
           FROM sw.t_job_parameters
           WHERE job = _job
         ) Src;
    */

    ---------------------------------------------------
    -- Lookup the job parameters
    ---------------------------------------------------

    SELECT Src.parameters
    INTO _xmlParameters
    FROM sw.t_job_parameters Src
    WHERE Src.job = _job;

    If Not FOUND Then
        SELECT Src.parameters
        INTO _xmlParameters
        FROM sw.t_job_parameters_history Src
        WHERE Src.job = _job AND
              Src.most_recent_entry = 1;

        If Not FOUND Then
            RAISE WARNING 'Job % not found in sw.t_job_parameters or sw.t_job_parameters_history', _job;
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Convert the XML job parameters into a table
    -- We must surround the job parameter XML with <params></params> so that the XML will be rooted, as required by XMLTABLE()
    ---------------------------------------------------

    RETURN QUERY
    SELECT _job AS Job, Trim(XmlQ.section)::citext, Trim(XmlQ.name)::citext, Trim(XmlQ.value)::citext
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _xmlParameters::text || '</params>')::xml as rooted_xml
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section text PATH '@Section',
                              name    text PATH '@Name',
                              value   text PATH '@Value')
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
                    format('get job parameters for job %s', _job),
                    _logError => true);

    RETURN QUERY
    SELECT _job AS Job, 'Error_Message'::citext, _message::citext, _message::citext;
END
$$;


ALTER FUNCTION sw.get_job_param_table_local(_job integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_param_table_local(_job integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_param_table_local(_job integer) IS 'GetJobParamTableLocal';

