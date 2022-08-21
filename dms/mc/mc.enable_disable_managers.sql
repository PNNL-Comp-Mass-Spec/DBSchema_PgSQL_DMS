--
-- Name: enable_disable_managers(integer, integer, text, integer, integer, refcursor, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_managers(IN _enable integer, IN _managertypeid integer DEFAULT 11, IN _managernamelist text DEFAULT ''::text, IN _infoonly integer DEFAULT 0, IN _includedisabled integer DEFAULT 0, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enables or disables all managers of the given type
**
**  Arguments:
**    _enable            0 to disable, 1 to enable
**    _managerTypeID     Defined in table T_MgrTypes.  8=Space, 9=DataImport, 11=Analysis Tool Manager, 15=CaptureTaskManager
**    _managerNameList   Required when _enable = 1.  Only managers specified here will be enabled, though you can use 'All' to enable All managers.
**                       When _enable = 0, if this parameter is blank (or All) then all managers of the given type will be disabled
**                       supports the % wildcard
**   _infoOnly           When non-zero, show the managers that would be updated
**   _includeDisabled    By default, this procedure skips managers with control_from_website = 0 in t_mgrs; set _includeDisabled to 1 to also include them
**
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL mc.enable_disable_managers(
**              _enable => 1,
**              _managerTypeID => 11,
**              _managerNameList => 'Pub-80%',
**              _infoOnly => 1,
**              _includeDisabled => 0
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
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _newValue text;
    _managerTypeName text;
    _activeStateDescription text;
    _countToUpdate int;
    _countUnchanged int;
    _infoHead text;
    _infoData text;
    _previewData record;
    _mgrNames text[];
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _managerNameList := Coalesce(_managerNameList, '');
    _infoOnly        := Coalesce(_infoOnly, 0);
    _includeDisabled := Coalesce(_includeDisabled, 0);

    _message := '';
    _returnCode := '';

    If _enable Is Null Then
        _message := '_enable cannot be null';
        _returnCode := 'U5201';
        Return;
    End If;

    If _managerTypeID Is Null Then
        _message := '_managerTypeID cannot be null';
        _returnCode := 'U5202';
        Return;
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
            Return;
        End If;
    End If;

    If _enable <> 0 AND char_length(_managerNameList) = 0 Then
        _message := '_managerNameList cannot be blank when _enable is non-zero; to update all managers, set _managerNameList to ''All''';
        _returnCode := 'U5204';
        Return;
    End If;

    -----------------------------------------------
    -- Create a temporary table
    -----------------------------------------------

    CREATE TEMP TABLE TmpManagerList (
        manager_name citext NOT NULL
    );

    If char_length(_managerNameList) > 0 And _managerNameList::citext <> 'All' Then
        -- Populate TmpManagerList using parse_manager_name_list

        INSERT INTO TmpManagerList (manager_name)
        SELECT manager_name
        FROM mc.parse_manager_name_list (_managerNameList, _remove_unknown_managers => 1);

        If _managerTypeID > 0 Then
            -- Delete entries from TmpManagerList that don't match entries in mgr_name of the given type
            DELETE FROM TmpManagerList
            WHERE NOT manager_name IN ( SELECT M.mgr_name
                                        FROM TmpManagerList U
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

        IF _includeDisabled = 0 THEN
            DELETE FROM TmpManagerList
            WHERE NOT manager_name IN ( SELECT M.mgr_name
                                        FROM TmpManagerList U
                                             INNER JOIN mc.t_mgrs M
                                               ON M.mgr_name = U.manager_name AND
                                                  M.mgr_type_id = _managerTypeID
                                        WHERE control_from_website > 0);
        END IF;
    Else
        -- Populate TmpManagerList with all managers in mc.t_mgrs (of type _managerTypeID)
        --
        INSERT INTO TmpManagerList (manager_name)
        SELECT mgr_name
        FROM mc.t_mgrs
        WHERE mgr_type_id = _managerTypeID And
              (control_from_website > 0 Or _includeDisabled > 0);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    -- Set _newValue based on _enable
    If _enable = 0 Then
        _newValue := 'False';
        _activeStateDescription := 'Inactive';
    Else
        _newValue := 'True';
        _activeStateDescription := 'Active';
    End If;

    -- Count the number of managers that need to be updated
    --
    SELECT COUNT(*) INTO _countToUpdate
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.type_id = PT.param_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN TmpManagerList U
           ON M.mgr_name = U.manager_name
    WHERE PT.param_name = 'mgractive' AND
          PV.value <> _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Count the number of managers already in the target state
    --
    SELECT COUNT(*) INTO _countUnchanged
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.type_id = PT.param_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN TmpManagerList U
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
                        FROM TmpManagerList
                      );

    -- We no longer need the temporary table
    DROP TABLE TmpManagerList;

    If _countToUpdate = 0 Then
        If _countUnchanged = 0 Then
            If char_length(_managerNameList) > 0 Then
                If _managerTypeID = 0 Then
                    _message := 'None of the managers in _managerNameList was recognized';
                Else
                    _message := 'No ' || _managerTypeName || ' managers were found matching _managerNameList';
                End If;
            Else
                _message := 'No ' || _managerTypeName || ' managers were found in mc.t_mgrs';
            End If;
        Else
            If _countUnchanged = 1 Then
                _message := 'The manager is already ' || _activeStateDescription;
            Else
                If _managerTypeID = 0 Then
                    _message := 'All ' || _countUnchanged::text || ' managers are already ' || _activeStateDescription;
                Else
                    _message := 'All ' || _countUnchanged::text || ' ' || _managerTypeName || ' managers are already ' || _activeStateDescription;
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
                   ON PV.type_id = PT.param_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
            WHERE M.mgr_name = ANY (_mgrNames) AND
                  PT.param_name = 'mgractive' AND
                  MT.mgr_type_active > 0;

        Return;
    End If;

    If _infoOnly <> 0 Then

        _infoHead := format('%-22s %-15s %-20s %-25s %-25s',
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
                   ON PV.type_id = PT.param_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
            WHERE M.mgr_name = ANY (_mgrNames) AND
                  PT.param_name = 'mgractive' AND
                  PV.value <> _newValue AND
                  MT.mgr_type_active > 0
        LOOP

            _infoData := format('%-22s %-15s %-20s %-25s %-25s',
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
                   ON PV.type_id = PT.param_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
            WHERE M.mgr_name = ANY (_mgrNames) AND
                  PT.param_name = 'mgractive' AND
                  PV.value <> _newValue AND
                  MT.mgr_type_active > 0;

        Return;
    End If;

    -- Update mgractive for the managers in the _mgrNames array
    --
    UPDATE mc.t_param_value
    SET value = _newValue
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.type_id = PT.param_id
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
               ON PV.type_id = PT.param_id
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
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error enabling/disabling managers: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning '%', _message;
    RAISE Warning 'Context: %', _exceptionContext;

    Call public.post_log_entry ('Error', _message, 'EnableDisableManagers', 'mc');

    DROP TABLE IF EXISTS TmpManagerList;
END
$$;


ALTER PROCEDURE mc.enable_disable_managers(IN _enable integer, IN _managertypeid integer, IN _managernamelist text, IN _infoonly integer, IN _includedisabled integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_disable_managers(IN _enable integer, IN _managertypeid integer, IN _managernamelist text, IN _infoonly integer, IN _includedisabled integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_disable_managers(IN _enable integer, IN _managertypeid integer, IN _managernamelist text, IN _infoonly integer, IN _includedisabled integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) IS 'EnableDisableManagers';

