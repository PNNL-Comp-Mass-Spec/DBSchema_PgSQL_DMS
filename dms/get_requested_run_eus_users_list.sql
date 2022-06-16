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
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    IF _mode = 'I' Then
        SELECT string_agg(CAST(EUS_Person_ID AS text), ', ' ORDER BY EUS_Person_ID)
        INTO _result
        FROM t_requested_run_eus_users INNER JOIN
             t_eus_users ON t_requested_run_eus_users.eus_person_id = t_eus_users.person_id
        WHERE t_requested_run_eus_users.request_id = _requestID;
    ElseIF _mode = 'N' Then
        SELECT string_agg(NAME_FM, '; ' ORDER BY NAME_FM)
        INTO _result
        FROM t_requested_run_eus_users INNER JOIN
             t_eus_users ON t_requested_run_eus_users.eus_person_id = t_eus_users.person_id
        WHERE t_requested_run_eus_users.request_id = _requestID;
    ElseIF _mode = 'V' Then
        SELECT string_agg(NAME_FM || ' (' || CAST(EUS_Person_ID AS text) || ')', '; ' ORDER BY NAME_FM)
        INTO _result
        FROM t_requested_run_eus_users INNER JOIN
             t_eus_users ON t_requested_run_eus_users.eus_person_id = t_eus_users.person_id
        WHERE t_requested_run_eus_users.request_id = _requestID;

        If Length(Coalesce(_result, '')) = 0 Then
            _result := '(none)';
        End If;
    Else
        _result := '';
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_requested_run_eus_users_list(_requestid integer, _mode text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_run_eus_users_list(_requestid integer, _mode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_run_eus_users_list(_requestid integer, _mode text) IS 'GetRequestedRunEUSUsersList';

