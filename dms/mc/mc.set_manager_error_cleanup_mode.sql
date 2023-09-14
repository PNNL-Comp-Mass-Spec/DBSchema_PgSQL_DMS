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
**    _mgrList       Comma-separated list of manager names; supports wildcards. If blank, selects all managers of type 11 (Analysis Tool Manager)
**    _cleanupMode   0 = No auto cleanup, 1 = Attempt auto cleanup once, 2 = Auto cleanup always
**    _showTable     Set to true to show the cleanup mode for the specified managers
**
**  Example usage:
**
**      CALL mc.set_manager_error_cleanup_mode('Pub-10-1,Pub-11%', 1, _infoonly => true);
**
**  Auth:   mem
**  Date:   09/10/2009 mem - Initial version
**          09/29/2014 mem - Expanded _mgrList to varchar(max) and added parameters _showTable and _infoOnly
**                         - Fixed where clause bug in final update query
**          02/07/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Parse_Manager_Name_List
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _showTable and _infoOnly from integer to boolean
**          01/30/2023 mem - Use new column name in view
**          01/31/2023 mem - Use new column names in tables
**          05/12/2023 mem - Rename variables
**          05/30/2023 mem - Use format() for string concatenation
**          06/24/2023 mem - Use check_plural() to customize preview message
**          08/07/2023 mem - Display a blank line before additional status messages
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _insertCount int := 0;
    _mgrID int;
    _paramTypeID int;
    _cleanupModeString text;
    _countToUpdate int;

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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrList     := Trim(Coalesce(_mgrList, ''));
    _cleanupMode := Coalesce(_cleanupMode, 1);
    _showTable   := Coalesce(_showTable, true);
    _infoOnly    := Coalesce(_infoOnly, false);

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

    If char_length(_mgrList) > 0 And _mgrList <> '%' Then
        ---------------------------------------------------
        -- Populate Tmp_ManagerList with the managers in _mgrList
        ---------------------------------------------------

        INSERT INTO Tmp_ManagerList (manager_name)
        SELECT manager_name
        FROM mc.parse_manager_name_list (_mgrList, _remove_unknown_managers => 1);

        If Not Exists (SELECT * FROM Tmp_ManagerList) Then
            _message := 'No valid managers were found in _mgrList';

            RAISE INFO '';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_ManagerList;
            RETURN;
        End If;

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

    SELECT param_type_id
    INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'ManagerErrorCleanupMode';

    If Not FOUND Then
        _message := 'Could not find parameter ManagerErrorCleanupMode in mc.t_param_type';
        _returnCode := 'U5201';

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure each manager in Tmp_ManagerList has an entry
    -- in mc.t_param_value for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    INSERT INTO mc.t_param_value (mgr_id, param_type_id, value)
    SELECT A.mgr_id, _paramTypeID, '0'
    FROM ( SELECT MgrListA.mgr_id
           FROM Tmp_ManagerList MgrListA
         ) A
         LEFT OUTER JOIN
          ( SELECT MgrListB.mgr_id
            FROM Tmp_ManagerList MgrListB
                 INNER JOIN mc.t_param_value PV
                   ON MgrListB.mgr_id = PV.mgr_id
            WHERE PV.param_type_id = _paramTypeID
         ) B
           ON A.mgr_id = B.mgr_id
    WHERE B.mgr_id IS NULL;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    If _insertCount <> 0 Then
        _message := format('Added entry for "ManagerErrorCleanupMode" to mc.t_param_value for %s %s',
                            _insertCount,
                            public.check_plural(_insertCount, 'manager', 'managers'));

        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Update the 'ManagerErrorCleanupMode' entry for each manager in Tmp_ManagerList
    ---------------------------------------------------

    _cleanupModeString := _cleanupMode::text;

    If _infoOnly THEN

        RAISE INFO '';

        _formatSpecifier := '%-10s %-25s %-25s %-15s %-18s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'Cleanup Mode',
                            'New Cleanup Mode',
                            'Last Affected'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '-------------------------',
                                     '-------------------------',
                                     '---------------',
                                     '------------------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

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

        _message := format('Would set ManagerErrorCleanupMode to %s for %s %s; see the Output window for details',
                            _cleanupMode,
                            _countToUpdate,
                            public.check_plural(_countToUpdate, 'manager', 'managers'));

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    UPDATE mc.t_param_value
    SET value = _cleanupModeString
    WHERE entry_id in (
        SELECT PV.entry_id
        FROM mc.t_param_value PV
            INNER JOIN Tmp_ManagerList MgrList
            ON PV.mgr_id = MgrList.mgr_id
        WHERE PV.param_type_id = _paramTypeID AND
            PV.value <> _cleanupModeString);
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    If _insertCount > 0 Then
        _message := format('Set "ManagerErrorCleanupMode" to %s for %s %s',
                            _cleanupModeString,
                            _insertCount,
                            public.check_plural(_insertCount, 'manager', 'managers'));

        RAISE INFO '';
        RAISE INFO '%', _message;
    ELSE
        _message := format('All managers already have ManagerErrorCleanupMode set to %s', _cleanupModeString);
    End If;

    ---------------------------------------------------
    -- Optionally show the new values
    ---------------------------------------------------

    If _showTable Then

        RAISE INFO '';

        _formatSpecifier := '%-10s %-25s %-25s %-15s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'Cleanup Mode',
                            'Last Affected'
                            );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '-------------------------',
                                     '-------------------------',
                                     '---------------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

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

         _message := format('%s; see the Output window for details', _message);

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

