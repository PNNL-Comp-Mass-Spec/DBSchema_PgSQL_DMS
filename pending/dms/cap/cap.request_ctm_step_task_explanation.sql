--
CREATE OR REPLACE FUNCTION cap.request_ctm_step_task_explanation
(
    _processorName text,
    _processorIsAssigned int,
    _machine text
) RETURNS TABLE (
    Parameter text,
    Value text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Called from request_ctm_step_task to explain the assignment logic when _infoLevel is 2
**
**      Uses several temp tables created by request_ctm_step_task
**
**  Auth:   grk
**  Date:   09/07/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/20/2010 grk - Added logic for instrument/processor assignment
**          01/27/2017 mem - Clarify some descriptions
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    ---------------------------------------------------
    -- Look at all potential candidate steps
    -- by assignment rules and explain suitability
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_CandidateJobStepDetails (
      Seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
      Job int,
      Step int,
      Job_Priority int,
      Tool text,
      Tool_Priority int,
      Server_OK text,
      Bionet_OK text,
      Instrument_OK text,
      Assignment_OK text,
      Retry_Holdoff_OK text,
      Candidate text NULL
    )

    INSERT INTO Tmp_CandidateJobStepDetails (
            Job,
            Step,
            Job_Priority,
            Tool,
            Tool_Priority,
            Bionet_OK,
            Server_OK,
            Instrument_OK,
            Assignment_OK,
            Retry_Holdoff_OK
          )
    SELECT
            T.Job,
            TS.Step,
            T.Priority,
            TS.Tool,
            TS.Tool_Priority,
            TS.Bionet_OK,
            CASE WHEN ( Only_On_Storage_Server = 'Y' ) AND ( Storage_Server <> _machine ) THEN 'N' ELSE 'Y' END AS Server_OK,
            CASE WHEN ( Tmp_AvailableProcessorTools.Instrument_Capacity_Limited = 'N' OR (NOT Coalesce(Available_Capacity, 1) < 1) ) THEN 'Y' ELSE 'N' END AS Instrument_OK,
            CASE WHEN (
                (Processor_Assignment_Applies = 'N')
                OR
                (
                    ( _processorIsAssigned > 0 AND Coalesce(Assigned_To_This_Processor, 0) > 0 )
                    OR
                    ( _processorIsAssigned = 0 AND Coalesce(Assigned_To_Any_Processor, 0) = 0 )
                )
            ) THEN 'Y' ELSE 'N' END
            AS Assignment_OK,
            CASE WHEN CURRENT_TIMESTAMP > TS.Next_Try THEN 'Y' ELSE 'N' END AS Retry_Holdoff_OK
    FROM cap.t_task_steps TS
         INNER JOIN cap.t_tasks T ON TS.Job = T.Job
         INNER JOIN Tmp_AvailableProcessorTools ON TS.Tool = Tmp_AvailableProcessorTools.Tool_Name
         LEFT OUTER JOIN Tmp_InstrumentProcessor ON Tmp_InstrumentProcessor.Instrument = T.Instrument
         LEFT OUTER JOIN Tmp_InstrumentLoading ON Tmp_InstrumentLoading.Instrument = T.Instrument
    WHERE TS.State = 2 AND
          T.State IN (1,2)
    ORDER BY T.Job, TS.Step;

    ---------------------------------------------------
    -- Mark actual candidates that were in request table
    ---------------------------------------------------
    --

    UPDATE Tmp_CandidateJobStepDetails
    SET Candidate = 'Y'
    FROM Tmp_CandidateJobSteps
    WHERE Tmp_CandidateJobStepDetails.Job = Tmp_CandidateJobSteps.Job AND
          Tmp_CandidateJobStepDetails.Step = Tmp_CandidateJobSteps.Step;

    ---------------------------------------------------
    -- Dump candidate tables and variables
    ---------------------------------------------------

    RETURN QUERY
    SELECT 'Step tools available to this processor (Tmp_AvailableProcessorTools)' AS Parameter,
           string_agg(format('%s (Priority: %s, Only_on_Storage_Server: %s, Capacity_Limited: %s, Processor_Assignment_Applies: %s)',
                             Tool_Name, Tool_Priority, Only_On_Storage_Server, Instrument_Capacity_Limited, Processor_Assignment_Applies),
                      '; ') As Value
    FROM Tmp_AvailableProcessorTools;

    RETURN QUERY
    SELECT 'Instruments subject to CPU loading restrictions (Tmp_InstrumentLoading)' AS Parameter,
           string_agg(format('%s (Captures_In_Progress: %s, Max_Simultaneous: %s, Capacity: %s)',
                             Instrument, Captures_In_Progress, Max_Simultaneous_Captures, Available_Capacity),
                      '; ') As Value
    FROM Tmp_InstrumentLoading;

    RETURN QUERY
    SELECT 'Instruments assigned to specific processors (Tmp_InstrumentProcessor)' AS Parameter,
           string_agg(format('%s (Assigned_to_this_proc: %s, Assigned_to_any_Proc: %s)',
                             Instrument, Assigned_To_This_Processor, Assigned_To_Any_Processor),
                      '; ') As Value
    FROM Tmp_InstrumentProcessor;

    RETURN QUERY
    SELECT 'Candidate capture task job steps (Tmp_CandidateJobStepDetails) that could be assigned to this processor, but may be excluded due to a Bionet, Storage Server, Instrument Capacity, or Instrument Lock rule' AS Parameter,
           JobCount::text AS Value
    FROM ( SELECT COUNT(*) AS JobCount
           FROM Tmp_CandidateJobStepDetails AS CJS
                INNER JOIN cap.t_tasks T ON T.Job = CJS.Job
                LEFT OUTER JOIN cap.t_step_tools ON cap.t_step_tools.step_tool = CJS.Tool
         ) CountQ;

    RETURN QUERY
    SELECT 'Candidate job' As Parameter,
           format('Job %s, Step %s, Tool %s, Instrument %s, Candidate: %s, Bionet_OK: %s, Server_OK: %s, Instrument_OK: %s, Assignment_OK: %s, Retry_Holdoff_OK: %s, Dataset: %s',
                  CJS.Job, CJS.Step, CJS.Tool, CJS.Instrument, Coalesce(CJS.Candidate, 'N'),
                  CJS.Bionet_OK, CJS.Server_OK, CJS.Instrument_OK, CJS.Assignment_OK, CJS.Retry_Holdoff_OK, T.Dataset) As Value
    FROM
        Tmp_CandidateJobStepDetails CJS
        INNER JOIN cap.t_tasks T ON T.Job = Tmp_CandidateJobStepDetails.Job
        LEFT OUTER JOIN cap.t_step_tools ON cap.t_step_tools.step_tool = CJS.Tool;

    DROP TABLE Tmp_CandidateJobStepDetails;
END
$$;

COMMENT ON PROCEDURE cap.request_ctm_step_task_explanation IS 'RequestStepTaskExplanation';
