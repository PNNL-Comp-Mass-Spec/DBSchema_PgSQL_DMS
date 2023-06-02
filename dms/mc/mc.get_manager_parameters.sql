--
-- Name: get_manager_parameters(text, integer, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.get_manager_parameters(_managernamelist text DEFAULT ''::text, _sortmode integer DEFAULT 0, _maxrecursion integer DEFAULT 10) RETURNS TABLE(mgr_name text, param_name text, entry_id integer, param_type_id integer, value text, mgr_id integer, comment text, last_affected timestamp without time zone, entered_by text, mgr_type_id integer, parent_param_pointer_state integer, source text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets the parameters for the given analysis manager(s)
**      Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**  Arguments:
**    _sortMode   0 means sort by param_type_id, mgr_name
**                1 means sort by param_name,    mgr_name
**                2 means sort by mgr_name,      param_name
**                3 means sort by value,         param_name
**
**  Auth:   mem
**  Date:   05/07/2015 mem - Initial version
**          08/10/2015 mem - Add _sortMode=3
**          09/02/2016 mem - Increase the default for parameter _maxRecursion from 5 to 50
**          03/14/2018 mem - Refactor actual parameter lookup into stored procedure Get_Manager_Parameters_Work
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Get_Manager_Parameters_Work
**          04/02/2022 mem - Use new procedure name
**          08/19/2022 mem - Drop the temp table when exiting the function
**          02/01/2023 mem - Rename columns in Tmp_Mgr_Params
**
*****************************************************/
DECLARE
    _message text;
BEGIN
    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _managerNameList := Coalesce(_managerNameList, '');

    _sortMode := Coalesce(_sortMode, 0);

    If _maxRecursion > 10 Then
        _maxRecursion := 10;
    End If;

    -----------------------------------------------
    -- Create the Temp Table to hold the manager parameters
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_Mgr_Params (
        mgr_name text NOT NULL,
        param_name text NOT NULL,
        entry_id int NOT NULL,
        param_type_id int NOT NULL,
        value text NOT NULL,
        mgr_id int NOT NULL,
        comment text NULL,
        last_affected timestamp NULL,
        entered_by text NULL,
        mgr_type_id int NOT NULL,
        parent_param_pointer_state int,
        source text NOT NULL
    );

    -- Populate the temporary table with the manager parameters
    CALL mc.get_manager_parameters_work (_managerNameList, _sortMode, _maxRecursion, _message => _message);

    -- Return the parameters as a result set
    --
    If _sortMode = 0 Then
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.param_type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.parent_param_pointer_state, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.param_type_id, P.mgr_name;

    ElsIf _sortMode = 1 Then
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.param_type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.parent_param_pointer_state, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.param_name, P.mgr_name;

    ElsIf _sortMode = 2 Then
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.param_type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.parent_param_pointer_state, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.mgr_name, P.param_name;

    Else
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.param_type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.parent_param_pointer_state, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.value, P.param_name;

    End If;

    DROP TABLE Tmp_Mgr_Params;

END
$$;


ALTER FUNCTION mc.get_manager_parameters(_managernamelist text, _sortmode integer, _maxrecursion integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_manager_parameters(_managernamelist text, _sortmode integer, _maxrecursion integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.get_manager_parameters(_managernamelist text, _sortmode integer, _maxrecursion integer) IS 'GetManagerParameters';

