--
-- Name: update_instrument_usage_allocations_xml(text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_instrument_usage_allocations_xml(IN _parameterlist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update instrument usage allocation using an XML list
**
**      This procedure is obsolete since instrument allocation was last tracked in 2012 (see table t_instrument_allocation)
**
**      Example XML in _parameterList:
**
**      1) Setting values
**          <c fiscal_year="2022"/>
**          <r p="29591" g="FT" a="23.2" x="Comment1"/>
**          <r p="33200" g="FT" a="102.1" x="Comment2"/>
**          <r p="34696" g="FT" a="240" />
**          <r p="34708" g="FT" a="177.7" x="Comment3"/>
**
**     2) Transferring hours between two proposals
**          <c fiscal_year="2022"/>
**          <r o="i" p="29591" g="FT" a="14.5" x="Comment"/>
**          <r o="d" p="33200" g="FT" a="14.5" x="Comment"/>
**
**      Abbreviations:
**        o: Operation, where operation "i" means increment, "d" means decrement, and anything else means set
**        p: Proposal
**        g: Instrument Group
**        a: Allocation
**        x: Comment
**
**  Arguments:
**    _parameterList    XML specifying allocation hours
**    _infoOnly         When true, preview the changes that would be made
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/28/2012 grk - Initial version
**          03/30/2012 grk - Added change command capability
**          03/30/2012 mem - Added support for x="Comment" in the XML
**                         - Now calling Update_Instrument_Usage_Allocations_Work to apply the updates
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/24/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _fiscalYear text;
    _currentYear int;
    _fy int;
    _msg2 text;
    _xml xml;
    _updateCount int;
    _rowNumber int;

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

        _parameterList := Trim(Coalesce(_parameterList, ''));
        _infoOnly      := Coalesce(_infoOnly, false);

        -----------------------------------------------------------
        -- Temporary table to hold operations
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Allocation_Operations (
            Entry_ID   int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Allocation text NULL,
            InstGroup  text NULL,
            Proposal   text NULL,
            Comment    text NULL,
            FY         int NOT NULL,
            Operation  text NULL -- 'i' -> increment, 'd' -> decrement, anything else -> set
        );

        -----------------------------------------------------------
        -- Convert _parameterList into rooted XML
        -----------------------------------------------------------

        _xml := public.try_cast(format('<root>%s</root>', _parameterList), null::xml);

        -----------------------------------------------------------
        -- Resolve fiscal year
        -- Example XML to parse:
        --   <c fiscal_year="2022"/>
        -----------------------------------------------------------

        _currentYear := Extract(year from CURRENT_TIMESTAMP);
        _fiscalYear  := (xpath('//c/@fiscal_year', _xml))[1]::text;

        _fy := Coalesce(public.try_cast(_fiscalYear, _currentYear), _currentYear);

        -----------------------------------------------------------
        -- Populate operations table from input parameters
        -- Example XML to parse:
        --   <r o="i" p="29591" g="FT" a="14.5" x="Comment"/>
        --   <r o="d" p="33200" g="FT" a="14.5" x="Comment"/>
        -----------------------------------------------------------

        -- Count the number of instances of '<r ' in the XML
        SELECT COUNT(*)
        INTO _updateCount
        FROM ( SELECT (regexp_matches(_parameterList, '<r ', 'g'))[1]
             ) MatchQ;

        If Coalesce(_updateCount, 0) < 1 Then
            _updateCount := 1;
        End If;

        FOR _rowNumber IN 1 .. _updateCount
        LOOP
            INSERT INTO Tmp_Allocation_Operations (
                Operation,
                Proposal,
                InstGroup,
                Allocation,
                Comment,
                FY
            )
            SELECT
                Coalesce((xpath('//r/@o', _xml))[_rowNumber]::text, '') AS Operation,    -- If missing from the XML, the merge will treat this as 'Set'
                         (xpath('//r/@p', _xml))[_rowNumber]::text      AS Proposal,
                         (xpath('//r/@g', _xml))[_rowNumber]::text      AS InstGroup,
                         (xpath('//r/@a', _xml))[_rowNumber]::text      AS Allocation,
                Coalesce((xpath('//r/@x', _xml))[_rowNumber]::text, '') AS Comment,
                _fy AS FY;

        END LOOP;

        -----------------------------------------------------------
        -- Call update_instrument_usage_allocations_work to perform the work
        -----------------------------------------------------------

        CALL public.update_instrument_usage_allocations_work (
                        _fy          => _fy,
                        _message     => _message,
                        _returnCode  => _returnCode,
                        _callingUser => _callingUser,
                        _infoOnly    => _infoOnly);

        DROP TABLE Tmp_Allocation_Operations;
        RETURN;

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


ALTER PROCEDURE public.update_instrument_usage_allocations_xml(IN _parameterlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_instrument_usage_allocations_xml(IN _parameterlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_instrument_usage_allocations_xml(IN _parameterlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateInstrumentUsageAllocationsXML';

