--
-- Name: get_sample_prep_request_eus_users_list(integer, character); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_sample_prep_request_eus_users_list(_requestid integer, _mode character DEFAULT 'I'::bpchar) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns the EUS User associated with the sample prep request
**
**          When _mode is 'I', return user ID
**          When _mode is 'N', return user name
**          When _mode is 'V', return hybrid in the form Person_Name (Person_ID)
**
**  Arguments:
**    _mode   'I', 'N', or 'V'
**
**  Auth:   mem
**  Date:   05/01/2014
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**          06/15/2022 mem - Ported to PostgreSQL
**          12/09/2022 mem - Assure that _mode is uppercase
**          05/30/2023 mem - Use ElsIf for Else If
**                         - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _eusUserID int;
    _list text := '';
BEGIN
    _mode := Upper(_mode);

    SELECT eus_user_id
    INTO _eusUserID
    FROM t_sample_prep_request
    WHERE prep_request_id = _requestID;

    If Coalesce(_eusUserID, 0) > 0 Then
        If _mode = 'I' Then
            SELECT EU.person_id::text
            INTO _list
            FROM t_eus_users EU
            WHERE EU.person_id = _eusUserID;
        ElsIf _mode = 'N' Then
            SELECT EU.name_fm
            INTO _list
            FROM t_eus_users EU
            WHERE EU.person_id = _eusUserID;
        ElsIf _mode = 'V' Then
            SELECT format('%s (%s)', name_fm, EU.person_id)
            INTO _list
            FROM t_eus_users EU
            WHERE EU.person_id = _eusUserID;
        End If;
    End If;

    If Coalesce(_list, '') = '' Then
        _list := '(none)';
    End If;

    RETURN _list;
END
$$;


ALTER FUNCTION public.get_sample_prep_request_eus_users_list(_requestid integer, _mode character) OWNER TO d3l243;

--
-- Name: FUNCTION get_sample_prep_request_eus_users_list(_requestid integer, _mode character); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_sample_prep_request_eus_users_list(_requestid integer, _mode character) IS 'GetSamplePrepRequestEUSUsersList';

