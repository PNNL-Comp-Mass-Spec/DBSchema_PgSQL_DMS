--
CREATE OR REPLACE FUNCTION public.get_instrument_usage_allocations_for_grid
(
    _itemList text,
    _fiscalYear text
)
RETURNS TABLE
(
    ...
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get grid data for editing given usage allocations
**
**  Arguments:
**    _itemList     Comma separated list of proposal IDs to filter on; if an empty string, include all proposals
**    _fiscalYear   Fiscal year
**
**  Auth:   grk
**  Date:   01/15/2013
**          01/15/2013 grk - Initial release
**          01/16/2013 grk - Single fiscal year
**          12/15/2023 mem - Ported to PostgreSQL
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
          (char_length(_itemList) = 0 OR Proposal_ID IN (SELECT Item FROM Tmp_Proposals));

    DROP TABLE Tmp_Proposals;
END
$$;

COMMENT ON FUNCTION public.get_instrument_usage_allocations_for_grid IS 'GetInstrumentUsageAllocationsForGrid';
