--
-- Name: get_job_step_params_xml(integer, integer, integer); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_step_params_xml(_job integer, _step integer, _jobisrunningremote integer DEFAULT 0) RETURNS xml
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get job step parameters for given job step, formatted as XML
**
**      Data comes from sw.T_Job_Parameters, not from the public tables
**
**  Arguments:
**    _job                  Job number
**    _step                 Step number
**    _jobIsRunningRemote   Request_Step_Task_XML will set this to 1 if the newly started job step was state 9
**
**  Example Results:
**      <sections>
**        <section name="JobParameters">
**          <item key="DataPackageID" value="0" />
**          <item key="DatasetID" value="1110297" />
**          <item key="DatasetType" value="HMS-HCD-HMSn" />
**          <item key="Instrument" value="Eclipse02" />
**        </section>
**        <section name="MSGFPlus">
**          <item key="MSGFPlusJavaMemorySize" value="4000" />
**          <item key="MSGFPlusThreads" value="all" />
**        </section>
**        <section name="StepParameters">
**          <item key="Job" value="2131747" />
**          <item key="Step" value="1" />
**          <item key="StepTool" value="MSXML_Gen" />
**        </section>
**      </sections>
**
**  Auth:   grk
**  Date:   12/11/2008 grk - Initial release
**          01/14/2009 mem - Increased the length of the Value entries extracted from T_Job_Parameters to be 2000 characters (nvarchar(4000)), Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714
**          05/29/2009 mem - Added parameter _debugMode
**          12/04/2009 mem - Moved the code that defines the job parameters to GetJobStepParamsWork
**          05/11/2017 mem - Add parameter _jobIsRunningRemote
**          05/13/2017 mem - Only add RunningRemote to Tmp_JobParamsTable if _jobIsRunningRemote is non-zero
**          06/08/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _xmlParameters xml;
BEGIN

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobParamsTable (
        Section text,
        Name text,
        Value text
    );

    ---------------------------------------------------
    -- Query get_job_step_params_work to populate the temporary table
    ---------------------------------------------------

    INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
    SELECT Src.Section, Src.Name, Src.Value
    FROM sw.get_job_step_params_work (_job, _step) Src;

    If Not FOUND Then
        DROP TABLE Tmp_JobParamsTable;
        RETURN null;
    End If;

    If (Coalesce(_jobIsRunningRemote, 0) > 0) Then
        INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
        VALUES ('StepParameters', 'RunningRemote', _jobIsRunningRemote);
    End If;

    ---------------------------------------------------
    -- Convert the analysis job parameters to XML
    ---------------------------------------------------

    SELECT xml_item
    INTO _xmlParameters
    FROM ( SELECT
             XMLELEMENT(name "sections",
               XMLAGG(XMLELEMENT(NAME "section", XMLATTRIBUTES(Sections.Section As "name"),
                 (SELECT XMLAGG(XMLELEMENT(
                                NAME "item",
                                XMLATTRIBUTES(
                                     Src.Name As "key",
                                     Src.Value As "value")))
                  FROM Tmp_JobParamsTable Src
                  WHERE Sections.Section = Src.Section))
               )
             ) AS xml_item
           FROM (SELECT Section
                 FROM Tmp_JobParamsTable
                 GROUP BY Section
                 ORDER BY Section
                 ) Sections
         ) AS LookupQ;

    DROP TABLE Tmp_JobParamsTable;

    RETURN _xmlParameters;

END
$$;


ALTER FUNCTION sw.get_job_step_params_xml(_job integer, _step integer, _jobisrunningremote integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_step_params_xml(_job integer, _step integer, _jobisrunningremote integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_step_params_xml(_job integer, _step integer, _jobisrunningremote integer) IS 'GetJobStepParamsXML';

