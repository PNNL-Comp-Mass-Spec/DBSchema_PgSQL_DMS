--
-- Name: post_usage_log_entry(text, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.post_usage_log_entry(IN _postedby text, IN _message text DEFAULT ''::text, IN _minimumupdateinterval integer DEFAULT 1)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**       Put new entry into T_Usage_Log and update T_Usage_Stats
**
**  Arguments:
**    _postedBy                Calling procedure name
**    _message                 Usage message
**    _minimumUpdateInterval   Set to a value greater than 0 to limit the entries to occur at most every _minimumUpdateInterval hours
**
**  Example usage:
**
**      CALL post_usage_log_entry('store_dataset_file_info', 'Dataset: QC_Mam_19_01_1a_Samwise_19Aug22_WBEH-22-05-03');
**      SELECT * FROM t_usage_stats WHERE posted_by LIKE 'store%dataset%file%info';
**
**  Auth:   mem
**  Date:   10/22/2004
**          07/29/2005 mem - Added parameter _minimumUpdateInterval
**          03/16/2006 mem - Now updating T_Usage_Stats
**          03/17/2006 mem - Now populating Usage_Count in T_Usage_Log and changed _minimumUpdateInterval from 6 hours to 1 hour
**          05/03/2009 mem - Removed parameter _dBName
**          02/06/2020 mem - Ported to PostgreSQL
**          06/24/2022 mem - Capitalize _sqlState
**          08/18/2022 mem - Set _ignoreErrors to true when calling post_log_entry
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          05/22/2023 mem - Capitalize reserved words
**          06/14/2023 mem - Use citext for case-insensitive comparisons
**
*****************************************************/
DECLARE
    _currentTargetTable text := 'Undefined';
    _currentOperation text := 'initializing';
    _callingUser citext := SESSION_USER;
    _lastUpdated timestamp;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _currentTargetTable := 't_usage_stat';

    -- Update entry for _postedBy in t_usage_stats

    If Not Exists (SELECT posted_by FROM t_usage_stats WHERE posted_by = _postedBy::citext) THEN
        _currentOperation := 'appending to';

        INSERT INTO t_usage_stats (posted_by, last_posting_time, usage_count)
        VALUES (_postedBy, CURRENT_TIMESTAMP, 1);
    Else
        _currentOperation := 'updating';

        UPDATE t_usage_stats
        SET last_posting_time = CURRENT_TIMESTAMP, usage_count = usage_count + 1
        WHERE posted_by = _postedBy::citext;
    End If;

    _currentTargetTable := 't_usage_log';
    _currentOperation := 'selecting from';

    If _minimumUpdateInterval > 0 Then
        -- See if the last update was less than _minimumUpdateInterval hours ago

        SELECT MAX(posting_time)
        INTO _lastUpdated
        FROM t_usage_log
        WHERE posted_by = _postedBy::citext AND calling_user = _callingUser;

        If FOUND Then
            If CURRENT_TIMESTAMP <= _lastUpdated + _minimumUpdateInterval * INTERVAL '1 hour' Then
                -- The last usage message was posted recently
                RETURN;
            End If;
        End If;
    End If;

    _currentOperation := 'appending to';

    INSERT INTO t_usage_log
            (posted_by, posting_time, message, calling_user, usage_count)
    SELECT _postedBy, CURRENT_TIMESTAMP, _message, _callingUser, stats.usage_count
    FROM t_usage_stats stats
    WHERE stats.posted_by = _postedBy::citext;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    format('%s %s', _currentOperation, _currentTargetTable),
                    _logError => true, _displayError => true);
END
$$;


ALTER PROCEDURE public.post_usage_log_entry(IN _postedby text, IN _message text, IN _minimumupdateinterval integer) OWNER TO d3l243;

--
-- Name: PROCEDURE post_usage_log_entry(IN _postedby text, IN _message text, IN _minimumupdateinterval integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.post_usage_log_entry(IN _postedby text, IN _message text, IN _minimumupdateinterval integer) IS 'PostUsageLogEntry';

