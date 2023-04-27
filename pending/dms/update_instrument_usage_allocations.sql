--
CREATE OR REPLACE PROCEDURE public.update_instrument_usage_allocations
(
    _fyProposal text,
    _fiscalYear text,
    _proposalID text,
    _ft text = '',
    _ftComment text = '',
    _ims text = '',
    _imsComment text = '',
    _orb text = '',
    _orbComment text = '',
    _exa text = '',
    _exaComment text = '',
    _ltq text = '',
    _ltqComment text = '',
    _gc text = '',
    _gcComment text = '',
    _qqq text = '',
    _qqqComment text = '',
    _mode text = 'update',
    INOUT _message text,
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update requested instrument usage allocation via specific parameters
**
**  Arguments:
**    _fyProposal   Only used when _mode is 'update'
**    _fiscalYear   Only used when _mode is 'add'
**    _proposalID   Only used when _mode is 'add'
**    _mode         'add' or 'update'
**    _infoOnly     Set to true to preview the changes that would be made
**
**  Auth:   grk
**  Date:   03/28/2012 grk - Initial release
**          03/30/2012 grk - Added change command capability
**          03/30/2012 mem - Added support for x="Comment" in the XML
**                         - Now calling UpdateInstrumentUsageAllocationsWork to apply the updates
**          03/31/2012 mem - Added _fiscalYear, _proposalID, and _mode
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _fy int;
    _charIndex int;
    _msg2 text;
    _fiscalYearParam text;
    _proposalIDParam text;

    _ftHours real;
    _imsHours real;
    _orbHours real;
    _exaHours real;
    _ltqHours real;
    _gcHours real;
    _qqqHours real:

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _fyProposal := Coalesce(_fyProposal, '');
        _fiscalYear := Coalesce(_fiscalYear, '');
        _proposalID := Coalesce(_proposalID, '');

        _ft := Coalesce(_ft, '');
        _ims := Coalesce(_ims, '');
        _orb := Coalesce(_orb, '');
        _exa := Coalesce(_exa, '');
        _ltq := Coalesce(_ltq, '');
        _gc := Coalesce(_gc, '');
        _qqq := Coalesce(_qqq, '');

        _ftComment := Coalesce(_ftComment, '');
        _imsComment := Coalesce(_imsComment, '');
        _orbComment := Coalesce(_orbComment, '');
        _exaComment := Coalesce(_exaComment, '');
        _ltqComment := Coalesce(_ltqComment, '');
        _gcComment := Coalesce(_gcComment,  '');
        _qqqComment := Coalesce(_qqqComment, '');

        _message := '';
        _infoOnly := Coalesce(_infoOnly, false);

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode::citext In ('add', 'update') Then
            _msg2 := 'Invalid mode: ' || Coalesce(_mode, '??');
            RAISE EXCEPTION '%', _msg2;
        End If;

        If _mode = 'add' Then
            If _fiscalYear = '' Then
                RAISE EXCEPTION 'Fiscal Year is empty; cannot add';
            End If;

            If _proposalID = '' Then
                RAISE EXCEPTION 'Proposal ID is empty; cannot add';
            End If;

            If Exists (SELECT * FROM t_instrument_allocation WHERE proposal_id = _proposalID AND fiscal_year = _fiscalYear) Then
                _msg2 := 'Existing entry already exists, cannot add: ' || _fiscalYear || '_' || _proposalID;
                RAISE EXCEPTION '%', _msg2;
            End If;

        End If;

        If _mode = 'update' Then
            If _fYProposal = '' Then
                RAISE EXCEPTION '_fYProposal parameter is empty';
            End If;

            -- Split _fYProposal into _fiscalYear and _proposalID
            _charIndex := Position('_' In _fYProposal);
            If _charIndex <= 1 Or _charIndex = char_length(_fYProposal) Then
                RAISE EXCEPTION '_fYProposal parameter is not in the correct format';
            End If;

            _fiscalYearParam := _fiscalYear;
            _proposalIDParam := _proposalID;

            _fiscalYear := Substring(_fYProposal, 1, _charIndex-1);
            _proposalID := Substring(_fYProposal, _charIndex+1, 128);

            If Not Exists (SELECT * FROM t_instrument_allocation WHERE fy_proposal = _fYProposal) Then
                _msg2 := 'Entry not found, unable to update: ' || _fYProposal;
                RAISE EXCEPTION '%', _msg2;
            End If;

            If Not Exists (SELECT * FROM t_instrument_allocation WHERE fy_proposal = _fYProposal AND proposal_id = _proposalID AND fiscal_year = _fiscalYear) Then
                _msg2 := 'Mismatch between fy_proposal, FiscalYear, and ProposalID: ' || _fYProposal || ' vs. ' || _fiscalYear || ' vs. ' || _proposalID;
                RAISE EXCEPTION '%', _msg2;
            End If;

            If Coalesce(_fiscalYearParam, '') <> '' And _fiscalYearParam <> _fiscalYear Then
                _msg2 := 'Cannot change FiscalYear when updating: ' || _fiscalYear || ' vs. ' || _fiscalYearParam;
                RAISE EXCEPTION '%', _msg2;
            End If;

            If Coalesce(_proposalIDParam, '') <> '' And _proposalIDParam <> _proposalID Then
                _msg2 := 'Cannot change ProposalID when updating: ' || _proposalID || ' vs. ' || _proposalIDParam;
                RAISE EXCEPTION '%', _msg2;
            End If;
        End If;

        -- Validate _proposalID
        If Not Exists (SELECT * FROM t_eus_proposals WHERE proposal_id = _proposalID) Then
            _msg2 := 'Invalid EUS ProposalID: ' || _proposalID;
            RAISE EXCEPTION '%', _msg2;
        End If;

        -----------------------------------------------------------
        -- Temp table to hold operations
        -----------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_Allocation_Operations (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Allocation text null,
            InstGroup text null,
            Proposal text null,
            Comment text null,
            FY int,
            Operation text null     -- 'i' -> increment, 'd' -> decrement, anything else -> set
        )

        _fy := public.try_cast(_fiscalYear, null::int);
        If _fy Is Null Or _fy = 0 Then
            _msg2 := 'Fiscal year is not numeric: ' || _fiscalYear;
            RAISE EXCEPTION '%', _msg2;
        End If;

        If _ft <> '' Then
            _ftHours := public.try_cast(_ft, null::real);

            If _ftHours Is Null Then
                _msg2 := 'FT hours is not numeric: ' || _ft;
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY);
            End If;
                VALUES ('',  _proposalID, 'FT', _ftHours, _ftComment, _fy)
        End If;

        If _ims <> '' Then
            _imsHours := public.try_cast(_ims, null::real);

            If _imsHours Is Null Then
                _msg2 := 'IMS hours is not numeric: ' || _ims;
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY);
            End If;
                VALUES ('',  _proposalID, 'IMS', _imsHours, _imsComment, _fy)
        End If;

        If _orb <> '' Then
            _orbHours := public.try_cast(_orb, null::real);

            If _orbHours Is Null Then
                _msg2 := 'Orbitrap hours is not numeric: ' || _orb;
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY);
            End If;
                VALUES ('',  _proposalID, 'ORB', _orbHours, _orbComment, _fy)
        End If;

        If _exa <> '' Then
            _exaHours := public.try_cast(_exa, null::real);

            If _exaHours Is Null Then
                _msg2 := 'Exactive hours is not numeric: ' || _exa;
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY);
            End If;
                VALUES ('',  _proposalID, 'EXA', _exaHours, _exaComment, _fy)
        End If;

        If _ltq <> '' Then
            _ltqHours := public.try_cast(_ltq, null::real);

            If _ltqHours Is Null Then
                _msg2 := 'LTQ hours is not numeric: ' || _ltq;
                RAISE EXCEPTION '%', _msg2;
            End If;
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'LTQ', _ltqHours, _ltqComment, _fy)
        End If;

        If _gc <> '' Then
            _gcHours := public.try_cast(_gc, null::real);

            If _gcHours Is Null Then
                _msg2 := 'GC hours is not numeric: ' || _gc;
                RAISE EXCEPTION '%', _msg2;
            End If;
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'GC', _gcHours, _gcComment, _fy)
        End If;

        If _qqq <> '' Then
            _qqqHours := public.try_cast(_qqq, null::real);

            If _qqqHours Is Null Then
                _msg2 := 'QQQ hours is not numeric: ' || _qqq;
                RAISE EXCEPTION '%', _msg2;
            End If;
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'QQQ', _qqqHours, _qqqComment, _fy)
        End If;

        -----------------------------------------------------------
        -- Call UpdateInstrumentUsageAllocationsWork to perform the work
        -----------------------------------------------------------
        --
        Call update_instrument_usage_allocations_work (_fy, _message => _message, _callingUser => _callingUser, _infoOnly => _infoOnly);

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_Allocation_Operations;
END
$$;

COMMENT ON PROCEDURE public.update_instrument_usage_allocations IS 'UpdateInstrumentUsageAllocations';
