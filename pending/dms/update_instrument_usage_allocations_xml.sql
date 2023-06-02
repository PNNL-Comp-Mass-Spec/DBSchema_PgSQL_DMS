--
CREATE OR REPLACE PROCEDURE public.update_instrument_usage_allocations_xml
(
    _parameterList text = '',
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
**      Update requested instrument usage allocation from input XML list
**
**  _parameterList will look like this (for setting values):
**
**  <c fiscal_year="2022"/>
**  <r p="29591" g="FT" a="23.2" x="Comment1"/>
**  <r p="33200" g="FT" a="102.1" x="Comment2"/>
**  <r p="34696" g="FT" a="240" />
**  <r p="34708" g="FT" a="177.7" x="Comment3"/>
**
**  or this (for transferring hours between two proposals):
**
**  <c fiscal_year="2022"/>
**  <r o="i" p="29591" g="FT" a="14.5" x="Comment"/>
**  <r o="d" p="33200" g="FT" a="14.5" x="Comment"/>
**
**  Arguments:
**    _parameterList   XML specifying allocation hours
**    _infoOnly        Set to true to preview the changes that would be made
**
**  Auth:   grk
**  Date:   03/28/2012 grk - Initial release
**          03/30/2012 grk - Added change command capability
**          03/30/2012 mem - Added support for x="Comment" in the XML
**                         - Now calling Update_Instrument_Usage_Allocations_Work to apply the updates
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _fiscalYear text;
    _fy int;
    _msg2 text;
    _xml AS xml;

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

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

        _infoOnly := Coalesce(_infoOnly, false);

        -----------------------------------------------------------
        -- Temp table to hold operations
        -----------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_Allocation_Operations (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Allocation text NULL,
            InstGroup text null,
            Proposal text null,
            Comment text null,
            FY int,
            Operation text NULL -- 'i' -> increment, 'd' -> decrement, anything else -> set
        )

        -----------------------------------------------------------
        -- Copy _parameterList text variable into the XML variable
        -----------------------------------------------------------
        _xml := _parameterList;

        -----------------------------------------------------------
        -- Resolve fiscal year
        -- Example XML to parse:
        --   <c fiscal_year="2022"/>
        -----------------------------------------------------------
        --
        _fiscalYear := (xpath('//c/@fiscal_year', _xml))[1]::text;

        _fy := public.try_cast(_fiscalYear, Extract(year from CURRENT_TIMESTAMP));

        If _fy Is Null Then
            _fy := Extract(year from CURRENT_TIMESTAMP);
        End If;

        -----------------------------------------------------------
        -- Populate operations table from input parameters
        -- Example XML to parse:
        --   <r o="i" p="29591" g="FT" a="14.5" x="Comment"/>
        -----------------------------------------------------------
        --
        INSERT INTO Tmp_Allocation_Operations
            (Operation, Proposal, InstGroup, Allocation, Comment, FY)
        SELECT
            Coalesce((xpath('//r/@o', _xml))[1]::text, '') AS Operation,    -- If missing from the XML, the merge will treat this as 'Set'
            (xpath('//r/@p', _xml))[1]::text AS Proposal,
            (xpath('//r/@g', _xml))[1]::text AS InstGroup,
            (xpath('//r/@a', _xml))[1]::text AS Allocation,
            Coalesce((xpath('//r/@x', _xml))[1]::text, '') AS Comment,
            _fy AS FY;

        -----------------------------------------------------------
        -- Call update_instrument_usage_allocations_work to perform the work
        -----------------------------------------------------------
        --
        CALL update_instrument_usage_allocations_work (_fy, _message => _message, _callingUser, _infoOnly);

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

COMMENT ON PROCEDURE public.update_instrument_usage_allocations_xml IS 'UpdateInstrumentUsageAllocationsXML';
