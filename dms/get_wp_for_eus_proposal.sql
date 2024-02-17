--
-- Name: get_wp_for_eus_proposal(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_wp_for_eus_proposal(_eusproposalid text) RETURNS TABLE(work_package text, months_searched integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Determines best work package to use for a given EUS user proposal
**          Column work_package will be 'none' in the returned table if no match is found
**
**  Arguments:
**    _eusProposalID    EUS user proposal ID
**
**  Returned Values:
**    work_package      Work package associated with the EUS user proposal, or 'none' if no match
**    months_searched   Number of months back that this function searched to find a work package for _eusProposalID; 0 if no match
**
**  Example usage:
**      SELECT * FROM get_wp_for_eus_proposal('51735');
**      SELECT * FROM get_wp_for_eus_proposal('60702');
**
**  Auth:   mem
**  Date:   01/29/2016 mem - Initial Version
**          10/14/2022 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(RR.request_id) insted of COUNT(*)
**          07/26/2023 mem - Move "Not" keyword to before the field name
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _workPackage text;
    _workPackageNew citext := '';
    _monthsSearched int;
    _allMonthsCount int;
    _monthThreshold int;
    _continue boolean;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _eusProposalID  := Trim(Coalesce(_eusProposalID, ''));
    _workPackage    := 'none';
    _monthsSearched := 0;

    -- This is an estimate to the number of months between today and January 1, 1900
    -- It corresponds to the result of "DateDiff(month, 0, GetDate())" in SQL Server:
    _allMonthsCount := Round(Extract(day FROM current_timestamp - make_date(1900, 1, 1)) / 30.45);

    -----------------------------------------
    -- Find the most commonly used work package for the EUS proposal
    -- First look for use in the last 2 months
    -- If no match, try the last 4 months, then 8 months, then 16 months, then all records
    -----------------------------------------

    If Exists (SELECT proposal_id FROM t_eus_proposals WHERE proposal_id = _eusProposalID) Then

        _monthThreshold := 2;
        _continue := true;

        WHILE _continue
        LOOP
            SELECT RR.work_package
            INTO _workPackageNew
            FROM t_requested_run RR
            WHERE RR.eus_proposal_id = _eusProposalID AND
                  RR.work_package <> 'none' AND
                  RR.entered >= CURRENT_TIMESTAMP - CAST(format('%s months', _monthThreshold) AS interval)
            GROUP BY RR.work_package
            ORDER BY COUNT(RR.request_id) DESC
            LIMIT 1;

            If FOUND Then
                _continue := false;
            Else
                If _monthThreshold >= _allMonthsCount Then
                    _continue := false;
                Else
                    _monthThreshold := _monthThreshold * 2;
                    If _monthThreshold > 16 Then
                        _monthThreshold := _allMonthsCount;
                    End If;
                End If;
            End If;
        END LOOP;

        _workPackageNew := Trim(Coalesce(_workPackageNew, ''));

        If Not _workPackageNew In ('', 'none', 'na') Then
            _workPackage := _workPackageNew;
            _monthsSearched := _monthThreshold;
        End If;

    End If;

    RETURN QUERY
    SELECT _workPackage, _monthsSearched;
END
$$;


ALTER FUNCTION public.get_wp_for_eus_proposal(_eusproposalid text) OWNER TO d3l243;

--
-- Name: FUNCTION get_wp_for_eus_proposal(_eusproposalid text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_wp_for_eus_proposal(_eusproposalid text) IS 'GetWPforEUSProposal';

