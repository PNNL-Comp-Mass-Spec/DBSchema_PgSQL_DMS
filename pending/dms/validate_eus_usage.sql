--
CREATE OR REPLACE PROCEDURE public.validate_eus_usage
(
    INOUT _eusUsageType text,
    INOUT _eusProposalID text,
    INOUT _eusUsersList text,
    INOUT _eusUsageTypeID int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _autoPopulateUserListIfBlank boolean = false,
    _samplePrepRequest boolean = false,
    _experimentID int = 0,
    _campaignID int = 0,
    _addingItem boolean = false,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Verifies that given usage type, proposal ID,
**      and user list are valid for DMS
**
**      Clears contents of _eusProposalID and _eusUsersList
**      for certain values of _eusUsageType
**
**  Arguments:
**    _eusUsageType                 EUS usage type
**    _eusProposalID                EUS proposal ID
**    _eusUsersList                 Comma separated list of EUS user IDs (integers); also supports the form 'Baker, Erin (41136)'; does not support 'Baker, Erin'
**    _eusUsageTypeID               EUS usage type ID (output)
**    _autoPopulateUserListIfBlank  When true, will auto-populate _eusUsersList if it is empty and _eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
**    _samplePrepRequest            When true, validating EUS fields for a sample prep request
**    _experimentID                 When non-zero, validate EUS Usage Type against the experiment's campaign
**    _campaignID                   When non-zero, validate EUS Usage Type against the campaign
**    _addingItem                   When _experimentID or _campaignID is non-zero, set this to true if creating a new prep request or new requested run
**    _infoOnly                     When true, show debug info
**
**  Auth:   grk
**  Date:   07/11/2007 grk - Initial Version
**          09/09/2010 mem - Added parameter _autoPopulateUserListIfBlank
**                         - Now auto-clearing _eusProposalID and _eusUsersList if _eusUsageType is not 'USER'
**          12/12/2011 mem - Now auto-fixing _eusUsageType if it is an abbreviated form of Cap_Dev, Maintenance, or Broken
**          11/20/2013 mem - Now automatically extracting the integers from _eusUsersList if it instead has user names and integers
**          08/11/2015 mem - Now trimming spaces from the parameters
**          10/01/2015 mem - When _eusUsageType is '(ignore)' we now auto-change it to 'CAP_DEV'
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          01/09/2016 mem - Added option for disabling EUS validation using table T_MiscOptions
**          01/20/2017 mem - Auto-fix USER_UNKOWN to USER_UNKNOWN for _eusUsageType
**          03/17/2017 mem - Only call Make_Table_From_List if _eusUsersList contains a semicolon
**          04/10/2017 mem - Auto-change USER_UNKNOWN to CAP_DEV
**          07/19/2019 mem - Custom error message if _eusUsageType is blank
**          11/06/2019 mem - Auto-change _eusProposalID if a value is defined for Proposal_ID_AutoSupersede
**          08/12/2020 mem - Add support for a series of superseded proposals
**          08/14/2020 mem - Add safety check in case of a circular references (proposal 1 superseded by proposal 2, which is superseded by proposal 1)
**          08/18/2020 mem - Add missing Else keyword
**          08/20/2020 mem - When a circular reference exists, choose the proposal with the highest numeric ID
**          05/25/2021 mem - Add parameter _samplePrepRequest
**          05/26/2021 mem - Capitalize _eusUsageType
**          05/27/2021 mem - Add parameters _experimentID, _campaignID, and _addingItem
**          09/29/2021 mem - Assure that EUS Usage Type is 'USER_ONSITE' if associated with a Resource Owner proposal
**          10/13/2021 mem - Use Like when extracting integers
**                         - Add additional debug messages
**                         - Use Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidCount int;
    _userCount int;
    _personID int;
    _newUserList text;
    _enabledForPrepRequests boolean := false;
    _eusUsageTypeName text;
    _originalProposalID text;
    _numericID int;
    _proposalType text;
    _usageTypeUpdated int := 0;
    _autoSupersedeProposalID text;
    _checkSuperseded int;
    _iterations int;
    _logMessage text;
    _validateEUSData int := 1;
    _stringLength int;
    _charNum int := 1;
    _integerList text := '';
    _currentChar char;
    _eusUsageTypeCampaign text;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    _autoPopulateUserListIfBlank := Coalesce(_autoPopulateUserListIfBlank, false);
    _samplePrepRequest := Coalesce(_samplePrepRequest, false);
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Remove leading and trailing spaces, and check for nulls
    ---------------------------------------------------

    _eusUsageType := Trim(Coalesce(_eusUsageType, ''));
    _eusProposalID := Trim(Coalesce(_eusProposalID, ''));
    _eusUsersList := Trim(Coalesce(_eusUsersList, ''));

    If _eusUsageType::citext = '(ignore)' AND Not Exists (SELECT * FROM t_eus_usage_type WHERE eus_usage_type = _eusUsageType::citext) Then
        _eusUsageType := 'CAP_DEV';
        _eusProposalID := '';
        _eusUsersList := '';
    End If;

    ---------------------------------------------------
    -- Auto-fix _eusUsageType if it is an abbreviated form of Cap_Dev, Maintenance, or Broken
    ---------------------------------------------------

    If _eusUsageType::citext Like 'Cap%' AND Not Exists (SELECT * FROM t_eus_usage_type WHERE eus_usage_type = _eusUsageType::citext) Then
        _eusUsageType := 'CAP_DEV';
    End If;

    If _eusUsageType::citext Like 'Maint%' AND Not Exists (SELECT * FROM t_eus_usage_type WHERE eus_usage_type = _eusUsageType::citext) Then
        _eusUsageType := 'MAINTENANCE';
    End If;

    If _eusUsageType::citext Like 'Brok%' AND Not Exists (SELECT * FROM t_eus_usage_type WHERE eus_usage_type = _eusUsageType::citext) Then
        _eusUsageType := 'BROKEN';
    End If;

    If _eusUsageType::citext Like 'USER_UNKOWN%' Then
        _eusUsageType := 'USER_UNKNOWN';
    End If;

    ---------------------------------------------------
    -- Auto-change USER_UNKNOWN to CAP_DEV
    -- Monthly EUS instrument usage validation will not allow USER_UNKNOWN but will allow CAP_DEV
    ---------------------------------------------------

    If _eusUsageType::citext = 'USER_UNKNOWN' Then
        _eusUsageType := 'CAP_DEV';
    End If;

    ---------------------------------------------------
    -- Confirm that EUS validation is enabled
    ---------------------------------------------------

    SELECT value
    INTO _validateEUSData
    FROM t_misc_options
    WHERE name = 'ValidateEUSData';

    If Not FOUND Then
        _validateEUSData := 1;
    End If;

    If Coalesce(_validateEUSData, 0) = 0 Then
        -- Validation is disabled
        _eusUsageTypeID := 10;
        _eusProposalID := null;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve EUS usage type name to ID
    ---------------------------------------------------

    If _eusUsageType = '' Then
        _message := 'EUS usage type cannot be blank';
        _returnCode := 'U5370';
        RETURN;
    End If;

    SELECT eus_usage_type_id,
           eus_usage_type,
           public.try_cast(enabled_prep_request::text, false)
    INTO _eusUsageTypeID, _eusUsageTypeName, _enabledForPrepRequests
    FROM t_eus_usage_type
    WHERE eus_usage_type = _eusUsageType::citext;

    If Not FOUND Then
        _message := format('Could not resolve EUS usage type: "%s"', _eusUsageType);
        _returnCode := 'U5371';
        RETURN;
    End If;

    If _samplePrepRequest And Not _enabledForPrepRequests Then
        If _eusUsageType::citext = 'USER' Then
            _message := 'Please choose usage type USER_ONSITE if processing a sample from an onsite user or a sample for a Resource Owner project; '
                        'choose USER_REMOTE if processing a sample for an EMSL user';
        Else
            _message := format('EUS usage type "%s" is not allowed for Sample Prep Requests', _eusUsageType);
        End If;

        _returnCode := 'U5372';
        RETURN;
    End If;

    _eusUsageType := _eusUsageTypeName;

    ---------------------------------------------------
    -- Validate EUS proposal and user
    -- if EUS usage type requires them
    ---------------------------------------------------

    If Not _eusUsageType::citext In ('USER', 'USER_ONSITE', 'USER_REMOTE') Then
        -- Make sure no proposal ID or users are specified
        If Coalesce(_eusProposalID, '') <> '' OR _eusUsersList <> '' Then
            _message := format('Warning: Cleared proposal ID and/or users since usage type is "%s"', _eusUsageType);
        End If;

        _eusProposalID := NULL;
        _eusUsersList := '';
    End If;

    If _eusUsageType::citext In ('USER', 'USER_ONSITE', 'USER_REMOTE') Then
    -- <a1>

        ---------------------------------------------------
        -- Proposal and user list cannot be blank when the usage type is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
        ---------------------------------------------------

        If Coalesce(_eusProposalID, '') = '' Then
            _message := format('A Proposal ID must be selected for usage type "%s"', _eusUsageType);
            _returnCode := 'U5373';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Verify EUS proposal ID, get the Numeric_ID value, get the proposal type
        ---------------------------------------------------

        SELECT proposal_type
        INTO _proposalType
        FROM t_eus_proposals
        WHERE proposal_id = _eusProposalID

        If Not FOUND Then
            _message := format('Unknown EUS proposal ID: "%s"', _eusProposalID);
            _returnCode := 'U5374';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Check for a superseded proposal
        ---------------------------------------------------

        -- Create a table to track superseded proposals in the case of a circular reference
        -- E.g. two proposals with the same name, but different IDs (and likely different start or end dates)
        CREATE TEMP TABLE Tmp_Proposal_Stack (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Proposal_ID text,
            Numeric_ID int Not Null
        )

        _originalProposalID := _eusProposalID;
        _checkSuperseded := 1;
        _iterations := 0;

        WHILE _checkSuperseded = 1 AND _iterations < 30
        LOOP
            _autoSupersedeProposalID := '';
            _iterations := _iterations + 1;

            SELECT proposal_id_auto_supersede
            INTO _autoSupersedeProposalID
            FROM t_eus_proposals
            WHERE proposal_id = _eusProposalID;

            If Coalesce(_autoSupersedeProposalID, '') = '' Then
                _checkSuperseded := 0;
            Else
            -- <c>
                If _eusProposalID = _autoSupersedeProposalID Then
                    _logMessage := format('Proposal %s in t_eus_proposals has proposal_id_auto_supersede set to itself; this is invalid',
                                          Coalesce(_eusProposalID, '??'));

                    If Not _infoOnly Then
                        CALL post_log_entry ('Error', _logMessage, 'Validate_EUS_Usage', _duplicateEntryHoldoffHours => 1);
                    Else
                        RAISE INFO '%', _logMessage;
                    End If;

                    _checkSuperseded := 0;
                Else
                -- <d>
                    If Not Exists (SELECT * FROM t_eus_proposals WHERE proposal_id = _autoSupersedeProposalID) Then
                        _logMessage := format('Proposal %s in t_eus_proposals has proposal_id_auto_supersede set to %s, but that proposal does not exist in t_eus_proposals',
                                              Coalesce(_eusProposalID, '??'), Coalesce(_autoSupersedeProposalID, '??'));

                        If Not _infoOnly Then
                            CALL post_log_entry ('Error', _logMessage, 'Validate_EUS_Usage', _duplicateEntryHoldoffHours => 1);
                        Else
                            RAISE INFO '%', _logMessage;
                        End If;

                        _checkSuperseded := 0;
                    Else
                        If Not Exists (SELECT * FROM Tmp_Proposal_Stack) Then
                            INSERT INTO Tmp_Proposal_Stack (Proposal_ID, Numeric_ID)
                            Values (_eusProposalID, Coalesce(_numericID, 0))
                        End If;

                        SELECT numeric_id
                        INTO _numericID
                        FROM t_eus_proposals
                        WHERE proposal_id = _autoSupersedeProposalID

                        If Exists (SELECT * FROM Tmp_Proposal_Stack WHERE Proposal_ID = _autoSupersedeProposalID) Then
                            -- Circular reference
                            If _infoOnly Then
                                RAISE INFO 'Circular reference found; choosing the one with the highest ID';
                            End If;

                            SELECT Proposal_ID
                            INTO _eusProposalID
                            FROM Tmp_Proposal_Stack
                            ORDER BY Numeric_ID Desc, Proposal_ID Desc
                            LIMIT 1;

                            If _originalProposalID = _eusProposalID Then
                                _message := '';
                            Else
                                _message := format('Proposal %s is superseded by %s', _originalProposalID, _eusProposalID);
                            End If;

                            _checkSuperseded := 0;
                        Else
                            INSERT INTO Tmp_Proposal_Stack (Proposal_ID, Numeric_ID)
                            VALUES (_autoSupersedeProposalID, Coalesce(_numericID, 0));

                            _message := public.append_to_text(
                                                _message,
                                                format('Proposal %s is superseded by %s', _eusProposalID, _autoSupersedeProposalID),
                                                0, '; ', 1024)

                            _eusProposalID := _autoSupersedeProposalID;
                        End If;
                    End If;
                End If; -- </d>
            End If; -- </c>
        END LOOP; -- </b>

        If _infoOnly AND EXISTS (SELECT * from Tmp_Proposal_Stack) Then

            -- ToDo: Update this to use RAISE INFO

            SELECT *
            FROM Tmp_Proposal_Stack
            ORDER BY Entry_ID
        End If;

        If _eusProposalID <> _originalProposalID Then
            SELECT proposal_type
            INTO _proposalType
            FROM t_eus_proposals
            WHERE proposal_id = _eusProposalID
        End If;
        ---------------------------------------------------
        -- Check for a blank user list
        ---------------------------------------------------

        If _eusUsersList = '' Then
            -- Blank user list
            --
            If Not _autoPopulateUserListIfBlank Then
                _message := format('Associated users must be selected for usage type "%s"', _eusUsageType);
                _returnCode := 'U5375';
                RETURN;
            End If;

            -- Auto-populate _eusUsersList with the first user associated with the given user proposal
            --
            _personID := 0;

            SELECT MIN(EUSU.person_id)
            INTO _personID
            FROM t_eus_proposals EUSP
                INNER JOIN t_eus_proposal_users EUSU
                ON EUSP.proposal_id = EUSU.proposal_id
            WHERE EUSP.proposal_id = _eusProposalID;

            If Coalesce(_personID, 0) > 0 Then
                _eusUsersList := _personID;
                _message := public.append_to_text(;
                                    _message,
                                    format('Warning: EUS User list was empty; auto-selected user "%s"', _eusUsersList),
                                    0, '; ', 1024)
            End If;
        End If;

        ---------------------------------------------------
        -- Verify that all users in list have access to
        -- given proposal
        ---------------------------------------------------

        If _eusUsersList <> '' Then
        -- <e>

            If _eusUsersList Similar To '%[A-Z]%' And _eusUsersList Similar To '%([0-9]%' And _eusUsersList Similar To '%[0-9])%' Then
                If _infoOnly Then
                    RAISE INFO 'Parsing %', _eusUsersList;
                End If;

                -- _eusUsersList has entries of the form 'Baker, Erin (41136)'
                -- Parse _eusUsersList to only keep the integers and commas
                --

                _stringLength := char_length(_eusUsersList);

                WHILE _charNum <= _stringLength
                LOOP
                    _currentChar := Substring(_eusUsersList, _charNum, 1);

                    If _currentChar = ',' Or _currentChar Similar To '[0-9]' Then
                        _integerList := format('%s%s', _integerList, _currentChar);
                    End If;

                    _charNum := _charNum + 1;
                END LOOP;

                _eusUsersList := _integerList;
            End If;

            If _eusUsersList Like ',%' Then
                -- Trim the leading comma
                _eusUsersList := Substring(_eusUsersList, 2, char_length(_eusUsersList));
            End If;

            If _eusUsersList Like '%,' Then
                -- Trim the trailing comma
                _eusUsersList := Substring(_eusUsersList, 1, char_length(_eusUsersList) - 1);
            End If;

            CREATE TEMP TABLE Tmp_Users
            (
                Item text
            );

            If _infoOnly Then
                RAISE INFO 'Splitting: %', _eusUsersList;
            End If;

            -- Split items in _eusUsersList on commas
            --
            If _eusUsersList Like '%,%' Then
                INSERT INTO Tmp_Users (Item)
                SELECT Item
                FROM public.parse_delimited_list(_eusUsersList)

                If _infoOnly Then
                    RAISE INFO 'User IDs: %', _eusUsersList;
                End If;
            Else
                INSERT INTO Tmp_Users (Item)
                VALUES (_eusUsersList)

                If _infoOnly Then
                    RAISE INFO 'User ID: %', _eusUsersList;
                End If;
            End If;

            -- Look for entries that are not integers
            --
            SELECT COUNT(*)
            INTO _invalidCount
            FROM Tmp_Users
            WHERE public.try_cast(item, null::int) IS NULL;

            If _invalidCount > 0 Then

                If _invalidCount = 1 Then
                    _message := 'EMSL User ID is not numeric';
                Else
                    _message := format('%s EMSL User IDs are not numeric', _invalidCount);
                End If;

                _returnCode := 'U5376';
                RETURN;
            End If;

            -- Look for entries that are not in t_eus_proposal_users
            --
            SELECT COUNT(*)
            INTO _invalidCount
            FROM Tmp_Users
            WHERE
                public.try_cast(item, 0) NOT IN
                (
                    SELECT person_id
                    FROM  t_eus_proposal_users
                    WHERE proposal_id = _eusProposalID
                );

            If _invalidCount > 0 Then
            -- <f>

                -- Invalid users were found
                --
                If Not _autoPopulateUserListIfBlank Then

                    If _invalidCount = 1 Then
                        _message := format('%s user is not associated with the specified proposal', _invalidCount);
                    Else
                        _message := format('%s users are not associated with the specified proposal', _invalidCount);
                    End If;

                    _returnCode := 'U5377';
                    RETURN;
                End If;

                -- Auto-remove invalid entries from Tmp_Users
                --
                DELETE
                FROM  Tmp_Users
                WHERE
                    CAST(Item As int) NOT IN
                    (
                        SELECT person_id
                        FROM  t_eus_proposal_users
                        WHERE proposal_id = _eusProposalID
                    )

                SELECT COUNT(*)
                INTO _userCount
                FROM Tmp_Users

                _newUserList := '';

                If _userCount >= 1 Then
                    -- Reconstruct the users list
                    --
                    SELECT string_agg(Item, ', ' ORDER BY Item)
                    INTO _newUserList
                    FROM Tmp_Users;

                End If;

                If Coalesce(_newUserList, '') = '' Then
                    -- Auto-populate _eusUsersList with the first user associated with the given user proposal
                    _personID := 0;

                    SELECT MIN(EUSU.person_id)
                    INTO _personID
                    FROM t_eus_proposals EUSP
                        INNER JOIN t_eus_proposal_users EUSU
                        ON EUSP.proposal_id = EUSU.proposal_id
                    WHERE EUSP.proposal_id = _eusProposalID;

                    If Coalesce(_personID, 0) > 0 Then
                        _newUserList := _personID;
                    End If;
                End If;

                _eusUsersList := Coalesce(_newUserList, '');
                _message := public.append_to_text(;
                                    _message,
                                    format('Warning: Removed users from EUS User list that are not associated with proposal "%s"', _eusProposalID),
                                    0, '; ', 1024)

            End If; -- </f>
        End If; -- </e>
    End If; -- </a1>

    If _campaignID > 0 OR _experimentID > 0 Then
    -- <a2>

        If _campaignID > 0 Then
            SELECT EUT.eus_usage_type
            INTO _eusUsageTypeCampaign
            FROM t_campaign C
                 INNER JOIN t_eus_usage_type EUT
                   ON C.eus_usage_type_id = EUT.eus_usage_type_id
            WHERE C.campaign_id = _campaignID
        Else
            SELECT EUT.eus_usage_type
            INTO _eusUsageTypeCampaign
            FROM t_experiments E
                 INNER JOIN t_campaign C
                   ON E.campaign_id = C.campaign_id
                 INNER JOIN t_eus_usage_type EUT
                   ON C.eus_usage_type_id = EUT.eus_usage_type_id
            WHERE E.exp_id = _experimentID
        End If;

        If _eusUsageTypeCampaign::citext = 'USER_REMOTE' And _eusUsageType::citext In ('USER_ONSITE', 'USER') And _proposalType::citext <> 'Resource Owner' Then
            If _addingItem Then
                _eusUsageType := 'USER_REMOTE';
                _msg := 'Auto-updated EUS Usage Type to USER_REMOTE since the campaign has USER_REMOTE';
                _usageTypeUpdated := 1;
            Else
                _msg := 'Warning: campaign has EUS Usage Type USER_REMOTE; the new item should likely also be of type USER_REMOTE';
            End If;

            _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
        End If;

        If _eusUsageTypeCampaign::citext = 'USER_ONSITE' And _eusUsageType::citext = 'USER' And _proposalType::citext <> 'Resource Owner' Then
            _eusUsageType := 'USER_ONSITE';
            _msg := 'Auto-updated EUS Usage Type to USER_ONSITE since the campaign has USER_ONSITE';
            _usageTypeUpdated := 1;
        End If;
    End If;

    If _proposalType::citext = 'Resource Owner' And _eusUsageType::citext In ('USER_REMOTE', 'USER') Then
        -- Requested runs for Resource Owner projects should always have EUS Usage Type 'USER_ONSITE'
        _eusUsageType := 'USER_ONSITE';
        _msg := 'Auto-updated EUS Usage Type to USER_ONSITE since associated with a Resource Owner project';
        _usageTypeUpdated := 1;
    End If;

    If _usageTypeUpdated > 0 Then
        _message := public.append_to_text(_message, _msg, 0, '; ', 1024);

        SELECT eus_usage_type_id
        INTO _eusUsageTypeID
        FROM t_eus_usage_type
        WHERE eus_usage_type = _eusUsageType::citext;

        If Not FOUND Then
            _msg := format('%s; Could not find usage type "%s" in t_eus_usage_type; this is unexpected', _msg, _eusUsageType);

            CALL post_log_entry ('Error', _msg, 'Validate_EUS_Usage');

            -- Only append _msg to _message if an error occurs
            _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
        End If;
    End If;

    DROP TABLE Tmp_Proposal_Stack;
END
$$;

COMMENT ON PROCEDURE public.validate_eus_usage IS 'ValidateEUSUsage';
