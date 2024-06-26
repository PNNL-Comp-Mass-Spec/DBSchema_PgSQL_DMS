--
-- Name: get_proposal_eus_users_list(text, text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_proposal_eus_users_list(_proposalid text, _mode text DEFAULT 'I'::text, _maxusers integer DEFAULT 5) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of EUS users for given proposal
**
**  Arguments:
**    _mode   Can be I, N, L, or V:
**              I for comma-separated list of EUS User IDs,       e.g. 36746, 44666
**              N for semicolon-separated list of names,          e.g. Adkins, Josh; Ansong, Charles;
**              L for semicolon-separated list of last names,     e.g. Adkins; Ansong
**              V for semicolon-separated list of both,           e.g. Adkins, Josh (36746); Ansong, Charles (44666)
**
**  Returns:
**      Comma or semicolon separated list
**
**  Auth:   jds
**  Date:   09/07/2006
**          04/01/2011 mem - Added mode 'V' (verbose)
**                         - Now excluding users with State_ID 5="No longer associated with proposal"
**          06/13/2013 mem - Added mode 'L' (last names only)
**          02/19/2018 mem - Added parameter _maxUsers
**          06/22/2022 mem - Ported to PostgreSQL
**          05/24/2023 mem - Use format() for string concatenation
**          05/30/2023 mem - Use ElsIf for Else If
**          01/20/2024 mem - Change data type of _proposalID to text
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    If Coalesce(_maxUsers, 0) <= 0 Then
        _maxUsers := 10000;
    End If;

    _mode := Upper(_mode);

    If _mode = 'I' Then
        SELECT string_agg(U.person_id::text, ', ' ORDER BY U.person_id)
        INTO _result
        FROM t_eus_proposal_users P
             INNER JOIN t_eus_users U
               ON P.person_id = U.person_id
        WHERE P.proposal_id = _proposalID::citext AND
              P.state_id <> 5
        LIMIT _maxUsers;

    ElsIf _mode = 'N' Then
        SELECT string_agg(U.name_fm, '; ' ORDER BY U.name_fm)
        INTO _result
        FROM t_eus_proposal_users P
             INNER JOIN t_eus_users U
               ON P.person_id = U.person_id
        WHERE P.proposal_id = _proposalID::citext AND
              P.state_id <> 5
        LIMIT _maxUsers;

    ElsIf _mode = 'L' Then
        SELECT string_agg(U.last_name, '; ' ORDER BY U.last_name)
        INTO _result
        FROM t_eus_proposal_users P
             INNER JOIN t_eus_users U
               ON P.person_id = U.person_id
        WHERE P.proposal_id = _proposalID::citext AND
              P.state_id <> 5
        LIMIT _maxUsers;

    ElsIf _mode = 'V' Then
        SELECT string_agg(format('%s (%s)', U.name_fm, U.person_id), '; ' ORDER BY U.name_fm)
        INTO _result
        FROM t_eus_proposal_users P
             INNER JOIN t_eus_users U
               ON P.person_id = U.person_id
        WHERE P.proposal_id = _proposalID::citext AND
              P.state_id <> 5
        LIMIT _maxUsers;

    Else
        _result := null;
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_proposal_eus_users_list(_proposalid text, _mode text, _maxusers integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_proposal_eus_users_list(_proposalid text, _mode text, _maxusers integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_proposal_eus_users_list(_proposalid text, _mode text, _maxusers integer) IS 'GetProposalEUSUsersList';

