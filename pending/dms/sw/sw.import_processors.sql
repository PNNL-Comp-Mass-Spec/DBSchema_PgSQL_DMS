--
CREATE OR REPLACE PROCEDURE sw.import_processors
(
    _bypassDMS boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get list of processors
**
**
**  Auth:   grk
**  Date:   06/03/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          09/03/2009 mem - Now skipping disabled processors when looking for new processors to import
**          11/11/2013 mem - Now setting ProcTool_Mgr_ID to 1 for newly added processors
**          10/14/2022 mem - Remove invalid update query that aimed to disable local processors that were not in DMS, but didn't actually work
**          10/15/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

    If _bypassDMS Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Add processors from DMS that aren't already in local table
    ---------------------------------------------------
    --
    INSERT INTO sw.t_local_processors (ID, processor_name, state, Groups, GP_Groups, Machine, proc_tool_mgr_id)
    SELECT ID, processor_name, state, groups, GP_Groups, Machine, 1
    FROM public.V_Get_Pipeline_Processors VPP
    WHERE VPP.state = 'E' AND
          NOT processor_name IN (SELECT processor_name FROM sw.t_local_processors);

    ---------------------------------------------------
    -- Update local processors
    ---------------------------------------------------
    --
    UPDATE sw.t_local_processors
    SET
        state = VPP.state,
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

COMMENT ON PROCEDURE sw.import_processors IS 'ImportProcessors';
