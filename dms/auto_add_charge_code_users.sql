--
-- Name: auto_add_charge_code_users(boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_add_charge_code_users(IN _infoonly boolean DEFAULT false, IN _includeinactivechargecodes boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine the responsible user for active charge codes with one or more sample prep requests or requested runs
**      Auto-adds any users who are not in t_users
**
**      Uses external server SQLSRVPROD02, which is accessed via a foreign data wrapper
**
**  Arguments:
**    _infoOnly                     When true, preview updates
**    _includeInactiveChargeCodes   When true, add users for both active and inactive charge codes
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          06/10/2013 mem - Now storing payroll number in U_Payroll and Network_ID in Username
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/17/2022 mem - Tabs to spaces
**          05/19/2023 mem - Add missing Else
**          05/24/2023 mem - When previewing new users, show charge codes associated with each new user
**          12/13/2023 mem - Add argument _includeInactiveChargeCodes
**                         - Also look for new users that do not have a payroll number (column CC.resp_username)
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int := 0;
    _operationID int := 0;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly                   := Coalesce(_infoOnly, false);
    _includeInactiveChargeCodes := Coalesce(_includeInactiveChargeCodes, false);

    If _infoOnly Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Create temporary tables to track users to add
    --
    -- Column resp_username in t_charge_code is actually the payroll number (e.g. '3L243') and not username
    -- It is null for staff whose username starts with the first four letters of their last name, as has been the case since 2010
    --
    -- Table Tmp_NewUsers tracks charge codes where resp_username is not null
    -- Table Tmp_NewUsersByHID tracks charge codes where resp_username is null
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewUsers (
        Payroll text,
        HID citext,
        LastName_FirstName text,
        Network_ID text NULL,
        Charge_Code_First text NULL,
        Charge_Code_Last text NULL,
        DMS_ID int NULL
    );

    CREATE TEMP TABLE Tmp_NewUsersByHID (
        HID citext,
        LastName_FirstName text,
        Network_ID text NULL,
        Charge_Code_First text NULL,
        Charge_Code_Last text NULL,
        DMS_ID int NULL
    );

    BEGIN

        ---------------------------------------------------
        -- Look for new users that have a payroll number (column CC.resp_username)
        ---------------------------------------------------

        INSERT INTO Tmp_NewUsers (Payroll, HID, Charge_Code_First, Charge_Code_Last)
        SELECT CC.resp_username, MAX(CC.resp_hid), Min(CC.Charge_Code) AS Charge_Code_First, Max(CC.Charge_Code) AS Charge_Code_Last
        FROM t_charge_code CC
             LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map UMap
               ON CC.charge_code = UMap.charge_code
        WHERE NOT CC.resp_username IS NULL AND
              NOT CC.resp_hid IS NULL AND
              UMap.Username IS NULL AND
              (CC.charge_code_state > 0 OR _includeInactiveChargeCodes) AND
              (CC.usage_sample_prep > 0 OR
               CC.usage_requested_run > 0)
        GROUP BY CC.resp_username;

        UPDATE Tmp_NewUsers
        SET Network_ID = W."NETWORK_ID",
            LastName_FirstName = W."PREFERRED_NAME_FM"
        FROM pnnldata."VW_PUB_BMI_EMPLOYEE" W
        WHERE Tmp_NewUsers.HID = W."HANFORD_ID" AND
              Coalesce(W."NETWORK_ID", '') <> '';

        ---------------------------------------------------
        -- Look for new users that do not have a payroll number (column CC.resp_username)
        ---------------------------------------------------

        INSERT INTO Tmp_NewUsersByHID (HID, Charge_Code_First, Charge_Code_Last)
        SELECT CC.resp_hid, Min(CC.Charge_Code) AS Charge_Code_First, Max(CC.Charge_Code) AS Charge_Code_Last
        FROM t_charge_code CC
             LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map UMap
               ON CC.charge_code = UMap.charge_code
        WHERE CC.resp_username IS NULL AND
              NOT CC.resp_hid IS NULL AND
              UMap.Username IS NULL AND
              (CC.charge_code_state > 0 OR _includeInactiveChargeCodes) AND
              (CC.usage_sample_prep > 0 OR
               CC.usage_requested_run > 0)
        GROUP BY CC.resp_hid;

        UPDATE Tmp_NewUsersByHID
        SET Network_ID = W."NETWORK_ID",
            LastName_FirstName = W."PREFERRED_NAME_FM"
        FROM pnnldata."VW_PUB_BMI_EMPLOYEE" W
        WHERE Tmp_NewUsersByHID.HID = W."HANFORD_ID" AND
              Coalesce(W."NETWORK_ID", '') <> '';

        ---------------------------------------------------
        -- Append users to Tmp_NewUsers
        ---------------------------------------------------

        INSERT INTO Tmp_NewUsers (Payroll, HID, Charge_Code_First, Charge_Code_Last, Network_ID, LastName_FirstName)
        SELECT Null AS Payroll,
               Src.HID,
               Src.Charge_Code_First,
               Src.Charge_Code_Last,
               Src.Network_ID,
               Src.LastName_FirstName
        FROM Tmp_NewUsersByHID Src
             LEFT OUTER JOIN Tmp_NewUsers NewUsers
               ON Src.HID = NewUsers.HID
        WHERE Coalesce(Src.Network_ID, '') <> '' AND
              NewUsers.HID IS NULL;

        If Not _infoOnly Then
            If Exists (SELECT Network_ID FROM Tmp_NewUsers WHERE NOT Network_ID IS NULL) Then

                INSERT INTO t_users( username,       -- Network_ID (aka login) goes in the username field
                                     name,
                                     hid,
                                     payroll,        -- payroll number goes in the payroll field; this has been null for new users since 2010
                                     status,
                                     update,
                                     comment )
                SELECT Network_ID,
                       LastName_FirstName,
                       format('H%s', hid),
                       payroll,
                       'Active' AS status,
                       'Y' AS U_update,
                       '' AS U_comment
                FROM Tmp_NewUsers
                WHERE NOT Network_ID IS NULL
                ORDER BY Network_ID;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _message := format('Auto added %s %s to t_users since they are associated with charge codes used by DMS',
                                       _insertCount, public.check_plural(_insertCount, 'user', 'users'));

                    CALL post_log_entry ('Normal', _message, 'Auto_Add_Charge_Code_Users');
                End If;

                UPDATE Tmp_NewUsers
                SET DMS_ID = U.user_id
                FROM t_users U
                WHERE Tmp_NewUsers.Network_ID = U.username;

                ---------------------------------------------------
                -- Define the DMS_Guest operation for the newly added users
                ---------------------------------------------------

                SELECT operation_id
                INTO _operationID
                FROM t_user_operations
                WHERE operation ='DMS_Guest';

                If Coalesce(_operationID, 0) = 0 Then
                    _message := 'User operation DMS_Guest not found in t_user_operations';
                    CALL post_log_entry ('Error', _message, 'Auto_Add_Charge_Code_Users');
                Else
                    INSERT INTO t_user_operations_permissions (user_id, operation_id)
                    SELECT Tmp_NewUsers.DMS_ID, _operationID
                    FROM Tmp_NewUsers
                         INNER JOIN t_users U
                           ON Tmp_NewUsers.Network_ID = U.username;

                End If;

            End If;

            DROP TABLE Tmp_NewUsers;
            DROP TABLE Tmp_NewUsersByHID;
            RETURN;
        End If;

        If Not Exists (SELECT Network_ID FROM Tmp_NewUsers) Then
            _message := 'All active charge codes are associated with known users; nothing to add';

            RAISE INFO '';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_NewUsers;
            DROP TABLE Tmp_NewUsersByHID;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Preview the new users
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-30s %-10s %-17s %-17s %-60s';

        _infoHead := format(_formatSpecifier,
                            'Network_ID',
                            'HID',
                            'LastName_FirstName',
                            'Payroll',
                            'Charge_Code_First',
                            'Charge_Code_Last',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------',
                                     '------------------------------',
                                     '----------',
                                     '-----------------',
                                     '-----------------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Network_ID,
                   HID,
                   LastName_FirstName,
                   Payroll,
                   Charge_Code_First,
                   Charge_Code_Last,
                   CASE WHEN Network_ID IS NULL
                        THEN 'This person does not have a username and thus will not be added'
                        ELSE ''
                   END AS Comment
            FROM Tmp_NewUsers
            ORDER BY HID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Network_ID,
                                _previewData.HID,
                                _previewData.LastName_FirstName,
                                _previewData.Payroll,
                                _previewData.Charge_Code_First,
                                _previewData.Charge_Code_Last,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        SELECT COUNT(*)
        INTO _insertCount
        FROM Tmp_NewUsers
        WHERE NOT Network_ID IS NULL;

        _message := format('Would add %s new %s', _insertCount, public.check_plural(_insertCount, 'user', 'users'));

        RAISE INFO '';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_NewUsers;
        DROP TABLE Tmp_NewUsersByHID;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_NewUsers;
    DROP TABLE IF EXISTS Tmp_NewUsersByHID;
END
$$;


ALTER PROCEDURE public.auto_add_charge_code_users(IN _infoonly boolean, IN _includeinactivechargecodes boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_add_charge_code_users(IN _infoonly boolean, IN _includeinactivechargecodes boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_add_charge_code_users(IN _infoonly boolean, IN _includeinactivechargecodes boolean, INOUT _message text, INOUT _returncode text) IS 'AutoAddChargeCodeUsers';

