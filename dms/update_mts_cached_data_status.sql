--
-- Name: update_mts_cached_data_status(text, boolean, integer, integer, integer, boolean, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_mts_cached_data_status(IN _cacheddatatablename text, IN _incrementrefreshcount boolean DEFAULT false, IN _insertcountnew integer DEFAULT 0, IN _updatecountnew integer DEFAULT 0, IN _deletecountnew integer DEFAULT 0, IN _fullrefreshperformed boolean DEFAULT false, IN _lastrefreshminimumid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update data in t_mts_cached_data_status
**
**  Arguments:
**    _cachedDataTableName      Cached data table name
**    _incrementRefreshCount    If true, increment the refresh count in t_mts_cached_data_status
**    _insertCountNew           Ignored if _incrementRefreshCount is false
**    _updateCountNew           Ignored if _incrementRefreshCount is false
**    _deleteCountNew           Ignored if _incrementRefreshCount is false
**    _fullRefreshPerformed     When true, updates both Last_Refreshed and Last_Full_Refresh; otherwise, just updates Last_Refreshed
**    _lastRefreshMinimumID     Last refresh minimumID
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   02/05/2010 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          02/17/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        _currentLocation := 'Validate the inputs';

        _cachedDataTableName   := Trim(Coalesce(_cachedDataTableName, ''));
        _incrementRefreshCount := Coalesce(_incrementRefreshCount, false);
        _fullRefreshPerformed  := Coalesce(_fullRefreshPerformed, false);
        _lastRefreshMinimumID  := Coalesce(_lastRefreshMinimumID, 0);

        -- Abort if _cachedDataTableName is blank
        If _cachedDataTableName = '' Then
            _message := '_cachedDataTableName not specified; unable to continue';
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Not _incrementRefreshCount Then
            -- Force the new counts to 0
            _insertCountNew := 0;
            _updateCountNew := 0;
            _deleteCountNew := 0;
        Else
            -- Validate the new counts
            _insertCountNew := Coalesce(_insertCountNew, 0);
            _updateCountNew := Coalesce(_updateCountNew, 0);
            _deleteCountNew := Coalesce(_deleteCountNew, 0);
        End If;

        _currentLocation := 'Make sure _cachedDataTableName exists in t_mts_cached_data_status';

        If Not Exists (SELECT table_name FROM t_mts_cached_data_status WHERE table_name = _cachedDataTableName::citext) Then
            INSERT INTO t_mts_cached_data_status (table_name, refresh_count)
            VALUES (_cachedDataTableName, 0);
        End If;

        _currentLocation := 'Update the stats in t_mts_cached_data_status';

        UPDATE t_mts_cached_data_status
        SET refresh_count = CASE WHEN _incrementRefreshCount THEN refresh_count + 1 ELSE refresh_count END,
            insert_count = insert_count + _insertCountNew,
            update_count = update_count + _updateCountNew,
            delete_count = delete_count + _deleteCountNew,
            last_refreshed = CURRENT_TIMESTAMP,
            last_refresh_minimum_id = _lastRefreshMinimumID,
            last_full_refresh = CASE WHEN _fullRefreshPerformed THEN CURRENT_TIMESTAMP ELSE last_full_refresh END
        WHERE table_name = _cachedDataTableName::citext;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.update_mts_cached_data_status(IN _cacheddatatablename text, IN _incrementrefreshcount boolean, IN _insertcountnew integer, IN _updatecountnew integer, IN _deletecountnew integer, IN _fullrefreshperformed boolean, IN _lastrefreshminimumid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_mts_cached_data_status(IN _cacheddatatablename text, IN _incrementrefreshcount boolean, IN _insertcountnew integer, IN _updatecountnew integer, IN _deletecountnew integer, IN _fullrefreshperformed boolean, IN _lastrefreshminimumid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_mts_cached_data_status(IN _cacheddatatablename text, IN _incrementrefreshcount boolean, IN _insertcountnew integer, IN _updatecountnew integer, IN _deletecountnew integer, IN _fullrefreshperformed boolean, IN _lastrefreshminimumid integer, INOUT _message text, INOUT _returncode text) IS 'UpdateMTSCachedDataStatus';

