--
-- Name: check_emsl_usage_item_validity(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.check_emsl_usage_item_validity(_seq integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Check EMSL usage item validity
**
**  Arguments:
**    _seq      Seq ID of row in t_emsl_instrument_usage_report to validate
**
**  Example usage:
**      SELECT *
**      FROM (SELECT Src.seq,
**                   check_emsl_usage_item_validity(Src.seq) AS Result
**            FROM t_emsl_instrument_usage_report Src
**            WHERE Src.seq Between 600 AND 1000 OR
**                  Src.seq Between 574291 AND 599883) CheckQ
**      WHERE char_length(CheckQ.Result) > 0
**      ORDER BY seq;
**
**  Auth:   grk
**  Date:   08/28/2012
**          08/31/2012 grk - Fixed spelling error in message
**          10/03/2012 grk - Maintenance usage no longer requires comment
**          03/20/2013 mem - Changed from Call_Type to Proposal_Type
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/05/2016 mem - Add one day to the proposal end date
**          03/17/2017 mem - Only call MakeTableFromList if _users is a comma-separated list
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Updated field name in T_EMSL_Instrument_Usage_Report
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/17/2022 mem - Ported to PostgreSQL
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          05/29/2023 mem - Use format() for string concatenation
**          06/15/2023 mem - Add support for usage type 'RESOURCE_OWNER'
**          06/16/2023 mem - Use named arguments when calling append_to_text()
**          07/11/2023 mem - Use COUNT(proposal_id) instead of COUNT(*)
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Use schema name with try_cast
**
*****************************************************/
DECLARE
    _message text;
    _instrumentUsage record;
    _proposalInfo record;
    _hits int := 0;
BEGIN
    _message := '';

    SELECT -- InstUsage.type,
           InstUsage.start,
           -- InstUsage.minutes,
           InstUsage.proposal,
           Coalesce(InstUsageType.usage_type, '') as usage,
           InstUsage.users,
           InstUsage.operator,
           InstUsage.comment,
           InstUsage.year,
           InstUsage.month
           -- InstUsage.dataset_id
    INTO _instrumentUsage
    FROM t_emsl_instrument_usage_report InstUsage
         INNER JOIN t_instrument_name InstName
           ON InstUsage.dms_inst_id = InstName.instrument_id
         LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
    WHERE InstUsage.seq = _seq;

    If _instrumentUsage.usage = 'CAP_DEV' And _instrumentUsage.operator Is Null Then
        _message := public.append_to_text(_message, 'Capability Development requires an instrument operator ID', _delimiter => ', ');
    End If;

    If _instrumentUsage.usage = 'RESOURCE_OWNER' And _instrumentUsage.operator Is Null Then
        _message := public.append_to_text(_message, 'Resource Owner requires an instrument operator ID', _delimiter => ', ');
    End If;

    If Not _instrumentUsage.usage In ('ONSITE', 'MAINTENANCE') And Coalesce(_instrumentUsage.comment, '') = '' Then
        _message := public.append_to_text(_message, 'Missing Comment', _delimiter => ', ');
    End If;

    If _instrumentUsage.usage = 'OFFSITE' And _instrumentUsage.proposal = '' Then
        _message := public.append_to_text(_message, 'Missing Proposal', _delimiter => ', ');
    End If;

    If _instrumentUsage.usage = 'ONSITE' And Not _instrumentUsage.proposal SIMILAR TO '[0-9]%' Then
        _message := public.append_to_text(_message, 'Preliminary Proposal number', _delimiter => ', ');
    End If;

    SELECT proposal_id as proposalID,
           proposal_start_date as proposalStartDate,
           proposal_end_date + INTERVAL '1 day' as proposalEndDate
    INTO _proposalInfo
    FROM t_eus_proposals
    WHERE proposal_id = _instrumentUsage.proposal;

    If _instrumentUsage.usage = 'ONSITE' And _proposalInfo.proposalID IS null Then
        _message := public.append_to_text(_message, 'Proposal number is not in EUS', _delimiter => ', ');
    End If;

    If Not _proposalInfo.proposalID Is Null And _instrumentUsage.usage = 'ONSITE' And
       Not (_instrumentUsage.start Between _proposalInfo.proposalStartDate And _proposalInfo.proposalEndDate)
    Then
        _message := public.append_to_text(_message, 'Run start not between proposal start/end dates', _delimiter => ', ');
    End If;

    If Not _proposalInfo.proposalID Is Null Then
        If _instrumentUsage.users Like '%,%' Then
            SELECT COUNT(*)
            INTO _hits
            FROM public.parse_delimited_list (_instrumentUsage.users)
                 INNER JOIN (SELECT proposal_id,
                                    person_id
                             FROM t_eus_proposal_users
                             WHERE proposal_id = _instrumentUsage.proposal) ProposalUsers
                   ON ProposalUsers.person_id = public.try_cast(Value, 0);
        Else
            SELECT COUNT(proposal_id)
            INTO _hits
            FROM t_eus_proposal_users
            WHERE proposal_id = _instrumentUsage.proposal AND person_id = public.try_cast(_instrumentUsage.users, 0);
        End If;

        If _hits = 0 Then
            _message := public.append_to_text(_message, 'No users were listed for proposal', _delimiter => ', ');
        End If;
    End If;

    RETURN _message;
END
$$;


ALTER FUNCTION public.check_emsl_usage_item_validity(_seq integer) OWNER TO d3l243;

--
-- Name: FUNCTION check_emsl_usage_item_validity(_seq integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.check_emsl_usage_item_validity(_seq integer) IS 'CheckEMSLUsageItemValidity';

