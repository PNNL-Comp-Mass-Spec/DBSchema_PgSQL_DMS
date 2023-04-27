--
CREATE OR REPLACE PROCEDURE public.find_active_requested_run_for_dataset
(
    _datasetName text,
    _experimentID int = 0,
    INOUT _requestID int = 0,
    INOUT _requestInstGroup text = '',
    INOUT _requestMatchCount int = 0,
    _showDebugMessages boolean = false
)
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
**      If one and only one match is found, returns that requested run's id via the output parameter
**      If multiple matches are found, _requestID will be 0
**
**  Arguments:
**    _datasetName         Dataset name
**    _experimentID        Optional; include to limit by experiment ID,
**    _requestID           Output: Matched request run ID; 0 if no match
**    _requestInstGroup    Output: Instrument group for the matched request; empty if no match
**    _requestMatchCount   Output: Number of matching candidate run requests
**
**  Auth:   mem
**  Date:   06/10/2016 mem - Initial version
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _startPos int := 1;
    _datasetReversed text;
    _datasetNameLength int;
    _underscorePos int;
    _dashPos int;
    _datasetPrefix citext;
    _requestName text := '';
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName := Coalesce(_datasetName, '');
    _experimentID := Coalesce(_experimentID, 0);
    _showDebugMessages := Coalesce(_showDebugMessages, false);

    If _datasetName = '' Then
        RAISE EXCEPTION 'Dataset name cannot be blank';
    End If;

    ---------------------------------------------------
    -- Initialize some variables
    ---------------------------------------------------

    _datasetReversed := reverse(_datasetName);
    _datasetNameLength := char_length(_datasetName);

    _requestID := 0;
    _requestInstGroup := '';
    _requestMatchCount := 0;

    ---------------------------------------------------
    -- Search for active requested runs
    ---------------------------------------------------

    WHILE _startPos > 0
    LOOP

        _underscorePos := Position('_', _datasetReversed In _startPos);
        _dashPos := Position('-', _datasetReversed In _startPos);

        If _underscorePos > 0 Then
            If _dashPos > 0 AND _dashPos < _underscorePos Then
                _startPos := _dashPos;
            Else
                _startPos := _underscorePos;
            End If;
        Else
            _startPos := _dashPos;
        End If;

        If _startPos <= 0 Then
            -- Break out of the While Loop
            EXIT;
        End If;

        _datasetPrefix := Substring(_datasetName, 1, _datasetNameLength - _startPos);

        If _showDebugMessages Then
            RAISE INFO '%', Substring(_datasetName, 1, _datasetNameLength - _startPos);
        End If;

        If _experimentID <= 0 Then
            SELECT COUNT(*),
                   MIN(request_id)
            INTO _requestMatchCount, _requestID
            FROM t_requested_run
            WHERE request_name LIKE _datasetPrefix || '%' AND
                  state_name = 'Active';
        Else
            SELECT COUNT(*),
                   MIN(request_id)
            INTO _requestMatchCount, _requestID
            FROM t_requested_run
            WHERE request_name LIKE _datasetPrefix || '%' AND
                  state_name = 'Active' AND
                  exp_id = _experimentID

        If FOUND And _requestMatchCount = 1 Then
            -- Match found; lookup the requested run's instrument group
            --
            SELECT instrument_group,
                   request_name
            INTO _requestInstGroup, _requestName
            FROM t_requested_run
            WHERE request_id = _requestID

            _startPos := 0;
        Else
            _requestID := 0;
            _startPos := _startPos + 1;
        End If;

    END LOOP;

    If _showDebugMessages Then
        If _requestID > 0 Then
            RAISE INFO 'Match Found for dataset %: ID %, Request Name %, Instrument Group %', _datasetName, _requestID, _requestName, _requestInstGroup;
        Else
            RAISE INFO 'Match not found for dataset %; candidate count: %', _datasetName, _requestMatchCount;
    End If;

END
$$;

COMMENT ON PROCEDURE public.find_active_requested_run_for_dataset IS 'FindActiveRequestedRunForDataset';
