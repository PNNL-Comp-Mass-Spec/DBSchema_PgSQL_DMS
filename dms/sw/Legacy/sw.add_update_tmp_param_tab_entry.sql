--
-- Name: add_update_tmp_param_tab_entry(text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_update_tmp_param_tab_entry(IN _section text, IN _paramname text, IN _paramvalue text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in temp table Tmp_ParamTab
**      This procedure was previously called by Get_Job_Param_Table and by legacy procedure Check_Add_Special_Processing_Param
**
**      The calling procedure must create table Tmp_ParamTab
**
**      CREATE TEMP TABLE Tmp_ParamTab
**      (
**          Step text,
**          Section text,
**          Name text,
**          Value text
**      );
**
**  Arguments:
**    _section      Example: JobParameters
**    _paramName    Example: AMTDBServer
**    _paramValue   Example: Elmer
**
**  Auth:   mem
**  Date:   04/20/2011 mem - Initial Version
**          06/05/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    ---------------------------------------------------
    -- Use a Merge statement to add or update the value
    ---------------------------------------------------

    MERGE INTO Tmp_ParamTab AS target
    USING ( SELECT Null AS Step,
                   _section AS Section,
                   _paramName AS Name,
                   _paramValue AS Value
          ) AS Source
    ON (target.Section = source.Section AND
        target.Name = source.Name)
    WHEN MATCHED AND target.value <> source.value THEN
        UPDATE SET Value = source.Value
    WHEN NOT MATCHED THEN
        INSERT (Step, Section, Name, Value)
        VALUES (source.Step, source.Section, source.Name, source.Value);

END
$$;


ALTER PROCEDURE sw.add_update_tmp_param_tab_entry(IN _section text, IN _paramname text, IN _paramvalue text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_tmp_param_tab_entry(IN _section text, IN _paramname text, IN _paramvalue text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_update_tmp_param_tab_entry IS 'AddUpdateTmpParamTabEntry';
