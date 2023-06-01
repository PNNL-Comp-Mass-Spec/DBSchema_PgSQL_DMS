--
CREATE OR REPLACE PROCEDURE public.assign_eus_users_to_requested_run
(
    _request int,
    _eusProposalID text = '',
    _eusUsersList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Associates the given list of EUS users with given requested run
**
**      The calling procedure should call validate_eus_usage before calling this procedure
**
**  Arguments:
**    _eusProposalID   Only used for logging
**    _eusUsersList    Comma separated list of EUS user IDs (integers)
**
**  Auth:   grk
**  Date:   02/21/2006
**          11/09/2006 grk - Added numeric test for eus user ID (Ticket #318)
**          07/11/2007 grk - Factored out EUS proposal validation (Ticket #499)
**          11/16/2016 mem - Use Parse_Delimited_Integer_List to parse _eusUsersList
**          03/24/2017 mem - Validate user IDs in _eusUsersList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _unknownUserCount int;
    _unknownUsers text;
    _logType text := 'Error';
    _validateEUSData int := 1;
BEGIN
    _message := '';
    _returnCode := '';

    _eusProposalID := Coalesce(_eusProposalID, '');
    _eusUsersList := Coalesce(_eusUsersList, '');

    ---------------------------------------------------
    -- Clear all associations if the user list is blank
    ---------------------------------------------------

    If _eusUsersList = '' Then
        DELETE FROM t_requested_run_eus_users
        WHERE request_id = _request;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate a temporary table with the user IDs in _eusUsersList
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_UserIDs (
        ID int
    );

    INSERT INTO Tmp_UserIDs (ID)
    SELECT DISTINCT Value
    FROM public.parse_delimited_integer_list(_eusUsersList, ',');

    ---------------------------------------------------
    -- Look for unknown EUS users
    -- Upstream validation should have already identified these and prevented this procedure from getting called
    -- Post a log entry if unknown users are found
    ---------------------------------------------------

    SELECT string_agg(ID:int, ',')
    INTO _unknownUsers
    FROM Tmp_UserIDs NewUsers LEFT OUTER JOIN t_eus_users U ON NewUsers.ID = U.person_id
    WHERE U.person_id IS Null;

    If Coalesce(_unknownUsers, '') <> '' Then

        _unknownUserCount := array_length(string_to_array(_unknownUsers, ','), 1);

        _message := format('Trying to associate %s unknown EUS %s with request %s; ignoring unknown %s %s',
                            _unknownUserCount, _userText, _request,
                            public.check_plural(_unknownUserCount, 'user', 'users'),
                            _unknownUsers);

        SELECT value
        INTO _validateEUSData
        FROM t_misc_options
        WHERE name = 'ValidateEUSData';

        If Not FOUND Then
            _validateEUSData := 1;
        End If;

        If Coalesce(_validateEUSData, 0) = 0 Then
            -- EUS validation is disabled; log this as a warning
            _logType := 'Warning';
        End If;

        CALL post_log_entry (_logType, _msg, 'Assign_EUS_Users_To_Requested_Run');

        _message := '';

    End If;

    ---------------------------------------------------
    -- Add associations between request and users who are in list, but not in association table
    -- Skip unknown EUS users
    ---------------------------------------------------
    --
    INSERT INTO t_requested_run_eus_users( eus_person_id,
                                           request_id )
    SELECT NewUsers.ID AS EUS_Person_ID,
           _request AS Request_ID
    FROM Tmp_UserIDs NewUsers
         INNER JOIN t_eus_users U
           ON NewUsers.ID = U.person_id
    WHERE NewUsers.ID NOT IN ( SELECT eus_person_id
                               FROM t_requested_run_eus_users
                               WHERE request_id = _request );

    ---------------------------------------------------
    -- Remove associations between request and users
    -- who are in association table but not in list
    ---------------------------------------------------
    --
    DELETE FROM t_requested_run_eus_users
    WHERE request_id = _request AND
          eus_person_id NOT IN ( SELECT ID
                                 FROM Tmp_UserIDs );

END
$$;

COMMENT ON PROCEDURE public.assign_eus_users_to_requested_run IS 'AssignEUSUsersToRequestedRun';
