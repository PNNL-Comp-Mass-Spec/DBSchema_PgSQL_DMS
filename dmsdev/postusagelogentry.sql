--
-- Name: postusagelogentry(text, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.postusagelogentry(_postedby text, _message text DEFAULT ''::text, _minimumupdateinterval integer DEFAULT 1)
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
**  Auth:   mem
**  Date:   10/22/2004
**          07/29/2005 mem - Added parameter _minimumUpdateInterval
**          03/16/2006 mem - Now updating T_Usage_Stats
**          03/17/2006 mem - Now populating Usage_Count in T_Usage_Log and changed _minimumUpdateInterval from 6 hours to 1 hour
**          05/03/2009 mem - Removed parameter _dBName
**          02/06/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentTargetTable text := 'Undefined';
    _currentOperation text := 'initializing';
    _callingUser text := session_user;
    _lastUpdated timestamp;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    _currentTargetTable := 't_usage_stat';

    -- Update entry for _postedBy in t_usage_stats
    --
    If Not Exists (SELECT posted_by FROM t_usage_stats WHERE posted_by = _postedBy) THEN
        _currentOperation := 'appending to';
    
        INSERT INTO t_usage_stats (posted_by, last_posting_time, usage_count)
        VALUES (_postedBy, CURRENT_TIMESTAMP, 1);
    Else
        _currentOperation := 'updating';
    
        UPDATE t_usage_stats
        SET last_posting_time = CURRENT_TIMESTAMP, usage_count = usage_count + 1
        WHERE posted_by = _postedBy;
    End If;

    _currentTargetTable := 't_usage_log';
    _currentOperation := 'selecting';

    If _minimumUpdateInterval > 0 Then
        -- See if the last update was less than _minimumUpdateInterval hours ago

        SELECT MAX(posting_time) INTO _lastUpdated
        FROM t_usage_log
        WHERE posted_by = _postedBy AND calling_user = _callingUser;
       
        IF Found Then
            If CURRENT_TIMESTAMP <= _lastUpdated + _minimumUpdateInterval * INTERVAL '1 hour' Then
                -- The last usage message was posted recently
                Return;
            End If;
        End If;
    End If;

    _currentOperation := 'appending to';

    INSERT INTO t_usage_log
            (posted_by, posting_time, message, calling_user, usage_count)
    SELECT _postedBy, CURRENT_TIMESTAMP, _message, _callingUser, stats.usage_count
    FROM t_usage_stats stats
    WHERE stats.posted_by = _postedBy;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Error %s %s: %s', 
                _currentOperation, _currentTargetTable, _exceptionMessage);

    RAISE Warning '%', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'PostUsageLogEntry', 'public');

END
$$;


ALTER PROCEDURE public.postusagelogentry(_postedby text, _message text, _minimumupdateinterval integer) OWNER TO d3l243;

--
-- Name: PROCEDURE postusagelogentry(_postedby text, _message text, _minimumupdateinterval integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.postusagelogentry(_postedby text, _message text, _minimumupdateinterval integer) IS 'PostUsageLogEntry';

