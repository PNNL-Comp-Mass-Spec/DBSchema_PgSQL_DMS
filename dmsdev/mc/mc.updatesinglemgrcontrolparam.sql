--
-- Name: updatesinglemgrcontrolparam(text, text, text, text, integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.updatesinglemgrcontrolparam(_paramname text, _newvalue text, _manageridlist text, _callinguser text DEFAULT ''::text, _infoonly integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Changes single manager params for set of given managers
**
**  Arguments:
**    _paramName       The parameter name
**    _newValue        The new value to assign for this parameter
**    _managerIDList   manager ID values (numbers, not manager names)
**
**  Auth:   jds
**  Date:   06/20/2007
**          07/31/2007 grk - changed for 'controlfromwebsite' no longer a parameter
**          04/16/2009 mem - Added optional parameter _callingUser; if provided, then UpdateSingleMgrParamWork will populate field Entered_By with this name
**          04/08/2011 mem - Will now add parameter _paramValue to managers that don't yet have the parameter defined
**          04/21/2011 mem - Expanded _managerIDList to varchar(8000)
**          05/11/2011 mem - Fixed bug reporting error resolving _paramValue to _paramTypeID
**          04/29/2015 mem - Now parsing _managerIDList using udfParseDelimitedIntegerList
**                         - Added parameter _infoOnly
**                         - Renamed the first parameter from _paramValue to _paramName
**          02/10/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _paramTypeID int;
    _previewData record;
    _infoHead text;
    _infoData text;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _newValue := Coalesce(_newValue, '');
    _infoOnly := Coalesce(_infoOnly, 0);
    _message := '';
    _returnCode := '';
    
    ---------------------------------------------------
    -- Create a temporary table that will hold the entry_id
    -- values that need to be updated in mc.t_param_value
    ---------------------------------------------------

    DROP TABLE IF EXISTS TmpParamValueEntriesToUpdate;

    CREATE TEMP TABLE TmpParamValueEntriesToUpdate (
        entry_id int NOT NULL
    );

    CREATE UNIQUE INDEX IX_TmpParamValueEntriesToUpdate ON TmpParamValueEntriesToUpdate (entry_id);

    DROP TABLE IF EXISTS TmpMgrIDs;

    CREATE TEMP TABLE TmpMgrIDs (
        mgr_id int NOT NULL
    );

    ---------------------------------------------------
    -- Resolve _paramName to _paramTypeID
    ---------------------------------------------------

    SELECT param_id INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = _paramName;

    If Not Found Then
        _message := 'Error: Parameter ''' || _paramName || ''' not found in mc.t_param_type';
        Raise Warning '%', _message;
        _returnCode := 'U5309'
        Return;
    End If;


    RAISE Info 'Param type ID is %', _paramTypeID;
    
    ---------------------------------------------------
    -- Parse the manager ID list
    ---------------------------------------------------
    --
    INSERT INTO TmpMgrIDs (mgr_id)
    SELECT value
    FROM public.udf_parse_delimited_integer_list ( _managerIDList, ',' );
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    RAISE Info 'Inserted % manager IDs into TmpMgrIDs', _myRowCount;
    
    If _infoOnly <> 0 Then
        _infoHead := format('%-10s %-10s %-25s %-25s %-15s %-15s %-15s %-15s',
                            'Entry_ID',
                            'Mgr_ID',
                            'Manager',
                            'Param Name',
                            'ParamTypeID',
                            'Value',
                            'New Value',
                            'Status'
                        );

        RAISE INFO '%', _infoHead;

        FOR _previewData IN
            SELECT PV.entry_id,
                   M.mgr_id,
                   M.mgr_name,
                   PV.param_name,
                   PV.type_id,
                   PV.value,
                   _newValue AS NewValue,
                   Case When Coalesce(PV.value, '') <> _newValue Then 'Changed' Else 'Unchanged' End As Status
            FROM mc.t_mgrs M
                 INNER JOIN TmpMgrIDs
                   ON M.mgr_id = TmpMgrIDs.mgr_id
                 INNER JOIN mc.v_param_value PV
                   ON PV.mgr_id = M.mgr_id AND
                      PV.type_id = _paramTypeID
            WHERE M.control_from_website > 0
            UNION
            SELECT PV.entry_id,
                   M.mgr_id,
                   M.mgr_name,
                   PV.param_name,
                   PV.type_id,
                   PV.value,
                   '' AS NewValue,
                   'Skipping: control_from_website is 0 in mc.t_mgrs' AS  Status
            FROM mc.t_mgrs M
                 INNER JOIN TmpMgrIDs
                   ON M.mgr_id = TmpMgrIDs.mgr_id
                 INNER JOIN mc.v_param_value PV
                   ON PV.mgr_id = M.mgr_id AND
                      PV.type_id = _paramTypeID
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
                 INNER JOIN TmpMgrIDs
                   ON M.mgr_id = TmpMgrIDs.mgr_id
                 LEFT OUTER JOIN mc.t_param_value PV
                   ON PV.mgr_id = M.mgr_id AND
                      PV.type_id = _paramTypeID
            WHERE PV.type_id IS NULL
        LOOP
            _infoData := format('%-10s %-10s %-25s %-25s %-15s %-15s %-15s %-15s',
                                    _previewData.entry_id,
                                    _previewData.mgr_id,
                                    _previewData.mgr_name,
                                    _previewData.param_name,
                                    _previewData.type_id,
                                    _previewData.value,
                                    _previewData.NewValue,
                                    _previewData.Status
                        );

            RAISE INFO '%', _infoData;

        END LOOP;

        _message := public.udf_append_to_text(_message, 'See the Output window for details');
    
        Return;
    End If;

    ---------------------------------------------------
    -- Add new entries for Managers in _managerIDList that
    -- don't yet have an entry in mc.t_param_value for parameter _paramName
    --
    -- Adding value '##_DummyParamValue_##' so that
    --  we'll force a call to UpdateSingleMgrParamWork
    --
    -- Intentionally not filtering on M.control_from_website > 0 here,
    -- but the query that populates TmpParamValueEntriesToUpdate does filter on that parameter
    ---------------------------------------------------

    INSERT INTO mc.t_param_value( type_id,
                                  value,
                                  mgr_id )
    SELECT _paramTypeID,
           '##_DummyParamValue_##',
           TmpMgrIDs.mgr_id
    FROM mc.t_mgrs M
         INNER JOIN TmpMgrIDs
           ON M.mgr_id = TmpMgrIDs.mgr_id
         LEFT OUTER JOIN mc.t_param_value PV
           ON PV.mgr_id = M.mgr_id AND
              PV.type_id = _paramTypeID
    WHERE PV.type_id IS NULL;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Find the entries for the Managers in _managerIDList
    -- Populate TmpParamValueEntriesToUpdate with the entries that need to be updated
    ---------------------------------------------------
    --
    INSERT INTO TmpParamValueEntriesToUpdate( entry_id )
    SELECT PV.entry_id
    FROM mc.t_param_value PV
         INNER JOIN mc.t_mgrs M
           ON PV.mgr_id = M.mgr_id
         INNER JOIN TmpMgrIDs
           ON M.mgr_id = TmpMgrIDs.mgr_id
    WHERE M.control_from_website > 0 AND
          PV.type_id = _paramTypeID AND
          Coalesce(PV.value, '') <> _newValue;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Call UpdateSingleMgrParamWork to perform the update, then call
    -- AlterEnteredByUserMultiID and AlterEventLogEntryUserMultiID for _callingUser
    ---------------------------------------------------
    --
    Call UpdateSingleMgrParamWork (_paramName, _newValue, _callingUser, _message => _message, _returnCode => _returnCode);

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error updating values in mc.t_param_value for the given managers: ' || _exceptionMessage;
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'UpdateSingleMgrControlParam', 'mc');

END
$$;


ALTER PROCEDURE mc.updatesinglemgrcontrolparam(_paramname text, _newvalue text, _manageridlist text, _callinguser text, _infoonly integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE updatesinglemgrcontrolparam(_paramname text, _newvalue text, _manageridlist text, _callinguser text, _infoonly integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.updatesinglemgrcontrolparam(_paramname text, _newvalue text, _manageridlist text, _callinguser text, _infoonly integer, INOUT _message text, INOUT _returncode text) IS 'UpdateSingleMgrControlParam';

