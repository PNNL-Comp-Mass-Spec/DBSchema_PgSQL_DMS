--
-- Name: assign_eus_users_to_requested_run(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.assign_eus_users_to_requested_run(IN _requestid integer, IN _eususerslist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Associate the given list of EUS users with the given requested run
**
**      The calling procedure should call validate_eus_usage before calling this procedure
**
**      Prior to February 2020, requested runs could have multiple EUS user IDs,
**      but add_update_requested_run and add_requested_run_fractions now prevent that
**
**  Arguments:
**    _requestID        Requested run ID
**    _eusUsersList     Comma-separated list of EUS user IDs (integers)
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   02/21/2006
**          11/09/2006 grk - Added numeric test for eus user ID (Ticket #318)
**          07/11/2007 grk - Factored out EUS proposal validation (Ticket #499)
**          11/16/2016 mem - Use Parse_Delimited_Integer_List to parse _eusUsersList
**          03/24/2017 mem - Validate user IDs in _eusUsersList
**          10/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _unknownUserCount int;
    _unknownUsers text;
    _userText text;
    _logType text;
    _validateEUSData boolean;
BEGIN
    _message := '';
    _returnCode := '';

    _eusUsersList  := Trim(Coalesce(_eusUsersList, ''));

    ---------------------------------------------------
    -- Clear all associations if the user list is blank
    ---------------------------------------------------

    If _eusUsersList = '' Then
        DELETE FROM t_requested_run_eus_users
        WHERE request_id = _requestID;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate a temporary table with the user IDs in _eusUsersList
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UserIDs (
        ID int
    );

    INSERT INTO Tmp_UserIDs (ID)
    SELECT DISTINCT Value
    FROM public.parse_delimited_integer_list(_eusUsersList);

    ---------------------------------------------------
    -- Look for unknown EUS users
    -- Upstream validation should have already identified these and prevented this procedure from getting called
    -- Post a log entry if unknown users are found
    ---------------------------------------------------

    SELECT string_agg(ID::text, ',' ORDER BY ID)
    INTO _unknownUsers
    FROM Tmp_UserIDs NewUsers LEFT OUTER JOIN
         t_eus_users U
           ON NewUsers.ID = U.person_id
    WHERE U.person_id IS Null;

    If Coalesce(_unknownUsers, '') <> '' Then

        _unknownUserCount := array_length(string_to_array(_unknownUsers, ','), 1);
        _userText := public.check_plural(_unknownUserCount, 'user', 'users');

        _message := format('Trying to associate %s unknown EUS %s with requested run %s; ignoring unknown %s %s',
                            _unknownUserCount,
                            _userText,
                            _requestID,
                            _userText,
                            _unknownUsers);

        SELECT CASE WHEN value <> 0 THEN true ELSE false END
        INTO _validateEUSData
        FROM t_misc_options
        WHERE name = 'ValidateEUSData';

        If Not FOUND Then
            _validateEUSData := true;
        End If;

        If _validateEUSData Then
            _logType := 'Error';
        Else
            -- EUS validation is disabled; log this as a warning
            _logType := 'Warning';
        End If;

        CALL post_log_entry (_logType, _message, 'Assign_EUS_Users_To_Requested_Run');

        _message := '';

    End If;

    ---------------------------------------------------
    -- Add associations between requested run and users who are in list, but not in association table
    -- Skip unknown EUS users
    ---------------------------------------------------

    INSERT INTO t_requested_run_eus_users (eus_person_id, request_id)
    SELECT NewUsers.ID AS EUS_Person_ID,
           _requestID AS Request_ID
    FROM Tmp_UserIDs NewUsers
         INNER JOIN t_eus_users U
           ON NewUsers.ID = U.person_id
    WHERE NOT NewUsers.ID IN (SELECT eus_person_id
                              FROM t_requested_run_eus_users
                              WHERE request_id = _requestID);

    ---------------------------------------------------
    -- Remove associations between requested run and users
    -- who are in association table but not in list
    ---------------------------------------------------

    DELETE FROM t_requested_run_eus_users
    WHERE request_id = _requestID AND
          NOT eus_person_id IN (SELECT ID
                                FROM Tmp_UserIDs);

    DROP TABLE Tmp_UserIDs;
END
$$;


ALTER PROCEDURE public.assign_eus_users_to_requested_run(IN _requestid integer, IN _eususerslist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE assign_eus_users_to_requested_run(IN _requestid integer, IN _eususerslist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.assign_eus_users_to_requested_run(IN _requestid integer, IN _eususerslist text, INOUT _message text, INOUT _returncode text) IS 'AssignEUSUsersToRequestedRun';

