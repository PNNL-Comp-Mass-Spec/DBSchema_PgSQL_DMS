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
    --

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

    -- ToDo: Convert these to use XMLTABLE

    SELECT COUNT(*)
    INTO _overlapCount
    FROM (    SELECT
                xmlNode.value('@Number', 'text') Step_Number
            FROM
                _currentScriptXML.nodes('//Step') AS R(xmlNode)
        ) C
        INNER JOIN
        (    SELECT
                xmlNode.value('@Number', 'text') Step_Number
            FROM
                _extensionScriptXML.nodes('//Step') AS R(xmlNode)
        ) E ON C.Step_Number = E.Step_Number

    If _overlapCount > 0 Then
        _message := format('One or more steps overlap between scripts "%s" and "%s"', _currentScript, _extensionScriptName);

        -- ToDo: Show the conflicts using RAISE INFO
        -- ToDo: Replace xmlNode.Value with XMLTable

        -- Show the conflicting steps
        -- Yes, this query is a bit more complex than was needed
        --
        WITH ConflictQ (Step_Number)
        AS (    SELECT C.Step_Number
                FROM (    SELECT
                            xmlNode.value('@Number', 'text') Step_Number
                        FROM
                            _currentScriptXML.nodes('//Step') AS R(xmlNode)
                    ) C
                    INNER JOIN
                    (    SELECT
                            xmlNode.value('@Number', 'text') Step_Number
                        FROM
                            _extensionScriptXML.nodes('//Step') AS R(xmlNode)
                    ) E ON C.Step_Number = E.Step_Number
        )
        SELECT  ScriptSteps.Script,
                ScriptSteps.Step_Number,
                ScriptSteps.Step_Tool,
                Case When ConflictQ.Step_Number Is Null Then 0 Else 1 End as Conflict
        FROM (
            SELECT _currentScript AS Script,
                xmlNode.value('@Number', 'text') Step_Number,
                xmlNode.value('@Tool', 'text') Step_Tool
            FROM
                _currentScriptXML.nodes('//Step') AS R(xmlNode)
            ) ScriptSteps LEFT OUTER JOIN ConflictQ ON ScriptSteps.Step_Number = ConflictQ.Step_Number
        UNION
        SELECT  ScriptSteps.Script,
                ScriptSteps.Step_Number,
                ScriptSteps.Step_Tool,
                Case When ConflictQ.Step_Number Is Null Then 0 Else 1 End as Conflict
        FROM (
            SELECT _extensionScriptName AS Script,
                xmlNode.value('@Number', 'text') Step_Number,
                xmlNode.value('@Tool', 'text') Step_Tool
            FROM
                _extensionScriptXML.nodes('//Step') AS R(xmlNode)
            ) ScriptSteps LEFT OUTER JOIN ConflictQ ON ScriptSteps.Step_Number = ConflictQ.Step_Number
        ORDER BY Script, Step_Number;

        RAISE WARNING '%', _message;

        _returnCode := 'U6203';
        RETURN;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.validate_extension_script_for_job IS 'ValidateExtensionScriptForJob';
