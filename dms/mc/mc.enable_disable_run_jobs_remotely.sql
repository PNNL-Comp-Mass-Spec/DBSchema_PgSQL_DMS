--
-- Name: enable_disable_run_jobs_remotely(integer, text, integer, integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_run_jobs_remotely(IN _enable integer, IN _managernamelist text DEFAULT ''::text, IN _infoonly integer DEFAULT 0, IN _addmgrparamsifmissing integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enables or disables a manager to run jobs remotely
**
**  Arguments:
**    _enable                  0 to disable running jobs remotely, 1 to enable
**    _managerNameList         Manager(s) to update; supports % for wildcards
**    _infoOnly                When non-zero, show the managers that would be updated
**    _addMgrParamsIfMissing   When 1, if manger(s) are missing parameters RunJobsRemotely or RemoteHostName, will auto-add those parameters
**
**  Example usage:
**
**      Call mc.enable_disable_run_jobs_remotely(1, 'Pub-14-2,Pub-15-2', _infoOnly => 1, _addMgrParamsIfMissing => 0);
**      Call mc.enable_disable_run_jobs_remotely(1, 'Pub-14-2,Pub-15-2', _infoOnly => 0, _addMgrParamsIfMissing => 0);
**
**  Auth:   mem
**  Date:   03/28/2018 mem - Initial version
**          03/29/2018 mem - Add parameter _addMgrParamsIfMissing
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling ParseManagerNameList
**          03/24/2022 mem - Fix typo in comment
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _newValue text;
    _activeStateDescription text;
    _countToUpdate int;
    _countUnchanged int;
    _mgrRecord record;
    _mgrName text := '';
    _mgrId int := 0;
    _paramTypeId int := 0;
    _infoHead text;
    _infoData text;
    _previewData record;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _managerNameList := Coalesce(_managerNameList, '');
    _infoOnly := Coalesce(_infoOnly, 0);
    _addMgrParamsIfMissing := Coalesce(_addMgrParamsIfMissing, 0);

    _message := '';
    _returnCode := '';

    If _enable Is Null Then
        _message := '_enable cannot be null';
        _returnCode := 'U4000';
        Return;
    End If;

    If char_length(_managerNameList) = 0 Then
        _message := '_managerNameList cannot be blank';
        _returnCode := 'U4003';
        Return;
    End If;

    -----------------------------------------------
    -- Create a temporary table
    -----------------------------------------------

    CREATE TEMP TABLE TmpManagerList (
        manager_name citext NOT NULL
    );

    -- Populate TmpManagerList using parse_manager_name_list
    --
    INSERT INTO TmpManagerList (manager_name)
    SELECT manager_name
    FROM mc.parse_manager_name_list (_managerNameList, _remove_unknown_managers => 1);

    IF NOT EXISTS (SELECT * FROM TmpManagerList) THEN
        _message := 'No valid managers were found in _managerNameList';
        RAISE INFO '%', _message;

        DROP TABLE TmpManagerList;
        Return;
    END IF;

    -- Set _newValue based on _enable
    If _enable = 0 Then
        _newValue := 'False';
        _activeStateDescription := 'run jobs locally';
    Else
        _newValue := 'True';
        _activeStateDescription := 'run jobs remotely';
    End If;

    If Exists (Select * From TmpManagerList Where manager_name = 'Default_AnalysisMgr_Params') Then
        Delete From TmpManagerList Where manager_name = 'Default_AnalysisMgr_Params';

        _message := 'For safety, not updating RunJobsRemotely for manager Default_AnalysisMgr_Params';

        If Exists (Select * From TmpManagerList) Then
            -- TmpManagerList contains other managers; update them
            RAISE INFO '%', _message;
        Else
            -- TmpManagerList is now empty; abort
            RAISE INFO '%', _message;

            DROP TABLE TmpManagerList;
            Return;
        End If;
    End If;

    If _addMgrParamsIfMissing > 0 Then
        -- <a>
        FOR _mgrRecord IN
            SELECT U.manager_name,
                   M.mgr_id
            FROM TmpManagerList U
                 INNER JOIN mc.t_mgrs M
                   ON U.manager_name = M.mgr_name
            ORDER BY U.manager_name
        LOOP

            _mgrName := _mgrRecord.manager_name;
            _mgrId   := _mgrRecord.mgr_id;

            If Not Exists (SELECT * FROM mc.v_mgr_params Where ParameterName = 'RunJobsRemotely' And ManagerName = _mgrName) Then
                -- <d1>

                SELECT param_id
                INTO _paramTypeId
                FROM mc.t_param_type
                WHERE param_name = 'RunJobsRemotely';

                If Coalesce(_paramTypeId, 0) = 0 Then
                    RAISE WARNING '%', 'Error: could not find parameter "RunJobsRemotely" in mc.t_param_type';
                Else
                    If _infoOnly > 0 Then
                        RAISE INFO '%', 'Would create parameter RunJobsRemotely for Manager ' || _mgrName || ', value ' || _newValue;

                        -- Actually do go ahead and create the parameter, but use a value of False even if _newValue is True
                        -- We need to do this so the managers are included in the query below with PT.ParamName = 'RunJobsRemotely'
                        INSERT INTO mc.t_param_value (mgr_id, type_id, value)
                        VALUES (_mgrId, _paramTypeId, 'False');
                    Else
                        INSERT INTO mc.t_param_value (mgr_id, type_id, value)
                        VALUES (_mgrId, _paramTypeId, _newValue);
                    End If;
                End If;
            End If; -- </d1>

            If Not Exists (SELECT * FROM mc.v_mgr_params Where ParameterName = 'RemoteHostName' And ManagerName = _mgrName) Then
                -- <d2>

                SELECT param_id
                INTO _paramTypeId
                FROM mc.t_param_type
                WHERE param_name = 'RemoteHostName';

                If Coalesce(_paramTypeId, 0) = 0 Then
                    RAISE WARNING '%', 'Error: could not find parameter "RemoteHostName" in mc.t_param_type';
                Else
                    If _infoOnly > 0 Then
                        RAISE INFO '%', 'Would create parameter RemoteHostName  for Manager ' || _mgrName || ', value PrismWeb2';
                    Else
                        INSERT INTO mc.t_param_value (mgr_id, type_id, value)
                        VALUES (_mgrId, _paramTypeId, 'PrismWeb2');
                    End If;
                End If;
            End If; -- </d1>

        End Loop;

        If _infoOnly > 0 Then
            RAISE INFO '%', '';
        End If;

    End If; -- </a>

    -- Count the number of managers that need to be updated
    --
    SELECT COUNT(*)
    INTO _countToUpdate
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.type_id = PT.param_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN TmpManagerList U
           ON M.mgr_name = U.manager_name
    WHERE PT.param_name = 'RunJobsRemotely' AND
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
           ON PV.type_id = PT.param_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN TmpManagerList U
           ON M.mgr_name = U.manager_name
    WHERE PT.param_name = 'RunJobsRemotely' AND
          PV.value = _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    _countToUpdate  := COALESCE(_countToUpdate, 0);
    _countUnchanged := COALESCE(_countUnchanged, 0);

    If _countToUpdate = 0 Then
        If _countUnchanged = 0 Then
            If _addMgrParamsIfMissing = 0 THEN
                _message := 'None of the managers in _managerNameList has parameter "RunJobsRemotely" defined; use _addMgrParamsIfMissing := 1 to auto-add it';
            Else
                _message := 'No managers were found matching _managerNameList';
            End If;
        Else
            If _countUnchanged = 1 Then
                _message := 'The manager is already set to ' || _activeStateDescription;
            Else
                _message := 'All ' || _countUnchanged::text || ' managers are already set to ' || _activeStateDescription;
            End If;
        End If;

        RAISE INFO '%', _message;

        DROP TABLE TmpManagerList;
        Return;
    End If;

    If _infoOnly <> 0 Then

        _infoHead := format('%-22s %-17s %-20s',
                            'State Change Preview',
                            'Parameter Name',
                            'Manager Name'
                        );

        RAISE INFO '%', _infoHead;

        FOR _previewData IN
            SELECT PV.value || ' --> ' || _newValue AS State_Change_Preview,
                   PT.param_name AS Parameter_Name,
                   M.mgr_name AS manager_name
            FROM mc.t_param_value PV
                 INNER JOIN mc.t_param_type PT
                   ON PV.type_id = PT.param_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
                 INNER JOIN TmpManagerList U
                   ON M.mgr_name = U.manager_name
            WHERE PT.param_name = 'RunJobsRemotely' AND
                  PV.value <> _newValue AND
                  MT.mgr_type_active > 0
        LOOP

            _infoData := format('%-22s %-17s %-20s',
                                    _previewData.State_Change_Preview,
                                    _previewData.Parameter_Name,
                                    _previewData.manager_name
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

        _message := format('Would set %s %s to have RunJobsRemotely set to %s; see the Output window for details',
                            _countToUpdate,
                            public.check_plural(_countToUpdate, 'manager', 'managers'),
                            _newValue);

        DROP TABLE TmpManagerList;
        Return;
    End If;

    -- Update RunJobsRemotely for the managers in TmpManagerList
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
         INNER JOIN TmpManagerList U
           ON M.mgr_name = U.manager_name
    WHERE mc.t_param_value.entry_ID = PV.Entry_ID AND
          PT.param_name = 'RunJobsRemotely' AND
          PV.value <> _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 1 And _countUnchanged = 0 Then
        _message := 'Configured the manager to ' || _activeStateDescription;
    Else
        _message := format('Configured %s %s to %s',
                        _myRowCount,
                        public.check_plural(_myRowCount, 'manager', 'managers'),
                        _activeStateDescription);

        If _countUnchanged <> 0 Then
            _message := _message ||
                            format (' (%s %s already set to %s )',
                            _countUnchanged,
                            public.check_plural(_countUnchanged, 'manager was', 'managers were'),
                            _activeStateDescription);
        End If;
    End If;

    RAISE INFO '%', _message;

    DROP TABLE TmpManagerList;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error enabling/disabling managers to run jobs remotely: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning '%', _message;
    RAISE Warning 'Context: %', _exceptionContext;

    Call public.post_log_entry ('Error', _message, 'EnableDisableRunJobsRemotely', 'mc');

    DROP TABLE IF EXISTS TmpManagerList;
END
$$;


ALTER PROCEDURE mc.enable_disable_run_jobs_remotely(IN _enable integer, IN _managernamelist text, IN _infoonly integer, IN _addmgrparamsifmissing integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_disable_run_jobs_remotely(IN _enable integer, IN _managernamelist text, IN _infoonly integer, IN _addmgrparamsifmissing integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_disable_run_jobs_remotely(IN _enable integer, IN _managernamelist text, IN _infoonly integer, IN _addmgrparamsifmissing integer, INOUT _message text, INOUT _returncode text) IS 'EnableDisableRunJobsRemotely';

