--
CREATE OR REPLACE PROCEDURE public.update_charge_codes_from_warehouse
(
    _infoOnly boolean = false,
    _updateAll boolean = false,
    _onlyShowChanged boolean = false;
    _explicitChargeCodeList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates charge code (aka work package) information in T_Charge_Code using external server SQLSRVPROD02, which is accessed via a foreign data wrapper
**
**  Arguments:
**    _infoOnly                 Set to true to preview work package metadata after updates are applied
**    _updateAll                Set to true to force an update of all rows in T_Charge_Code; by default, filters on charge codes based on Setup_Date and Auth_Amt
**    _onlyShowChanged          When _infoOnly is true, set this to true to only show new or updated work packages
**    _explicitChargeCodeList   Comma-separated list of Charge codes (work packages) to add to T_Charge_Code regardless of filters.  When used, other charge codes are ignored
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
**          12/15/2023 mem - Ported to PostgreSQL
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

    -- Create a temporary table to keep track of WPs used within the last 12 months
    CREATE TEMP TABLE Tmp_WPsInUseLast3Years (
        Charge_Code text,
        Most_Recent_Usage timestamp
    );

    CREATE INDEX IX_Tmp_WPsInUseLast3Years ON Tmp_WPsInUseLast3Years (Charge_Code);

    -- Create a temporary table to keep track of WPs in _explicitChargeCodeList
    CREATE TEMP TABLE Tmp_WPsExplicit (
        Charge_Code text
    );

    CREATE INDEX IX_Tmp_WPsExplicit ON Tmp_WPsExplicit (Charge_Code);

    BEGIN

        If _explicitChargeCodeList <> '' Then
            -- Populate IX_Tmp_WPsExplicit
            INSERT INTO Tmp_WPsExplicit (Charge_Code)
            SELECT Value
            FROM public.parse_delimited_list(_explicitChargeCodeList)
        End If;

        ----------------------------------------------------------
        -- Create a temporary table to track the charge code information
        -- stored in the data warehouse
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ChargeCode(
            Charge_Code text NOT NULL,
            Resp_Username text NULL,
            Resp_HID text NULL,
            WBS_Title text NULL,
            Charge_Code_Title text NULL,
            SubAccount text NULL,
            SubAccount_Title text NULL,
            Setup_Date timestamp NOT NULL,
            SubAccount_Effective_Date timestamp NULL,
            Inactive_Date timestamp NULL,
            SubAccount_Inactive_Date timestamp NULL,
            Deactivated text NOT NULL,
            Auth_Amt numeric(12, 0) NOT NULL,
            Auth_Username text NULL,
            Auth_HID text NULL,
            Update_Status text NULL
        )

        CREATE INDEX IX_Tmp_ChargeCode ON Tmp_ChargeCode (Charge_Code);

        ----------------------------------------------------------
        -- Obtain charge code info
        ----------------------------------------------------------

        _currentLocation := 'Query opwhse';

        If Exists (Select * from Tmp_WPsExplicit) Then
            INSERT INTO Tmp_ChargeCode( Charge_Code,
                                         Resp_Username,
                                         Resp_HID,
                                         WBS_Title,
                                         Charge_Code_Title,
                                         SubAccount,
                                         SubAccount_Title,
                                         Setup_Date,
                                         SubAccount_Effective_Date,
                                         Inactive_Date,
                                         SubAccount_Inactive_Date,
                                         Deactivated,
                                         Auth_Amt,
                                         Auth_Username,
                                         Auth_HID,
                                         Update_Status)
            SELECT CC.CHARGE_CD,
                   CC.RESP_PAY_NO,
                   CC.RESP_HID,
                   CT.WBS_TITLE,
                   CC.CHARGE_CD_TITLE,
                   CC.SUBACCT,
                   CT.SA_TITLE,
                   CC.SETUP_DATE,
                   CC.SUBACCT_EFF_DATE,
                   CC.INACT_DATE,
                   CC.SUBACCT_INACT_DATE,
                   CC.DEACT_SW,
                   CC.AUTH_AMT,
                   CC.AUTH_PAY_NO,
                   CC.AUTH_HID,
                   ''
            FROM pnnldata."VW_PUB_CHARGE_CODE" CC
                 INNER JOIN Tmp_WPsExplicit
                   ON CC.CHARGE_CD = Tmp_WPsExplicit.Charge_Code
                 LEFT OUTER JOIN pnnldata."VW_PUB_CHARGE_CODE_TRAIL" CT
                   ON CC.CHARGE_CD = CT.CHARGE_CD;

        Else

            INSERT INTO Tmp_ChargeCode( charge_code,
                                        resp_username,
                                        resp_hid,
                                        wbs_title,
                                        charge_code_title,
                                        sub_account,
                                        sub_account_title,
                                        setup_date,
                                        sub_account_effective_date,
                                        inactive_date,
                                        sub_account_inactive_date,
                                        deactivated,
                                        auth_amt,
                                        auth_username,
                                        auth_hid,
                                        update_status)
            SELECT CC.CHARGE_CD,
                   CC.RESP_PAY_NO,
                   CC.resp_hid,
                   CT.wbs_title,
                   CC.CHARGE_CD_TITLE,
                   CC.SUBACCT,
                   CT.SA_TITLE,
                   CC.setup_date,
                   CC.SUBACCT_EFF_DATE,
                   CC.INACT_DATE,
                   CC.SUBACCT_INACT_DATE,
                   CC.DEACT_SW,
                   CC.auth_amt,
                   CC.AUTH_PAY_NO,
                   CC.auth_hid,
                   ''
            FROM pnnldata."VW_PUB_CHARGE_CODE" CC
                 LEFT OUTER JOIN pnnldata."VW_PUB_CHARGE_CODE_TRAIL" CT
                   ON CC.CHARGE_CD = CT.CHARGE_CD
            WHERE   (CC.setup_date >= CURRENT_TIMESTAMP - Interval '10 years' AND   -- Filter out charge codes created over 10 years ago
                     CC.auth_amt > 0 AND                                            -- Ignore charge codes with an authorization amount of $0
                     CC.CHARGE_CD NOT LIKE 'RB%' AND                                -- Filter out charge codes that are used for purchasing, not labor
                     CC.CHARGE_CD NOT SIMILAR TO '[RV]%'
                    )
                    OR
                    (CC.setup_date >= CURRENT_TIMESTAMP - INTERVAL '2 years' AND    -- Filter out charge codes created over 2 years ago
                     CC.resp_hid IN (                                               -- Filter on charge codes where the Responsible person is an active DMS user; this includes codes with auth_amt = 0
                        SELECT hid_number
                        FROM t_users
                        WHERE status = 'active'
                        ) AND
                     CC.CHARGE_CD NOT LIKE 'RB%' AND                                -- Filter out charge codes that are used for purchasing, not labor
                     CC.CHARGE_CD NOT SIMILAR TO '[RV]%'
                    )
                    OR
                    (_updateAll AND CC.CHARGE_CD IN (SELECT charge_code FROM t_charge_code));

        End If;

        If Not _infoOnly Then

            ----------------------------------------------------------
            -- Merge new/updated charge codes
            --
            -- Note that field Activation_State will be auto-updated by trigger trig_u_Charge_Code
            -- whenever values in any of these fields change:
            --    Deactivated, Charge_Code_State, Usage_SamplePrep, Usage_RequestedRun, Activation_State
            --
            -- Activation_State values are determined by scalar-valued function Charge_Code_Activation_State
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
                           sub_account, sub_account_title, setup_date, subaccount_effective_date,
                           inactive_date, sub_account_inactive_date, deactivated, auth_amt, auth_username, auth_hid
                    FROM Tmp_ChargeCode
                  ) AS Source
            ON (target.charge_code = source.charge_code)
            WHEN MATCHED AND
                 (Coalesce(target.resp_username, '') <> Coalesce(source.resp_username, '') OR
                  Coalesce(target.resp_hid, '') <> Coalesce(source.resp_hid, '') OR
                  Coalesce(target.wbs_title, '') <> Coalesce(source.wbs_title, '') OR
                  Coalesce(target.charge_code_title, '') <> Coalesce(source.charge_code_title, '') OR
                  Coalesce(target.sub_account, '') <> Coalesce(source.sub_account, '') OR
                  Coalesce(target.sub_account_title, '') <> Coalesce(source.sub_account_title, '') OR
                  target.setup_date <> source.setup_date OR
                  Coalesce(target.sub_account_effective_date, '') <> Coalesce(source.sub_account_effective_date, '') OR
                  Coalesce(target.inactive_date, '') <> Coalesce(source.inactive_date, '') OR
                  Coalesce(target.sub_account_inactive_date, '') <> Coalesce(source.sub_account_inactive_date, '') OR
                  target.deactivated <> source.deactivated OR
                  target.auth_amt <> source.auth_amt OR
                  Coalesce(target.auth_username, '') <> Coalesce(source.auth_username, '') OR
                  Coalesce(target.auth_hid, '') <> Coalesce(source.auth_hid, '')) THEN
                UPDATE SET
                    resp_username = source.resp_username,
                    resp_hid = source.resp_hid,
                    wbs_title = source.wbs_title,
                    charge_code_title = source.charge_code_title,
                    sub_account = source.sub_account,
                    sub_account_title = source.sub_account_title,
                    setup_date = source.setup_date,
                    sub_account_effective_date = source.sub_account_effective_date,
                    inactive_date = source.inactive_date,
                    sub_account_inactive_date = source.sub_account_inactive_date,
                    deactivated = source.deactivated,
                    auth_amt = source.auth_amt,
                    auth_username = source.auth_username,
                    auth_hid = source.auth_hid,
                    last_affected = CURRENT_TIMESTAMP
            WHEN NOT Matched
                THEN INSERT  (
                         charge_code, resp_username, resp_hid, wbs_title, charge_code_title,
                         sub_account, sub_account_title, setup_date, subaccount_effective_date,
                         inactive_date, sub_account_inactive_date, deactivated, auth_amt, auth_username, auth_hid,
                         auto_defined, charge_code_state, activation_state, last_affected
                    ) VALUES
                    ( source.charge_code, source.resp_username, source.resp_hid, source.wbs_title, source.charge_code_title,
                      source.sub_account, source.sub_account_title, source.setup_date, source.subaccount_effective_date,
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
            ----------------------------------------------------------

            _currentLocation := 'Update usage columns';

            CALL update_charge_code_usage (_infoOnly => false);

            ----------------------------------------------------------
            -- Update Inactive_Date_Most_Recent
            -- based on Inactive_Date and SubAccount_Inactive_Date
            ----------------------------------------------------------

            _currentLocation := 'Update Inactive_Date_Most_Recent using Inactive_Date and SubAccount_Inactive_Date';

            UPDATE t_charge_code Target
            SET inactive_date_most_recent = OuterQ.inactive_date_most_recent
            FROM  ( SELECT Charge_Code,
                           Inactive1,
                           Inactive2,
                           CASE
                               WHEN Inactive1 >= COALESCE(Inactive2, Inactive1) THEN Inactive1
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
            -- Update Inactive_Date_Most_Recent
            -- based on Deactivated
            ----------------------------------------------------------

            _currentLocation := 'Update Inactive_Date_Most_Recent using Deactivated';

            UPDATE t_charge_code
            SET inactive_date_most_recent = CURRENT_TIMESTAMP
            WHERE deactivated = 'Y' AND inactive_date_most_recent IS NULL;

            -- Set the state to 0 for deactivated work packages
            --
            UPDATE t_charge_code
            SET charge_code_state = 0
            WHERE charge_code_state <> 0 AND
                  deactivated = 'Y';

            -- Look for work packages that have a state of 0 but are no longer deactivated
            -- If created within the last 2 years, or if Inactive_Date_Most_Recent is within the last two years,
            -- change their state back to 1 (Interest Unknown)
            --
            UPDATE t_charge_code
            SET charge_code_state = 1
            WHERE charge_code_state = 0 AND
                  deactivated = 'N' AND
                  (setup_date > CURRENT_TIMESTAMP - INTERVAL '2 years'
                    -- Or SubAccount_Inactive_Date > CURRENT_TIMESTAMP - INTERVAL '2 years'
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
            -- Find WPs used within the last 3 years
            ----------------------------------------------------------

            INSERT INTO Tmp_WPsInUseLast3Years ( Charge_Code, Most_Recent_Usage)
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
                  ) A INNER JOIN
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
            -- Note that DMS updates Inactive_Date_Most_Recent from Null to a valid date when it finds that a charge_code has been deactivated
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
                                       FROM Tmp_WPsInUseLast3Years
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
                                       FROM Tmp_WPsInUseLast3Years );

            ----------------------------------------------------------
            -- Add new users as DMS_Guest users
            -- We only add users associated with charge codes that have been used in DMS
            ----------------------------------------------------------

            CALL public.auto_add_charge_code_users (
                            _infoOnly   => false,
                            _message    => _message,
                            _returnCode => _returnCode);

            DROP TABLE Tmp_WPsInUseLast3Years;
            DROP TABLE Tmp_WPsExplicit;
            DROP TABLE Tmp_ChargeCode;

            RETURN;
        End If;

        ----------------------------------------------------------
        -- Preview the updates
        ----------------------------------------------------------

        UPDATE Tmp_ChargeCode
        SET Update_Status =
                CASE WHEN target.Deactivated = 'Y' And source.Deactivated = 'N' THEN 'Re-activated Existing WP'
                     WHEN target.Deactivated = 'N' And source.Deactivated = 'Y' THEN 'Deactivated Existing WP'
                     WHEN target.WBS_Title                 IS DISTINCT FROM source.WBS_Title OR
                          target.Charge_Code_Title         IS DISTINCT FROM source.Charge_Code_Title OR
                          target.SubAccount                IS DISTINCT FROM source.SubAccount OR
                          target.SubAccount_Title          IS DISTINCT FROM source.SubAccount_Title OR
                          target.Setup_Date                IS DISTINCT FROM source.Setup_Date OR
                          target.SubAccount_Effective_Date IS DISTINCT FROM source.SubAccount_Effective_Date OR
                          target.Inactive_Date             IS DISTINCT FROM source.Inactive_Date OR
                          target.SubAccount_Inactive_Date  IS DISTINCT FROM source.SubAccount_Inactive_Date OR
                          target.Deactivated               IS DISTINCT FROM source.Deactivated
                          THEN 'Updated Existing CC'
                     ELSE 'Unchanged Existing CC'
                END
        FROM t_charge_code Target
        WHERE Source.charge_code = Target.charge_code;

        UPDATE Tmp_ChargeCode
        SET Update_Status = 'New CC'
        WHERE Update_Status = ''

        SELECT Update_Status,
               New.charge_code,
               Old.resp_username, New.resp_username,
               Old.resp_hid, New.resp_hid,
               Old.wbs_title, New.wbs_title,
               Old.charge_code_title, New.charge_code_title,
               Old.sub_account, New.sub_account,
               Old.sub_account_title, New.sub_account_title,
               Old.setup_date, New.setup_date,
               Old.sub_account_effective_date, New.sub_account_effective_date,
               Old.inactive_date, New.inactive_date,
               Old.sub_account_inactive_date, New.sub_account_inactive_date,
               Old.deactivated, New.deactivated,
               Old.auth_amt, New.auth_amt,
               Old.auth_username, New.auth_username,
               Old.auth_hid, New.auth_hid
        FROM Tmp_ChargeCode New Left Outer Join
             t_charge_code Old
               ON New.charge_code = Old.charge_code
        WHERE _infoOnly And Not _onlyShowChanged OR
              _infoOnly And     _onlyShowChanged AND New.Update_Status NOT LIKE 'Unchanged%'
        ORDER BY New.Update_Status, New.charge_code;

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

    DROP TABLE IF EXISTS Tmp_WPsInUseLast3Years;
    DROP TABLE IF EXISTS Tmp_WPsExplicit;
    DROP TABLE IF EXISTS Tmp_ChargeCode;
END
$$;

COMMENT ON PROCEDURE public.update_charge_codes_from_warehouse IS 'UpdateChargeCodesFromWarehouse';
