--
-- Name: getmanagerparameterswork(text, integer, integer, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.getmanagerparameterswork(IN _managernamelist text DEFAULT ''::text, IN _sortmode integer DEFAULT 0, IN _maxrecursion integer DEFAULT 50, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populates temporary tables with the parameters for the given analysis manager(s)
**      Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**  Requires that the calling procedure create temporary table Tmp_Mgr_Params
**
**  Arguments:
**    _sortMode   0 means sort by ParamTypeID then mgr_name,
**                1 means param_name, then mgr_name,
**                2 means mgr_name, then param_name,
**                3 means value then param_name
**
**  Auth:   mem
**  Date:   03/14/2018 mem - Initial version (code refactored from GetManagerParameters)
**          02/05/2020 mem - Ported to PostgreSQL
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

    DROP TABLE IF EXISTS Tmp_Manager_Group_Info;

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
                                 type_id,
                                 value,
                                 mgr_id,
                                 comment,
                                 last_affected,
                                 entered_by,
                                 mgr_type_id,
                                 ParentParamPointerState,
                                 source )
    SELECT mgr_name,
           param_name,
           entry_id,
           type_id,
           value,
           mgr_id,
           comment,
           last_affected,
           entered_by,
           mgr_type_id,
           CASE
               WHEN type_id = 162 THEN 1        -- param_name 'Default_AnalysisMgr_Params'
               ELSE 0
           End As ParentParamPointerState,
           mgr_name
    FROM mc.v_param_value
    WHERE (mgr_name IN (Select value From public.udf_parse_delimited_list(_managerNameList, ',')));
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------------
    -- Append parameters for parent groups, which are
    -- defined by parameter Default_AnalysisMgr_Params (type_id 162)
    -----------------------------------------------
    --

    While Exists (Select * from Tmp_Mgr_Params Where ParentParamPointerState = 1) And _iterations < _maxRecursion
    Loop
        Truncate table Tmp_Manager_Group_Info;

        INSERT INTO Tmp_Manager_Group_Info (mgr_name, Group_Name)
        SELECT mgr_name, value
        FROM Tmp_Mgr_Params
        WHERE ParentParamPointerState = 1;

        UPDATE Tmp_Mgr_Params
        Set ParentParamPointerState = 2
        WHERE ParentParamPointerState = 1;

        INSERT INTO Tmp_Mgr_Params( mgr_name,
                                     param_name,
                                     entry_id,
                                     type_id,
                                     value,
                                     mgr_id,
                                     comment,
                                     last_affected,
                                     entered_by,
                                     mgr_type_id,
                                     ParentParamPointerState,
                                     source )
        SELECT ValuesToAppend.mgr_name,
               ValuesToAppend.param_name,
               ValuesToAppend.entry_id,
               ValuesToAppend.type_id,
               ValuesToAppend.value,
               ValuesToAppend.mgr_id,
               ValuesToAppend.comment,
               ValuesToAppend.last_affected,
               ValuesToAppend.entered_by,
               ValuesToAppend.mgr_type_id,
               CASE
                   WHEN ValuesToAppend.type_id = 162 THEN 1
                   ELSE 0
               End As ParentParamPointerState,
               ValuesToAppend.source
        FROM Tmp_Mgr_Params Target
             RIGHT OUTER JOIN ( SELECT FilterQ.mgr_name,
                                       PV.param_name,
                                       PV.entry_id,
                                       PV.type_id,
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
                                       ON PV.mgr_name = FilterQ.Group_Name ) ValuesToAppend
               ON Target.mgr_name = ValuesToAppend.mgr_name AND
                  Target.type_id = ValuesToAppend.type_id
        WHERE (Target.type_id IS NULL Or ValuesToAppend.type_id = 162);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- This is a safety check in case a manager has a Default_AnalysisMgr_Params value pointing to itself
        _iterations := _iterations + 1;

    END LOOP;

    Drop Table Tmp_Manager_Group_Info;

END
$$;


ALTER PROCEDURE mc.getmanagerparameterswork(IN _managernamelist text, IN _sortmode integer, IN _maxrecursion integer, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE getmanagerparameterswork(IN _managernamelist text, IN _sortmode integer, IN _maxrecursion integer, INOUT _message text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.getmanagerparameterswork(IN _managernamelist text, IN _sortmode integer, IN _maxrecursion integer, INOUT _message text) IS 'GetManagerParametersWork';

