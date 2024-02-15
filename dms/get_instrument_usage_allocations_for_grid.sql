--
-- Name: get_instrument_usage_allocations_for_grid(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_usage_allocations_for_grid(_itemlist text, _fiscalyear text) RETURNS TABLE(fiscal_year integer, proposal_id public.citext, title public.citext, status public.citext, general public.citext, ft double precision, ims double precision, orb double precision, exa double precision, ltq double precision, gc double precision, qqq double precision, last_updated text, fy_proposal public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get grid data for editing given instrument usage allocations
**
**      This function is obsolete since instrument allocation was last tracked in 2012 (see table t_instrument_allocation)
**
**  Arguments:
**    _itemList     Comma-separated list of proposal IDs to filter on; if an empty string, include all proposals
**    _fiscalYear   Fiscal year
**
**  Auth:   grk
**  Date:   01/15/2013
**          01/15/2013 grk - Initial version
**          01/16/2013 grk - Single fiscal year
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _fiscalYearValue int;
BEGIN
    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _itemList   := Trim(Coalesce(_itemList, ''));
    _fiscalYear := Trim(Coalesce(_fiscalYear, ''));

    _fiscalYearValue := public.try_cast(_fiscalYear, null::int);

    -----------------------------------------
    -- Query V_Instrument_Allocation_List_Report, filtering on the fiscal year and item list
    -----------------------------------------

    RETURN QUERY
    SELECT InstAlloc.fiscal_year,
           InstAlloc.proposal_id,
           InstAlloc.title,
           InstAlloc.status,
           InstAlloc.general,
           InstAlloc.ft,
           InstAlloc.ims,
           InstAlloc.orb,
           InstAlloc.exa,
           InstAlloc.ltq,
           InstAlloc.gc,
           InstAlloc.qqq,
           public.timestamp_text(InstAlloc.last_updated) AS last_updated,
           InstAlloc.fy_proposal
    FROM V_Instrument_Allocation_List_Report InstAlloc
    WHERE InstAlloc.Fiscal_Year = _fiscalYearValue AND
          (_itemList = '' OR InstAlloc.Proposal_ID IN (
                SELECT Value
                FROM public.parse_delimited_list(_itemList))
          );
END
$$;


ALTER FUNCTION public.get_instrument_usage_allocations_for_grid(_itemlist text, _fiscalyear text) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_usage_allocations_for_grid(_itemlist text, _fiscalyear text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_usage_allocations_for_grid(_itemlist text, _fiscalyear text) IS 'GetInstrumentUsageAllocationsForGrid';

