--
-- Name: get_user_login_without_domain(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_user_login_without_domain(_callinguser text DEFAULT ''::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the network login (username) of the calling user
**
**  Return value: username
**
**  Auth:   mem
**  Date:   11/08/2016 mem - Initial Version
**          11/10/2016 mem - Add parameter _callingUser, which is used in place of DMSWebUser
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _login citext;
BEGIN
    -- Determine the username of the current session user
    _login := SESSION_USER;

    -- On SQL Server, _login would include the domain name, e.g. pnl\D3M123 or pnl\pers1234
    -- On Postgres, _login is likely only the username
    -- If _login has a backslash, return the portion after the last backslash

    If Position('\' In _login) > 0 Then
        -- regexp_match returns an array; use [1] to retrieve the first match
        _login := (regexp_match(_login, '.+\\(.+)'))[1];
    End If;

    If _login = 'DMSWebUser' And Coalesce(_callingUser, '') <> '' Then
        -- Use the calling user's username instead of DMSWebUser
        _login := _callingUser;

        If Position('\' In _login) > 0 Then
            _login := (regexp_match(_login, '.+\\(.+)'))[1];
        End If;
    End If;

    RETURN _login;
END
$$;


ALTER FUNCTION public.get_user_login_without_domain(_callinguser text) OWNER TO d3l243;

--
-- Name: FUNCTION get_user_login_without_domain(_callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_user_login_without_domain(_callinguser text) IS 'GetUserLoginWithoutDomain';

