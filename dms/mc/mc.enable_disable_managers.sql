--
-- Name: enable_disable_managers(boolean, integer, text, boolean, boolean, refcursor, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_managers(IN _enable boolean, IN _managertypeid integer DEFAULT 11, IN _managernamelist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _includedisabled boolean DEFAULT false, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enables or disables all managers of the given type
**
**  Arguments:
**    _enable            False to disable, true to enable
**    _managerTypeID     Defined in table T_MgrTypes.  8=Space, 9=DataImport, 11=Analysis Tool Manager, 15=CaptureTaskManager
**    _managerNameList   Required when _enable is true.  Only managers specified here will be enabled, though you can use 'All' to enable All managers.
**                       When _enable is false, if this parameter is blank (or All) then all managers of the given type will be disabled
**                       supports the % wildcard
**   _infoOnly           When true, show the managers that would be updated
**   _includeDisabled    By default, this procedure skips managers with control_from_website = 0 in t_mgrs; set _includeDisabled to true to also include them
**
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL mc.enable_disable_managers(
**              _enable => true,
**              _managerTypeID => 11,
**              _managerNameList => 'Pub-80%',
**              _infoOnly => true,
**              _includeDisabled => false
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   07/12/2007
**          05/09/2008 mem - Added parameter @ManagerNameList
**          06/09/2011 mem - Now filtering on MT_Active > 0 in T_MgrTypes
**                         - Now allowing @ManagerNameList to be All when @Enable = 1
**          10/12/2017 mem - Allow @ManagerTypeID to be 0 if @ManagerNameList is provided
**          03/28/2018 mem - Use different messages when updating just one manager
**          01/30/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**          02/05/2020 mem - Update _message when previewing updates
**          02/15/2020 mem - Add _results cursor
**          03/23/2022 mem - Use mc schema when calling ParseManagerNameList
**          03/24/2022 mem - Fix typo in comment
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Store the manager names in an array, which allows the refcursor to filter by manager name without using the temporary table
**                         - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**                         - Update return codes
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _enable, _infoOnly and _includeDisabled from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _newValue text;
    _managerTypeName text;
    _activeStateDescription text;
    _countToUpdate int;
    _countUnchanged int;

    _formatSpecifier text := '%-22s %-15s %-20s %-25s %-25s';
    _infoHead text;
    _infoData text;
    _previewData record;

    _mgrNames text[];

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _managerNameList := Coalesce(_managerNameList, '');
    _infoOnly        := Coalesce(_infoOnly, false);
    _includeDisabled := Coalesce(_includeDisabled, false);

    If _enable Is Null Then
        _message := '_enable cannot be null';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _managerTypeID Is Null Then
        _message := '_managerTypeID cannot be null';
        _returnCode := 'U5202';
        RETURN;
    End If;

    If _managerTypeID = 0 And char_length(_managerNameList) > 0 And _managerNameList::citext <> 'All' Then
        _managerTypeName := 'Any';
    Else
        -- Make sure _managerTypeID is valid
        _managerTypeName := '';

        SELECT mgr_type_name
        INTO _managerTypeName
        FROM mc.t_mgr_types
        WHERE mgr_type_id = _managerTypeID AND
              mgr_type_active > 0;

        If Not Found Then
            If Exists (SELECT * FROM mc.t_mgr_types WHERE mgr_type_id = _managerTypeID AND mgr_type_active = 0) Then
                _message := '_managerTypeID ' || _managerTypeID::text || ' has mgr_type_active = 0 in mc.t_mgr_types; unable to continue';
            Else
                _message := '_managerTypeID ' || _managerTypeID::text || ' not found in mc.t_mgr_types';
            End If;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    If _enable AND char_length(_managerNameList) = 0 Then
        _message := '_managerNameList cannot be blank when _enable is true; to update all managers, set _managerNameList to ''All''';
        _returnCode := 'U5204';
        RETURN;
    End If;

    -----------------------------------------------
    -- Create a temporary table
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_ManagerList (
        manager_name citext NOT NULL
    );

    If char_length(_managerNameList) > 0 And _managerNameList::citext <> 'All' Then
        -- Populate Tmp_ManagerList using parse_manager_name_list

        INSERT INTO Tmp_ManagerList (manager_name)
        SELECT manager_name
        FROM mc.parse_manager_name_list (_managerNameList, _remove_unknown_managers => 1);

        If _managerTypeID > 0 Then
            -- Delete entries from Tmp_ManagerList that don't match entries in mgr_name of the given type
            DELETE FROM Tmp_ManagerList
            WHERE NOT manager_name IN ( SELECT M.mgr_name
                                        FROM Tmp_ManagerList U
                                             INNER JOIN mc.t_mgrs M
                                               ON M.mgr_name = U.manager_name AND
                                                  M.mgr_type_id = _managerTypeID );
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount > 0 Then
                _message := 'Found ' || _myRowCount || ' entries in _managerNameList that are not ' || _managerTypeName || ' managers';
                RAISE INFO '%', _message;
                _message := '';
            End If;
        End If;

        IF Not _includeDisabled THEN
            DELETE FROM Tmp_ManagerList
            WHERE NOT manager_name IN ( SELECT M.mgr_name
                                        FROM Tmp_ManagerList U
                                             INNER JOIN mc.t_mgrs M
                                               ON M.mgr_name = U.manager_name AND
                                                  M.mgr_type_id = _managerTypeID
                                        WHERE control_from_website > 0);
        END IF;
    Else
        -- Populate Tmp_ManagerList with all managers in mc.t_mgrs (of type _managerTypeID)
        --
        INSERT INTO Tmp_ManagerList (manager_name)
        SELECT mgr_name
        FROM mc.t_mgrs
        WHERE mgr_type_id = _managerTypeID And
              (control_from_website > 0 Or _includeDisabled);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    -- Set _newValue based on _enable
    If _enable Then
        _newValue := 'True';
        _activeStateDescription := 'Active';
    Else
        _newValue := 'False';
        _activeStateDescription := 'Inactive';
    End If;

    -- Count the number of managers that need to be updated
    --
    SELECT COUNT(*)
    INTO _countToUpdate
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.param_type_id = PT.param_type_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN Tmp_ManagerList U
           ON M.mgr_name = U.manager_name
    WHERE PT.param_name = 'mgractive' AND
          PV.value <> _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Count the number of managers already in the target state
    --
    SELECT COUNT(*)
    INTO _countUnchanged
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.param_type_id = PT.param_type_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN Tmp_ManagerList U
           ON M.mgr_name = U.manager_name
    WHERE PT.param_name = 'mgractive' AND
          PV.value = _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    _countToUpdate  := COALESCE(_countToUpdate, 0);
    _countUnchanged := COALESCE(_countUnchanged, 0);

    -- Store the manager names in an array,
    -- which allows the refcursor to filter by manager name
    -- without using the temporary table
    --
    _mgrNames := ARRAY( SELECT manager_name
                        FROM Tmp_ManagerList
                      );

    -- We no longer need the temporary table
    DROP TABLE Tmp_ManagerList;

    If _countToUpdate = 0 Then
        If _countUnchanged = 0 Then
            If char_length(_managerNameList) > 0 Then
                If _managerTypeID = 0 Then
                    _message := 'None of the managers in _managerNameList was recognized';
                Else
                    _message := format('No %s managers were found matching _managerNameList (%s)', _managerTypeName, _managerNameList);
                End If;
            Else
                _message := format('No %s managers were found in mc.t_mgrs', _managerTypeName);
            End If;
        Else
            If _countUnchanged = 1 Then
                _message := 'The manager is already ' || _activeStateDescription;
            Else
                If _managerTypeID = 0 Then
                    _message := format('All %s managers are already %s', _countUnchanged, _activeStateDescription);
                Else
                    _message := format('All %s %s managers are already %s', _countUnchanged, _managerTypeName, _activeStateDescription);
                End If;
            End If;
        End If;

        _message := _message || '; see also "FETCH ALL FROM _results"';

        RAISE INFO '%', _message;

        Open _results For
            SELECT PV.value Manager_State,
                   PT.param_name AS Parameter_Name,
                   M.mgr_name AS manager_name,
                   MT.mgr_type_name AS Manager_Type,
                   M.control_from_website
            FROM mc.t_param_value PV
                 INNER JOIN mc.t_param_type PT
                   ON PV.param_type_id = PT.param_type_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
            WHERE M.mgr_name = ANY (_mgrNames) AND
                  PT.param_name = 'mgractive' AND
                  MT.mgr_type_active > 0;

        RETURN;
    End If;

    If _infoOnly Then

        _infoHead := format(_formatSpecifier,
                            'State Change Preview',
                            'Parameter Name',
                            'Manager Name',
                            'Manager Type',
                            'Enabled (control_from_website=1)'
                        );

        RAISE INFO '%', _infoHead;

        FOR _previewData IN
            SELECT PV.value || ' --> ' || _newValue AS State_Change_Preview,
                   PT.param_name AS Parameter_Name,
                   M.mgr_name AS manager_name,
                   MT.mgr_type_name AS Manager_Type,
                   M.control_from_website
            FROM mc.t_param_value PV
                 INNER JOIN mc.t_param_type PT
                   ON PV.param_type_id = PT.param_type_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
            WHERE M.mgr_name = ANY (_mgrNames) AND
                  PT.param_name = 'mgractive' AND
                  PV.value <> _newValue AND
                  MT.mgr_type_active > 0
        LOOP

            _infoData := format(_formatSpecifier,
                                    _previewData.State_Change_Preview,
                                    _previewData.Parameter_Name,
                                    _previewData.manager_name,
                                    _previewData.Manager_Type,
                                    _previewData.control_from_website
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

        _message := format('Would set %s managers to %s; see the Output window for details, or use "FETCH ALL FROM _results"',
                            _countToUpdate,
                            _activeStateDescription);

        Open _results For
            SELECT PV.value || ' --> ' || _newValue AS State_Change_Preview,
                   PT.param_name AS Parameter_Name,
                   M.mgr_name AS manager_name,
                   MT.mgr_type_name AS Manager_Type,
                   M.control_from_website
            FROM mc.t_param_value PV
                 INNER JOIN mc.t_param_type PT
                   ON PV.param_type_id = PT.param_type_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
            WHERE M.mgr_name = ANY (_mgrNames) AND
                  PT.param_name = 'mgractive' AND
                  PV.value <> _newValue AND
                  MT.mgr_type_active > 0;

        RETURN;
    End If;

    -- Update mgractive for the managers in the _mgrNames array
    --
    UPDATE mc.t_param_value
    SET value = _newValue
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.param_type_id = PT.param_type_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
    WHERE M.mgr_name = ANY (_mgrNames) AND
          mc.t_param_value.entry_ID = PV.Entry_ID AND
          PT.param_name = 'mgractive' AND
          PV.value <> _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 1 And _countUnchanged = 0 Then
        _message := 'The manager is now ' || _activeStateDescription;
    Else
        If _managerTypeID = 0 Then
            _message := 'Set ' || _myRowCount || ' managers to state ' || _activeStateDescription;
        Else
            _message := 'Set ' || _myRowCount || ' ' || _managerTypeName || ' managers to state ' || _activeStateDescription;
        End If;

        If _countUnchanged <> 0 Then
            _message := _message || ' (' || _countUnchanged || ' managers were already ' || _activeStateDescription || ')';
        End If;
    End If;

    _message := _message || '; see also "FETCH ALL FROM _results"';

    RAISE INFO '%', _message;

    Open _results For
        SELECT PV.value Manager_State,
               PT.param_name AS Parameter_Name,
               M.mgr_name AS manager_name,
               MT.mgr_type_name AS Manager_Type,
               M.control_from_website
        FROM mc.t_param_value PV
             INNER JOIN mc.t_param_type PT
               ON PV.param_type_id = PT.param_type_id
             INNER JOIN mc.t_mgrs M
               ON PV.mgr_id = M.mgr_id
             INNER JOIN mc.t_mgr_types MT
               ON M.mgr_type_id = MT.mgr_type_id
        WHERE M.mgr_name = ANY (_mgrNames) AND
              PT.param_name = 'mgractive' AND
              MT.mgr_type_active > 0;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    _logError => true);

    _returnCode := _sqlState;

    DROP TABLE IF EXISTS Tmp_ManagerList;
END
$$;


ALTER PROCEDURE mc.enable_disable_managers(IN _enable boolean, IN _managertypeid integer, IN _managernamelist text, IN _infoonly boolean, IN _includedisabled boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_disable_managers(IN _enable boolean, IN _managertypeid integer, IN _managernamelist text, IN _infoonly boolean, IN _includedisabled boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_disable_managers(IN _enable boolean, IN _managertypeid integer, IN _managernamelist text, IN _infoonly boolean, IN _includedisabled boolean, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'EnableDisableManagers';

