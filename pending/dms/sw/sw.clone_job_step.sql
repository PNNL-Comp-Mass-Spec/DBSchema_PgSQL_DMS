--
CREATE OR REPLACE PROCEDURE sw.clone_job_step
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
**      Clone the given job step in the given job
**      in the temporary tables set up by caller
**
**      The calling procedure must have created and populated temporary table Tmp_Job_Steps,
**      which must include these columns:
**
**      CREATE TEMP TABLE Tmp_Job_Steps (
**          Job int NOT NULL,
**          Step int NOT NULL,
**          Tool citext NOT NULL,
**          CPU_Load int NULL,
**          Memory_Usage_MB int NULL,
**          Dependencies int NULL,
**          Shared_Result_Version int NULL,
**          Filter_Version int NULL,
**          Signature int NULL,
**          State int NULL,
**          Input_Directory_Name citext NULL,
**          Output_Directory_Name citext NULL,
**          Processor citext NULL,
**          Special_Instructions citext NULL
**      );
**
**  Auth:   grk
**  Date:   01/28/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/718)
**          02/06/2009 grk - Modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from Tmp_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _step_to_clone int;
    _num_clones int;
    _clone_step_num_base int;
    _count int;
    _clone_step int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Get clone parameters
    ---------------------------------------------------

    SELECT Step
    INTO _step_to_clone
    FROM Tmp_Job_Steps
    WHERE Special_Instructions = 'Clone' AND
          Job = _job;

    If Not FOUND Then
        RETURN;
    End If;


    -- Extract the step cloning informtaion
    -- This was obtained from the settings file for the job, but is now stored in _xmlParameters

    -- Example XML, as obtained using
    -- SELECT create_parameters_for_job::text FROM sw.create_parameters_for_job(2048662);

    -- <Param Section="JobParameters" Name="DatasetID" Value="1034787"/>
    -- <Param Section="JobParameters" Name="DatasetName" Value="rhizosphere_plant13C33_No45_2May22_Oak_WBEH-22-04-13"/>
    -- <Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-3\QExactP06\2022_2\"/>
    -- <Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-HMSn"/>
    -- <Param Section="JobParameters" Name="Experiment" Value="rhizosphere_plant13C33_No45"/>
    -- <Param Section="JobParameters" Name="Instrument" Value="QExactP06"/>
    -- <Param Section="MSXMLGenerator" Name="CentroidMSXML" Value="True"/>
    -- <Param Section="MSXMLOptions" Name="StoreMSXmlInCache" Value="True"/>
    -- <Param Section="MSXMLOptions" Name="StoreMSXmlInDataset" Value="False"/>
    -- <Param Section="ParallelMSGFPlus" Name="CloneStepRenumberStart" Value="50"/>
    -- <Param Section="ParallelMSGFPlus" Name="MergeResultsToKeepPerScan" Value="1"/>
    -- <Param Section="ParallelMSGFPlus" Name="NumberOfClonedSteps" Value="15"/>
    -- <Param Section="ParallelMSGFPlus" Name="SplitFasta" Value="True"/>
    -- <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="KBSSwiS62_FD_66596_TrypPigBov_2020-08-08.fasta"/>
    -- <Param Section="PeptideSearch" Name="OrganismName" Value="Rhizosphere_Community"/>
    -- <Param Section="PeptideSearch" Name="ParamFileName" Value="MSGFPlus_Tryp_NoMods_20ppmParTol.txt"/>
    -- <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MSGFPlus"/>
    -- <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="na"/>
    -- <Param Section="PeptideSearch" Name="ProteinOptions" Value="na"/>

    -- The following xpath expression finds nodes where the Name attribute is "NumberOfClonedSteps"
    -- then returns the text of the Value attribute
    --
    SELECT unnest(xpath('//params/Param[@Name="NumberOfClonedSteps"]/@Value', rooted_xml))::text
    INTO _num_clones
    FROM ( SELECT ('<params>' || create_parameters_for_job::text || '</params>')::xml As rooted_xml
           FROM sw.create_parameters_for_job(2048662)
         ) Src
    LIMIT 1;

    If Not FOUND Or _num_clones = 0 Then
        RETURN;
    End If;

    -- The following xpath expression finds nodes where the Name attribute is "NumberOfClonedSteps"
    -- then returns the text of the Value attribute
    --
    SELECT unnest(xpath('//params/Param[@Name="CloneStepRenumberStart"]/@Value', rooted_xml))::text
    INTO _clone_step_num_base
    FROM ( SELECT ('<params>' || create_parameters_for_job::text || '</params>')::xml As rooted_xml
           FROM sw.create_parameters_for_job(2048662)
         ) Src
    LIMIT 1;

    If Not FOUND Or _clone_step_num_base = 0 Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Clone given job step in given job in the temp
    -- tables
    ---------------------------------------------------
    _count := 0;

    WHILE _count < _num_clones
    LOOP

        _clone_step := _clone_step_num_base + _count;

        ---------------------------------------------------
        -- Copy new job steps from clone step
        ---------------------------------------------------
        --
        INSERT INTO Tmp_Job_Steps (
            Job,
            Step,
            Tool,
            CPU_Load,
            Memory_Usage_MB,
            Dependencies,
            Shared_Result_Version,
            Filter_Version,
            Signature,
            State,
            Input_Directory_Name,
            Input_Directory_Name
        )
        SELECT Job,
               _clone_step AS Step,
               Tool,
               CPU_Load,
               Memory_Usage_MB,
               Dependencies,
               Shared_Result_Version,
               Filter_Version,
               Signature,
               State,
               Input_Directory_Name,
               Output_Directory_Name
        FROM Tmp_Job_Steps
        WHERE Job = _job AND
              Step = _step_to_clone;

        ---------------------------------------------------
        -- Copy the clone step's dependencies
        ---------------------------------------------------
        --
        INSERT INTO Tmp_Job_Step_Dependencies( Job,
                                               Step,
                                               Target_Step,
                                               Condition_Test,
                                               Test_Value,
                                               Enable_Only )
        SELECT Job,
               _clone_step AS Step,
               Target_Step,
               Condition_Test,
               Test_Value,
               Enable_Only
        FROM Tmp_Job_Step_Dependencies
        WHERE Job = _job AND
              Step = _step_to_clone;

        ---------------------------------------------------
        -- Copy the dependencies that target the clone step
        ---------------------------------------------------
        --
        INSERT INTO Tmp_Job_Step_Dependencies( Job,
                                               Step,
                                               Target_Step,
                                               Condition_Test,
                                               Test_Value,
                                               Enable_Only )
        SELECT Job,
               Step,
               _clone_step AS Target_Step,
               Condition_Test,
               Test_Value,
               Enable_Only
        FROM Tmp_Job_Step_Dependencies
        WHERE Job = _job AND
              Target_Step = _step_to_clone;

        _count := _count + 1;
    END LOOP;

    ---------------------------------------------------
    -- Remove original dependencies
    ---------------------------------------------------
    --
    DELETE FROM Tmp_Job_Step_Dependencies
    WHERE Job = _job AND
          Target_Step = _step_to_clone;

    ---------------------------------------------------
    -- Remove original dependencies
    ---------------------------------------------------
    --
    DELETE FROM Tmp_Job_Step_Dependencies
    WHERE Job = _job AND
          Step = _step_to_clone;

    ---------------------------------------------------
    -- Remove the cloned step
    ---------------------------------------------------
    --
    DELETE FROM Tmp_Job_Steps
    WHERE Job = _job AND
          Step = _step_to_clone;

END
$$;

COMMENT ON PROCEDURE sw.clone_job_step IS 'CloneJobStep';
