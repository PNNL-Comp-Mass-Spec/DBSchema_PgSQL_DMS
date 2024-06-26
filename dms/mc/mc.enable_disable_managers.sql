--
-- Name: enable_disable_managers(boolean, integer, text, boolean, boolean, refcursor, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_managers(IN _enable boolean, IN _managertypeid integer DEFAULT 11, IN _managernamelist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _includedisabled boolean DEFAULT false, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enable or disable all managers of the given type
**
**  Arguments:
**    _enable           False to disable, true to enable
**    _managerTypeID    Defined in table T_MgrTypes.  8=Space, 9=DataImport, 11=Analysis Tool Manager, 15=CaptureTaskManager
**    _managerNameList  Required when _enable is true.  Only managers specified here will be enabled, though you can use 'All' to enable All managers.
**                      When _enable is false, if this parameter is blank (or 'All'), all managers of the given type will be disabled
**                      Supports the % wildcard
**    _infoOnly         When true, show the managers that would be updated
**    _includeDisabled  By default, this procedure skips managers with control_from_website = 0 in t_mgrs; set _includeDisabled to true to also include them
**    _results          Cursor for obtaining results
**    _message          Status message
**    _returnCode       Return code
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL mc.enable_disable_managers(
**              _enable          => true,
**              _managerTypeID   => 11,
**              _managerNameList => 'Pub-80%',
**              _infoOnly        => true,
**              _includeDisabled => false
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   07/12/2007
**          05/09/2008 mem - Added parameter _managerNameList
**          06/09/2011 mem - Now filtering on MT_Active > 0 in T_MgrTypes
**                         - Now allowing _managerNameList to be 'All' when _enable is 1
**          10/12/2017 mem - Allow _managerTypeID to be 0 if _managerNameList is provided
**          03/28/2018 mem - Use different messages when updating just one manager
**          01/30/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**          02/05/2020 mem - Update _message when previewing updates
**          02/15/2020 mem - Add _results cursor
**          03/23/2022 mem - Use mc schema when calling Parse_Manager_Name_List
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
**          05/12/2023 mem - Rename variables
**          05/30/2023 mem - Use format() for string concatenation
**          06/23/2023 mem - No longer mention "FETCH ALL FROM _results" in the output message
**          07/11/2023 mem - Use COUNT(PV.entry_id) instead of COUNT(*)
**          09/07/2023 mem - Update warning messages
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _deleteCount int;
    _updateCount int;
    _newValue text;
    _managerTypeName text;
    _activeStateDescription text;
    _countToUpdate int;
    _countUnchanged int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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

    _managerNameList := Trim(Coalesce(_managerNameList, ''));
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

    If _managerTypeID = 0 And Coalesce(_managerNameList, '') <> '' And _managerNameList::citext <> 'All' Then
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
            If Exists (SELECT mgr_type_id FROM mc.t_mgr_types WHERE mgr_type_id = _managerTypeID AND mgr_type_active = 0) Then
                _message := format('_managerTypeID %s has mgr_type_active = 0 in mc.t_mgr_types; unable to continue', _managerTypeID);
            Else
                _message := format('_managerTypeID %s not found in mc.t_mgr_types', _managerTypeID);
            End If;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    If _enable And _managerNameList = '' Then
        _message := '_managerNameList must be specified when _enable is true; to update all managers, set _managerNameList to ''All''';
        _returnCode := 'U5204';
        RETURN;
    End If;

    -----------------------------------------------
    -- Create a temporary table
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_ManagerList (
        manager_name citext NOT NULL
    );

    If _managerNameList <> '' And _managerNameList::citext <> 'All' Then
        -- Populate Tmp_ManagerList using parse_manager_name_list

        INSERT INTO Tmp_ManagerList (manager_name)
        SELECT manager_name
        FROM mc.parse_manager_name_list (_managerNameList, _remove_unknown_managers => 1);

        If _managerTypeID > 0 Then
            -- Delete entries from Tmp_ManagerList that don't match entries in mgr_name of the given type
            DELETE FROM Tmp_ManagerList
            WHERE NOT manager_name IN (SELECT M.mgr_name
                                       FROM Tmp_ManagerList U
                                            INNER JOIN mc.t_mgrs M
                                              ON M.mgr_name = U.manager_name AND
                                                 M.mgr_type_id = _managerTypeID);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Found %s entries in _managerNameList that are not %s managers', _deleteCount, _managerTypeName);
                RAISE INFO '%', _message;
                _message := '';
            End If;
        End If;

        If Not _includeDisabled Then
            DELETE FROM Tmp_ManagerList
            WHERE NOT manager_name IN (SELECT M.mgr_name
                                       FROM Tmp_ManagerList U
                                            INNER JOIN mc.t_mgrs M
                                              ON M.mgr_name = U.manager_name AND
                                                 M.mgr_type_id = _managerTypeID
                                       WHERE M.control_from_website > 0);
        End If;
    Else
        -- Populate Tmp_ManagerList with all managers in mc.t_mgrs (of type _managerTypeID)

        INSERT INTO Tmp_ManagerList (manager_name)
        SELECT mgr_name
        FROM mc.t_mgrs
        WHERE mgr_type_id = _managerTypeID AND
              (control_from_website > 0 OR _includeDisabled);
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

    SELECT COUNT(PV.entry_id)
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

    -- Count the number of managers already in the target state

    SELECT COUNT(PV.entry_id)
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

    _countToUpdate  := Coalesce(_countToUpdate, 0);
    _countUnchanged := Coalesce(_countUnchanged, 0);

    -- Store the manager names in an array,
    -- which allows the refcursor to filter by manager name
    -- without using the temporary table

    _mgrNames := ARRAY(SELECT manager_name
                       FROM Tmp_ManagerList
                      );

    -- We no longer need the temporary table
    DROP TABLE Tmp_ManagerList;

    If _countToUpdate = 0 Then
        If _countUnchanged = 0 Then
            If _managerNameList <> '' Then
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
                _message := format('The manager is already %s', _activeStateDescription);
            Else
                If _managerTypeID = 0 Then
                    _message := format('All %s managers are already %s', _countUnchanged, _activeStateDescription);
                Else
                    _message := format('All %s %s managers are already %s', _countUnchanged, _managerTypeName, _activeStateDescription);
                End If;
            End If;
        End If;

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

        RAISE INFO '';

        _formatSpecifier := '%-22s %-15s %-20s %-25s %-25s';

        _infoHead := format(_formatSpecifier,
                            'State Change Preview',
                            'Parameter Name',
                            'Manager Name',
                            'Manager Type',
                            'Enabled (control_from_website=1)'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------------',
                                     '---------------',
                                     '--------------------',
                                     '-------------------------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT format('%s --> %s', PV.value, _newValue) AS State_Change_Preview,
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

        _message := format('Would set %s managers %sto %s; see the Output window for details',
                            _countToUpdate,
                            CASE WHEN _managerTypeID = 0 THEN '' ELSE format('of type %s ', _managerTypeID) END,
                            _activeStateDescription);

        Open _results For
            SELECT format('%s --> %s', PV.value, _newValue) AS State_Change_Preview,
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
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount = 1 And _countUnchanged = 0 Then
        _message := format('The manager is now %s', _activeStateDescription);
    Else
        If _managerTypeID = 0 Then
            _message := format('Set %s managers to state %s', _updateCount, _activeStateDescription);
        Else
            _message := format('Set %s %s managers to state %s', _updateCount, _managerTypeName, _activeStateDescription);
        End If;

        If _countUnchanged <> 0 Then
            _message := format('%s (%s managers were already %s)', _message, _countUnchanged, _activeStateDescription);
        End If;
    End If;

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

