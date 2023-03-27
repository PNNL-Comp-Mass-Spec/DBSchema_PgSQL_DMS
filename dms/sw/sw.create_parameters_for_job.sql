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
**          03/26/2023 mem - Update logic to handle data package based jobs (which should have dataset name 'Aggregation')
**
*****************************************************/
DECLARE
    _xmlParameters xml;
    _dataPackageID int;
    _section text;
    _name text;
    _value text;
BEGIN

    CREATE TEMP TABLE Tmp_Job_Parameters (
        Job int,
        Step_Number int,        -- This will be null for every row since get_job_param_table does not consider job step
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

    -- Check whether this job is a data package based job
    SELECT data_pkg_id
    INTO _dataPackageID
    FROM sw.T_Jobs
    WHERE Job = _job;

    If FOUND And _dataPackageID > 0 And Exists (SELECT * FROM sw.T_Job_Parameters WHERE Job = _job) Then

        ---------------------------------------------------
        -- This is a data package based job with existing parameters
        -- Selectively update the existing job parameters using the parameters in Tmp_Job_Parameters
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Job_Parameters_Merged (
            Job int,
            Step_Number int,        -- This will be null for every row since get_job_param_table does not consider job step
            Section text,
            Name text,
            Value text
        );

        -- Populate Tmp_Job_Parameters_Merged with the existing job parameters

        INSERT INTO Tmp_Job_Parameters_Merged (Job, Step_Number, Section, Name, Value)
        SELECT _job,
               Null,
               XmlQ.section,
               XmlQ.name,
               XmlQ.value
        FROM (
                SELECT xmltable.section,
                       xmltable.name,
                       xmltable.value
                FROM ( SELECT ('<params>' || parameters::text || '</params>')::xml as rooted_xml
                       FROM sw.t_job_parameters
                       WHERE sw.t_job_parameters.job = _job ) Src,
                     XMLTABLE('//params/Param'
                              PASSING Src.rooted_xml
                              COLUMNS section citext PATH '@Section',
                                      name citext PATH '@Name',
                                      value citext PATH '@Value')
             ) XmlQ;

        -- Update Tmp_Job_Parameters_Merged using selected rows in Tmp_Job_Parameters
        -- Only update settings that come from T_Analysis_Job

        CREATE TEMP TABLE Tmp_Job_Parameters_To_Update (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Section text,
            Name text
        );

        INSERT INTO Tmp_Job_Parameters_To_Update (Section, Name)
        VALUES ('JobParameters', 'DatasetID'),
               ('JobParameters', 'SettingsFileName'),
               ('PeptideSearch', 'LegacyFastaFileName'),
               ('PeptideSearch', 'OrganismName'),
               ('PeptideSearch', 'ParamFileName'),
               ('PeptideSearch', 'ParamFileStoragePath'),
               ('PeptideSearch', 'ProteinCollectionList'),
               ('PeptideSearch', 'ProteinOptions');

        FOR _section, _name IN
            SELECT Section, Name
            FROM Tmp_Job_Parameters_To_Update
            ORDER BY Entry_ID
        LOOP
            SELECT Value
            INTO _value
            FROM Tmp_Job_Parameters
            WHERE Section = _section AND Name = _name;

            If Not FOUND Then
                CONTINUE;
            End If;

            If Exists (Select * From Tmp_Job_Parameters_Merged WHERE Section = _section AND Name = _name) Then
                UPDATE Tmp_Job_Parameters_Merged
                SET Value = _value
                WHERE Section = _section AND Name = _name;
            Else
                INSERT INTO Tmp_Job_Parameters_Merged (Job, Section, Name, Value)
                VALUES (_job, _section, _name,  _value);
            End If;

        END LOOP;

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
               FROM Tmp_Job_Parameters_Merged
            ) AS LookupQ;

        DROP TABLE Tmp_Job_Parameters_Merged;
        DROP TABLE Tmp_Job_Parameters_To_Update;

    Else
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

    End If;

    DROP TABLE Tmp_Job_Parameters;

    RETURN _xmlParameters;
END
$$;


ALTER FUNCTION sw.create_parameters_for_job(_job integer, _settingsfileoverride text, _debugmode boolean) OWNER TO d3l243;

--
-- Name: FUNCTION create_parameters_for_job(_job integer, _settingsfileoverride text, _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.create_parameters_for_job(_job integer, _settingsfileoverride text, _debugmode boolean) IS 'CreateParametersForJob';

