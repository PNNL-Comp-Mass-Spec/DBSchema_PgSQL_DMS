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
**      The calling procedure must create and populate temporary table Tmp_Job_Steps,
**      which must include these columns:
**
**          CREATE TEMP TABLE Tmp_Job_Steps (
**              Job int NOT NULL,
**              Tool text NOT NULL,
**              Memory_Usage_MB
**          );
**
**  Arguments:
**    _job              Analysis job number
**    _xmlParameters    XML parameters
**    _message          Status message
**    _returnCode       Return Code
**
**  Example nodes in _xmlParameters:
**
**      <Param Section="JobParameters" Name="DatasetID" Value="1146056" />
**      <Param Section="JobParameters" Name="DatasetName" Value="QC_Mam_19_01_d_22Apr23_Pippin_REP-23-03-09" />
**      <Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" />
**      <Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" />
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
    _rootedXML xml;
    _currentID int;
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

    _rootedXML := ('<params>' || _xmlParameters::text || '</params>')::xml;

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSGF' AS Tool, unnest(xpath('//params/Param[@Name="MSGFJavaMemorySize"]/@Value', _rootedXML))::text AS MemoryRequiredMB;

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSGFPlus' AS Tool, unnest(xpath('//params/Param[@Name="MSGFPlusJavaMemorySize"]/@Value', _rootedXML))::text AS MemoryRequiredMB;

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSDeconv' AS Tool, unnest(xpath('//params/Param[@Name="MSDeconvJavaMemorySize"]/@Value', _rootedXML))::text AS MemoryRequiredMB;

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSGF' AS Tool, unnest(xpath('//params/Param[@Name="MSGFJavaMemorySize"]/@Value', _rootedXML))::text AS MemoryRequiredMB;

    INSERT INTO Tmp_Memory_Settings (Tool, MemoryRequiredMB)
    SELECT 'MSAlign' AS Tool, unnest(xpath('//params/Param[@Name="MSAlignJavaMemorySize"]/@Value', _rootedXML))::text AS MemoryRequiredMB;

    If Not Exists (SELECT * FROM Tmp_Memory_Settings) Then
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
