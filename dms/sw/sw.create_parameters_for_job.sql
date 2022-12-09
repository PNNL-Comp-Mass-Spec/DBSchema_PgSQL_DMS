--
-- Name: create_parameters_for_job(integer, text, boolean); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.create_parameters_for_job(_job integer, _settingsfileoverride text DEFAULT ''::text, _debugmode boolean DEFAULT false) RETURNS xml
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Format parameters for given job as XML
**
**  Arguments:
**    _job                    Job number to obtain parameters for (should exist in sw.t_jobs, but not required)
**    _settingsFileOverride   When defined, will use this settings file name instead of the one obtained with public.v_get_pipeline_job_parameters (in get_job_param_table)
**    _debugMode              When true, show additional debug messages
**
**  Example usage:
**
**      SELECT * FROM sw.create_parameters_for_job(2023504);
**      SELECT create_parameters_for_job::text FROM sw.create_parameters_for_job(2023504);
**      SELECT * FROM sw.create_parameters_for_job(2023504, '', true);
**      SELECT * FROM sw.create_parameters_for_job(2023504, 'IonTrapDefSettings_MzML_StatCysAlk_16plexTMT.xml', true);
**
**  Auth:   grk
**          01/31/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/08/2009 mem - Added parameter _debugMode
**          06/01/2009 mem - Switched from S_GetJobParamTable (which pointed to a stored procedure in DMS5)
**                           to GetJobParamTable, which is local to this database (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          01/05/2010 mem - Added parameter _settingsFileOverride
**          10/14/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _xmlParameters xml;
BEGIN

    CREATE TEMP TABLE Tmp_Job_Parameters (
        Job int,
        Step_Number int,
        Section text,
        Name text,
        Value text
    );

    ---------------------------------------------------
    -- Get job parameters from public schema tables
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Job_Parameters (Job, Step_Number, Section, Name, Value)
    SELECT Job, null, Section, Name, Value
    FROM sw.get_job_param_table(_job, _settingsFileOverride, _debugMode => _debugMode);

    ---------------------------------------------------
    -- Convert the job parameters to XML
    ---------------------------------------------------
    --
    SELECT xml_item
    INTO _xmlParameters
    FROM ( SELECT
             XMLAGG(XMLELEMENT(
                    NAME "Param",
                    XMLATTRIBUTES(
                        section As "Section",
                        name As "Name",
                        value As "Value"))
                    ORDER BY section, name
                   ) AS xml_item
           FROM Tmp_Job_Parameters
        ) AS LookupQ;

    DROP TABLE Tmp_Job_Parameters;

    RETURN _xmlParameters;
END
$$;


ALTER FUNCTION sw.create_parameters_for_job(_job integer, _settingsfileoverride text, _debugmode boolean) OWNER TO d3l243;

--
-- Name: FUNCTION create_parameters_for_job(_job integer, _settingsfileoverride text, _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.create_parameters_for_job(_job integer, _settingsfileoverride text, _debugmode boolean) IS 'CreateParametersForJob';

