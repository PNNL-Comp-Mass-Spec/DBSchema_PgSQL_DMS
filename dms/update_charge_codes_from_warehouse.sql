--
-- Name: update_charge_codes_from_warehouse(boolean, boolean, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_charge_codes_from_warehouse(IN _infoonly boolean DEFAULT false, IN _updateall boolean DEFAULT false, IN _onlyshowchanged boolean DEFAULT false, IN _explicitchargecodelist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Update charge codes (aka work packages) in t_charge_code using external server SQLSRVPROD02, which is accessed via a foreign data wrapper
**
**  Arguments:
**    _infoOnly                 When true, preview updates that would be applied
**    _updateAll                When true, force an update of all rows in t_charge_code; by default, charge codes are filtered based on Setup_Date and Auth_Amt
**    _onlyShowChanged          When _infoOnly is true, set this to true to only show new or updated work packages
**    _explicitChargeCodeList   Comma-separated list of charge codes (work packages) to add to t_charge_code regardless of filters. When used, other charge codes are ignored
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   06/04/2013 mem - Initial version
**          06/05/2013 mem - Now calling Auto_Add_Charge_Code_Users
**          06/06/2013 mem - Now caching column DEACT_SW, which is 'Y' when the charge code is Deactivated (can also be 'R'; don't know what that means)
**          12/03/2013 mem - Now changing Charge_Code_State to 0 for Deactivated work packages
**                         - Now populating Activation_State when inserting new rows via the merge
**          08/13/2015 mem - Added field _explicitChargeCodeList
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          07/11/2017 mem - Use computed column HID_Number in T_Users
**          02/08/2022 mem - Change tabs to spaces and update comments
**          07/21/2022 mem - Also examine SubAccount_Inactive_Date when considering changing Charge_Code_State from 0 to 1 for work packages that are no longer Deactivated
**                         - When _infoOnly and _onlyShowChanged are both true, only show new or updated work packages
**          12/14/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _callingProcName text;
    _currentLocation text := 'Start';

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

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _infoOnly               := Coalesce(_infoOnly, false);
    _updateAll              := Coalesce(_updateAll, false);
    _onlyShowChanged        := Coalesce(_onlyShowChanged, false);

    _explicitChargeCodeList := Trim(Coalesce(_explicitChargeCodeList, ''));

    -- Create a temporary table to keep track of work packages used within the last 12 months

    CREATE TEMP TABLE Tmp_CCsInUseLast3Years (
        Charge_Code citext,
        Most_Recent_Usage timestamp
    );

    CREATE INDEX IX_Tmp_CCsInUseLast3Years ON Tmp_CCsInUseLast3Years (Charge_Code);

    -- Create a temporary table to keep track of work packages in _explicitChargeCodeList

    CREATE TEMP TABLE Tmp_CCsExplicit (
        Charge_Code citext
    );

    CREATE INDEX IX_Tmp_CCsExplicit ON Tmp_CCsExplicit (Charge_Code);

    BEGIN

        If _explicitChargeCodeList <> '' Then
            INSERT INTO Tmp_CCsExplicit (Charge_Code)
            SELECT Value
            FROM public.parse_delimited_list(_explicitChargeCodeList);
        End If;

        ----------------------------------------------------------
        -- Create a temporary table to track the charge code information
        -- stored in the data warehouse
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ChargeCode (
            Charge_Code citext NOT NULL,
            Resp_Username text NULL,
            Resp_HID text NULL,
            WBS_Title text NULL,
            Charge_Code_Title text NULL,
            Sub_Account text NULL,
            Sub_Account_Title text NULL,
            Setup_Date timestamp NOT NULL,
            Sub_Account_Effective_Date timestamp NULL,
            Inactive_Date timestamp NULL,
            Sub_Account_Inactive_Date timestamp NULL,
            Deactivated text NOT NULL,
            Auth_Amt numeric(12,0) NOT NULL,
            Auth_Username text NULL,
            Auth_HID text NULL,
            Update_Status text NULL
        );

        CREATE INDEX IX_Tmp_ChargeCode ON Tmp_ChargeCode (Charge_Code);

        ----------------------------------------------------------
        -- Obtain charge code info
        --
        -- Note that as of January 2024, in the source view, fields RESP_PAY_NO and AUTH_PAY_NO are null for people whose username is over 5 characters long (as has been standard for several years now)
        -- The Hanford ID (HID) values are defined, but the username is null
        ----------------------------------------------------------

        _currentLocation := 'Query opwhse';

        If Exists (SELECT Charge_Code FROM Tmp_CCsExplicit) Then

            INSERT INTO Tmp_ChargeCode( Charge_Code,
                                        Resp_Username,
                                        Resp_HID,
                                        WBS_Title,
                                        Charge_Code_Title,
                                        Sub_Account,
                                        Sub_Account_Title,
                                        Setup_Date,
                                        Sub_Account_Effective_Date,
                                        Inactive_Date,
                                        Sub_Account_Inactive_Date,
                                        Deactivated,
                                        Auth_Amt,
                                        Auth_Username,
                                        Auth_HID,
                                        Update_Status)
            SELECT CC."CHARGE_CD",
                   CC."RESP_PAY_NO",
                   CC."RESP_HID",
                   CT."WBS_TITLE",
                   CC."CHARGE_CD_TITLE",
                   CC."SUBACCT",
                   CT."SA_TITLE",
                   CC."SETUP_DATE",
                   CC."SUBACCT_EFF_DATE",
                   CC."INACT_DATE",
                   CC."SUBACCT_INACT_DATE",
                   CC."DEACT_SW",
                   CC."AUTH_AMT",
                   CC."AUTH_PAY_NO",
                   CC."AUTH_HID",
                   ''
            FROM pnnldata."VW_PUB_CHARGE_CODE" CC
                 INNER JOIN Tmp_CCsExplicit
                   ON Upper(CC."CHARGE_CD") = Upper(Tmp_CCsExplicit.Charge_Code)
                 LEFT OUTER JOIN pnnldata."VW_PUB_CHARGE_CODE_TRAIL" CT
                   ON Upper(CC."CHARGE_CD") = Upper(CT."CHARGE_CD");

        Else

            INSERT INTO Tmp_ChargeCode( Charge_Code,
                                        Resp_Username,
                                        Resp_HID,
                                        WBS_Title,
                                        Charge_Code_Title,
                                        Sub_Account,
                                        Sub_Account_Title,
                                        Setup_Date,
                                        Sub_Account_Effective_Date,
                                        Inactive_Date,
                                        Sub_Account_Inactive_Date,
                                        Deactivated,
                                        Auth_Amt,
                                        Auth_Username,
                                        Auth_HID,
                                        Update_Status)
            SELECT CC."CHARGE_CD",
                   CC."RESP_PAY_NO",
                   CC."RESP_HID",
                   CT."WBS_TITLE",
                   CC."CHARGE_CD_TITLE",
                   CC."SUBACCT",
                   CT."SA_TITLE",
                   CC."SETUP_DATE",
                   CC."SUBACCT_EFF_DATE",
                   CC."INACT_DATE",
                   CC."SUBACCT_INACT_DATE",
                   CC."DEACT_SW",
                   CC."AUTH_AMT",
                   CC."AUTH_PAY_NO",
                   CC."AUTH_HID",
                   ''
            FROM pnnldata."VW_PUB_CHARGE_CODE" CC
                 LEFT OUTER JOIN pnnldata."VW_PUB_CHARGE_CODE_TRAIL" CT
                   ON Upper(CC."CHARGE_CD") = Upper(CT."CHARGE_CD")
            WHERE (CC."SETUP_DATE" >= CURRENT_TIMESTAMP - INTERVAL '10 years' AND   -- Filter out charge codes created over 10 years ago
                   CC."AUTH_AMT" > 0 AND                                            -- Ignore charge codes with an authorization amount of $0
                   CC."CHARGE_CD" NOT LIKE 'R%' AND                                 -- Filter out charge codes that are used for purchasing, not labor
                   CC."CHARGE_CD" NOT LIKE 'V%'
                  )
                  OR
                  (CC."SETUP_DATE" >= CURRENT_TIMESTAMP - INTERVAL '2 years' AND    -- Filter out charge codes created over 2 years ago
                   CC."RESP_HID" IN (                                               -- Filter on charge codes where the Responsible person is an active DMS user; this includes codes with auth_amt = 0
                          SELECT hid_number
                          FROM t_users
                          WHERE status = 'Active'
                      ) AND
                   CC."CHARGE_CD" NOT LIKE 'R%' AND                                 -- Filter out charge codes that are used for purchasing, not labor
                   CC."CHARGE_CD" NOT LIKE 'V%'
                  )
                  OR
                  (_updateAll AND Upper(CC."CHARGE_CD") IN (SELECT Upper(charge_code) FROM t_charge_code));

        End If;

        If Not _infoOnly Then

            ----------------------------------------------------------
            -- Merge new/updated charge codes
            --
            -- Note that field Activation_State will be auto-updated by trigger trig_t_charge_code_after_update
            -- whenever values in any of these fields change:
            --    Deactivated, Charge_Code_State, Usage_SamplePrep, Usage_RequestedRun, Activation_State
            --
            -- Activation_State values are determined by scalar-valued function charge_code_activation_state()
            -- That function uses the Deactivated, Charge_Code_State, Usage_SamplePrep, and Usage_RequestedRun to determine the activation state
            --
            -- Logic below updates Charge_Code_State based on Deactivated, Setup_Date, Usage_SamplePrep, and Usage_RequestedRun
            ----------------------------------------------------------

            _currentLocation := 'Merge data';

            SELECT COUNT(charge_code)
            INTO _countBeforeMerge
            FROM t_charge_code;

            MERGE INTO t_charge_code AS Target
            USING ( SELECT charge_code, resp_username, resp_hid, wbs_title, charge_code_title,
                           sub_account, sub_account_title, setup_date, sub_account_effective_date,
                           inactive_date, sub_account_inactive_date, deactivated, auth_amt, auth_username, auth_hid
                    FROM Tmp_ChargeCode
                  ) AS Source
            ON (target.charge_code = source.charge_code)
            WHEN MATCHED AND
                 (target.resp_username              IS DISTINCT FROM source.resp_username OR
                  target.resp_hid                   IS DISTINCT FROM source.resp_hid OR
                  target.wbs_title                  IS DISTINCT FROM source.wbs_title OR
                  target.charge_code_title          IS DISTINCT FROM source.charge_code_title OR
                  target.sub_account                IS DISTINCT FROM source.sub_account OR
                  target.sub_account_title          IS DISTINCT FROM source.sub_account_title OR
                  target.setup_date                 IS DISTINCT FROM source.setup_date OR
                  target.sub_account_effective_date IS DISTINCT FROM source.sub_account_effective_date OR
                  target.inactive_date              IS DISTINCT FROM source.inactive_date OR
                  target.sub_account_inactive_date  IS DISTINCT FROM source.sub_account_inactive_date OR
                  target.deactivated                IS DISTINCT FROM source.deactivated OR
                  target.auth_amt                   IS DISTINCT FROM source.auth_amt OR
                  target.auth_username              IS DISTINCT FROM source.auth_username OR
                  target.auth_hid                   IS DISTINCT FROM source.auth_hid) THEN
                UPDATE SET
                    resp_username              = source.resp_username,
                    resp_hid                   = source.resp_hid,
                    wbs_title                  = source.wbs_title,
                    charge_code_title          = source.charge_code_title,
                    sub_account                = source.sub_account,
                    sub_account_title          = source.sub_account_title,
                    setup_date                 = source.setup_date,
                    sub_account_effective_date = source.sub_account_effective_date,
                    inactive_date              = source.inactive_date,
                    sub_account_inactive_date  = source.sub_account_inactive_date,
                    deactivated                = source.deactivated,
                    auth_amt                   = source.auth_amt,
                    auth_username              = source.auth_username,
                    auth_hid                   = source.auth_hid,
                    last_affected              = CURRENT_TIMESTAMP
            WHEN NOT MATCHED
                THEN INSERT  (
                         charge_code, resp_username, resp_hid, wbs_title, charge_code_title,
                         sub_account, sub_account_title, setup_date, sub_account_effective_date,
                         inactive_date, sub_account_inactive_date, deactivated, auth_amt, auth_username, auth_hid,
                         auto_defined, charge_code_state, activation_state, last_affected
                    ) VALUES
                    ( source.charge_code, source.resp_username, source.resp_hid, source.wbs_title, source.charge_code_title,
                      source.sub_account, source.sub_account_title, source.setup_date, source.sub_account_effective_date,
                      source.inactive_date, source.sub_account_inactive_date, source.deactivated, source.auth_amt, source.auth_username, source.auth_hid,
                      1,        -- auto_defined=1
                      1,        -- charge_code_state = 1 (Interest Unknown)
                      charge_code_activation_state(source.deactivated, 1, 0, 0),
                      CURRENT_TIMESTAMP
                    );

            GET DIAGNOSTICS _mergeCount = ROW_COUNT;

            SELECT COUNT(charge_code)
            INTO _countAfterMerge
            FROM t_charge_code;

            _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

            If _mergeCount > 0 Then
                _mergeUpdateCount := _mergeCount - _mergeInsertCount;
            Else
                _mergeUpdateCount := 0;
            End If;

            If _mergeUpdateCount > 0 Or _mergeInsertCount > 0 Then
                _message := format('Updated t_charge_code: %s added, %s updated', _mergeInsertCount, _mergeUpdateCount);

                CALL post_log_entry ('Normal', _message, 'Update_Charge_Codes_From_Warehouse');

                _message := '';
            End If;

            ----------------------------------------------------------
            -- Update usage columns
            --
            -- If not inside a procedure, you can use this to see old and new usage stats
            -- SELECT * FROM update_charge_code_usage(_infoOnly => false);
            --
            -- Use PERFORM to call update_charge_code_usage() from this procedure
            ----------------------------------------------------------

            _currentLocation := 'Update usage columns';

            PERFORM public.update_charge_code_usage(_infoOnly => false);

            ----------------------------------------------------------
            -- Update Inactive_Date_Most_Recent
            -- based on Inactive_Date and Sub_Account_Inactive_Date
            ----------------------------------------------------------

            _currentLocation := 'Update Inactive_Date_Most_Recent using Inactive_Date and Sub_Account_Inactive_Date';

            UPDATE t_charge_code Target
            SET inactive_date_most_recent = OuterQ.inactive_date_most_recent
            FROM ( SELECT Charge_Code,
                          Inactive1,
                          Inactive2,
                          CASE WHEN Inactive1 >= COALESCE(Inactive2, Inactive1) THEN Inactive1
                               ELSE Inactive2
                          END AS Inactive_Date_Most_Recent
                   FROM ( SELECT charge_code,
                                 COALESCE(inactive_date, sub_account_inactive_date, inactive_date_most_recent) AS Inactive1,
                                 COALESCE(sub_account_inactive_date, inactive_date, inactive_date_most_recent) AS Inactive2
                          FROM t_charge_code
                        ) InnerQ
                 ) OuterQ
            WHERE target.Charge_Code = OuterQ.Charge_Code AND
                  NOT OuterQ.Inactive_Date_Most_Recent IS NULL AND
                  target.Inactive_Date_Most_Recent IS DISTINCT FROM OuterQ.Inactive_Date_Most_Recent;

            ----------------------------------------------------------
            -- Update Inactive_Date_Most_Recent based on Deactivated
            ----------------------------------------------------------

            _currentLocation := 'Update Inactive_Date_Most_Recent using Deactivated';

            UPDATE t_charge_code
            SET inactive_date_most_recent = CURRENT_TIMESTAMP
            WHERE deactivated = 'Y' AND inactive_date_most_recent IS NULL;

            -- Set the state to 0 for deactivated work packages

            UPDATE t_charge_code
            SET charge_code_state = 0
            WHERE charge_code_state <> 0 AND
                  deactivated = 'Y';

            -- Look for work packages that have a state of 0 but are no longer deactivated
            -- If created within the last 2 years, or if Inactive_Date_Most_Recent is within the last two years,
            -- change their state back to 1 (Interest Unknown)

            UPDATE t_charge_code
            SET charge_code_state = 1
            WHERE charge_code_state = 0 AND
                  deactivated = 'N' AND
                  (setup_date > CURRENT_TIMESTAMP - INTERVAL '2 years'
                    -- Or Sub_Account_Inactive_Date > CURRENT_TIMESTAMP - INTERVAL '2 years'
                  );

            ----------------------------------------------------------
            -- Auto-mark active charge codes that are currently in state 1 = 'Interest Unknown'
            -- Change the state to 2 for any that have sample prep requests or requested runs that use the charge code
            ----------------------------------------------------------

            _currentLocation := 'Update Charge_Code_State';

            UPDATE t_charge_code
            SET charge_code_state = 2
            WHERE charge_code_state = 1 AND
                  (usage_sample_prep > 0 OR
                   usage_requested_run > 0);

            ----------------------------------------------------------
            -- Find work packages used within the last 3 years
            ----------------------------------------------------------

            INSERT INTO Tmp_CCsInUseLast3Years ( Charge_Code, Most_Recent_Usage)
            SELECT Charge_Code, MAX(Most_Recent_Usage)
            FROM ( SELECT A.Charge_Code,
                          CASE WHEN A.Most_Recent_SPR >= Coalesce(B.Most_Recent_RR, A.Most_Recent_SPR)
                               THEN A.Most_Recent_SPR
                               ELSE B.Most_Recent_RR
                          END AS Most_Recent_Usage
                   FROM ( SELECT CC.charge_code,
                                 MAX(SPR.created) AS Most_Recent_SPR
                          FROM t_charge_code CC
                               INNER JOIN t_sample_prep_request SPR
                                 ON CC.charge_code = SPR.work_package
                          GROUP BY CC.charge_code
                        ) A
                        INNER JOIN
                        ( SELECT CC.charge_code,
                                 MAX(RR.created) AS Most_Recent_RR
                          FROM t_requested_run RR
                               INNER JOIN t_charge_code CC
                                 ON RR.work_package = CC.charge_code
                          GROUP BY CC.charge_code
                        ) B
                        ON A.charge_code = B.charge_code
                 ) UsageQ
            WHERE Most_Recent_Usage >= CURRENT_TIMESTAMP - INTERVAL '3 years'
            GROUP BY charge_code;

            ----------------------------------------------------------
            -- Auto-mark Inactive charge codes that have usage counts of 0 and became inactive at least 6 months ago
            -- Note that DMS changes Inactive_Date_Most_Recent from Null to a valid date when it finds that a charge_code has been deactivated
            ----------------------------------------------------------

            UPDATE t_charge_code
            SET charge_code_state = 0
            WHERE charge_code_state IN (1, 2) AND
                  inactive_date_most_recent < CURRENT_TIMESTAMP - INTERVAL '6 months' AND
                  Coalesce(usage_sample_prep, 0) = 0 AND
                  Coalesce(usage_requested_run, 0) = 0;

            ----------------------------------------------------------
            -- Auto-mark Inactive charge codes that became inactive at least 12 months ago
            -- and haven't had any recent sample prep request or requested run usage
            ----------------------------------------------------------

            UPDATE t_charge_code
            SET charge_code_state = 0
            WHERE charge_code_state IN (1, 2) AND
                  inactive_date_most_recent < CURRENT_TIMESTAMP - INTERVAL '1 year' AND
                  NOT charge_code IN ( SELECT charge_code
                                       FROM Tmp_CCsInUseLast3Years
                                       WHERE Most_Recent_Usage >= CURRENT_TIMESTAMP - INTERVAL '1 year' );

            ----------------------------------------------------------
            -- Auto-mark Inactive charge codes that were created at least 3 years ago
            -- and haven't had any sample prep request or requested run usage within the last 3 years
            -- The goal is to hide charge codes that are still listed as active in the warehouse, yet have not been used in DMS for 3 years
            ----------------------------------------------------------

            UPDATE t_charge_code
            SET charge_code_state = 0
            WHERE charge_code_state IN (1, 2) AND
                  setup_date < CURRENT_TIMESTAMP - INTERVAL '3 years' AND
                  NOT charge_code IN ( SELECT charge_code
                                       FROM Tmp_CCsInUseLast3Years );

            ----------------------------------------------------------
            -- Add new users as DMS_Guest users
            -- We only add users associated with charge codes that have been used in DMS
            ----------------------------------------------------------

            CALL public.auto_add_charge_code_users (
                            _infoOnly                   => false,
                            _includeInactiveChargeCodes => false,
                            _message                    => _message,
                            _returnCode                 => _returnCode);

            DROP TABLE Tmp_CCsInUseLast3Years;
            DROP TABLE Tmp_CCsExplicit;
            DROP TABLE Tmp_ChargeCode;

            RETURN;
        End If;

        ----------------------------------------------------------
        -- Preview the updates
        ----------------------------------------------------------

        UPDATE Tmp_ChargeCode target
        SET Update_Status =
                CASE WHEN source.Deactivated = 'Y' And target.Deactivated = 'N' THEN 'Re-activated existing CC'
                     WHEN source.Deactivated = 'N' And target.Deactivated = 'Y' THEN 'Deactivated existing CC'
                     WHEN source.WBS_Title                  IS DISTINCT FROM target.WBS_Title OR
                          source.Charge_Code_Title          IS DISTINCT FROM target.Charge_Code_Title OR
                          source.Sub_Account                IS DISTINCT FROM target.Sub_Account OR
                          source.Sub_Account_Title          IS DISTINCT FROM target.Sub_Account_Title OR
                          source.Setup_Date                 IS DISTINCT FROM target.Setup_Date OR
                          source.Sub_Account_Effective_Date IS DISTINCT FROM target.Sub_Account_Effective_Date OR
                          source.Inactive_Date              IS DISTINCT FROM target.Inactive_Date OR
                          source.Sub_Account_Inactive_Date  IS DISTINCT FROM target.Sub_Account_Inactive_Date OR
                          source.Deactivated                IS DISTINCT FROM target.Deactivated
                          THEN 'Updated existing CC'
                     ELSE 'Unchanged existing CC'
                END
        FROM t_charge_code source
        WHERE target.charge_code = source.charge_code;

        UPDATE Tmp_ChargeCode
        SET Update_Status = 'New CC'
        WHERE Update_Status = '';

        RAISE INFO '';

        _formatSpecifier := '%-26s %-11s %-17s %-17s %-12s %-12s %-50s %-50s %-50s %-50s %-15s %-15s %-50s %-50s %-15s %-15s %-27s %-27s %-17s %-17s %-26s %-26s %-15s %-15s %-12s %-12s %-17s %-17s %-12s %-12s';

        _infoHead := format(_formatSpecifier,
                            'Update_Status',
                            'Charge_Code',
                            'Resp_Username_Old',
                            'Resp_Username_New',
                            'Resp_Hid_Old',
                            'Resp_Hid_New',
                            'Wbs_Title_Old',
                            'Wbs_Title_New',
                            'Charge_Code_Title_Old',
                            'Charge_Code_Title_New',
                            'Sub_Account_Old',
                            'Sub_Account_New',
                            'Sub_Account_Title_Old',
                            'Sub_Account_Title_New',
                            'Setup_Date_Old',
                            'Setup_Date_New',
                            'Sub_Acct_Effective_Date_Old',
                            'Sub_Acct_Effective_Date_New',
                            'Inactive_Date_Old',
                            'Inactive_Date_New',
                            'Sub_Acct_Inactive_Date_Old',
                            'Sub_Acct_Inactive_Date_New',
                            'Deactivated_Old',
                            'Deactivated_New',
                            'Auth_Amt_Old',
                            'Auth_Amt_New',
                            'Auth_Username_Old',
                            'Auth_Username_New',
                            'Auth_Hid_Old',
                            'Auth_Hid_New'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------------',
                                     '-----------',
                                     '-----------------',
                                     '-----------------',
                                     '------------',
                                     '------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '---------------',
                                     '---------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '---------------',
                                     '---------------',
                                     '---------------------------',
                                     '---------------------------',
                                     '-----------------',
                                     '-----------------',
                                     '--------------------------',
                                     '--------------------------',
                                     '---------------',
                                     '---------------',
                                     '------------',
                                     '------------',
                                     '-----------------',
                                     '-----------------',
                                     '------------',
                                     '------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Update_Status,
                   New.charge_code,
                   Old.resp_username AS resp_username_old,                              New.resp_username AS resp_username_new,
                   Old.resp_hid AS resp_hid_old,                                        New.resp_hid AS resp_hid_new,
                   Left(Old.wbs_title, 50) AS wbs_title_old,                            Left(New.wbs_title, 50) AS wbs_title_new,
                   Left(Old.charge_code_title, 50) AS charge_code_title_old,            Left(New.charge_code_title, 50) AS charge_code_title_new,
                   Old.sub_account AS sub_account_old,                                  New.sub_account AS sub_account_new,
                   Left(Old.sub_account_title, 50) AS sub_account_title_old,            Left(New.sub_account_title, 50) AS sub_account_title_new,
                   Old.setup_date::date AS setup_date_old,                              New.setup_date::date AS setup_date_new,
                   Old.sub_account_effective_date::date AS sub_acct_effective_date_old, New.sub_account_effective_date::date AS sub_acct_effective_date_new,
                   Old.inactive_date::date AS inactive_date_old,                        New.inactive_date::date AS inactive_date_new,
                   Old.sub_account_inactive_date::date AS sub_acct_inactive_date_old,   New.sub_account_inactive_date::date AS sub_acct_inactive_date_new,
                   Old.deactivated AS deactivated_old,                                  New.deactivated AS deactivated_new,
                   Old.auth_amt AS auth_amt_old,                                        New.auth_amt AS auth_amt_new,
                   Old.auth_username AS auth_username_old,                              New.auth_username AS auth_username_new,
                   Old.auth_hid AS auth_hid_old,                                        New.auth_hid AS auth_hid_new
            FROM Tmp_ChargeCode New LEFT OUTER JOIN
                 t_charge_code Old
                   ON New.charge_code = Old.charge_code
            WHERE _infoOnly AND NOT _onlyShowChanged OR
                  _infoOnly AND     _onlyShowChanged AND New.Update_Status NOT LIKE 'Unchanged%'
            ORDER BY New.Update_Status, New.charge_code
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Update_Status,
                                _previewData.Charge_Code,
                                _previewData.Resp_Username_Old,
                                _previewData.Resp_Username_New,
                                _previewData.Resp_Hid_Old,
                                _previewData.Resp_Hid_New,
                                _previewData.Wbs_Title_Old,
                                _previewData.Wbs_Title_New,
                                _previewData.Charge_Code_Title_Old,
                                _previewData.Charge_Code_Title_New,
                                _previewData.Sub_Account_Old,
                                _previewData.Sub_Account_New,
                                _previewData.Sub_Account_Title_Old,
                                _previewData.Sub_Account_Title_New,
                                _previewData.Setup_Date_Old,
                                _previewData.Setup_Date_New,
                                _previewData.Sub_Acct_Effective_Date_Old,
                                _previewData.Sub_Acct_Effective_Date_New,
                                _previewData.Inactive_Date_Old,
                                _previewData.Inactive_Date_New,
                                _previewData.Sub_Acct_Inactive_Date_Old,
                                _previewData.Sub_Acct_Inactive_Date_New,
                                _previewData.Deactivated_Old,
                                _previewData.Deactivated_New,
                                _previewData.Auth_Amt_Old,
                                _previewData.Auth_Amt_New,
                                _previewData.Auth_Username_Old,
                                _previewData.Auth_Username_New,
                                _previewData.Auth_Hid_Old,
                                _previewData.Auth_Hid_New
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_CCsInUseLast3Years;
        DROP TABLE Tmp_CCsExplicit;
        DROP TABLE Tmp_ChargeCode;

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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_CCsInUseLast3Years;
    DROP TABLE IF EXISTS Tmp_CCsExplicit;
    DROP TABLE IF EXISTS Tmp_ChargeCode;
END
$_$;


ALTER PROCEDURE public.update_charge_codes_from_warehouse(IN _infoonly boolean, IN _updateall boolean, IN _onlyshowchanged boolean, IN _explicitchargecodelist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_charge_codes_from_warehouse(IN _infoonly boolean, IN _updateall boolean, IN _onlyshowchanged boolean, IN _explicitchargecodelist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_charge_codes_from_warehouse(IN _infoonly boolean, IN _updateall boolean, IN _onlyshowchanged boolean, IN _explicitchargecodelist text, INOUT _message text, INOUT _returncode text) IS 'UpdateChargeCodesFromWarehouse';

