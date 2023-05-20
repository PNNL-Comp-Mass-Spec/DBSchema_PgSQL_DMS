--
CREATE OR REPLACE PROCEDURE public.validate_request_users
(
    _requestName text,
    _callingProcedure text,
    INOUT _requestedPersonnel text,
    INOUT _assignedPersonnel text,
    _requireValidRequestedPersonnel boolean = true,
    _message text Output
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates the requested personnel and assigned personnel
**      for a Data Analysis Request or Sample Prep Request
**
**  Arguments:
**    _callingProcedure     AddUpdateDataAnalysisRequest or add_update_sample_prep_request
**    _requestedPersonnel   Input/output parameter
**    _assignedPersonnel    Input/output parameter
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version (refactored code from AddUpdateSamplePrepRequest)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _nameValidationIteration int := 1;
    _userFieldName text := '';
    _cleanNameList text;
    _entryID int := 0;
    _unknownUser text;
    _matchCount int;
    _newUsername text;
    _newUserID int;
    _firstInvalidUser text := '';
BEGIN

    _requestName := Coalesce(_requestName, '(unnamed request)');
    _callingProcedure := Coalesce(_callingProcedure, '(unknown caller)');
    _requestedPersonnel := Coalesce(_requestedPersonnel, '');
    _assignedPersonnel := Coalesce(_assignedPersonnel, '');
    _requireValidRequestedPersonnel := Coalesce(_requireValidRequestedPersonnel, true);

    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Validate requested and assigned personnel
    -- Names should be in the form 'Last Name, First Name (Username)'
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UserInfo (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Name_and_Username citext NOT NULL,
        User_ID int NULL
    )

    WHILE _nameValidationIteration <= 2
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
        SET User_ID = U.ID
        FROM t_users U
        WHERE Tmp_UserInfo.Name_and_Username = U.name_with_username;

        -- Use User_ID of 0 if the name is 'na'
        -- Set User_ID to 0
        UPDATE Tmp_UserInfo
        SET User_ID = 0
        WHERE Name_and_Username IN ('na');

        ---------------------------------------------------
        -- Look for entries in Tmp_UserInfo where Name_and_Username did not resolve to a user_id
        -- Try-to auto-resolve using the name and username columns in t_users
        ---------------------------------------------------

        FOR _unknownUser IN
            SELECT Name_and_Username
            FROM Tmp_UserInfo
            WHERE USER_ID IS NULL
            ORDER BY EntryID
        LOOP
            _matchCount := 0;

            Call auto_resolve_name_to_username (_unknownUser, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

            If _matchCount = 1 Then
                -- Single match was found; update User_ID in Tmp_UserInfo
                UPDATE Tmp_UserInfo
                SET User_ID = _newUserID
                WHERE EntryID = _entryID

            End If;

        END LOOP;

        If Exists (SELECT * FROM Tmp_UserInfo WHERE User_ID Is Null) Then

            SELECT Name_and_Username
            INTO _firstInvalidUser
            FROM Tmp_UserInfo
            WHERE USER_ID IS NULL
            LIMIT 1;

            _message := 'Invalid username for ' || _userFieldName || ': "' || _firstInvalidUser || '"';
            _returnCode := 'U5201';
            RETURN;
        End If;

        If _nameValidationIteration = 1 And _requireValidRequestedPersonnel And Not Exists (SELECT * FROM Tmp_UserInfo WHERE User_ID > 0) Then
            -- Requested personnel person must be a specific person (or list of people)
            _message := 'The Requested Personnel person must be a specific DMS user; "' || _requestedPersonnel || '" is invalid';
            _returnCode := 'U5202';
            RETURN;
        End If;

        If _nameValidationIteration = 2 And
           Exists (SELECT * FROM Tmp_UserInfo WHERE User_ID > 0) AND
           Exists (SELECT * FROM Tmp_UserInfo WHERE Name_and_Username = 'na') THEN

            -- Auto-remove the 'na' user since an actual person is defined
            DELETE FROM Tmp_UserInfo
            WHERE Name_and_Username = 'na';

        End If;

        -- Make sure names are capitalized properly
        --
        UPDATE Tmp_UserInfo
        SET Name_and_Username = U.name_with_username
        FROM t_users U
        WHERE Tmp_UserInfo.user_id = U.user_id AND
              Tmp_UserInfo.user_id <> 0;

        -- Regenerate the list of names
        --
        SELECT string_agg(Name_and_Username, '; ' ORDER BY EntryID)
        INTO _cleanNameList
        FROM Tmp_UserInfo;

        If _nameValidationIteration = 1 Then
            _requestedPersonnel := _cleanNameList;
        Else
            _assignedPersonnel := _cleanNameList;
        End If;

        _nameValidationIteration := _nameValidationIteration + 1;

    END LOOP; -- </a>

    DROP TABLE Tmp_UserInfo;
END
$$;

COMMENT ON PROCEDURE public.validate_request_users IS 'ValidateRequestUsers';
