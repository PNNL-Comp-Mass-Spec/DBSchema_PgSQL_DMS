--
CREATE OR REPLACE PROCEDURE public.update_instrument_usage_allocations_work
(
    _fy int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update requested instrument usage allocation using data in Tmp_Allocation_Operations
**
**      CREATE TABLE Tmp_Allocation_Operations (
**          Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
**          Allocation text null,
**          InstGroup text null,
**          Proposal text null,
**          Comment text null,
**          FY int,
**          Operation text null     -- 'i' -> increment, 'd' -> decrement, anything else -> set
**      )
**
**
**  Arguments:
**    _infoOnly   Set to true to preview the changes that would be made
**
**  Auth:   grk
**  Date:   03/30/2012 mem - Factored out of UpdateInstrumentAllocations
**          03/31/2012 mem - Updated Merge statement to not enter new rows if the allocation hours are 0 and comment is empty
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _allocationInfo record;
    _targetEntryID int;
    _currentTime timestamp;
    _countUpdated int := 0;
    _matchIndex int;
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

    If Coalesce(_callingUser, '') = '' Then
        _callingUser := get_user_login_without_domain('');
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    If _infoOnly Then
        -- ToDo: Show the data using RAISE INFO
        SELECT * FROM Tmp_Allocation_Operations
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Perform necessary inserts
    -- and set/increment/decrement operations for updates
    -----------------------------------------------------------

    MERGE INTO t_instrument_allocation AS Target
    USING ( SELECT Proposal, InstGroup, Allocation, Comment, FY, Operation
            FROM Tmp_Allocation_Operations
          ) AS Source
    ON (Source.Proposal = Target.proposal_id AND
        Source.InstGroup = Target.allocation_tag AND
        Source.FY = Target.fiscal_year)
    WHEN MATCHED THEN
        UPDATE SET
            allocated_hours = CASE
                                  WHEN Source.Operation = 'i' THEN allocated_hours + Source.Allocation
                                  WHEN Source.Operation = 'd' THEN allocated_hours - Source.Allocation
                                  ELSE Allocation
                              END,
            Comment = Source.Comment,
            Last_Affected = CASE WHEN Coalesce(Source.Operation, '') <> '' Then CURRENT_TIMESTAMP
                                 ELSE CASE WHEN Coalesce(Allocated_Hours, -1) <> Coalesce(Allocation, -1) THEN CURRENT_TIMESTAMP
                                           ELSE Last_Affected
                                      END
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
    If char_length(_callingUser) = 0 Then
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

        If NOT FOUND Then
            CONTINUE;
        End If;

        -- Confirm that _enteredBy doesn't already contain _callingUser
        -- If it does, there's no need to update it

        _matchIndex := Position(_callingUser In _enteredBy);

        If _matchIndex > 0 Then
            CONTINUE;
        End If;

        -- Need to update Entered_By
        -- Look for a semicolon in _enteredBy

        _matchIndex := Position(';' In _enteredBy);

        If _matchIndex > 0 Then
            _enteredByNew := format ('%s (via %s)%s',
                                    _callingUser,
                                    SubString(_enteredBy, 1, _matchIndex - 1)
                                    SubString(_enteredBy, _matchIndex, char_length(_enteredBy)));
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

COMMENT ON PROCEDURE public.update_instrument_usage_allocations_work IS 'UpdateInstrumentUsageAllocationsWork';
