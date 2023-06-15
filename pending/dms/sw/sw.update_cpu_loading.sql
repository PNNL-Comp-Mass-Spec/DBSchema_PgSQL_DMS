--
CREATE OR REPLACE PROCEDURE sw.update_cpu_loading
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update local processor list with count of CPUs
**      that are available for new tasks, given current
**      task assignments
**
**      Also updates memory usage
**
**
**  Auth:   grk
**  Date:   06/03/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          09/10/2010 mem - Now using READUNCOMMITTED when querying T_Job_Steps
**          10/17/2011 mem - Now populating Memory_Available
**          09/24/2014 mem - Removed reference to Machine in T_Job_Steps
**          02/26/2015 mem - Split the Update query into two parts
**          04/17/2015 mem - Now using column Uses_All_Cores
**          11/18/2015 mem - Now using Actual_CPU_Load
**          05/26/2017 mem - Consider Remote_Info_ID when determining CPU and memory usage
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    CREATE TEMP TABLE Tmp_MachineStats (
        Machine text NOT NULL,
        CPUs_Used int null,
        Memory_Used int null
    )

    ---------------------------------------------------
    -- Find job steps that are currently busy
    -- and sum up cpu counts and memory uage for tools by machine
    -- Update sw.t_machines
    --
    -- This is a two-step query to avoid locking sw.t_job_steps
    ---------------------------------------------------

    INSERT INTO Tmp_MachineStats (Machine, CPUs_Used, Memory_Used)
    SELECT M.Machine,
        SUM(CASE WHEN JobStepsQ.State = 4
                 THEN
                    CASE
                       WHEN JobStepsQ.Remote_Info_ID > 1
                         THEN 0
                       WHEN JobStepsQ.Uses_All_Cores > 0 AND JobStepsQ.Actual_CPU_Load = JobStepsQ.CPU_Load
                         THEN M.Total_CPUs
                       ELSE
                         Coalesce(JobStepsQ.Actual_CPU_Load, 1)
                    END
                 ELSE 0
            END) AS CPUs_used,
        SUM(CASE WHEN JobStepsQ.State = 4 AND JobStepsQ.Remote_Info_ID <= 1
                 THEN JobStepsQ.Memory_Usage_MB
                 ELSE 0
            END) AS Memory_Used
    FROM sw.t_machines M
         LEFT OUTER JOIN sw.t_local_processors LP
           ON M.machine = LP.machine
         LEFT OUTER JOIN ( SELECT JS.processor,
                                  JS.state,
                                  ST.uses_all_cores,
                                  JS.cpu_load,
                                  JS.actual_cpu_load,
                                  JS.memory_usage_mb,
                                  Coalesce(JS.remote_info_id, 0) AS Remote_Info_ID
                           FROM sw.t_job_steps JS
                                INNER JOIN sw.t_step_tools ST
                                  ON ST.step_tool = JS.tool ) JobStepsQ
           ON LP.processor_name = JobStepsQ.processor
    GROUP BY M.machine
    --
    UPDATE sw.t_machines
    SET cpus_available = M.total_cpus - TX.CPUs_used,
        memory_available = M.total_memory_mb - TX.Memory_Used
    FROM sw.t_machines M

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE sw.t_machines
    **   SET ...
    **   FROM source
    **   WHERE source.id = sw.t_machines.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN Tmp_MachineStats AS TX
           ON TX.Machine = M.Machine
    WHERE CPUs_Available <> M.Total_CPUs - TX.CPUs_used OR
          Memory_Available <> M.Total_Memory_MB - TX.Memory_Used

    DROP TABLE Tmp_MachineStats;
END
$$;

COMMENT ON PROCEDURE sw.update_cpu_loading IS 'UpdateCPULoading';
