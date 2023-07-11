--
-- Name: auto_resolve_name_to_username(text, integer, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_resolve_name_to_username(IN _namesearchspec text, INOUT _matchcount integer DEFAULT 0, INOUT _matchingusername text DEFAULT ''::text, INOUT _matchinguserid integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for entries in T_Users that match _nameSearchSpec (supports % as a wildcard)
**      Updates _matchCount with the number of matching entries
**      If a match is found, also updates _matchingUsername and _matchingUserID with the first match
**
**  Arguments:
**    _nameSearchSpec       Used to search both name and username in T_Users; use % for a wildcard
**                          - % will be appended to _nameSearchSpec if it doesn't end in one
**                          - If the search spec is of the form 'Last, First (D3P704)' or 'Last, First Middle (D3P704)',
**                            extracts the username (e.g., 'D3P704') and searches the username column in T_Users
**                          - Otherwise, first searches the name column (which lists people by LastName, FirstName)
**                          - If no match, searches the username column
**    _matchCount           Number of entries in T_Users that match _nameSearchSpec
**    _matchingUsername     If _matchCount > 0, will have the username of the first match in T_Users
**    _matchingUserID       If _matchCount > 0, will have the ID of the first match in T_Users
**
**  Auth:   mem
**  Date:   02/07/2010
**          01/20/2017 mem - Now checking for names of the form 'Last, First (D3P704)' or 'Last, First Middle (D3P704)' and auto-fixing those
**          06/12/2017 mem - Check for _nameSearchSpec being a username
**          11/11/2019 mem - Return no matches if _nameSearchSpec is null or an empty string
**          09/11/2020 mem - Use TrimWhitespaceAndPunctuation to remove trailing whitespace and punctuation
**          02/14/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(user_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _charIndexStart int;
    _charIndexEnd int;
BEGIN
    _matchCount := 0;

    -- Trim leading and trailing whitespace
    _nameSearchSpec :=public.trim_whitespace_and_punctuation(Coalesce(_nameSearchSpec, ''));

    If char_length(_nameSearchSpec) = 0 Then
        RETURN;
    End If;

    -- Trim leading and trailing punctuation

    If _nameSearchSpec Like '%,%(%)' Then
        -- Name is of the form 'Last, First (D3P704)' or 'Last, First Middle (D3P704)'
        -- Extract D3P704

        _charIndexStart := Position('(' In _nameSearchSpec);
        _charIndexEnd   := Position(')' In substr(_nameSearchSpec, _charIndexStart));

        If _charIndexStart > 0 And _charIndexEnd > 2 Then
            _nameSearchSpec := substr(_nameSearchSpec, _charIndexStart + 1, _charIndexEnd - 2);

            SELECT username,
                   user_id
            INTO _matchingUsername, _matchingUserID
            FROM t_users
            WHERE username = _nameSearchSpec;

            If FOUND Then
                _matchCount := 1;
                RETURN;
            End If;
        End If;
    End If;

    If Not _nameSearchSpec SIMILAR TO '%[%]' Then
        _nameSearchSpec := _nameSearchSpec || '%';
    End If;

    SELECT COUNT(user_id)
    INTO _matchCount
    FROM t_users
    WHERE name LIKE _nameSearchSpec;

    If _matchCount > 0 Then
        -- Update _matchingUsername and _matchingUserID
        SELECT username,
               user_id
        INTO _matchingUsername, _matchingUserID
        FROM t_users
        WHERE name LIKE _nameSearchSpec
        ORDER BY user_id
        LIMIT 1;

    End If;

    If _matchCount = 0 Then
        -- Check _nameSearchSpec against the Username column
        SELECT COUNT(user_id)
        INTO _matchCount
        FROM t_users
        WHERE username LIKE _nameSearchSpec;

        If _matchCount > 0 Then
            -- Update _matchingUsername and _matchingUserID
            SELECT username, user_id
            INTO _matchingUsername, _matchingUserID
            FROM t_users
            WHERE username LIKE _nameSearchSpec
            ORDER BY user_id
            LIMIT 1;
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.auto_resolve_name_to_username(IN _namesearchspec text, INOUT _matchcount integer, INOUT _matchingusername text, INOUT _matchinguserid integer) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_resolve_name_to_username(IN _namesearchspec text, INOUT _matchcount integer, INOUT _matchingusername text, INOUT _matchinguserid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_resolve_name_to_username(IN _namesearchspec text, INOUT _matchcount integer, INOUT _matchingusername text, INOUT _matchinguserid integer) IS 'AutoResolveNameToPRN or AutoResolveNameToUsername';

