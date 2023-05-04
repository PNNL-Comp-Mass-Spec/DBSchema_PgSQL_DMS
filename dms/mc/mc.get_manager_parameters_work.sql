--
-- Name: get_manager_parameters_work(text, integer, integer, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.get_manager_parameters_work(IN _managernamelist text DEFAULT ''::text, IN _sortmode integer DEFAULT 0, IN _maxrecursion integer DEFAULT 50, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populates a temporary table with the parameters for the given analysis manager(s)
**      Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**  Requires that the calling procedure create temporary table Tmp_Mgr_Params
**
**      CREATE TEMP TABLE Tmp_Mgr_Params (
**          mgr_name text NOT NULL,
**          param_name text NOT NULL,
**          entry_id int NOT NULL,
**          param_type_id int NOT NULL,
**          value text NOT NULL,
**          mgr_id int NOT NULL,
**          comment text NULL,
**          last_affected timestamp NULL,
**          entered_by text NULL,
**          mgr_type_id int NOT NULL,
**          parent_param_pointer_state int,
**          source text NOT NULL
**      );
**
**  Arguments:
**    _sortMode   0 means sort by param_type_id then mgr_name,
**                1 means param_name, then mgr_name,
**                2 means mgr_name, then param_name,
**                3 means value then param_name
**
**  Auth:   mem
**  Date:   03/14/2018 mem - Initial version (code refactored from GetManagerParameters)
**          02/05/2020 mem - Ported to PostgreSQL
**          04/02/2022 mem - Remove initial temp table drop since unnecessary
**                         - Use case insensitive matching of manager name
**          04/16/2022 mem - Use new function name
**          02/01/2023 mem - Rename column in temp table
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _iterations int := 0;
BEGIN
    _message := '';

    -----------------------------------------------
    -- Create the Temp Table to hold the manager group information
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_Manager_Group_Info (
        mgr_name text NOT NULL,
        Group_Name text NOT NULL
    );

    -----------------------------------------------
    -- Lookup the initial manager parameters
    -----------------------------------------------
    --

    INSERT INTO Tmp_Mgr_Params(  mgr_name,
                                 param_name,
                                 entry_id,
                                 param_type_id,
                                 value,
                                 mgr_id,
                                 comment,
                                 last_affected,
                                 entered_by,
                                 mgr_type_id,
                                 parent_param_pointer_state,
                                 source )
    SELECT mgr_name,
           param_name,
           entry_id,
           param_type_id,
           value,
           mgr_id,
           comment,
           last_affected,
           entered_by,
           mgr_type_id,
           CASE
               WHEN param_type_id = 162 THEN 1        -- param_name 'Default_AnalysisMgr_Params'
               ELSE 0
           End As parent_param_pointer_state,
           mgr_name
    FROM mc.v_param_value
    WHERE (mgr_name IN (Select value::citext From public.parse_delimited_list(_managerNameList, ',')));
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------
    -- Append parameters for parent groups, which are
    -- defined by parameter Default_AnalysisMgr_Params (param_type_id 162)
    -----------------------------------------------
    --

    While Exists (Select * from Tmp_Mgr_Params Where parent_param_pointer_state = 1) And _iterations < _maxRecursion
    Loop
        Truncate table Tmp_Manager_Group_Info;

        INSERT INTO Tmp_Manager_Group_Info (mgr_name, Group_Name)
        SELECT mgr_name, value
        FROM Tmp_Mgr_Params
        WHERE parent_param_pointer_state = 1;

        UPDATE Tmp_Mgr_Params
        Set parent_param_pointer_state = 2
        WHERE parent_param_pointer_state = 1;

        INSERT INTO Tmp_Mgr_Params( mgr_name,
                                     param_name,
                                     entry_id,
                                     param_type_id,
                                     value,
                                     mgr_id,
                                     comment,
                                     last_affected,
                                     entered_by,
                                     mgr_type_id,
                                     parent_param_pointer_state,
                                     source )
        SELECT ValuesToAppend.mgr_name,
               ValuesToAppend.param_name,
               ValuesToAppend.entry_id,
               ValuesToAppend.param_type_id,
               ValuesToAppend.value,
               ValuesToAppend.mgr_id,
               ValuesToAppend.comment,
               ValuesToAppend.last_affected,
               ValuesToAppend.entered_by,
               ValuesToAppend.mgr_type_id,
               CASE
                   WHEN ValuesToAppend.param_type_id = 162 THEN 1
                   ELSE 0
               End As parent_param_pointer_state,
               ValuesToAppend.source
        FROM Tmp_Mgr_Params Target
             RIGHT OUTER JOIN ( SELECT FilterQ.mgr_name,
                                       PV.param_name,
                                       PV.entry_id,
                                       PV.param_type_id,
                                       PV.value,
                                       PV.mgr_id,
                                       PV.comment,
                                       PV.last_affected,
                                       PV.entered_by,
                                       PV.mgr_type_id,
                                       PV.mgr_name AS source
                                FROM mc.v_param_value PV
                                     INNER JOIN ( SELECT mgr_name,
                                                         Group_Name
                                                  FROM Tmp_Manager_Group_Info ) FilterQ
                                       ON PV.mgr_name::citext = FilterQ.Group_Name::citext ) ValuesToAppend
               ON Target.mgr_name = ValuesToAppend.mgr_name AND
                  Target.param_type_id = ValuesToAppend.param_type_id
        WHERE (Target.param_type_id IS NULL Or ValuesToAppend.param_type_id = 162);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- This is a safety check in case a manager has a Default_AnalysisMgr_Params value pointing to itself
        _iterations := _iterations + 1;

    END LOOP;

    Drop Table Tmp_Manager_Group_Info;

END
$$;


ALTER PROCEDURE mc.get_manager_parameters_work(IN _managernamelist text, IN _sortmode integer, IN _maxrecursion integer, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_manager_parameters_work(IN _managernamelist text, IN _sortmode integer, IN _maxrecursion integer, INOUT _message text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.get_manager_parameters_work(IN _managernamelist text, IN _sortmode integer, IN _maxrecursion integer, INOUT _message text) IS 'GetManagerParametersWork';

