--
-- Name: clone_job_step(integer, xml, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.clone_job_step(IN _job integer, IN _xmlparameters xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Clone the given job step by adding rows to the temporary tables created by the caller
**      - Tmp_Job_Steps
**      - Tmp_Job_Step_Dependencies
**
**      See procedure sw.create_job_steps() for the temporary table definitions
**
**  Arguments:
**    _job              Job number
**    _xmlParameters    XML job parameters
**    _message          Status message
**    _returnCode       Return code
**    _debugMode        When true, show debugging messages
**
**  Example job parameters, as obtained using:
**     SELECT create_parameters_for_job::text FROM sw.create_parameters_for_job(2167189);
**
**     <Param Section="JobParameters" Name="DatasetID" Value="1137910" />
**     <Param Section="JobParameters" Name="DatasetName" Value="Soil_Strap_Test_BC_03_FAIMS_HMSn_Samwise_21Mar23_WBEH-23-02-09" />
**     <Param Section="JobParameters" Name="DatasetStoragePath" Value="\\proto-8\Eclipse01\2023_1\" />
**     <Param Section="JobParameters" Name="DatasetType" Value="HMS-HCD-MSn" />
**     <Param Section="JobParameters" Name="Experiment" Value="Soil_Strap_Test_BC_03" />
**     <Param Section="JobParameters" Name="InstClass" Value="LTQ_FT" />
**     <Param Section="JobParameters" Name="Instrument" Value="Eclipse01" />
**     <Param Section="MSGFPlus" Name="MSGFPlusJavaMemorySize" Value="4000" />
**     <Param Section="MSGFPlus" Name="MSGFPlusThreads" Value="all" />
**     <Param Section="MSGFPlus" Name="SkipPeptideToProteinMapping" Value="True" />
**     <Param Section="MSXMLGenerator" Name="CentroidMSXML" Value="True" />
**     <Param Section="MSXMLGenerator" Name="CentroidPeakCountToRetain" Value="-1" />
**     <Param Section="MSXMLGenerator" Name="MSXMLGenerator" Value="MSConvert.exe" />
**     <Param Section="MSXMLGenerator" Name="MSXMLOutputType" Value="mzML" />
**     <Param Section="MSXMLOptions" Name="StoreMSXmlInCache" Value="True" />
**     <Param Section="MSXMLOptions" Name="StoreMSXmlInDataset" Value="False" />
**     <Param Section="MzRefinery" Name="MzRefParamFile" Value="MzRef_NoMods_SkipRefinement.txt" />
**     <Param Section="MzRefineryRuntimeOptions" Name="MzRefMSGFPlusJavaMemorySize" Value="4000" />
**     <Param Section="ParallelMSGFPlus" Name="CloneStepRenumberStart" Value="50" />
**     <Param Section="ParallelMSGFPlus" Name="MergeResultsToKeepPerScan" Value="1" />
**     <Param Section="ParallelMSGFPlus" Name="NumberOfClonedSteps" Value="25" />
**     <Param Section="ParallelMSGFPlus" Name="SplitFasta" Value="True" />
**     <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="WA_v2_0_JGI_derep_1_0_TryPigBov_2021-01-28.fasta" />
**     <Param Section="PeptideSearch" Name="OrganismName" Value="Prosser_soil" />
**     <Param Section="PeptideSearch" Name="ParamFileName" Value="MSGFPlus_Tryp_NoMods_20ppmParTol.txt" />
**     <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MSGFPlus" />
**     <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="na" />
**     <Param Section="PeptideSearch" Name="ProteinOptions" Value="na" />
**
**  Auth:   grk
**  Date:   01/28/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/718)
**          02/06/2009 grk - Modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from Tmp_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          07/28/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stepToClone int;
    _valueText text;
    _numClones int;
    _cloneStepNumBase int;
    _cloneStep int;
    _rootedXML xml;
BEGIN
    _message := '';
    _returnCode := '';

    _debugMode := Coalesce(_debugMode, false);

    If _debugMode Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Get clone parameters
    ---------------------------------------------------

    SELECT Step
    INTO _stepToClone
    FROM Tmp_Job_Steps
    WHERE Special_Instructions::citext = 'Clone' AND
          Job = _job;

    If Not FOUND Then
        -- Nothing to do

        If _debugMode Then
            RAISE INFO 'Job % does not have a job step where Special_Instructions = "Clone"; nothing to do', _job;
        End If;

        RETURN;
    End If;

    -- Extract the step cloning informtaion
    -- This was obtained from the settings file for the job, but is now stored in _xmlParameters

    -- Created rooted XML, as required by xpath
    --
    _rootedXML := ('<params>' || _xmlParameters::text || '</params>')::xml;

    -- The following xpath expression finds nodes where the Name attribute is "NumberOfClonedSteps"
    -- then returns the text of the Value attribute
    --
    SELECT unnest(xpath('//params/Param[@Name="NumberOfClonedSteps"]/@Value', _rootedXML))::text
    INTO _valueText
    LIMIT 1;

    If Not FOUND Then
        If _debugMode Then
            RAISE INFO 'Job % does not have job parameter "NumberOfClonedSteps"; unable to create cloned steps', _job;
        End If;

        RETURN;
    End If;

    _numClones := public.try_cast(_valueText, 0);

    If _numClones = 0 Then
        If _debugMode Then
            RAISE INFO 'Job parameter "NumberOfClonedSteps" for job % is not a positive integer (%); unable to create cloned steps', _job, _valueText;
        End If;

        RETURN;
    End If;

    -- The following xpath expression finds nodes where the Name attribute is "CloneStepRenumberStart"
    -- then returns the text of the Value attribute
    --
    SELECT unnest(xpath('//params/Param[@Name="CloneStepRenumberStart"]/@Value', _rootedXML))::text
    INTO _valueText
    LIMIT 1;

    If Not FOUND Then
        If _debugMode Then
            RAISE INFO 'Job % does not have job parameter "CloneStepRenumberStart"; unable to create cloned steps', _job;
        End If;

        RETURN;
    End If;

    _cloneStepNumBase := public.try_cast(_valueText, 0);

    If _cloneStepNumBase = 0 Then
        If _debugMode Then
            RAISE INFO 'Job parameter "CloneStepRenumberStart" for job % is not a positive integer (%); unable to create cloned steps', _job, _valueText;
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Clone given job step
    ---------------------------------------------------

    If _debugMode Then
        RAISE INFO 'Adding % cloned job steps for job %', _numClones, _job;
    End If;

    FOR _cloneStep IN _cloneStepNumBase .. _cloneStepNumBase + _numClones - 1
    LOOP
        If _debugMode Then
            RAISE INFO 'Cloning step % to create step %', _stepToClone, _cloneStep;
        End If;

        ---------------------------------------------------
        -- Add new job steps
        ---------------------------------------------------

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
            Output_Directory_Name
        )
        SELECT Job,
               _cloneStep AS Step,
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
              Step = _stepToClone;

        ---------------------------------------------------
        -- Copy the clone step's dependencies
        ---------------------------------------------------

        INSERT INTO Tmp_Job_Step_Dependencies( Job,
                                               Step,
                                               Target_Step,
                                               Condition_Test,
                                               Test_Value,
                                               Enable_Only )
        SELECT Job,
               _cloneStep AS Step,
               Target_Step,
               Condition_Test,
               Test_Value,
               Enable_Only
        FROM Tmp_Job_Step_Dependencies
        WHERE Job = _job AND
              Step = _stepToClone;

        ---------------------------------------------------
        -- Copy the dependencies that target the clone step
        ---------------------------------------------------

        INSERT INTO Tmp_Job_Step_Dependencies( Job,
                                               Step,
                                               Target_Step,
                                               Condition_Test,
                                               Test_Value,
                                               Enable_Only )
        SELECT Job,
               Step,
               _cloneStep AS Target_Step,
               Condition_Test,
               Test_Value,
               Enable_Only
        FROM Tmp_Job_Step_Dependencies
        WHERE Job = _job AND
              Target_Step = _stepToClone;

    END LOOP;

    If _debugMode Then
        RAISE INFO '';
        RAISE INFO 'Removing job step % from the temporary tables', _stepToClone;
    End If;

    ---------------------------------------------------
    -- Remove original dependencies
    ---------------------------------------------------

    DELETE FROM Tmp_Job_Step_Dependencies
    WHERE Job = _job AND
          Target_Step = _stepToClone;

    ---------------------------------------------------
    -- Remove original dependencies
    ---------------------------------------------------

    DELETE FROM Tmp_Job_Step_Dependencies
    WHERE Job = _job AND
          Step = _stepToClone;

    ---------------------------------------------------
    -- Remove the cloned step
    ---------------------------------------------------

    DELETE FROM Tmp_Job_Steps
    WHERE Job = _job AND
          Step = _stepToClone;

END
$$;


ALTER PROCEDURE sw.clone_job_step(IN _job integer, IN _xmlparameters xml, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE clone_job_step(IN _job integer, IN _xmlparameters xml, INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.clone_job_step(IN _job integer, IN _xmlparameters xml, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'CloneJobStep';

