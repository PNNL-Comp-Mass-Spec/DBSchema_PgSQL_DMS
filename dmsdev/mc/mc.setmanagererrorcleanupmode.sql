--
-- Name: setmanagererrorcleanupmode(text, integer, integer, integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.setmanagererrorcleanupmode(IN _mgrlist text DEFAULT ''::text, IN _cleanupmode integer DEFAULT 1, IN _showtable integer DEFAULT 1, IN _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Sets ManagerErrorCleanupMode to _cleanupMode for the given list of managers
**      If _mgrList is blank, then sets it to _cleanupMode for all "Analysis Tool Manager" managers
**
**  Arguments:
**    _mgrList   Comma separated list of manager names; supports wildcards. If blank, selects all managers of type 11 (Analysis Tool Manager)
**    _cleanupMode   0 = No auto cleanup, 1 = Attempt auto cleanup once, 2 = Auto cleanup always
**
**  Auth:   mem
**  Date:   09/10/2009 mem - Initial version
**          09/29/2014 mem - Expanded _mgrList to varchar(max) and added parameters _showTable and _infoOnly
**                         - Fixed where clause bug in final update query
**          02/07/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _mgrID int;
    _paramTypeID int;
    _cleanupModeString text;
    _previewData record;
    _countToUpdate int;
    _infoHead text;
    _infoData text;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrList := Coalesce(_mgrList, '');
    _cleanupMode := Coalesce(_cleanupMode, 1);
    _showTable := Coalesce(_showTable, 1);
    _infoOnly := Coalesce(_infoOnly, 0);
    _message := '';
    _returnCode := '';

    If _cleanupMode < 0 Then
        _cleanupMode := 0;
    End If;

    If _cleanupMode > 2 Then
        _cleanupMode := 2;
    End If;

    DROP TABLE IF EXISTS TmpManagerList;

    CREATE TEMP TABLE TmpManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL
    );

    If char_length(_mgrList) > 0 AND _mgrList <> '%' Then
        ---------------------------------------------------
        -- Populate TmpManagerList with the managers in _mgrList
        ---------------------------------------------------
        --
        Call ParseManagerNameList (_mgrList, _removeUnknownManagers => 1, _message => _message);

        IF NOT EXISTS (SELECT * FROM TmpManagerList) THEN
            _message := 'No valid managers were found in _mgrList';
            RAISE INFO '%', _message;
            Return;
        END IF;

        UPDATE TmpManagerList
        SET mgr_id = M.mgr_id
        FROM mc.t_mgrs M
        WHERE TmpManagerList.Manager_Name = M.mgr_name;

        DELETE FROM TmpManagerList
        WHERE mgr_id IS NULL;

    Else
        INSERT INTO TmpManagerList (mgr_id, manager_name)
        SELECT mgr_id, mgr_name
        FROM mc.t_mgrs
        WHERE mgr_type_id = 11;
    End If;

    ---------------------------------------------------
    -- Lookup the ParamID value for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    SELECT param_id INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'ManagerErrorCleanupMode';

    IF NOT FOUND THEN
        _message := 'Could not find parameter ManagerErrorCleanupMode in mc.t_param_type';
        _returnCode := 'U5201';
        Return;
    End If;

    ---------------------------------------------------
    -- Make sure each manager in TmpManagerList has an entry
    --  in mc.t_param_value for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    INSERT INTO mc.t_param_value (mgr_id, type_id, value)
    SELECT A.mgr_id, _paramTypeID, '0'
    FROM ( SELECT MgrListA.mgr_id
           FROM TmpManagerList MgrListA
         ) A
         LEFT OUTER JOIN
          ( SELECT MgrListB.mgr_id
            FROM TmpManagerList MgrListB
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
    -- Update the 'ManagerErrorCleanupMode' entry for each manager in TmpManagerList
    ---------------------------------------------------

    _cleanupModeString := _cleanupMode::text;

    If _infoOnly <> 0 THEN
        _infoHead := format('%-10s %-25s %-25s %-15s %-18s %-25s',
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
                 INNER JOIN TmpManagerList MgrList
                   ON MP.mgr_id = MgrList.mgr_id
            WHERE MP.ParamTypeID = _paramTypeID
            ORDER BY MP.manager
        LOOP

            _infoData := format('%-10s %-25s %-25s %-15s %-18s %-25s',
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

        Return;
    End If;

    UPDATE mc.t_param_value
    SET value = _cleanupModeString
    WHERE entry_id in (
        SELECT PV.entry_id
        FROM mc.t_param_value PV
            INNER JOIN TmpManagerList MgrList
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

    If _showTable <> 0 Then
        _infoHead := format('%-10s %-25s %-25s %-15s %-25s',
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
                 INNER JOIN TmpManagerList MgrList
                   ON MP.mgr_id = MgrList.mgr_id
            WHERE MP.ParamTypeID = _paramTypeID
            ORDER BY MP.manager
        LOOP

            _infoData := format('%-10s %-25s %-25s %-15s %-25s',
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

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating ManagerErrorCleanupMode for multiple managers in mc.t_param_value: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'SetManagerErrorCleanupMode', 'mc');

END
$$;


ALTER PROCEDURE mc.setmanagererrorcleanupmode(IN _mgrlist text, IN _cleanupmode integer, IN _showtable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE setmanagererrorcleanupmode(IN _mgrlist text, IN _cleanupmode integer, IN _showtable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.setmanagererrorcleanupmode(IN _mgrlist text, IN _cleanupmode integer, IN _showtable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'SetManagerErrorCleanupMode';

