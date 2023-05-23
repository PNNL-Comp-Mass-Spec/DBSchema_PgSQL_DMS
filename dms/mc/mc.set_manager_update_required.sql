--
-- Name: set_manager_update_required(text, boolean, boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.set_manager_update_required(IN _mgrlist text DEFAULT ''::text, IN _showtable boolean DEFAULT false, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Sets ManagerUpdateRequired to true for the given list of managers
**      If _managerList is blank, then sets it to true for all "Analysis Tool Manager" managers
**
**  Arguments:
**    _mgrList      Comma separated list of manager names; supports wildcards. If blank, selects all managers of type 11 (Analysis Tool Manager)
**    _showTable    Set to true to show the old and new values using RAISE INFO messages when _infoOnly is false; ignored when _infoOnly is true (since the table output is always shown)
**    _infoOnly     True to preview changes, false to make changes
**
**  Example usage:
**
**      UPDATE mc.v_param_value SET value = 'false' WHERE mgr_name = 'pub-10-1' AND param_name = 'ManagerUpdateRequired';
**      Call mc.set_manager_update_required ('Pub-10-1, Pub-12-%', _showTable => true, _infoOnly => true);
**
**  Auth:   mem
**  Date:   01/24/2009 mem - Initial version
**          04/17/2014 mem - Expanded _managerList to varchar(max) and added parameter _showTable
**          02/08/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling ParseManagerNameList
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp table before exiting the procedure
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _infoOnly and _showTable from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**          05/12/2023 mem - Rename variables
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _insertCount int;
    _updateCount int;
    _mgrID int;
    _paramTypeID int;
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
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrList := Coalesce(_mgrList, '');
    _showTable := Coalesce(_showTable, false);
    _infoOnly := Coalesce(_infoOnly, false);

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
            RETURN;
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
    -- Lookup the ParamID value for 'ManagerUpdateRequired'
    ---------------------------------------------------

    SELECT param_type_id
    INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'ManagerUpdateRequired';

    IF NOT FOUND THEN
        _message := 'Could not find parameter ManagerUpdateRequired in mc.t_param_type';
        _returnCode := 'U5201';

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure each manager in Tmp_ManagerList has an entry
    -- in mc.t_param_value for 'ManagerUpdateRequired'
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
        _message := format('Added entry for ManagerUpdateRequired to mc.t_param_value for %s %s',
                        _insertCount,
                        public.check_plural(_insertCount, 'manager', 'managers'));

        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Update the 'ManagerUpdateRequired' entry for each manager in Tmp_ManagerList
    ---------------------------------------------------

    If _infoOnly THEN
        _formatSpecifier := '%-10s %-25s %-25s %-15s %-18s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'Update Required',
                            'New Update Required',
                            'Last Affected'
                        );

        RAISE INFO '%', _infoHead;

       _countToUpdate := 0;

        FOR _previewData IN
            SELECT MP.mgr_id,
                   MP.manager,
                   MP.param_name,
                   MP.value AS update_required,
                   'True' AS new_update_required,
                   MP.last_affected
            FROM mc.v_analysis_mgr_params_update_required MP
                 INNER JOIN Tmp_ManagerList MgrList
                   ON MP.mgr_id = MgrList.mgr_id
            WHERE MP.param_type_id = _paramTypeID
            ORDER BY MP.manager
        LOOP

            _infoData := format(_formatSpecifier,
                                    _previewData.mgr_id,
                                    _previewData.manager,
                                    _previewData.param_name,
                                    _previewData.update_required,
                                    _previewData.new_update_required,
                                    _previewData.last_affected
                            );

            RAISE INFO '%', _infoData;

            _countToUpdate := _countToUpdate + 1;
        END LOOP;

        _message := format('Would set ManagerUpdateRequired to True for %s %s; see the Output window for details',
                            _countToUpdate,
                            public.check_plural(_countToUpdate, 'manager', 'managers'));

        DROP TABLE Tmp_ManagerList;
        RETURN;
    End If;

    UPDATE mc.t_param_value
    SET value = 'True'
    WHERE entry_id in (
        SELECT PV.entry_id
        FROM mc.t_param_value PV
            INNER JOIN Tmp_ManagerList MgrList
            ON PV.mgr_id = MgrList.mgr_id
        WHERE PV.param_type_id = _paramTypeID AND
            PV.value <> 'True');
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        _message := format('Set ManagerUpdateRequired to True for %s %s',
                        _updateCount,
                        public.check_plural(_updateCount, 'manager', 'managers'));

        RAISE INFO '%', _message;
    ELSE
        _message := 'All managers already have ManagerUpdateRequired set to True';
    End If;

    If _showTable Then
        _formatSpecifier := '%-10s %-25s %-25s %-15s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'Update Required',
                            'Last Affected'
                        );

        RAISE INFO '%', _infoHead;

        FOR _previewData IN
            SELECT U.mgr_id,
                   U.manager,
                   U.param_name,
                   U.value as update_required,
                   U.last_affected
            FROM mc.v_analysis_mgr_params_update_required U
                INNER JOIN Tmp_ManagerList MgrList
                   ON U.mgr_id = MgrList.mgr_id
            ORDER BY U.Manager
        LOOP

            _infoData := format(_formatSpecifier,
                                    _previewData.mgr_id,
                                    _previewData.manager,
                                    _previewData.param_name,
                                    _previewData.update_required,
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


ALTER PROCEDURE mc.set_manager_update_required(IN _mgrlist text, IN _showtable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_manager_update_required(IN _mgrlist text, IN _showtable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.set_manager_update_required(IN _mgrlist text, IN _showtable boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'SetManagerUpdateRequired';

