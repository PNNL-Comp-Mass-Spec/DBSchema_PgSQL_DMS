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
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update instrument usage allocation data by populating a temporary table then calling update_instrument_usage_allocations_work
**
**      This procedure is obsolete since instrument allocation was last tracked in 2012 (see table t_instrument_allocation)
**
**  Arguments:
**    _fyProposal   Only used when _mode is 'update'
**    _fiscalYear   Only used when _mode is 'add'
**    _proposalID   Only used when _mode is 'add'
**    _ft           FTICR hours
**    _ftComment    FTICR comment
**    _ims          IMS hours
**    _imsComment   IMS comment
**    _orb          Orbitrap hours
**    _orbComment   Orbitrap comment
**    _exa          Exactive hours
**    _exaComment   Exactive comment
**    _ltq          LTQ hours
**    _ltqComment   LTQ comment
**    _gc           GC hours
**    _gcComment    GC comment
**    _qqq          Triple-quad hours
**    _qqqComment   Triple-quad comments
**    _mode         Mode: 'add' or 'update'
**    _message      Status message
**    _infoOnly     When true, preview the changes that would be made
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   03/28/2012 grk - Initial version
**          03/30/2012 grk - Added change command capability
**          03/30/2012 mem - Added support for x="Comment" in the XML
**                         - Now calling Update_Instrument_Usage_Allocations_Work to apply the updates
**          03/31/2012 mem - Added _fiscalYear, _proposalID, and _mode
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _fy int;
    _charPos int;
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
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

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

        _fyProposal := Trim(Coalesce(_fyProposal, ''));
        _fiscalYear := Trim(Coalesce(_fiscalYear, ''));
        _proposalID := Trim(Coalesce(_proposalID, ''));

        _ft  := Trim(Coalesce(_ft, ''));
        _ims := Trim(Coalesce(_ims, ''));
        _orb := Trim(Coalesce(_orb, ''));
        _exa := Trim(Coalesce(_exa, ''));
        _ltq := Trim(Coalesce(_ltq, ''));
        _gc  := Trim(Coalesce(_gc, ''));
        _qqq := Trim(Coalesce(_qqq, ''));

        _ftComment  := Trim(Coalesce(_ftComment, ''));
        _imsComment := Trim(Coalesce(_imsComment, ''));
        _orbComment := Trim(Coalesce(_orbComment, ''));
        _exaComment := Trim(Coalesce(_exaComment, ''));
        _ltqComment := Trim(Coalesce(_ltqComment, ''));
        _gcComment  := Trim(Coalesce(_gcComment,  ''));
        _qqqComment := Trim(Coalesce(_qqqComment, ''));

        _infoOnly   := Coalesce(_infoOnly, false);
        _mode       := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode In ('add', 'update') Then
            _msg2 := format('Invalid mode: %s', Coalesce(_mode, '??'));
            RAISE EXCEPTION '%', _msg2;
        End If;

        If _mode = 'add' Then
            If _fiscalYear = '' Then
                RAISE EXCEPTION 'Fiscal Year is empty; cannot add';
            End If;

            If _proposalID = '' Then
                RAISE EXCEPTION 'Proposal ID is empty; cannot add';
            End If;

            If Exists (SELECT proposal_id FROM t_instrument_allocation WHERE proposal_id = _proposalID AND fiscal_year = _fiscalYear) Then
                _msg2 := format('Existing entry already exists, cannot add: %s_%s', _fiscalYear, _proposalID);
                RAISE EXCEPTION '%', _msg2;
            End If;

        End If;

        If _mode = 'update' Then
            If _fyProposal = '' Then
                RAISE EXCEPTION '_fyProposal parameter is empty';
            End If;

            -- Split _fyProposal into _fiscalYear and _proposalID
            _charPos := Position('_' In _fyProposal);

            If _charPos <= 1 Or _charPos = char_length(_fyProposal) Then
                RAISE EXCEPTION '_fyProposal parameter is not in the correct format';
            End If;

            _fiscalYearParam := _fiscalYear;
            _proposalIDParam := _proposalID;

            _fiscalYear := Substring(_fyProposal, 1, _charPos - 1);
            _proposalID := Substring(_fyProposal, _charPos + 1, 128);

            If Not Exists (SELECT fy_proposal FROM t_instrument_allocation WHERE fy_proposal = _fyProposal) Then
                _msg2 := format('Entry not found, unable to update: %s', _fyProposal);
                RAISE EXCEPTION '%', _msg2;
            End If;

            If Not Exists (SELECT fy_proposal FROM t_instrument_allocation WHERE fy_proposal = _fyProposal AND proposal_id = _proposalID AND fiscal_year = _fiscalYear) Then
                _msg2 := format('Mismatch between fy_proposal, FiscalYear, and ProposalID: %s vs. %s vs. %s',
                                _fyProposal, _fiscalYear, _proposalID);
                RAISE EXCEPTION '%', _msg2;
            End If;

            If Coalesce(_fiscalYearParam, '') <> '' And _fiscalYearParam <> _fiscalYear Then
                _msg2 := format('Cannot change FiscalYear when updating: %s vs. %s', _fiscalYear, _fiscalYearParam);
                RAISE EXCEPTION '%', _msg2;
            End If;

            If Coalesce(_proposalIDParam, '') <> '' And _proposalIDParam <> _proposalID Then
                _msg2 := format('Cannot change ProposalID when updating: %s vs. %s', _proposalID, _proposalIDParam);
                RAISE EXCEPTION '%', _msg2;
            End If;
        End If;

        -- Validate _proposalID
        If Not Exists (SELECT proposal_id FROM t_eus_proposals WHERE proposal_id = _proposalID) Then
            _msg2 := format('Invalid EUS ProposalID: %s', _proposalID);
            RAISE EXCEPTION '%', _msg2;
        End If;

        -----------------------------------------------------------
        -- Temp table to hold operations
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Allocation_Operations (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Allocation text NULL,
            InstGroup text NULL,
            Proposal text NULL,
            Comment text NULL,
            FY int,
            Operation text NULL     -- 'i' -> increment, 'd' -> decrement, anything else -> set
        )

        _fy := public.try_cast(_fiscalYear, null::int);
        If _fy Is Null Or _fy = 0 Then
            _msg2 := format('Fiscal year is not numeric: %s', _fiscalYear);
            RAISE EXCEPTION '%', _msg2;
        End If;

        If _ft <> '' Then
            _ftHours := public.try_cast(_ft, null::real);

            If _ftHours Is Null Then
                _msg2 := format('FT hours is not numeric: %s', _ft);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'FT', _ftHours, _ftComment, _fy);
            End If;
        End If;

        If _ims <> '' Then
            _imsHours := public.try_cast(_ims, null::real);

            If _imsHours Is Null Then
                _msg2 := format('IMS hours is not numeric: %s', _ims);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'IMS', _imsHours, _imsComment, _fy);
            End If;
        End If;

        If _orb <> '' Then
            _orbHours := public.try_cast(_orb, null::real);

            If _orbHours Is Null Then
                _msg2 := format('Orbitrap hours is not numeric: %s', _orb);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'ORB', _orbHours, _orbComment, _fy);
            End If;
        End If;

        If _exa <> '' Then
            _exaHours := public.try_cast(_exa, null::real);

            If _exaHours Is Null Then
                _msg2 := format('Exactive hours is not numeric: %s', _exa);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'EXA', _exaHours, _exaComment, _fy);
            End If;
        End If;

        If _ltq <> '' Then
            _ltqHours := public.try_cast(_ltq, null::real);

            If _ltqHours Is Null Then
                _msg2 := format('LTQ hours is not numeric: %s', _ltq);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'LTQ', _ltqHours, _ltqComment, _fy);
            End If;
        End If;

        If _gc <> '' Then
            _gcHours := public.try_cast(_gc, null::real);

            If _gcHours Is Null Then
                _msg2 := format('GC hours is not numeric: %s', _gc);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'GC', _gcHours, _gcComment, _fy);
            End If;
        End If;

        If _qqq <> '' Then
            _qqqHours := public.try_cast(_qqq, null::real);

            If _qqqHours Is Null Then
                _msg2 := format('QQQ hours is not numeric: %s', _qqq);
                RAISE EXCEPTION '%', _msg2;
            Else
                INSERT INTO Tmp_Allocation_Operations (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  _proposalID, 'QQQ', _qqqHours, _qqqComment, _fy);
            End If;
        End If;

        -----------------------------------------------------------
        -- Call update_instrument_usage_allocations_work to perform the work
        -----------------------------------------------------------

        CALL public.update_instrument_usage_allocations_work (
                        _fy          => _fy,
                        _message     => _message,
                        _returnCode  => _returnCode,
                        _callingUser => _callingUser,
                        _infoOnly    => _infoOnly);

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
