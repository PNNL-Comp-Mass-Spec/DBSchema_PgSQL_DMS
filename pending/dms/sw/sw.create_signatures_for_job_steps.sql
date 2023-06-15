--
CREATE OR REPLACE PROCEDURE sw.create_signatures_for_job_steps
(
    _job int,
    _xmlParameters xml,
    _datasetOrDataPackageId int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create signatures for job steps
**
**      The calling procedure must have created and populated temporary table Tmp_Job_Steps,
**      which must include these columns:
**
**      CREATE TEMP TABLE Tmp_Job_Steps (
**          Job int NOT NULL,
**          Step int NOT NULL,
**          tool text NOT NULL,
**          Shared_Result_Version int NULL,
**          Signature int NULL,
**          Input_Directory_Name text NULL,
**          Output_Directory_Name text NULL
**      )
**
**  Auth:   grk
**  Date:   01/30/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/08/2009 mem - Added parameter _debugMode
**          12/21/2009 mem - Added warning message if _debugMode is non-zero and a signature cannot be computed for a step tool
**          03/22/2011 mem - Now using varchar(1024) when extracting the _value from the XML parameters
**          07/16/2014 mem - Updated capitalization of keywords
**          03/02/2022 mem - Rename parameter _datasetID to _datasetOrDataPackageId
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _signature int;
    _shared int;
    _stepTool text;
    _curStep int;
    _prevStep Int := 0;
    _continue boolean;
    _settings text := '';
    _sharedResultsDirectoryName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Get job parameters into table format
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Job_Parameters (
        Job int,
        Step int,
        Section citext,
        Name citext,
        Value citext
    );

    INSERT INTO Tmp_Job_Parameters
        (Job, Step, Section, Name, Value)
    SELECT XmlQ.job, XmlQ.step, XmlQ.section, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _xmlParameters::text || '</params>')::xml As rooted_xml ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS job int PATH '@Job',
                              step int PATH '@Step_Number',
                              section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

    If _debugMode Then
        -- ToDo: Update this to use RAISE INFO

        SELECT 'Tmp_Job_Parameters' As Table, *;
        FROM Tmp_Job_Parameters
    End If;

    ---------------------------------------------------
    -- Calculate signature and shared resuts folder name
    -- for job steps that have tools that require signature
    ---------------------------------------------------

    _continue := true;

    WHILE _continue
    LOOP
        -- Get next step that requires signature
        --
        SELECT Step,
               Tool,
               Shared_Result_Version
        INTO _curStep, _stepTool, _shared
        FROM Tmp_Job_Steps
        WHERE Job = _job AND
              (Shared_Result_Version + Filter_Version) > 0 AND
              Step > _prevStep
        ORDER BY Step
        LIMIT 1;

        -- If none found, done, otherwise process
        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        _prevStep := _curStep;

        ---------------------------------------------------
        -- Get signature for step
        -- rollup parameter names and values for sections
        -- associated with step's step tool into single string
        --
        -- To allow for more than one instance of a tool
        -- in a single script, look at parameters in sections
        -- that either are not locked to any step
        -- (step number is null) or are locked to the current step

        _signature := 0;

        -- This query looks up the section names defined in the Parameter_Template column for tool _stepTool
        -- It uses those names to find the rows in Tmp_Job_Parameters that match any of the section names
        -- In addition, matching rows must either have a null Step_Number or have Step_Number = _curStep

        SELECT string_agg(format('%s=%s', JP.Name, JP.Value), ';' ORDER BY JP.Section, JP.Name)
        INTO _settings
        FROM Tmp_Job_Parameters JP
        WHERE JP.Section In (
                SELECT unnest(xpath('//sections/section/@name', rooted_xml))::text
                FROM ( SELECT ('<sections>' || Parameter_Template::text || '</sections>')::xml As rooted_xml
                       FROM sw.t_step_tools
                       WHERE sw.t_step_tools.step_tool = _stepTool
                     ) Src
                )
              AND
              (
                (JP.Step_Number Is Null) OR
                (JP.Step_Number = _curStep)
              );

        If Coalesce(_settings, '') <> '' Then
            ---------------------------------------------------
            -- Get signature for rolled-up parameter string
            --
            _signature = get_signature (_settings);

            If _signature = 0 Then
                _message := 'Error calculating signature';

                DROP TABLE Tmp_Job_Parameters;
                RETURN;
            End If;

            If _debugMode Then
                RAISE INFO 'Signature: %', _signature;
                RAISE INFO 'Settings: %', _settings;
            End If;

        Else
            If _debugMode Then
                RAISE WARNING 'Cannot compute signature since could not find a section named "%" in column parameter_template in table sw.t_step_tools', _stepTool;
            End If;
        End If;

        ---------------------------------------------------
        -- calculate shared directory name
        --
        _sharedResultsDirectoryName := format('%s_%s_%s_%s',
                                                _stepTool,
                                                _shared,
                                                _signature,
                                                _datasetOrDataPackageId);

        ---------------------------------------------------
        -- Set signature (and shared results directory name for shared results steps)
        --
        UPDATE Tmp_Job_Steps
        SET Signature = _signature,
            Output_Directory_Name = CASE
                                        WHEN _shared > 0 THEN _sharedResultsDirectoryName
                                        ELSE Output_Directory_Name
                                    END
        WHERE Job = _job AND
              Step = _curStep;

    END LOOP;

    DROP TABLE Tmp_Job_Parameters;

END
$$;

COMMENT ON PROCEDURE sw.create_signatures_for_job_steps IS 'CreateSignaturesForJobSteps';
