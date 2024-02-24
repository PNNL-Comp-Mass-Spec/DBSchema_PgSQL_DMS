--
CREATE OR REPLACE PROCEDURE public.update_users_from_warehouse
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
**      Update user information in t_users using external server SQLSRVPROD02, which is accessed via a foreign data wrapper
**
**      Foreign data wrapper setup steps:
**
**      1) Install the required packages
**          # sudo yum install postgresql14-libs postgresql14-devel
**
**          # Install epel-release-8-16
**          sudo yum install epel-release
**
**          # Install the Tabular Data Stream foreign data wrapper
**          sudo yum install tds_fdw14.x86_64
**
**      2) Restart the PostgreSQL service, then add the new tds_fdw extension
**
**          SELECT * FROM pg_available_extensions where name like '%fdw';
**
**          name           default_version
**          -------------  ---------------
**          postgres_fdw   1.1
**          file_fdw       1.0
**          tds_fdw        2.0.2
**
**
**          CREATE EXTENSION IF NOT EXISTS tds_fdw;
**
**          DROP SERVER IF EXISTS op_warehouse_fdw CASCADE;
**
**          -- The default port for SQL Server is 1433, but OPWHSE uses port 915
**          CREATE SERVER op_warehouse_fdw
**          FOREIGN DATA WRAPPER tds_fdw
**          OPTIONS (servername 'SQLSrvProd02.pnl.gov', database 'OPWHSE', port '915');    -- port '915', tds_version '7.3'
**
**          -- SELECT * FROM pg_catalog.pg_user;
**
**          CREATE USER MAPPING FOR postgres SERVER op_warehouse_fdw OPTIONS (username 'PRISM', password '5.......');       -- PasswordUpdateTool.exe /decode 4HhhXbvo
**          CREATE USER MAPPING FOR d3l243   SERVER op_warehouse_fdw OPTIONS (username 'PRISM', password '5.......');       -- PasswordUpdateTool.exe /decode 4HhhXbvo
**
**          SELECT * FROM pg_user_mapping;
**
**          oid     umuser  umserver  umoptions
**          ------  ------  --------  ---------------------------------
**          67,762  16,489  67,761    {user=dmsreader,password=dms....}
**          85,757  10      85,756    {username=PRISM,password=5.......}
**          85,758  16489   85,756    {username=PRISM,password=5.......}
**
**          -- The following is needed if the user is not a superuser, but it doesn't hurt to use it here
**          GRANT USAGE ON FOREIGN SERVER op_warehouse_fdw TO d3l243;
**
**          CREATE SCHEMA IF NOT EXISTS pnnldata;
**          IMPORT FOREIGN SCHEMA dbo FROM SERVER op_warehouse_fdw INTO pnnldata;
**
**          SELECT * FROM pnnldata."VW_PUB_BMI_EMPLOYEE" limit 5;
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   03/25/2013 mem - Initial version
**          06/07/2013 mem - Removed U_NetID since Username tracks the username
**                         - Added column U_Payroll to track the Payroll number
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/14/2016 mem - Add check for duplicate names
**          08/22/2018 mem - Tabs to spaces
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _addon text;

    _conflictCount int;
    _updateCount int;
    _missingCount int;
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ----------------------------------------------------------
        -- Create a temporary table to track the user information
        -- stored in the data warehouse
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_UserInfo (
            ID int NOT NULL,                 -- User ID
            Name text NULL,                  -- Last Name, First Name
            Email text NULL,                 -- E-mail
            Domain text NULL,                -- PNL
            Username text NULL,              -- Username on the domain
            PNNL_Payroll text NULL,          -- Payroll number
            Active text NOT NULL,            -- Y if an active login; N if a former staff member
            UpdateRequired boolean NOT NULL  -- Initially false; this procedure will set this to true for staff that need to be updated
        );

        CREATE INDEX IX_Tmp_UserInfo_ID ON Tmp_UserInfo (ID);

        ----------------------------------------------------------
        -- Obtain info for staff
        ----------------------------------------------------------

        INSERT INTO Tmp_UserInfo( user_id,
                                   name,
                                   email,
                                   domain,
                                   Username,
                                   PNNL_Payroll,
                                   active,
                                   UpdateRequired )
        SELECT U.user_id,
               PREFERRED_NAME_FM,
               INTERNET_EMAIL_ADDRESS,
               NETWORK_DOMAIN,
               NETWORK_ID,              -- Username
               PNNL_PAY_NO,
               Coalesce(ACTIVE_SW, 'N') AS Active,
               false AS UpdateRequired
        FROM t_users U
             INNER JOIN pnnldata."VW_PUB_BMI_EMPLOYEE" Src
               ON U.hid = format('H%s', Src.HANFORD_ID)
        WHERE U.update = 'Y';

        ----------------------------------------------------------
        -- Obtain info for associates
        ----------------------------------------------------------

        INSERT INTO Tmp_UserInfo( user_id,
                                   name,
                                   email,
                                   domain,
                                   Username,
                                   PNNL_Payroll,
                                   active,
                                   UpdateRequired )
        SELECT U.user_id,
               format('%s, %s', Src.last_name, Src.pref_first_name),
               Src.internet_address,
               NetworkInfo.NETWORK_DOMAIN,
               NetworkInfo.NETWORK_ID,          -- Username
               NULL AS PNNL_Payroll,
               Coalesce(Src.pnl_maintained_sw, 'N') AS Active,
               false AS UpdateRequired
        FROM t_users U
             INNER JOIN pnnldata.vw_pub_pnnl_associate Src
               ON U.hid = format('H%s', Src.HANFORD_ID)
             LEFT OUTER JOIN pnnldata."VW_PUB_BMI_NT_ACCT_TBL" NetworkInfo
               ON Src.hanford_id = NetworkInfo.HANFORD_ID
             LEFT OUTER JOIN Tmp_UserInfo Target
               ON U.user_id = Target.user_id
        WHERE U.update = 'Y' AND
              Target.user_id IS NULL;

        ----------------------------------------------------------
        -- Look for users that need to be updated
        ----------------------------------------------------------

        UPDATE Tmp_UserInfo
        SET UpdateRequired = true
        FROM t_users U
             INNER JOIN Tmp_UserInfo Src
               ON U.user_id = Src.user_id
        WHERE Coalesce(U.name, '') <> Coalesce(Src.name, Coalesce(U.name, '')) OR
              Coalesce(U.email, '') <> Coalesce(Src.email, Coalesce(U.email, '')) OR
              Coalesce(U.domain, '') <> Coalesce(Src.domain, Coalesce(U.domain, '')) OR
              Coalesce(U.payroll, '') <> Coalesce(Src.PNNL_Payroll, Coalesce(U.payroll, '')) OR
              Coalesce(U.active, '') <> Coalesce(Src.active, Coalesce(U.active, ''));

        ----------------------------------------------------------
        -- Look for updates that would result in a name conflict
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_NamesAfterUpdate (
            ID int NOT NULL,
            OldName text NULL,
            NewName text NULL,
            Conflict boolean NOT NULL
        );

        CREATE INDEX IX_Tmp_NamesAfterUpdate_ID ON Tmp_NamesAfterUpdate (ID);

        CREATE INDEX IX_Tmp_NamesAfterUpdate_Name ON Tmp_NamesAfterUpdate (NewName);

        -- Store the names of the users that will be updated

        INSERT INTO Tmp_NamesAfterUpdate (user_id, OldName, NewName, Conflict)
        SELECT U.user_id, U.name, Coalesce(Src.name, U.name) AS NewName, false
        FROM t_users U
                INNER JOIN Tmp_UserInfo Src
                ON U.user_id = Src.user_id
        WHERE Src.UpdateRequired;

        -- Append the remaining users

        INSERT INTO Tmp_NamesAfterUpdate (user_id, OldName, NewName, Conflict)
        SELECT user_id, name, name, false
        FROM t_users
        WHERE NOT user_id IN (SELECT user_id FROM Tmp_NamesAfterUpdate);

        -- Look for conflicts

        UPDATE Tmp_NamesAfterUpdate
        SET Conflict = true
        WHERE NewName IN ( SELECT DupeCheck.NewName
                           FROM Tmp_NamesAfterUpdate DupeCheck
                           GROUP BY DupeCheck.NewName
                           HAVING COUNT(*) > 1 );

        SELECT COUNT(*)
        INTO _conflictCount
        FROM Tmp_NamesAfterUpdate
        WHERE Conflict;

        If _conflictCount > 0 Then

            _message := format('User update would result in %s', public.check_plural(_conflictCount, 'a duplicate name', 'duplicate names'));

            SELECT string_agg(format('%s --> %s', Coalesce(OldName, '??? Undefined ???'), Coalesce(NewName, '??? Undefined ???')), ', ' ORDER BY NewName, OldName)
            INTO _addon
            FROM Tmp_NamesAfterUpdate
            WHERE Conflict;

            _message := format('%s: %s', _message, _addon);

            If Not _infoOnly Then
                CALL post_log_entry ('Error', _message, 'Update_Users_From_Warehouse');
            Else
                RAISE WARNING '%', _message;
            End If;

        End If;

        If Not _infoOnly Then
            ----------------------------------------------------------
            -- Perform the update, skip entries with a potential name conflict
            ----------------------------------------------------------

            UPDATE t_users U
            SET name = CASE WHEN Coalesce(NameConflicts.Conflict, false)
                            THEN U.name
                            ELSE Coalesce(Src.Name, U.Name) End,
                email = Coalesce(Src.email, U.email),
                domain = Coalesce(Src.domain, U.domain),
                payroll = Coalesce(Src.PNNL_Payroll, U.payroll),
                active = Src.active,
                last_affected = CURRENT_TIMESTAMP
            FROM Tmp_UserInfo Src
                 LEFT OUTER JOIN Tmp_NamesAfterUpdate NameConflicts
                   ON U.ID = NameConflicts.ID
              WHERE U.ID = Src.ID AND U.UpdateRequired;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            If _updateCount > 0 Then
                _message := format('Updated %s %s using the PNNL Data Warehouse', _updateCount, public.check_plural(_updateCount, 'user', 'users');
                RAISE INFO '%', _message;

                CALL post_log_entry ('Normal', _message, 'Update_Users_From_Warehouse');
            End If;

        Else

            ----------------------------------------------------------
            -- Preview the updates
            ----------------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-40s %-40s %-40s %-40s %-6s %-10s %-7s %-11s %-10s %-12s %-6s %-10s';

            _infoHead := format(_formatSpecifier,
                                'Name',
                                'Name_New',
                                'Email',
                                'Email_New',
                                'Domain',
                                'Domain_New',
                                'Payroll',
                                'Payroll_New',
                                'Username',
                                'Username_New',
                                'Active',
                                'Active_New'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------------------------------------',
                                         '----------------------------------------',
                                         '----------------------------------------',
                                         '----------------------------------------',
                                         '------',
                                         '----------',
                                         '-------',
                                         '-----------',
                                         '----------',
                                         '------------',
                                         '------',
                                         '----------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT U.Name,
                       Src.name AS Name_New,
                       U.Email,
                       Src.email AS Email_New,
                       U.Domain,
                       Src.domain AS Domain_New,
                       U.Payroll,
                       Src.PNNL_Payroll AS Payroll_New,
                       U.Username,
                       Src.Username AS Username_New,
                       U.Active,
                       Src.active AS Active_New
                FROM t_users U
                     INNER JOIN Tmp_UserInfo Src
                       ON U.user_id = Src.user_id
                WHERE UpdateRequired
                ORDER BY U.Name
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Name,
                                    _previewData.Name_New,
                                    _previewData.Email,
                                    _previewData.Email_New,
                                    _previewData.Domain,
                                    _previewData.Domain_New,
                                    _previewData.Payroll,
                                    _previewData.Payroll_New,
                                    _previewData.Username,
                                    _previewData.Username_New,
                                    _previewData.Active,
                                    _previewData.Active_New
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        CREATE TEMP TABLE Tmp_UserProblems (
            ID int NOT NULL,
            Warning text,
            Username text NULL
        );

        ----------------------------------------------------------
        -- Look for users marked for auto-update who were not found in either of the data warehouse views
        ----------------------------------------------------------

        INSERT INTO Tmp_UserProblems (user_id, Warning, Username)
        SELECT U.user_id,
               'User not found in the Data Warehouse',
               U.username        -- username contains the network login
        FROM t_users U
             LEFT OUTER JOIN Tmp_UserInfo Src
               ON U.user_id = Src.user_id
        WHERE U.update = 'Y' AND
              Src.user_id IS NULL
        --
        GET DIAGNOSTICS _missingCount = ROW_COUNT;

        If Not _infoOnly And _missingCount > 0 Then
            _message := format('%s not found in the Data Warehouse', public.check_plural(_missingCount, 'User', 'Users');

            SELECT string_agg(Coalesce(U.hid, format('??? Undefined hid for user_id=%s ???', U.user_id)), ', ' ORDER BY U.user_id)
            INTO _addon
            FROM t_users U
                 INNER JOIN Tmp_UserProblems M
                    ON U.user_id = M.user_id;

            _message format('%s: %s', _message, _addon);

            CALL post_log_entry ('Error', _message, 'Update_Users_From_Warehouse');

            DELETE FROM Tmp_UserProblems;
        End If;

        ----------------------------------------------------------
        -- Look for users for which t_users.Username does not match Tmp_UserInfo.Username
        ----------------------------------------------------------

        INSERT INTO Tmp_UserProblems (user_id, Warning, Username)
        SELECT U.user_id,
               'Mismatch between username in DMS and network login in Warehouse',
               Src.Username
        FROM t_users U INNER JOIN Tmp_UserInfo Src
               ON U.user_id = Src.user_id
        WHERE U.update = 'y' AND
              U.username <> Src.Username AND
              Coalesce(Src.Username, '') <> ''
        --
        GET DIAGNOSTICS _missingCount = ROW_COUNT;

        If Not _infoOnly And _missingCount > 0 Then
            _message := format('%s with mismatch between username in DMS and network login in Warehouse', public.check_plural(_missingCount, 'User', 'Users'));

            SELECT string_agg(format('%s <> %s',
                                        Coalesce(U.username, format('??? Undefined username for user_id=%s ???', U.user_id)),
                                        Coalesce(M.Username, '??')),
                              ', ' ORDER BY U.user_id)
            INTO _addon
            FROM t_users U
                 INNER JOIN Tmp_UserProblems M
                   ON U.user_id = M.user_id;

            _message := format('%s: %s', _message, _addon);

            CALL post_log_entry ('Error', _message, 'Update_Users_From_Warehouse');

            DELETE FROM Tmp_UserProblems;
        End If;

        If _infoOnly And Exists (SELECT * from Tmp_UserProblems) Then

            RAISE INFO '';

            _formatSpecifier := '%-65s %-7s %-11s %-40s %-10s %-8s %-40s %-6s %-12s %-6s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Warning',
                                'User_ID',
                                'HID',
                                'Name',
                                'Username',
                                'Status',
                                'Email',
                                'Domain',
                                'Username_Alt',
                                'Active',
                                'Created'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-----------------------------------------------------------------',
                                         '-------',
                                         '-----------',
                                         '----------------------------------------',
                                         '----------',
                                         '--------',
                                         '----------------------------------------',
                                         '------',
                                         '------------',
                                         '------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT M.Warning,
                       U.User_ID,
                       Coalesce(U.hid, format('??? Undefined hid for user_id=%s ???', U.user_id)) AS HID,
                       Name,
                       Username,
                       Status,
                       Email,
                       Domain,
                       M.Username AS Username_Alt,
                       Active,
                       public.timestamp_text(Created) AS Created
                FROM t_users U
                     INNER JOIN Tmp_UserProblems M
                       ON U.user_id = M.user_id
                ORDER BY U.user_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Warning,
                                    _previewData.User_ID,
                                    _previewData.HID,
                                    _previewData.Name,
                                    _previewData.Username,
                                    _previewData.Status,
                                    _previewData.Email,
                                    _previewData.Domain,
                                    _previewData.Username_Alt,
                                    _previewData.Active,
                                    _previewData.Created
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

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

    DROP TABLE IF EXISTS Tmp_UserInfo;
    DROP TABLE IF EXISTS Tmp_NamesAfterUpdate;
    DROP TABLE IF EXISTS Tmp_UserProblems;
END
$$;

COMMENT ON PROCEDURE public.update_users_from_warehouse IS 'UpdateUsersFromWarehouse';
