--
-- Name: get_eus_users_proposal_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_eus_users_proposal_list(_personid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Builds delimited list of proposals for given EUS user
**
**  Arguments:
**     _personID    Person ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   12/28/2008 mem - Initial version
**          09/15/2011 mem - Now excluding users with State_ID = 5
**          06/21/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(P.Proposal_ID, ', ' ORDER BY P.Proposal_ID)
    INTO _result
    FROM t_eus_proposal_users P
    WHERE P.person_id = _personID AND P.state_id <> 5;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_eus_users_proposal_list(_personid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_eus_users_proposal_list(_personid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_eus_users_proposal_list(_personid integer) IS 'GetEUSUsersProposalList';

