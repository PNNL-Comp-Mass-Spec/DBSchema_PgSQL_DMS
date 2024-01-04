--
CREATE OR REPLACE FUNCTION public.get_instrument_usage_allocations_for_grid
(
    _itemList text,
    _fiscalYear text
)
RETURNS TABLE
(
    fiscal_year int4,
	proposal_id citext,
	title citext,
	status citext,
	general citext,
	ft float8,
	ims float8,
	orb float8,
	exa float8,
	ltq float8,
	gc float8,
	qqq float8,
	last_updated text,
	fy_proposal citext
)
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
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _itemList   := Trim(Coalesce(_itemList, ''));
    _fiscalYear := Trim(Coalesce(_fiscalYear, ''));

    -----------------------------------------
    -- Convert item list into temp table
    -----------------------------------------

    CREATE TEMP TABLE Tmp_Proposals (
        Item text
    );

    INSERT INTO Tmp_Proposals (Item)
    SELECT Value
    FROM public.parse_delimited_list(_itemList);

    RETURN QUERY
    SELECT fiscal_year,
           proposal_id,
           title,
           status,
           general,
           ft,
           ims,
           orb,
           exa,
           ltq,
           gc,
           qqq,
           public.timestamp_text(Last_Updated) AS last_updated,
           fy_proposal
    FROM V_Instrument_Allocation_List_Report
    WHERE Fiscal_Year = _fiscalYear AND
          (_itemList = '' OR Proposal_ID IN (SELECT Item FROM Tmp_Proposals));

    DROP TABLE Tmp_Proposals;
END
$$;

COMMENT ON FUNCTION public.get_instrument_usage_allocations_for_grid IS 'GetInstrumentUsageAllocationsForGrid';
