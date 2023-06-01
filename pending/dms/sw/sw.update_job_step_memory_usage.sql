--
CREATE OR REPLACE PROCEDURE sw.update_job_step_memory_usage
(
    _job int,
    _xmlParameters xml,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines the job parameters to find entries related to memory usage
**      Updates updates Memory_Usage_MB in Tmp_Job_Steps
**
**      The calling procedure must have created and populateD temporary table Tmp_Job_Steps,
**      which must include these columns:
**
**          CREATE TEMP TABLE Tmp_Job_Steps (
**              Job int NOT NULL,
**              Tool text NOT NULL,
**              Memory_Usage_MB
**          )
**
**  Auth:   mem
**  Date:   10/17/2011 mem - Initial release
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/28/2023 mem - Use XML element names that start with 'MSGFPlus'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentID Int := 0;
    _stepTool text;
    _memoryRequiredMB text;
    _valMemoryRequiredMB int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Look for the memory size parmeters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Memory_Settings (
        UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Tool text,
        MemoryRequiredMB text
    )

    /*
    -- Could use this query to populate Tmp_Memory_Settings
    -- However, this turns out to be more expensive than running 4 separate queries against _xmlParameters with a specific XPath filter
    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT REPLACE(Name, 'JavaMemorySize', '') AS Name, Value
    FROM (
        SELECT
            xmlNode.value('@Name', 'text') Name,
            xmlNode.value('@Value', 'text') Value
        FROM _xmlParameters.nodes('//Param') AS R(xmlNode)
        ) ParameterQ
    WHERE Name like '%JavaMemorySize'
    */

    -- ToDo: Update these to use xpath()
    --       Look for similar capture task code in cap.*

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSGF', xmlNode.value('@Value', 'text') AS MemoryRequiredMB
    FROM   _xmlParameters.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="MSGFJavaMemorySize"]') = 1

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSGFPlus', xmlNode.value('@Value', 'text') AS MemoryRequiredMB
    FROM   _xmlParameters.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="MSGFPlusJavaMemorySize"]') = 1

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSDeconv', xmlNode.value('@Value', 'text') AS MemoryRequiredMB
    FROM   _xmlParameters.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="MSDeconvJavaMemorySize"]') = 1

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSAlign', xmlNode.value('@Value', 'text') AS MemoryRequiredMB
    FROM   _xmlParameters.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="MSAlignJavaMemorySize"]') = 1

    If Not Exists (Select * From Tmp_Memory_Settings) Then
        RETURN;
    End If;

    FOR _currentID, _stepTool, _memoryRequiredMB IN
        SELECT UniqueID,
               Tool,
               MemoryRequiredMB
        FROM Tmp_Memory_Settings
        ORDER BY UniqueID
    LOOP
        _valMemoryRequiredMB := public.try_cast(_memoryRequiredMB, null::int);

        If Coalesce(_memoryRequiredMB, '') <> '' And Not _valMemoryRequiredMB Is Null Then

            UPDATE Tmp_Job_Steps
            SET Memory_Usage_MB = _valMemoryRequiredMB
            WHERE Tool = _stepTool AND
                  Job = _job;

        End If;

    END LOOP;

    DROP TABLE Tmp_Memory_Settings;
END
$$;

COMMENT ON PROCEDURE sw.update_job_step_memory_usage IS 'UpdateJobStepMemoryUsage';
