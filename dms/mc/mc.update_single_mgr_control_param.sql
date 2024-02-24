--
-- Name: update_single_mgr_control_param(text, text, text, text, boolean, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.update_single_mgr_control_param(IN _paramname text, IN _newvalue text, IN _manageridlist text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Change a single manager parameter for set of given managers
**
**  Arguments:
**    _paramName        The parameter name
**    _newValue         The new value to assign for this parameter
**    _managerIDList    Comma-separated list of manager IDs (numbers, not manager names)
**    _callingUser      Username of the calling user
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Example usage:
**
**      CALL mc.update_single_mgr_control_param('orgdbdir', 'G:\DMS_Temp_Org', '1277, 1317, 1318', _infoOnly => true);
**
**  Auth:   jds
**  Date:   06/20/2007
**          07/31/2007 grk - Changed for 'controlfromwebsite' no longer a parameter
**          04/16/2009 mem - Added optional parameter _callingUser; if provided, then Update_Single_Mgr_Param_Work will populate field Entered_By with this name
**          04/08/2011 mem - Will now add parameter _paramValue to managers that don't yet have the parameter defined
**          04/21/2011 mem - Expanded _managerIDList to varchar(8000)
**          05/11/2011 mem - Fixed bug reporting error resolving _paramValue to _paramTypeID
**          04/29/2015 mem - Now parsing _managerIDList using parse_delimited_integer_list
**                         - Added parameter _infoOnly
**                         - Renamed the first parameter from _paramValue to _paramName
**          02/10/2020 mem - Ported to PostgreSQL
**          03/23/2022 mem - Use mc schema when calling Update_Single_Mgr_Param_Work
**                         - Show a warning if all of the managers have control_from_website = 0 in t_mgrs
**          03/24/2022 mem - Show a warning if _managerIDList did not have one or more integers
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new function name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp tables before exiting the procedure
**          08/21/2022 mem - Update return code
**          08/23/2022 mem - Add missing semicolon (which resulted in the RETURN statement being ignored)
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          10/11/2023 mem - Ignore case when resolving parameter name to ID
**          12/08/2023 mem - Select a single column when using If Not Exists()
**
*****************************************************/
DECLARE
    _managerCount int;
    _paramTypeID int;

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

    _newValue := Trim(Coalesce(_newValue, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Resolve _paramName to _paramTypeID
    ---------------------------------------------------

    SELECT param_type_id
    INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = _paramName::citext;

    If Not Found Then
        _message := format('Error: Parameter "%s" not found in mc.t_param_type', _paramName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    RAISE INFO 'Param type ID is %', _paramTypeID;

    ---------------------------------------------------
    -- Create a temporary table that will hold the entry_id
    -- values that need to be updated in mc.t_param_value
    --
    -- Also create a temporary table for tracking manager IDs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamValueEntriesToUpdate (
        entry_id int NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_ParamValueEntriesToUpdate ON Tmp_ParamValueEntriesToUpdate (entry_id);

    CREATE TEMP TABLE Tmp_MgrIDs (
        mgr_id int NOT NULL
    );

    ---------------------------------------------------
    -- Parse the manager ID list
    ---------------------------------------------------

    INSERT INTO Tmp_MgrIDs (mgr_id)
    SELECT value
    FROM public.parse_delimited_integer_list(_managerIDList);
    --
    GET DIAGNOSTICS _managerCount = ROW_COUNT;

    If Not FOUND Then
        _message := 'Use Manager IDs, not manager names';

        RAISE WARNING '%', _message;

        DROP TABLE Tmp_ParamValueEntriesToUpdate;
        DROP TABLE Tmp_MgrIDs;

        RETURN;
    END If;

    RAISE INFO 'Inserted % manager IDs into Tmp_MgrIDs', _managerCount;

    If Not Exists (SELECT M.mgr_id
                   FROM mc.t_mgrs M
                          INNER JOIN Tmp_MgrIDs ON M.mgr_id = Tmp_MgrIDs.mgr_id
                   WHERE M.control_from_website > 0) Then

        _message := 'All of the managers have control_from_website = 0 in t_mgrs; parameters not updated';

        RAISE WARNING '%', _message;

        DROP TABLE Tmp_ParamValueEntriesToUpdate;
        DROP TABLE Tmp_MgrIDs;

        RETURN;
    END If;

    If _infoOnly Then
        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-25s %-25s %-15s %-15s %-15s %-15s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'ParamTypeID',
                            'Value',
                            'New Value',
                            'Status'
                            );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------',
                                     '-------------------------',
                                     '-------------------------',
                                     '---------------',
                                     '---------------',
                                     '---------------',
                                     '---------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT PV.entry_id,
                   M.mgr_id,
                   M.mgr_name,
                   PV.param_name,
                   PV.param_type_id,
                   PV.value,
                   _newValue AS NewValue,
                   CASE WHEN Coalesce(PV.value, '') <> _newValue THEN 'Changed' ELSE 'Unchanged' END AS Status
            FROM mc.t_mgrs M
                 INNER JOIN Tmp_MgrIDs
                   ON M.mgr_id = Tmp_MgrIDs.mgr_id
                 INNER JOIN mc.v_param_value PV
                   ON PV.mgr_id = M.mgr_id AND
                      PV.param_type_id = _paramTypeID
            WHERE M.control_from_website > 0
            UNION
            SELECT PV.entry_id,
                   M.mgr_id,
                   M.mgr_name,
                   PV.param_name,
                   PV.param_type_id,
                   PV.value,
                   '' AS NewValue,
                   'Skipping: control_from_website is 0 in mc.t_mgrs' AS Status
            FROM mc.t_mgrs M
                 INNER JOIN Tmp_MgrIDs
                   ON M.mgr_id = Tmp_MgrIDs.mgr_id
                 INNER JOIN mc.v_param_value PV
                   ON PV.mgr_id = M.mgr_id AND
                      PV.param_type_id = _paramTypeID
            WHERE M.control_from_website = 0
            UNION
            SELECT NULL AS entry_id,
                   M.mgr_id,
                   M.mgr_name,
                   _paramName,
                   _paramTypeID,
                   NULL AS value,
                   _newValue AS NewValue,
                   'New'
            FROM mc.t_mgrs M
                 INNER JOIN Tmp_MgrIDs
                   ON M.mgr_id = Tmp_MgrIDs.mgr_id
                 LEFT OUTER JOIN mc.t_param_value PV
                   ON PV.mgr_id = M.mgr_id AND
                      PV.param_type_id = _paramTypeID
            WHERE PV.param_type_id IS NULL
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.entry_id,
                                _previewData.mgr_id,
                                _previewData.mgr_name,
                                _previewData.param_name,
                                _previewData.param_type_id,
                                _previewData.value,
                                _previewData.NewValue,
                                _previewData.Status
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        _message := public.append_to_text(_message, 'See the Output window for details');

        DROP TABLE Tmp_ParamValueEntriesToUpdate;
        DROP TABLE Tmp_MgrIDs;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Add new entries for Managers in _managerIDList that
    -- don't yet have an entry in mc.t_param_value for parameter _paramName
    --
    -- Adding value '##_DummyParamValue_##' so that
    -- we'll force a call to update_single_mgr_param_work
    --
    -- Intentionally not filtering on M.control_from_website > 0 here,
    -- but the query that populates Tmp_ParamValueEntriesToUpdate does filter on that parameter
    ---------------------------------------------------

    INSERT INTO mc.t_param_value( param_type_id,
                                  value,
                                  mgr_id )
    SELECT _paramTypeID,
           '##_DummyParamValue_##',
           Tmp_MgrIDs.mgr_id
    FROM mc.t_mgrs M
         INNER JOIN Tmp_MgrIDs
           ON M.mgr_id = Tmp_MgrIDs.mgr_id
         LEFT OUTER JOIN mc.t_param_value PV
           ON PV.mgr_id = M.mgr_id AND
              PV.param_type_id = _paramTypeID
    WHERE PV.param_type_id IS NULL;

    ---------------------------------------------------
    -- Find the entries for the Managers in _managerIDList
    -- Populate Tmp_ParamValueEntriesToUpdate with the entries that need to be updated
    ---------------------------------------------------

    INSERT INTO Tmp_ParamValueEntriesToUpdate( entry_id )
    SELECT PV.entry_id
    FROM mc.t_param_value PV
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN Tmp_MgrIDs
           ON M.mgr_id = Tmp_MgrIDs.mgr_id
    WHERE M.control_from_website > 0 AND
          PV.param_type_id = _paramTypeID AND
          Coalesce(PV.value, '') <> _newValue;

    If Not FOUND THEN
        If Not Exists (SELECT PV.entry_id
                       FROM mc.t_param_value PV
                            INNER JOIN mc.t_mgrs M
                              ON PV.mgr_id = M.mgr_id
                            INNER JOIN Tmp_MgrIDs
                              ON M.mgr_id = Tmp_MgrIDs.mgr_id
                       WHERE M.control_from_website > 0 AND
                             PV.param_type_id = _paramTypeID) Then

            -- Example messages:
            -- Managers 1277, 1317, 1318 do not have parameter param_name
            -- Manager 1277 does not have parameter param_name

            _message := format('%s %s %s not have parameter %s',
                                public.check_plural(_managerCount, 'Manager', 'Managers'),
                                _managerIDList,
                                public.check_plural(_managerCount, 'does', 'do'),
                                _paramName);

            RAISE WARNING '%', _message;
        END If;

        _message := format('%s %s for %s',
                            public.check_plural(_managerCount, 'Manager', format('Manager %s already has', _managerIDList), 'All managers already have'),
                            _newValue,
                            _paramName);

        RAISE INFO '%', _message;

        DROP TABLE Tmp_ParamValueEntriesToUpdate;
        DROP TABLE Tmp_MgrIDs;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Call update_single_mgr_param_work to perform the update
    -- Note that it calls alter_entered_by_user_multi_id and alter_event_log_entry_user_multi_id for _callingUser
    ---------------------------------------------------

    CALL mc.update_single_mgr_param_work (
                _paramName,
                _newValue,
                _callingUser,
                _message => _message,           -- Output
                _returnCode => _returnCode);    -- Output

    DROP TABLE Tmp_ParamValueEntriesToUpdate;
    DROP TABLE Tmp_MgrIDs;

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

    DROP TABLE IF EXISTS Tmp_ParamValueEntriesToUpdate;
    DROP TABLE IF EXISTS Tmp_MgrIDs;
END
$$;


ALTER PROCEDURE mc.update_single_mgr_control_param(IN _paramname text, IN _newvalue text, IN _manageridlist text, IN _callinguser text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_single_mgr_control_param(IN _paramname text, IN _newvalue text, IN _manageridlist text, IN _callinguser text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.update_single_mgr_control_param(IN _paramname text, IN _newvalue text, IN _manageridlist text, IN _callinguser text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateSingleMgrControlParam';

