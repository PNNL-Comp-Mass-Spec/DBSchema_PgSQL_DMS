--
-- Name: update_instrument_usage_allocations_work(integer, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_instrument_usage_allocations_work(IN _fy integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update requested instrument usage allocation using data in Tmp_Allocation_Operations
**
**      CREATE TEMP TABLE Tmp_Allocation_Operations (
**          Entry_ID   int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
**          Allocation text NULL,
**          InstGroup  text NULL,
**          Proposal   text NULL,
**          Comment    text NULL,
**          FY         int NOT NULL,
**          Operation  text NULL     -- 'i' -> increment, 'd' -> decrement, anything else -> set
**      );
**
**      This procedure is obsolete since instrument allocation was last tracked in 2012 (see table t_instrument_allocation)
**
**  Arguments:
**    _fy               Fiscal year
**    _infoOnly         When true, preview the changes that would be made
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/30/2012 mem - Factored out of UpdateInstrumentAllocations
**          03/31/2012 mem - Updated Merge statement to not enter new rows if the allocation hours are 0 and comment is empty
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          02/24/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _allocationInfo record;
    _targetEntryID int;
    _currentTime timestamp;
    _countUpdated int := 0;
    _matchPos int;
    _enteredBy text;
    _enteredByNew text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _fy          := Coalesce(_fy, 1970);
    _infoOnly    := Coalesce(_infoOnly, false);
    _callingUser := Trim(Coalesce(_callingUser, ''));

    If _callingUser = '' Then
        _callingUser := public.get_user_login_without_domain('');
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-8s %-5s %-10s %-16s %-10s %-10s %-40s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'FY',
                            'Proposal',
                            'Instrument_Group',
                            'Operation',
                            'Allocation',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                    '--------',
                                    '-----',
                                    '----------',
                                    '----------------',
                                    '----------',
                                    '----------',
                                    '----------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Entry_ID,
                   FY,
                   Proposal,
                   InstGroup AS Instrument_Group,
                   CASE WHEN Operation = 'i' THEN 'Increment'
                        WHEN Operation = 'd' THEN 'Decrement'
                        ELSE 'Set'
                   END AS Operation,
                   Allocation,
                   Comment
            FROM Tmp_Allocation_Operations
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.FY,
                                _previewData.Proposal,
                                _previewData.Instrument_Group,
                                _previewData.Operation,
                                _previewData.Allocation,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    -----------------------------------------------------------
    -- Perform necessary inserts and set/increment/decrement operations for updates
    -----------------------------------------------------------

    MERGE INTO t_instrument_allocation AS Target
    USING (SELECT Proposal,
                  InstGroup,
                  Coalesce(public.try_cast(Allocation, 0.0), 0) AS Allocation,
                  Comment,
                  FY,
                  Operation
           FROM Tmp_Allocation_Operations
          ) AS Source
    ON (Source.Proposal = Target.proposal_id AND
        Source.InstGroup = Target.allocation_tag AND
        Source.FY = Target.fiscal_year)
    WHEN MATCHED THEN
        UPDATE SET
            allocated_hours = GREATEST(0,       -- Use Greatest to assure that a decrement operation does not give a negative number
                                       CASE
                                          WHEN Source.Operation = 'i' THEN allocated_hours + Source.Allocation  -- Increment
                                          WHEN Source.Operation = 'd' THEN allocated_hours - Source.Allocation  -- Decrement
                                          ELSE Allocation
                                       END),
            Comment = Source.Comment,
            Last_Affected = CASE WHEN Coalesce(Source.Operation, '') <> '' THEN CURRENT_TIMESTAMP
                                 WHEN Coalesce(Allocated_Hours, -1) <> Coalesce(Allocation, -1) THEN CURRENT_TIMESTAMP
                                 ELSE Last_Affected
                            END
    WHEN NOT MATCHED And
         (Coalesce(Source.Allocation, 0) <> 0 Or
          Coalesce(Source.Comment, '') <> '') THEN
        INSERT (Allocation_Tag,
                Proposal_ID,
                Allocated_Hours,
                Comment,
                Fiscal_Year)
        VALUES (Source.InstGroup,
                Source.Proposal,
                Source.Allocation,
                Source.Comment,
                Source.FY);

    -- If _callingUser is defined, update entered_by in t_instrument_allocation_updates
    If _callingUser = '' Then
        RETURN;
    End If;

    ------------------------------------------------
    -- Call public.alter_entered_by_user for each entry in Tmp_Allocation_Operations
    ------------------------------------------------

    _currentTime := clock_timestamp();

    FOR _allocationInfo IN
        SELECT Entry_ID,
               Proposal,
               InstGroup
        FROM Tmp_Allocation_Operations
        ORDER BY Entry_ID
    LOOP
        SELECT entry_id,
               entered_by
        INTO _targetEntryID, _enteredBy
        FROM t_instrument_allocation_updates
        WHERE allocation_tag = _allocationInfo.InstGroup AND
              proposal_id = _allocationInfo.Proposal AND
              fiscal_year = _fy AND
              entered BETWEEN _currentTime - INTERVAL '15 seconds' AND _currentTime + INTERVAL '1 second';

        If Not FOUND Then
            CONTINUE;
        End If;

        -- Confirm that _enteredBy doesn't already contain _callingUser
        -- If it does, there's no need to update it

        _matchPos := Position(_callingUser In _enteredBy);

        If _matchPos > 0 Then
            CONTINUE;
        End If;

        -- Need to update Entered_By
        -- Look for a semicolon in _enteredBy

        _matchPos := Position(';' In _enteredBy);

        If _matchPos > 0 Then
            _enteredByNew := format ('%s (via %s)%s',
                                    _callingUser,
                                    Substring(_enteredBy, 1, _matchPos - 1),
                                    Substring(_enteredBy, _matchPos, char_length(_enteredBy)));
        Else
            _enteredByNew := format('%s (via %s)', _callingUser, _enteredBy);
        End If;

        If char_length(Coalesce(_enteredByNew, '')) > 0 Then
            UPDATE t_instrument_allocation_updates
            SET entered_by = _enteredByNew
            WHERE entry_id = _targetEntryID;
        End If;

    END LOOP;

END
$$;


ALTER PROCEDURE public.update_instrument_usage_allocations_work(IN _fy integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_instrument_usage_allocations_work(IN _fy integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_instrument_usage_allocations_work(IN _fy integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateInstrumentUsageAllocationsWork';

