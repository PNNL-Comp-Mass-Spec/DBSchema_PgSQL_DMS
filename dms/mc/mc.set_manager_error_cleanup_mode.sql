--
-- Name: set_manager_error_cleanup_mode(text, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.set_manager_error_cleanup_mode(IN _mgrlist text DEFAULT ''::text, IN _cleanupmode integer DEFAULT 1, IN _showtable boolean DEFAULT true, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Sets ManagerErrorCleanupMode to _cleanupMode for the given list of managers
**      If _mgrList is blank, then sets it to _cleanupMode for all "Analysis Tool Manager" managers
**
**  Arguments:
**    _mgrList       Comma separated list of manager names; supports wildcards. If blank, selects all managers of type 11 (Analysis Tool Manager)
**    _cleanupMode   0 = No auto cleanup, 1 = Attempt auto cleanup once, 2 = Auto cleanup always
**    _showTable     Set to true to show the cleanup mode for the specified managers
**
**  Example usage:
**
**      Call mc.set_manager_error_cleanup_mode('Pub-10-1,Pub-11%', 1, _infoonly => true);
**
**  Auth:   mem
**  Date:   09/10/2009 mem - Initial version
**          09/29/2014 mem - Expanded _mgrList to varchar(max) and added parameters _showTable and _infoOnly
**                         - Fixed where clause bug in final update query
**          02/07/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling ParseManagerNameList
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _showTable and _infoOnly from integer to boolean
**          01/30/2023 mem - Use new column name in view
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _mgrID int;
    _paramTypeID int;
    _cleanupModeString text;
    _countToUpdate int;

    _formatSpecifier text;
    _infoHead text;
    _infoData text;
    _previewData record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrList := Coalesce(_mgrList, '');
    _cleanupMode := Coalesce(_cleanupMode, 1);
    _showTable := Coalesce(_showTable, true);
    _infoOnly := Coalesce(_infoOnly, false);

    _message := '';
    _returnCode := '';

    If _cleanupMode < 0 Then
        _cleanupMode := 0;
    End If;

    If _cleanupMode > 2 Then
        _cleanupMode := 2;
    End If;

    CREATE TEMP TABLE Tmp_ManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL
    );

    If char_length(_mgrList) > 0 AND _mgrList <> '%' Then
        ---------------------------------------------------
        -- Populate Tmp_ManagerList with the managers in _mgrList
        ---------------------------------------------------
        --
        INSERT INTO Tmp_ManagerList (manager_name)
        SELECT manager_name
        FROM mc.parse_manager_name_list (_mgrList, _remove_unknown_managers => 1);

        IF NOT EXISTS (SELECT * FROM Tmp_ManagerList) THEN
            _message := 'No valid managers were found in _mgrList';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_ManagerList;
            Return;
        END IF;

        UPDATE Tmp_ManagerList
        SET mgr_id = M.mgr_id
        FROM mc.t_mgrs M
        WHERE Tmp_ManagerList.Manager_Name = M.mgr_name;

        DELETE FROM Tmp_ManagerList
        WHERE mgr_id IS NULL;

    Else
        INSERT INTO Tmp_ManagerList (mgr_id, manager_name)
        SELECT mgr_id, mgr_name
        FROM mc.t_mgrs
        WHERE mgr_type_id = 11;
    End If;

    ---------------------------------------------------
    -- Lookup the ParamID value for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    SELECT param_id
    INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'ManagerErrorCleanupMode';

    IF NOT FOUND THEN
        _message := 'Could not find parameter ManagerErrorCleanupMode in mc.t_param_type';
        _returnCode := 'U5201';

        DROP TABLE Tmp_ManagerList;
        Return;
    End If;

    ---------------------------------------------------
    -- Make sure each manager in Tmp_ManagerList has an entry
    --  in mc.t_param_value for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    INSERT INTO mc.t_param_value (mgr_id, type_id, value)
    SELECT A.mgr_id, _paramTypeID, '0'
    FROM ( SELECT MgrListA.mgr_id
           FROM Tmp_ManagerList MgrListA
         ) A
         LEFT OUTER JOIN
          ( SELECT MgrListB.mgr_id
            FROM Tmp_ManagerList MgrListB
                 INNER JOIN mc.t_param_value PV
                   ON MgrListB.mgr_id = PV.mgr_id
            WHERE PV.type_id = _paramTypeID
         ) B
           ON A.mgr_id = B.mgr_id
    WHERE B.mgr_id IS NULL;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount <> 0 Then
        _message := 'Added entry for "ManagerErrorCleanupMode" to mc.t_param_value for ' || _myRowCount::text || ' manager';
        If _myRowCount > 1 Then
            _message := _message || 's';
        End If;

        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Update the 'ManagerErrorCleanupMode' entry for each manager in Tmp_ManagerList
    ---------------------------------------------------

    _cleanupModeString := _cleanupMode::text;

    If _infoOnly THEN

        _formatSpecifier := '%-10s %-25s %-25s %-15s %-18s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'Cleanup Mode',
                            'New Cleanup Mode',
                            'Last Affected'
                        );

        RAISE INFO '%', _infoHead;

       _countToUpdate := 0;

        FOR _previewData IN
            SELECT MP.mgr_id,
                   MP.manager,
                   MP.param_name,
                   MP.value AS cleanup_mode,
                   _cleanupMode AS new_cleanup_mode,
                   MP.last_affected
            FROM mc.v_analysis_mgr_params_active_and_debug_level MP
                 INNER JOIN Tmp_ManagerList MgrList
                   ON MP.mgr_id = MgrList.mgr_id
            WHERE MP.param_type_id = _paramTypeID
            ORDER BY MP.manager
        LOOP

            _infoData := format(_formatSpecifier,
                                    _previewData.mgr_id,
                                    _previewData.manager,
                                    _previewData.param_name,
                                    _previewData.cleanup_mode,
                                    _previewData.new_cleanup_mode,
                                    _previewData.last_affected
                            );

            RAISE INFO '%', _infoData;

            _countToUpdate := _countToUpdate + 1;
        END LOOP;

        _message := format('Would set ManagerErrorCleanupMode to %s for %s managers; see the Output window for details',
                            _cleanupMode,
                            _countToUpdate);

        DROP TABLE Tmp_ManagerList;
        Return;
    End If;

    UPDATE mc.t_param_value
    SET value = _cleanupModeString
    WHERE entry_id in (
        SELECT PV.entry_id
        FROM mc.t_param_value PV
            INNER JOIN Tmp_ManagerList MgrList
            ON PV.mgr_id = MgrList.mgr_id
        WHERE PV.type_id = _paramTypeID AND
            PV.value <> _cleanupModeString);
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := 'Set "ManagerErrorCleanupMode" to ' || _cleanupModeString || ' for ' || _myRowCount::text || ' manager';
        If _myRowCount > 1 Then
            _message := _message || 's';
        End If;

        RAISE INFO '%', _message;
    ELSE
        _message := 'All managers already have ManagerErrorCleanupMode set to ' || _cleanupModeString;
    End If;

    ---------------------------------------------------
    -- Optionally show the new values
    ---------------------------------------------------

    If _showTable Then

        _formatSpecifier := '%-10s %-25s %-25s %-15s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'Cleanup Mode',
                            'Last Affected'
                        );

        RAISE INFO '%', _infoHead;

        FOR _previewData IN
            SELECT MP.mgr_id,
                   MP.manager,
                   MP.param_name,
                   MP.value AS cleanup_mode,
                   MP.last_affected
            FROM mc.v_analysis_mgr_params_active_and_debug_level MP
                 INNER JOIN Tmp_ManagerList MgrList
                   ON MP.mgr_id = MgrList.mgr_id
            WHERE MP.param_type_id = _paramTypeID
            ORDER BY MP.manager
        LOOP

            _infoData := format(_formatSpecifier,
                                    _previewData.mgr_id,
                                    _previewData.manager,
                                    _previewData.param_name,
                                    _previewData.cleanup_mode,
                                    _previewData.last_affected
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

         _message := _message || '; see the Output window for details';

    End If;

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


ALTER PROCEDURE mc.set_manager_error_cleanup_mode(IN _mgrlist text, IN _cleanupmode integer, IN _showtable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_manager_error_cleanup_mode(IN _mgrlist text, IN _cleanupmode integer, IN _showtable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.set_manager_error_cleanup_mode(IN _mgrlist text, IN _cleanupmode integer, IN _showtable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SetManagerErrorCleanupMode';

