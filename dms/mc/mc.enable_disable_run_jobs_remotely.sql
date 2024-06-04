--
-- Name: enable_disable_run_jobs_remotely(boolean, text, boolean, boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.enable_disable_run_jobs_remotely(IN _enable boolean, IN _managernamelist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _addmgrparamsifmissing boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Enable or disable a manager to run jobs remotely
**
**  Arguments:
**    _enable                   False to disable running jobs remotely, true to enable
**    _managerNameList          Manager(s) to update; supports % for wildcards
**    _infoOnly                 When true, show the managers that would be updated
**    _addMgrParamsIfMissing    When true, if manger(s) are missing parameters RunJobsRemotely or RemoteHostName, will auto-add those parameters
**    _message                  Status message
**    _returnCode               Return code
**
**  Example usage:
**
**      CALL mc.enable_disable_run_jobs_remotely(true, 'Pub-14-2,Pub-15-2', _infoOnly => true,  _addMgrParamsIfMissing => false);
**      CALL mc.enable_disable_run_jobs_remotely(true, 'Pub-14-2,Pub-15-2', _infoOnly => false, _addMgrParamsIfMissing => false);
**
**  Auth:   mem
**  Date:   03/28/2018 mem - Initial version
**          03/29/2018 mem - Add parameter _addMgrParamsIfMissing
**          02/05/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Parse_Manager_Name_List
**          03/24/2022 mem - Fix typo in comment
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**                         - Update return codes
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _enable and _infoOnly and false from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**          05/13/2023 mem - Rename variables
**          05/22/2023 mem - Use format() for string concatenation
**          05/25/2023 mem - Simplify calls to RAISE INFO
**          05/30/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(PV.entry_id) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**                         - Update warning messages
**          09/11/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          11/06/2023 mem - Use new column names in view v_mgr_params
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _updateCount int := 0;
    _newValue text;
    _activeStateDescription text;
    _countToUpdate int;
    _countUnchanged int;
    _mgrRecord record;
    _mgrName text := '';
    _mgrId int := 0;
    _paramTypeId int := 0;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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

    _managerNameList       := Trim(Coalesce(_managerNameList, ''));
    _infoOnly              := Coalesce(_infoOnly, false);
    _addMgrParamsIfMissing := Coalesce(_addMgrParamsIfMissing, false);

    If _enable Is Null Then
        _message := '_enable cannot be null';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _managerNameList = '' Then
        _message := '_managerNameList must be specified';
        _returnCode := 'U5202';
        RETURN;
    End If;

    -----------------------------------------------
    -- Create a temporary table
    -----------------------------------------------

    CREATE TEMP TABLE Tmp_ManagerList (
        manager_name citext NOT NULL
    );

    -- Populate Tmp_ManagerList using parse_manager_name_list

    INSERT INTO Tmp_ManagerList (manager_name)
    SELECT manager_name
    FROM mc.parse_manager_name_list (_managerNameList, _remove_unknown_managers => 1);

    If Not Exists (SELECT * FROM Tmp_ManagerList) Then
        _message := 'No valid managers were found in _managerNameList';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    -- Set _newValue based on _enable
    If _enable Then
        _newValue := 'True';
        _activeStateDescription := 'run jobs remotely';
    Else
        _newValue := 'False';
        _activeStateDescription := 'run jobs locally';
    End If;

    If Exists (SELECT manager_name FROM Tmp_ManagerList WHERE manager_name = 'Default_AnalysisMgr_Params') Then
        DELETE FROM Tmp_ManagerList WHERE manager_name = 'Default_AnalysisMgr_Params';

        _message := 'For safety, not updating RunJobsRemotely for manager Default_AnalysisMgr_Params';

        If Exists (SELECT manager_name FROM Tmp_ManagerList) Then
            -- Tmp_ManagerList contains other managers; update them
            RAISE INFO '%', _message;
        Else
            -- Tmp_ManagerList is now empty; abort
            RAISE INFO '%', _message;

            DROP TABLE Tmp_ManagerList;
            RETURN;
        End If;
    End If;

    If _addMgrParamsIfMissing Then

        FOR _mgrRecord IN
            SELECT U.manager_name,
                   M.mgr_id
            FROM Tmp_ManagerList U
                 INNER JOIN mc.t_mgrs M
                   ON U.manager_name = M.mgr_name
            ORDER BY U.manager_name
        LOOP

            _mgrName := _mgrRecord.manager_name;
            _mgrId   := _mgrRecord.mgr_id;

            If Not Exists (SELECT parameter_name FROM mc.v_mgr_params WHERE parameter_name = 'RunJobsRemotely' AND manager_name = _mgrName) Then

                SELECT param_type_id
                INTO _paramTypeId
                FROM mc.t_param_type
                WHERE param_name = 'RunJobsRemotely';

                If Coalesce(_paramTypeId, 0) = 0 Then
                    RAISE WARNING 'Error: could not find parameter "RunJobsRemotely" in mc.t_param_type';
                Else
                    If _infoOnly Then
                        RAISE INFO 'Would create parameter RunJobsRemotely for Manager %, value %', _mgrName, _newValue;

                        -- Actually do go ahead and create the parameter, but use a value of False even if _newValue is True
                        -- We need to do this so the managers are included in the query below with PT.ParamName = 'RunJobsRemotely'
                        INSERT INTO mc.t_param_value (mgr_id, param_type_id, value)
                        VALUES (_mgrId, _paramTypeId, 'False');
                    Else
                        INSERT INTO mc.t_param_value (mgr_id, param_type_id, value)
                        VALUES (_mgrId, _paramTypeId, _newValue);
                    End If;
                End If;
            End If;

            If Not Exists (SELECT parameter_name FROM mc.v_mgr_params WHERE parameter_name = 'RemoteHostName' AND manager_name = _mgrName) Then

                SELECT param_type_id
                INTO _paramTypeId
                FROM mc.t_param_type
                WHERE param_name = 'RemoteHostName';

                If Coalesce(_paramTypeId, 0) = 0 Then
                    RAISE WARNING 'Error: could not find parameter "RemoteHostName" in mc.t_param_type';
                Else
                    If _infoOnly Then
                        RAISE INFO 'Would create parameter RemoteHostName for Manager %, value PrismWeb2', _mgrName;
                    Else
                        INSERT INTO mc.t_param_value (mgr_id, param_type_id, value)
                        VALUES (_mgrId, _paramTypeId, 'PrismWeb2');
                    End If;
                End If;
            End If;

        END LOOP;

        If _infoOnly Then
            RAISE INFO '';
        End If;

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
    WHERE PT.param_name = 'RunJobsRemotely' AND
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
    WHERE PT.param_name = 'RunJobsRemotely' AND
          PV.value = _newValue AND
          MT.mgr_type_active > 0;

    _countToUpdate  := Coalesce(_countToUpdate, 0);
    _countUnchanged := Coalesce(_countUnchanged, 0);

    If _countToUpdate = 0 Then
        If _countUnchanged = 0 Then
            If Not _addMgrParamsIfMissing THEN
                _message := 'None of the managers in _managerNameList has parameter "RunJobsRemotely" defined; use _addMgrParamsIfMissing => true to auto-add it';
            Else
                _message := 'No managers were found matching _managerNameList';
            End If;
        Else
            If _countUnchanged = 1 Then
                _message := format('The manager is already set to %s', _activeStateDescription);
            Else
                _message := format('All %s managers are already set to %s',
                                    _countUnchanged, _activeStateDescription);
            End If;
        End If;

        RAISE INFO '%', _message;

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-22s %-17s %-20s';

        _infoHead := format(_formatSpecifier,
                            'State Change Preview',
                            'Parameter Name',
                            'Manager Name'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------------',
                                     '-----------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT format('%s --> %s', PV.value, _newValue) AS State_Change_Preview,
                   PT.param_name AS Parameter_Name,
                   M.mgr_name AS manager_name
            FROM mc.t_param_value PV
                 INNER JOIN mc.t_param_type PT
                   ON PV.param_type_id = PT.param_type_id
                 INNER JOIN mc.t_mgrs M
                   ON PV.mgr_id = M.mgr_id
                 INNER JOIN mc.t_mgr_types MT
                   ON M.mgr_type_id = MT.mgr_type_id
                 INNER JOIN Tmp_ManagerList U
                   ON M.mgr_name = U.manager_name
            WHERE PT.param_name = 'RunJobsRemotely' AND
                  PV.value <> _newValue AND
                  MT.mgr_type_active > 0
        LOOP
            _infoData := format(_formatSpecifier,
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

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    -- Update RunJobsRemotely for the managers in Tmp_ManagerList

    UPDATE mc.t_param_value
    SET value = _newValue
    FROM mc.t_param_value PV
         INNER JOIN mc.t_param_type PT
           ON PV.param_type_id = PT.param_type_id
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN mc.t_mgr_types MT
           ON M.mgr_type_id = MT.mgr_type_id
         INNER JOIN Tmp_ManagerList U
           ON M.mgr_name = U.manager_name
    WHERE mc.t_param_value.entry_ID = PV.Entry_ID AND
          PT.param_name = 'RunJobsRemotely' AND
          PV.value <> _newValue AND
          MT.mgr_type_active > 0;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount = 1 And _countUnchanged = 0 Then
        _message := format('Configured the manager to %s', _activeStateDescription);
    Else
        _message := format('Configured %s %s to %s',
                        _updateCount,
                        public.check_plural(_updateCount, 'manager', 'managers'),
                        _activeStateDescription);

        If _countUnchanged <> 0 Then
            _message := format ('%s (%s %s already set to %s)',
                            _message,
                            _countUnchanged,
                            public.check_plural(_countUnchanged, 'manager was', 'managers were'),
                            _activeStateDescription);
        End If;
    End If;

    RAISE INFO '%', _message;

    DROP TABLE Tmp_ManagerList;

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


ALTER PROCEDURE mc.enable_disable_run_jobs_remotely(IN _enable boolean, IN _managernamelist text, IN _infoonly boolean, IN _addmgrparamsifmissing boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE enable_disable_run_jobs_remotely(IN _enable boolean, IN _managernamelist text, IN _infoonly boolean, IN _addmgrparamsifmissing boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.enable_disable_run_jobs_remotely(IN _enable boolean, IN _managernamelist text, IN _infoonly boolean, IN _addmgrparamsifmissing boolean, INOUT _message text, INOUT _returncode text) IS 'EnableDisableRunJobsRemotely';

