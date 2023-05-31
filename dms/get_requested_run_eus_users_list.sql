--
-- Name: get_requested_run_eus_users_list(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_run_eus_users_list(_requestid integer, _mode text DEFAULT 'I'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of EUS users for given requested run
**
**  Arguments:
**    _mode   'I' for comma separated list of EUS User IDs,       e.g. 36746, 39552
**            'N' for semicolon separated list of EUS User names, e.g. Adkins, Josh; Wong, Scott
**            'V' for semicolon separated list of both,           e.g. Adkins, Josh (36746); Wong, Scott (39552)
**
**  Auth:   grk
**  Date:   02/15/2006
**          06/13/2022 mem - Ported to PostgreSQL
**          12/09/2022 mem - Assure that _mode is uppercase
**          12/24/2022 mem - Use ::text
**          04/04/2023 mem - Use char_length() to determine string length
**          05/24/2023 mem - Use format() for string concatenation
**          05/30/2023 mem - Use ElsIf for Else If
**
*****************************************************/
DECLARE
    _result text;
BEGIN
     _mode := Upper(_mode);

    If _mode = 'I' Then
        SELECT string_agg(RRUsers.EUS_Person_ID::text, ', ' ORDER BY EUS_Person_ID)
        INTO _result
        FROM t_requested_run_eus_users RRUsers INNER JOIN
             t_eus_users U ON RRUsers.eus_person_id = U.person_id
        WHERE RRUsers.request_id = _requestID;

    ElsIf _mode = 'N' Then
        SELECT string_agg(U.NAME_FM, '; ' ORDER BY NAME_FM)
        INTO _result
        FROM t_requested_run_eus_users RRUsers INNER JOIN
             t_eus_users U ON RRUsers.eus_person_id = U.person_id
        WHERE RRUsers.request_id = _requestID;

    ElsIf _mode = 'V' Then
        SELECT string_agg(format('%s (%s)', U.NAME_FM, RRUsers.EUS_Person_ID), '; ' ORDER BY NAME_FM)
        INTO _result
        FROM t_requested_run_eus_users RRUsers INNER JOIN
             t_eus_users U ON RRUsers.eus_person_id = U.person_id
        WHERE RRUsers.request_id = _requestID;

        If char_length(Coalesce(_result, '')) = 0 Then
            _result := '(none)';
        End If;

    Else
        _result := '';
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_requested_run_eus_users_list(_requestid integer, _mode text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_run_eus_users_list(_requestid integer, _mode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_run_eus_users_list(_requestid integer, _mode text) IS 'GetRequestedRunEUSUsersList';

