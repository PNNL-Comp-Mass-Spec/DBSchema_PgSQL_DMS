--
-- Name: validate_request_users(text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_request_users(INOUT _requestedpersonnel text, INOUT _assignedpersonnel text, IN _requirevalidrequestedpersonnel boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validate the requested personnel and assigned personnel for a Data Analysis Request or Sample Prep Request
**
**  Arguments:
**    _requestedPersonnel               Input/output: semicolon-separated list of requested personnel, in the form 'LastName, FirstName (Username)'
**    _assignedPersonnel                Input/output: semicolon-separated list of assigned personnel, in the form 'LastName, FirstName (Username)'
**    _requireValidRequestedPersonnel   When true, require that the personnel are known DMS users
**    _message                          Status message
**    _returnCode                       Return code
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version (refactored code from AddUpdateSamplePrepRequest)
**          01/05/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _nameValidationIteration int;
    _userFieldName text := '';
    _cleanNameList text;
    _entryID int := 0;
    _unknownUser text;
    _matchCount int;
    _newUsername text;
    _newUserID int;
    _invalidUsers text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _requestedPersonnel             := Trim(Coalesce(_requestedPersonnel, ''));
    _assignedPersonnel              := Trim(Coalesce(_assignedPersonnel, ''));
    _requireValidRequestedPersonnel := Coalesce(_requireValidRequestedPersonnel, true);

    ---------------------------------------------------
    -- Validate requested and assigned personnel
    -- Names should be in the form 'Last Name, First Name (Username)'
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UserInfo (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Name_and_Username citext NOT NULL,
        User_ID int NULL
    );

    FOR _nameValidationIteration IN 1 .. 2
    LOOP

        DELETE FROM Tmp_UserInfo;

        If _nameValidationIteration = 1 Then
            INSERT INTO Tmp_UserInfo ( Name_and_Username )
            SELECT Value
            FROM public.parse_delimited_list(_requestedPersonnel, ';');

            _userFieldName := 'requested personnel';
        Else
            INSERT INTO Tmp_UserInfo ( Name_and_Username )
            SELECT Value
            FROM public.parse_delimited_list(_assignedPersonnel, ';');

            _userFieldName := 'assigned personnel';
        End If;

        UPDATE Tmp_UserInfo
        SET User_ID = U.user_id
        FROM t_users U
        WHERE Tmp_UserInfo.Name_and_Username = U.name_with_username;

        -- Use User_ID of 0 if the name is 'na'

        UPDATE Tmp_UserInfo
        SET User_ID = 0
        WHERE Name_and_Username IN ('na');

        ---------------------------------------------------
        -- Look for entries in Tmp_UserInfo where Name_and_Username did not resolve to a user_id
        -- Try-to auto-resolve using the name and username columns in t_users
        ---------------------------------------------------

        FOR _entryID, _unknownUser IN
            SELECT EntryID, Name_and_Username
            FROM Tmp_UserInfo
            WHERE User_ID IS NULL
            ORDER BY EntryID
        LOOP

            CALL public.auto_resolve_name_to_username (
                            _unknownUser,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _newUserID);   -- Output

            If _matchCount = 1 Then
                -- Single match was found; update User_ID in Tmp_UserInfo
                UPDATE Tmp_UserInfo
                SET User_ID = _newUserID
                WHERE EntryID = _entryID;
            End If;

        END LOOP;

        If Exists (SELECT EntryID FROM Tmp_UserInfo WHERE User_ID Is Null) Then

            SELECT string_agg(Name_and_Username, ', ' ORDER BY Name_and_Username)
            INTO _invalidUsers
            FROM Tmp_UserInfo
            WHERE User_ID IS NULL;

            _message := format('Invalid %s username(s): %s', _userFieldName, _invalidUsers);
            _returnCode := 'U5201';

            DROP TABLE Tmp_UserInfo;
            RETURN;
        End If;

        If _nameValidationIteration = 1 And _requireValidRequestedPersonnel And Not Exists (SELECT User_ID FROM Tmp_UserInfo WHERE User_ID > 0) Then
            -- Requested personnel person must be a specific person (or list of people)
            _message := format('The Requested Personnel person must be a specific DMS user; "%s" is invalid', _requestedPersonnel);
            _returnCode := 'U5202';

            DROP TABLE Tmp_UserInfo;
            RETURN;
        End If;

        If _nameValidationIteration = 2 And
           Exists (SELECT User_ID FROM Tmp_UserInfo WHERE User_ID > 0) AND
           Exists (SELECT User_ID FROM Tmp_UserInfo WHERE Name_and_Username = 'na') THEN

            -- Auto-remove the 'na' user since an actual person is defined
            DELETE FROM Tmp_UserInfo
            WHERE Name_and_Username = 'na';

        End If;

        -- Make sure names are capitalized properly

        UPDATE Tmp_UserInfo
        SET Name_and_Username = U.name_with_username
        FROM t_users U
        WHERE Tmp_UserInfo.User_ID = U.user_id AND
              Tmp_UserInfo.User_ID <> 0;

        -- Regenerate the list of names

        SELECT string_agg(Name_and_Username, '; ' ORDER BY EntryID)
        INTO _cleanNameList
        FROM Tmp_UserInfo;

        If _nameValidationIteration = 1 Then
            _requestedPersonnel := _cleanNameList;
        Else
            _assignedPersonnel := _cleanNameList;
        End If;

    END LOOP;

    DROP TABLE Tmp_UserInfo;
END
$$;


ALTER PROCEDURE public.validate_request_users(INOUT _requestedpersonnel text, INOUT _assignedpersonnel text, IN _requirevalidrequestedpersonnel boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_request_users(INOUT _requestedpersonnel text, INOUT _assignedpersonnel text, IN _requirevalidrequestedpersonnel boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_request_users(INOUT _requestedpersonnel text, INOUT _assignedpersonnel text, IN _requirevalidrequestedpersonnel boolean, INOUT _message text, INOUT _returncode text) IS 'ValidateRequestUsers';

