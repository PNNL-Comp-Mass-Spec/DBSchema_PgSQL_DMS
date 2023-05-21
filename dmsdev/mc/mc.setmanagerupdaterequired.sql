--
-- Name: setmanagerupdaterequired(text, integer, integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.setmanagerupdaterequired(IN _mgrlist text DEFAULT ''::text, IN _showtable integer DEFAULT 0, IN _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Sets ManagerUpdateRequired to true for the given list of managers
**      If _managerList is blank, then sets it to true for all "Analysis Tool Manager" managers
**
**  Arguments:
**    _mgrList   Comma separated list of manager names; supports wildcards. If blank, selects all managers of type 11 (Analysis Tool Manager)
**
**  Auth:   mem
**  Date:   01/24/2009 mem - Initial version
**          04/17/2014 mem - Expanded _managerList to varchar(max) and added parameter _showTable
**          02/08/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _mgrID int;
    _paramTypeID int;
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
    _showTable := Coalesce(_showTable, 0);
    _infoOnly := Coalesce(_infoOnly, 0);
    _message := '';
    _returnCode := '';

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
        CALL ParseManagerNameList (_mgrList, _removeUnknownManagers => 1, _message => _message);

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
    -- Lookup the ParamID value for 'ManagerUpdateRequired'
    ---------------------------------------------------

    SELECT param_id INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'ManagerUpdateRequired';

    IF NOT FOUND THEN
        _message := 'Could not find parameter ManagerUpdateRequired in mc.t_param_type';
        _returnCode := 'U5201';
        Return;
    End If;

    ---------------------------------------------------
    -- Make sure each manager in TmpManagerList has an entry
    --  in mc.t_param_value for 'ManagerUpdateRequired'
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
        _message := 'Added entry for "ManagerUpdateRequired" to mc.t_param_value for ' || _myRowCount::text || ' manager';
        If _myRowCount > 1 Then
            _message := _message || 's';
        End If;

        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Update the 'ManagerUpdateRequired' entry for each manager in TmpManagerList
    ---------------------------------------------------

    If _infoOnly <> 0 THEN
        _infoHead := format('%-10s %-25s %-25s %-15s %-18s %-25s',
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
                 INNER JOIN TmpManagerList MgrList
                   ON MP.mgr_id = MgrList.mgr_id
            WHERE MP.ParamTypeID = _paramTypeID
            ORDER BY MP.manager
        LOOP

            _infoData := format('%-10s %-25s %-25s %-15s %-18s %-25s',
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

        _message := format('Would set ManagerUpdateRequired to True for %s managers; see the Output window for details',
                            _countToUpdate);

        Return;
    End If;

    UPDATE mc.t_param_value
    SET value = 'True'
    WHERE entry_id in (
        SELECT PV.entry_id
        FROM mc.t_param_value PV
            INNER JOIN TmpManagerList MgrList
            ON PV.mgr_id = MgrList.mgr_id
        WHERE PV.type_id = _paramTypeID AND
            PV.value <> 'True');
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := 'Set "ManagerUpdateRequired" to True for ' || _myRowCount::text || ' manager';
        If _myRowCount > 1 Then
            _message := _message || 's';
        End If;

        RAISE INFO '%', _message;
    ELSE
        _message := 'All managers already have ManagerUpdateRequired set to True';
    End If;

 If _showTable <> 0 Then
        _infoHead := format('%-10s %-25s %-25s %-15s %-25s',
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
                INNER JOIN TmpManagerList MgrList
                   ON U.mgr_id = MgrList.mgr_id
            ORDER BY U.Manager
        LOOP

            _infoData := format('%-10s %-25s %-25s %-15s %-25s',
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

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating ManagerUpdateRequired for multiple managers in mc.t_param_value: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    CALL PostLogEntry ('Error', _message, 'SetManagerUpdateRequired', 'mc');

END
$$;


ALTER PROCEDURE mc.setmanagerupdaterequired(IN _mgrlist text, IN _showtable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE setmanagerupdaterequired(IN _mgrlist text, IN _showtable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.setmanagerupdaterequired(IN _mgrlist text, IN _showtable integer, IN _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'SetManagerUpdateRequired';

