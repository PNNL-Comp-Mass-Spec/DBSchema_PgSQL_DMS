--
CREATE OR REPLACE PROCEDURE sw.validate_extension_script_for_job
(
    _job int,
    _extensionScriptName text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates that the given extension script is appropriate for the given job
**
**  Auth:   mem
**  Date:   10/22/2010 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentScript text;
    _currentScriptXML xml;
    _extensionScriptXML xml;
    _overlapCount int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Determine the script name for the job
    ---------------------------------------------------

    _currentScript := '';

    SELECT script
    INTO _currentScript
    FROM sw.t_jobs
    WHERE job = _job;

    If Not FOUND Then
        -- Job not found in sw.t_jobs; check sw.t_jobs_history

        -- Find most recent successful historic job
        SELECT script
        INTO _currentScript
        FROM sw.t_jobs_history
        WHERE job = _job AND state = 4
        ORDER BY saved Desc
        LIMIT 1;

        If Not FOUND Then
            If Exists (SELECT * FROM sw.t_jobs_history WHERE job = _job) Then
                _message := 'Error: job not found in sw.t_jobs, but is present in sw.t_jobs_history.  However, job is not complete (state <> 4).  Therefore, the job cannot be extended';
            Else
                _message := 'Error: job not found in sw.t_jobs or sw.t_jobs_history.';
            End If;

            RAISE WARNING '%', _message;

            _returnCode := 'U6200';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Get the XML for both job scripts
    --
    -- Example value for _currentScriptXML:
    --
    -- <JobScript Name="MSGFPlus_MzML">
    --   <Step Number="1" Tool="MSXML_Gen" />
    --   <Step Number="2" Tool="Mz_Refinery">   <Depends_On Step_Number="1" /></Step>
    --   <Step Number="3" Tool="MSGFPlus">      <Depends_On Step_Number="2" /></Step>
    --   <Step Number="4" Tool="DataExtractor"> <Depends_On Step_Number="3" /></Step>
    --   <Step Number="5" Tool="MSGF">          <Depends_On Step_Number="4" /></Step>
    --   <Step Number="6" Tool="IDPicker">      <Depends_On Step_Number="5" /></Step>
    --   <Step Number="7" Tool="Results_Transfer">
    --     <Depends_On Step_Number="1" Test="Target_Skipped" />
    --     <Depends_On Step_Number="6" Enable_Only="1" />
    --   </Step>
    --   <Step Number="8" Tool="Results_Transfer">
    --     <Depends_On Step_Number="2" Test="Target_Skipped" />
    --     <Depends_On Step_Number="6" Enable_Only="1" />
    --   </Step>
    --   <Step Number="9" Tool="Results_Transfer">
    --     <Depends_On Step_Number="6" />
    --   </Step>
    -- </JobScript>
    ---------------------------------------------------

    SELECT contents
    INTO _currentScriptXML
    FROM sw.t_scripts
    WHERE script = _currentScript

    If Not FOUND Then
        _message := format('Error: Current script (%s) not found in sw.t_scripts', _currentScript);
        RAISE WARNING '%', _message;

        _returnCode := 'U6201';
        RETURN;
    End If;

    SELECT contents,
           script
    INTO _extensionScriptXML, _extensionScriptName
    FROM sw.t_scripts
    WHERE script = _extensionScriptName;

    If Not FOUND Then
        _message := format('Error: Extension script (%s) not found in sw.t_scripts', _extensionScriptName);
        RAISE WARNING '%', _message;

        _returnCode := 'U6202';
        RETURN;
    End If;

    -- Make sure there is no overlap in step numbers between the two scripts

    SELECT COUNT(*)
    INTO _overlapCount
    FROM ( SELECT xmltable.step_number
           FROM ( SELECT _currentScriptXML AS rooted_xml
                ) Src,
                XMLTABLE('//JobScript/Step'
                         PASSING Src.rooted_xml
                         COLUMNS step_number int PATH '@Number')
         ) C
         INNER JOIN
         ( SELECT xmltable.step_number
           FROM ( SELECT _extensionScriptXML AS rooted_xml
                ) Src,
                XMLTABLE('//JobScript/Step'
                         PASSING Src.rooted_xml
                         COLUMNS step_number int PATH '@Number')
         ) E ON C.step_number = E.step_number;

    If _overlapCount > 0 Then
        _message := format('One or more steps overlap between scripts "%s" and "%s"', _currentScript, _extensionScriptName);

        -- ToDo: Show the conflicts using RAISE INFO

        -- Show the conflicting steps
        WITH ConflictQ (step_number)
        AS ( SELECT C.step_number
             FROM ( SELECT xmltable.step_number
                    FROM ( SELECT _currentScriptXML AS rooted_xml
                         ) Src,
                         XMLTABLE('//JobScript/Step'
                                  PASSING Src.rooted_xml
                                  COLUMNS step_number int PATH '@Number')
                  ) C
                  INNER JOIN
                  ( SELECT xmltable.step_number
                    FROM ( SELECT _extensionScriptXML AS rooted_xml
                         ) Src,
                         XMLTABLE('//JobScript/Step'
                                  PASSING Src.rooted_xml
                                  COLUMNS step_number int PATH '@Number')
                  ) E ON C.step_number = E.step_number
        )
        SELECT ScriptSteps.Script,
               ScriptSteps.Step_Number,
               ScriptSteps.Step_Tool,
               CASE WHEN ConflictQ.Step_Number Is Null THEN 0 ELSE 1 END As Conflict
        FROM (
                SELECT _currentScript AS Script,
                       xmltable.step_number,
                       xmltable.step_tool
                FROM ( _currentScript AS rooted_xml
                     ) Src,
                     XMLTABLE('//JobScript/Step'
                              PASSING Src.rooted_xml
                              COLUMNS step_number int PATH '@Number',
                                      step_tool   citext PATH '@Tool')
            ) ScriptSteps LEFT OUTER JOIN ConflictQ ON ScriptSteps.step_number = ConflictQ.step_number
        UNION
        SELECT  ScriptSteps.Script,
                ScriptSteps.Step_Number,
                ScriptSteps.Step_Tool,
                CASE WHEN ConflictQ.Step_Number Is Null THEN 0 ELSE 1 END As Conflict
        FROM (
                SELECT _extensionScriptName AS Script,
                       xmltable.step_number,
                       xmltable.step_tool
                FROM ( _extensionScriptName AS rooted_xml
                     ) Src,
                     XMLTABLE('//JobScript/Step'
                              PASSING Src.rooted_xml
                              COLUMNS step_number int PATH '@Number',
                                      step_tool   citext PATH '@Tool')
            ) ScriptSteps LEFT OUTER JOIN ConflictQ ON ScriptSteps.Step_Number = ConflictQ.Step_Number
        ORDER BY Script, Step_Number;

        RAISE WARNING '%', _message;

        _returnCode := 'U6203';
        RETURN;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.validate_extension_script_for_job IS 'ValidateExtensionScriptForJob';
