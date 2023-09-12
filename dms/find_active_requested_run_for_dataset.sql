--
-- Name: find_active_requested_run_for_dataset(text, integer, integer, text, integer, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.find_active_requested_run_for_dataset(IN _datasetname text, IN _experimentid integer DEFAULT 0, INOUT _requestid integer DEFAULT 0, INOUT _requestinstgroup text DEFAULT ''::text, INOUT _requestmatchcount integer DEFAULT 0, IN _showdebugmessages boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for an active requested run for the specified dataset name
**
**      Steps backward through the name looking for dashes and underscores, looking
**      for active requested runs that match the dataset name portion
**
**      If one and only one match is found, returns that requested run's ID via the output parameter
**      If multiple matches are found, _requestID will be 0
**
**  Arguments:
**    _datasetName          Dataset name
**    _experimentID         Optional; include to limit by experiment ID,
**    _requestID            Output: Matched request run ID; 0 if no match
**    _requestInstGroup     Output: Instrument group for the matched request; empty if no match
**    _requestMatchCount    Output: Number of matching candidate run requests
**    _showDebugMessages    When true, show debug messages
**
**  Auth:   mem
**  Date:   06/10/2016 mem - Initial version
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          09/11/2023 mem - Stop searching for matches once one or more requested runs are matched
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _startPos int;
    _datasetReversed text;
    _datasetNameLength int;
    _underscorePos int;
    _dashPos int;
    _datasetPrefix citext;
    _requestName text := '';
    _matchCount int;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName       := Trim(Coalesce(_datasetName, ''));
    _experimentID      := Coalesce(_experimentID, 0);
    _showDebugMessages := Coalesce(_showDebugMessages, false);

    If _datasetName = '' Then
        RAISE EXCEPTION 'Dataset name must be specified';
    End If;

    If _showDebugMessages Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Initialize some variables
    ---------------------------------------------------

    _datasetReversed   := Reverse(_datasetName);
    _datasetNameLength := char_length(_datasetName);

    _requestID := 0;
    _requestInstGroup := '';
    _requestMatchCount := 0;
    _matchCount := 0;

    ---------------------------------------------------
    -- Search for active requested runs
    ---------------------------------------------------

    _startPos := 1;

    WHILE _startPos > 0
    LOOP

        _underscorePos := Position('_' In Substring(_datasetReversed, _startPos));
        _dashPos       := Position('-' In Substring(_datasetReversed, _startPos));

        If _underscorePos > 0 Then
            If _dashPos > 0 And _dashPos < _underscorePos Then
                _startPos := _dashPos + _startPos;
            Else
                _startPos := _underscorePos + _startPos;
            End If;
        Else
            _startPos := _dashPos + _startPos;
        End If;

        If _startPos <= 0 Or _datasetNameLength - _startPos + 1 < 1 Then
            -- Break out of the While Loop
            EXIT;
        End If;

        _datasetPrefix := Substring(_datasetName, 1, _datasetNameLength - _startPos + 1);

        If _showDebugMessages Then
            RAISE INFO '%', _datasetPrefix;
        End If;

        If _experimentID <= 0 Then
            SELECT COUNT(request_id),
                   MIN(request_id)
            INTO _matchCount, _requestID
            FROM t_requested_run
            WHERE request_name LIKE _datasetPrefix || '%' AND
                  state_name = 'Active';
        Else
            SELECT COUNT(request_id),
                   MIN(request_id)
            INTO _matchCount, _requestID
            FROM t_requested_run
            WHERE request_name LIKE _datasetPrefix || '%' AND
                  state_name = 'Active' AND
                  exp_id = _experimentID;
        End If;

        If _matchCount > 0 Then
            _requestMatchCount := _matchCount;

            If _matchCount = 1 Then
                -- Single match found; lookup the requested run's instrument group
                SELECT instrument_group,
                       request_name
                INTO _requestInstGroup, _requestName
                FROM t_requested_run
                WHERE request_id = _requestID;
            Else
                -- Multiple matches were found; set _requestID to 0
                _requestID := 0;
            End If;

            -- Break out of the While Loop
            EXIT;
        End If;

        _requestID := 0;
        _startPos := _startPos + 1;

    END LOOP;

    If _showDebugMessages Then
        If _matchCount = 1 Then
            RAISE INFO 'Match found for dataset %: ID = %, Request Name = %, Instrument Group = %', _datasetName, _requestID, _requestName, _requestInstGroup;
        ElsIf _matchCount > 1 Then
            RAISE INFO 'Multiple matches were found for dataset %: Match Count = %', _datasetName, _matchCount;
        Else
            RAISE INFO 'Match not found for dataset %', _datasetName;
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.find_active_requested_run_for_dataset(IN _datasetname text, IN _experimentid integer, INOUT _requestid integer, INOUT _requestinstgroup text, INOUT _requestmatchcount integer, IN _showdebugmessages boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE find_active_requested_run_for_dataset(IN _datasetname text, IN _experimentid integer, INOUT _requestid integer, INOUT _requestinstgroup text, INOUT _requestmatchcount integer, IN _showdebugmessages boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.find_active_requested_run_for_dataset(IN _datasetname text, IN _experimentid integer, INOUT _requestid integer, INOUT _requestinstgroup text, INOUT _requestmatchcount integer, IN _showdebugmessages boolean) IS 'FindActiveRequestedRunForDataset';

