--
-- Name: getmanagerparameters(text, integer, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.getmanagerparameters(_managernamelist text DEFAULT ''::text, _sortmode integer DEFAULT 0, _maxrecursion integer DEFAULT 10) RETURNS TABLE(mgr_name text, param_name text, entry_id integer, type_id integer, value text, mgr_id integer, comment text, last_affected timestamp without time zone, entered_by text, mgr_type_id integer, parentparampointerstate integer, source text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets the parameters for the given analysis manager(s)
**      Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**  Arguments:
**    _sortMode   0 means sort by type_id,     mgr_name
**                1 means sort by param_name,  mgr_name
**                2 means sort by mgr_name,    param_name
**                3 means sort by value,       param_name
**
**  Auth:   mem
**  Date:   05/07/2015 mem - Initial version
**          08/10/2015 mem - Add _sortMode=3
**          09/02/2016 mem - Increase the default for parameter _maxRecursion from 5 to 50
**          03/14/2018 mem - Refactor actual parameter lookup into stored procedure GetManagerParametersWork
**          02/05/2020 mem - Ported to PostgreSQL
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

    DROP TABLE IF EXISTS Tmp_Mgr_Params;

    CREATE TEMP TABLE Tmp_Mgr_Params (
        mgr_name text NOT NULL,
        param_name text NOT NULL,
        entry_id int NOT NULL,
        type_id int NOT NULL,
        value text NOT NULL,
        mgr_id int NOT NULL,
        comment text NULL,
        last_affected timestamp NULL,
        entered_by text NULL,
        mgr_type_id int NOT NULL,
        ParentParamPointerState int,
        source text NOT NULL
    );

    -- Populate the temporary table with the manager parameters
    Call GetManagerParametersWork (_managerNameList, _sortMode, _maxRecursion, _message := _message);

    -- Return the parameters as a result set
    --
    If _sortMode = 0 Then
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.ParentParamPointerState, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.type_id, P.mgr_name;
        Return;
    End If;

    If _sortMode = 1 Then
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.ParentParamPointerState, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.param_name, P.mgr_name;
        Return;
    End If;

    If _sortMode = 2 Then
        RETURN QUERY
        SELECT P.mgr_name, P.param_name, P.entry_id,
               P.type_id, P.value, P.mgr_id,
               P.comment, P.last_affected, P.entered_by,
               P.mgr_type_id, P.ParentParamPointerState, P.source
        FROM Tmp_Mgr_Params P
        ORDER BY P.mgr_name, P.param_name;
        Return;
    End If;

    RETURN QUERY
    SELECT P.mgr_name, P.param_name, P.entry_id,
           P.type_id, P.value, P.mgr_id,
           P.comment, P.last_affected, P.entered_by,
           P.mgr_type_id, P.ParentParamPointerState, P.source
    FROM Tmp_Mgr_Params P
    ORDER BY P.value, P.param_name;

END
$$;


ALTER FUNCTION mc.getmanagerparameters(_managernamelist text, _sortmode integer, _maxrecursion integer) OWNER TO d3l243;

--
-- Name: FUNCTION getmanagerparameters(_managernamelist text, _sortmode integer, _maxrecursion integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.getmanagerparameters(_managernamelist text, _sortmode integer, _maxrecursion integer) IS 'GetManagerParameters';

