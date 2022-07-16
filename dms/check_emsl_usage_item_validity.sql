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
**  Return value: error message
**
**  Auth:   grk
**  Date:   08/28/2012
**          08/31/2012 grk - fixed spelling error in message
**          10/03/2012 grk - Maintenance usage no longer requires comment
**          03/20/2013 mem - Changed from Call_Type to Proposal_Type
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/05/2016 mem - Add one day to the proposal end date
**          03/17/2017 mem - Only call MakeTableFromList if _users is a comma separated list
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Updated field name in T_EMSL_Instrument_Usage_Report
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/17/2022 mem - Ported to PostgreSQL
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**
*****************************************************/
DECLARE
    _message text;
    _instrumentUsage record;
    _proposalInfo record;
    _hits int := 0;
BEGIN
    _message := '';

    SELECT --InstUsage.type,
           InstUsage.start,
           --InstUsage.minutes,
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

    IF _instrumentUsage.usage = 'CAP_DEV' AND _instrumentUsage.operator is null  Then
        _message := _message || 'Capability Development requires an operator' || ', ';
    End If;

    IF NOT _instrumentUsage.usage IN ('ONSITE', 'MAINTENANCE') AND Coalesce(_instrumentUsage.comment, '') = '' Then
        _message := _message || 'Missing Comment' || ', ';
    End If;

    IF _instrumentUsage.usage = 'OFFSITE' AND _instrumentUsage.proposal = '' Then
        _message := _message || 'Missing Proposal' || ', ';
    End If;

    IF _instrumentUsage.usage = 'ONSITE' AND Not _instrumentUsage.proposal similar to '[0-9]%' Then
        _message := _message || 'Preliminary Proposal number' || ', ';
    End If;

    SELECT proposal_id as proposalID,
           proposal_start_date as proposalStartDate,
           proposal_end_date + Interval '1 day' as proposalEndDate
    INTO _proposalInfo
    FROM  t_eus_proposals
    WHERE proposal_id = _instrumentUsage.proposal;

    IF _instrumentUsage.usage = 'ONSITE' AND _proposalInfo.proposalID IS null Then
        _message := _message || 'Proposal number is not in ERS' || ', ';
    End If;

    IF NOT _proposalInfo.proposalID IS NULL and _instrumentUsage.usage = 'ONSITE' AND
       NOT (_instrumentUsage.start BETWEEN _proposalInfo.proposalStartDate AND _proposalInfo.proposalEndDate) Then
        _message := _message || 'Run start not between proposal start/end dates' || ', ';
    End If;

    IF NOT _proposalInfo.proposalID IS NULL Then
        If _instrumentUsage.users Like '%,%' Then
            SELECT COUNT(*)
            INTO _hits
            FROM public.parse_delimited_list ( _instrumentUsage.users )
                 INNER JOIN ( SELECT proposal_id,
                                     person_id
                              FROM t_eus_proposal_users
                              WHERE proposal_id = _instrumentUsage.proposal ) ProposalUsers
                   ON ProposalUsers.person_id = try_cast(Value, 0);
        Else
            SELECT COUNT(*)
            INTO _hits
            FROM t_eus_proposal_users
            WHERE proposal_id = _instrumentUsage.proposal And person_id = try_cast(_instrumentUsage.users, 0);
        End If;

        IF _hits = 0 Then
            _message := _message || 'No users were listed for proposal' || ', ';
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

