--
-- Name: import_processors(boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.import_processors(IN _bypassdms boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get list of processors from public.V_Get_Pipeline_Processors
**      (which references public schema tables t_analysis_job_processors and t_analysis_job_processor_group_membership)
**
**  Auth:   grk
**  Date:   06/03/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          09/03/2009 mem - Now skipping disabled processors when looking for new processors to import
**          11/11/2013 mem - Now setting Proc_Tool_Mgr_ID to 1 for newly added processors
**          10/14/2022 mem - Remove invalid update query that aimed to disable local processors that were not in DMS, but didn't actually work
**          06/09/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    If _bypassDMS Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Add processors from DMS that aren't already in local table
    ---------------------------------------------------
    --
    INSERT INTO sw.t_local_processors (processor_id, processor_name, state, Groups, GP_Groups, Machine, proc_tool_mgr_id)
    SELECT ID, processor_name, state, groups, GP_Groups, Machine, 1
    FROM public.V_Get_Pipeline_Processors VPP
    WHERE VPP.state = 'E' AND
          NOT processor_name IN (SELECT processor_name FROM sw.t_local_processors);

    ---------------------------------------------------
    -- Update local processors
    ---------------------------------------------------
    --
    UPDATE sw.t_local_processors
    SET state = VPP.state,
        groups = VPP.groups,
        gp_groups = VPP.gp_groups,
        machine = VPP.machine
    FROM public.V_Get_Pipeline_Processors AS VPP
    WHERE sw.t_local_processors.Processor_Name = VPP.Processor_Name;

    ---------------------------------------------------
    -- Deprecated: disable local copies that are not in DMS
    ---------------------------------------------------
    --
    -- Update sw.t_local_processors
    -- Set State = 'X'
    -- From sw.t_local_processors INNER JOIN
    --      public.V_Get_Pipeline_Processors AS VPP
    --        ON sw.t_local_processors.Processor_Name = VPP.Processor_Name
    -- WHERE Not sw.t_local_processors.Processor_Name IN (SELECT Processor_Name FROM public.V_Get_Pipeline_Processors);

END
$$;


ALTER PROCEDURE sw.import_processors(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

