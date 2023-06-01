--
CREATE OR REPLACE PROCEDURE public.auto_add_charge_code_users
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines the responsible user for active Charge_Codes with one or more sample prep requests or requested runs
**      Auto-adds any users who are not in T_User
**
**      Uses external server SQLSRVPROD02, which is accessed via a foreign data wrapper
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          06/10/2013 mem - Now storing payroll number in U_Payroll and Network_ID in Username
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/17/2022 mem - Tabs to spaces
**          05/19/2023 mem - Add missing Else
**          05/24/2023 mem - When previewing new users, show charge codes associated with each new user
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int := 0;
    _operationID int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create temporary table to keep track of users to add
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_NewUsers (
        Payroll text,
        HID text,
        LastName_FirstName text,
        Network_ID text NULL,
        Charge_Code_First text NULL,
        Charge_Code_Last text NULL,
        DMS_ID int NULL
    );

    BEGIN

        INSERT INTO Tmp_NewUsers (Payroll, HID, Charge_Code_First, Charge_Code_Last)
        SELECT CC.resp_username, MAX(CC.resp_hid), Min(CC.Charge_Code) AS Charge_Code_First, Max(CC.Charge_Code) AS Charge_Code_Last
        FROM t_charge_code CC
             LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map UMap
               ON CC.charge_code = UMap.charge_code
        WHERE UMap.Username IS NULL AND
              CC.charge_code_state > 0 AND
              (CC.usage_sample_prep > 0 OR
               CC.usage_requested_run > 0)
        GROUP BY CC.resp_username;

        UPDATE Tmp_NewUsers
        SET Network_ID = W.Network_ID,
            LastName_FirstName = PREFERRED_NAME_FM
        FROM pnnldata."VW_PUB_BMI_EMPLOYEE" W
        WHERE Target.HID = W.HANFORD_ID AND
              Coalesce(W.Network_ID, '') <> '';

        If Not _infoOnly Then
            If Exists (SELECT * FROM Tmp_NewUsers WHERE NOT Network_ID Is Null) Then

                INSERT INTO t_users( username,       -- Network_ID (aka login) goes in the username field
                                     name,
                                     hid,
                                     payroll,        -- payroll number goes in the payroll field
                                     status,
                                     update,
                                     comment )
                SELECT Network_ID,
                       LastName_FirstName,
                       'H' || hid,
                       payroll,
                       'active' AS status,
                       'Y' AS U_update,
                       '' AS U_comment
                FROM Tmp_NewUsers
                ORDER BY Network_ID;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                If _insertCount > 0 Then
                    _message := format('Auto added %s %s to t_users since they are associated with charge codes used by DMS',
                                        _insertCount, public.check_plural(_insertCount, 'user', 'users');

                    CALL post_log_entry ('Normal', _message, 'Auto_Add_Charge_Code_Users');
                End If;

                UPDATE Tmp_NewUsers
                SET DMS_ID = U.ID
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
                    SELECT DMS_ID, _operationID
                    FROM Tmp_NewUsers;
                End If;

            End If;

        Else
            -- ToDo: Use Raise Info

            -- Preview the new users
            SELECT *
            FROM Tmp_NewUsers
            WHERE NOT Network_ID Is Null

        End If;

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
END
$$;

COMMENT ON PROCEDURE public.auto_add_charge_code_users IS 'AutoAddChargeCodeUsers';
