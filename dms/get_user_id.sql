--
-- Name: get_user_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_user_id(_username text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get UserID for given user
**
**  Arguments:
**    _username      Username, or user's name with username in parentheses
**
**  Returns:
**      User ID if found, otherwise 0
**
**  Example usage:
**      SELECT * FROM public.get_user_id('d3l243');
**      SELECT * FROM public.get_user_id('Monroe, Matthew E (d3l243)');
**      SELECT * FROM public.get_user_id('unknown');
**      SELECT * FROM public.get_user_id(null);
**
**  Auth:   grk
**  Date:   01/26/2001 grk - Initial version
**          08/03/2017 mem - Add set nocount on
**          10/22/2020 mem - Add support for names of the form 'LastName, FirstName (Username)'
**          10/13/2022 mem - Ported to PostgreSQL
**          02/08/2023 mem - Rename argument to _username
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _userID int;
    _startLoc int;
BEGIN
    If _username Like '%(%)' Then
        _startLoc := position('(' In _username);
        If _startLoc > 0 Then
            _username := Substring(_username, _startLoc + 1, char_length(_username) - _startLoc - 1);
        End If;
    End If;

    SELECT user_id
    INTO _userID
    FROM t_users
    WHERE username::citext = _username::citext;

    If FOUND Then
        RETURN _userID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_user_id(_username text) OWNER TO d3l243;

--
-- Name: FUNCTION get_user_id(_username text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_user_id(_username text) IS 'GetUserID';

