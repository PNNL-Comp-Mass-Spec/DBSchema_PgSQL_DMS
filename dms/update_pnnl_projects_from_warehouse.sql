--
-- Name: update_pnnl_projects_from_warehouse(boolean, boolean, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_pnnl_projects_from_warehouse(IN _infoonly boolean DEFAULT false, IN _updateall boolean DEFAULT false, IN _onlyshowchanged boolean DEFAULT false, IN _explicitprojectlist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update PNNL projects in t_pnnl_projects using external server SQLSRVPROD02, which is accessed via foreign data wrapper op_warehouse_fdw
**
**      For details on creating and using op_warehouse_fdw, see procedure update_users_from_warehouse
**
**  Arguments:
**    _infoOnly                 When true, preview updates that would be applied
**    _updateAll                When true, force an update of all rows in t_pnnl_projects; by default, projects are filtered based on Setup_Date
**    _onlyShowChanged          When _infoOnly is true, set this to true to only show new or updated projects
**    _explicitProjectList      Comma-separated list of project numbers to add to t_pnnl_projects regardless of filters; when used, other projects are ignored
**    _message                  Status message
**    _returnCode               Return code
**
**  Example usage:
**      CALL update_pnnl_projects_from_warehouse (_infoOnly => true, _onlyShowChanged => true);
**      CALL update_pnnl_projects_from_warehouse (_infoOnly => true, _onlyShowChanged => false);
**      CALL update_pnnl_projects_from_warehouse (_infoOnly => true, _onlyShowChanged => false, _explicitProjectList => '');
**      CALL update_pnnl_projects_from_warehouse (_infoOnly => false);
**
**  Auth:   mem
**  Date:   09/11/2025 mem - Initial version
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _updateCount int;
    _callingProcName text;
    _currentLocation text := 'Start';

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
    _msg text;
    _currentProject citext;

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

    _explicitProjectList := Trim(Coalesce(_explicitProjectList, ''));

    -- Create a temporary table to keep track of projects in _explicitProjectList

    CREATE TEMP TABLE Tmp_Projects_Explicit (
        Project_Number citext
    );

    CREATE INDEX IX_Tmp_Projects_Explicit ON Tmp_Projects_Explicit (Project_Number);

    BEGIN

        If _explicitProjectList <> '' Then
            INSERT INTO Tmp_Projects_Explicit (Project_Number)
            SELECT Value
            FROM public.parse_delimited_list(_explicitProjectList);
        End If;

        ----------------------------------------------------------
        -- Create a temporary table to track the project information
        -- stored in the data warehouse
        ----------------------------------------------------------

        CREATE TEMP TABLE T_Tmp_PNNL_Projects (
            Project_Number citext NOT NULL,
            Project_Num int4 NULL,
            Setup_Date timestamp(3) NULL,
            Resp_Employee_Id citext NULL,
            Resp_Username citext NULL,
            Resp_Hid citext NULL,
            Resp_Cost_Code citext NULL,
            Project_Title citext NULL,
            Effective_Date timestamp(3) NULL,
            Inactive_Date timestamp(3) NULL,
            Deactivated smallint NULL,
            Deactivated_Date timestamp(3) NULL,
            Invalid smallint NULL,
            Last_Change_Date timestamp(3) NULL,
            Update_Status text NULL
        );

        CREATE INDEX IX_Tmp_PNNL_Projects ON T_Tmp_PNNL_Projects (Project_Number);

        ----------------------------------------------------------
        -- Obtain project info
        --
        -- Note that as of January 2024, in the source view, field RESP_PAY_NO is 'NONE' for people whose username is over 5 characters long (as has been standard for several years now)
        -- The Hanford ID (HID) values are defined, but the username is 'NONE'
        ----------------------------------------------------------

        _currentLocation := 'Query opwhse';

        If Exists (SELECT Project_Number FROM Tmp_Projects_Explicit) Then
            INSERT INTO T_Tmp_PNNL_Projects (
                Project_Number,
                Project_Num,
                Setup_Date,
                Resp_Employee_Id,
                Resp_Username,
                Resp_Hid,
                Resp_Cost_Code,
                Project_Title,
                Effective_Date,
                Inactive_Date,
                Deactivated_Date,
                Deactivated,
                Invalid,
                Last_Change_Date,
                Update_Status
            )
            SELECT Proj."PROJ_NO" AS project_number,
                   public.try_cast(Proj."PROJ_NO", null::int) AS project_num,
                   Proj."SETUP_DATE" AS setup_date,
                   Proj."RESP_EMPLID" AS resp_employee_id,
                   Proj."RESP_PAY_NO" AS resp_username,
                   Proj."RESP_HID" AS resp_hid,
                   Proj."RESP_COST_CD" AS resp_cost_code,
                   Proj."PROJ_TITLE" AS project_title,
                   Proj."EFF_DATE" AS effective_date,
                   Proj."INACT_DATE" AS inactive_date,
                   Proj."DEACT_SW_DATE" AS deactivated_date,
                   CASE Proj."DEACT_SW"     WHEN 'Y' THEN 1 WHEN 'N' THEN 0 ELSE Null END AS deactivated,
                   CASE Proj."INVALID_FLG"  WHEN 'Y' THEN 1 WHEN 'N' THEN 0 ELSE Null END AS invalid,
                   Proj."LAST_CHANGE_DATE" AS last_change_date,
                   '' AS update_status
            FROM pnnldata."VW_PUB_PROJECT" Proj
                 INNER JOIN Tmp_Projects_Explicit
                   ON Upper(Proj."PROJ_NO") = Upper(Tmp_Projects_Explicit.Project_Number);

        Else
            INSERT INTO T_Tmp_PNNL_Projects (
                Project_Number,
                Project_Num,
                Setup_Date,
                Resp_Employee_Id,
                Resp_Username,
                Resp_Hid,
                Resp_Cost_Code,
                Project_Title,
                Effective_Date,
                Inactive_Date,
                Deactivated_Date,
                Deactivated,
                Invalid,
                Last_Change_Date,
                Update_Status
            )
            SELECT Proj."PROJ_NO" AS project_number,
                   public.try_cast(Proj."PROJ_NO", null::int) AS project_num,
                   Proj."SETUP_DATE" AS setup_date,
                   Proj."RESP_EMPLID" AS resp_employee_id,
                   Proj."RESP_PAY_NO" AS resp_username,
                   Proj."RESP_HID" AS resp_hid,
                   Proj."RESP_COST_CD" AS resp_cost_code,
                   Proj."PROJ_TITLE" AS project_title,
                   Proj."EFF_DATE" AS effective_date,
                   Proj."INACT_DATE" AS inactive_date,
                   Proj."DEACT_SW_DATE" AS deactivated_date,
                   CASE Proj."DEACT_SW"     WHEN 'Y' THEN 1 WHEN 'N' THEN 0 ELSE Null END AS deactivated,
                   CASE Proj."INVALID_FLG"  WHEN 'Y' THEN 1 WHEN 'N' THEN 0 ELSE Null END AS invalid,
                   Proj."LAST_CHANGE_DATE" AS last_change_date,
                   '' AS update_status
            FROM pnnldata."VW_PUB_PROJECT" Proj
            WHERE (Proj."SETUP_DATE" >= CURRENT_TIMESTAMP - Interval '4 years')       -- Filter out projects created over 4 years ago
                  OR
                  (Proj."SETUP_DATE" >= CURRENT_TIMESTAMP - Interval '15 years' AND   -- Include active projects created within the last 15 years
                   Proj."DEACT_SW" = 'N')
                  OR
                  (Proj."SETUP_DATE" >= CURRENT_TIMESTAMP - Interval '2 years' AND    -- Filter on projects created in the last 2 years
                   Proj."RESP_HID" IN (                                               -- where the responsible person is an active DMS user
                          SELECT hid_number
                          FROM t_users
                          WHERE status = 'Active')
                  )
                  OR
                  (_updateAll AND Upper(Proj."PROJ_NO") IN (SELECT Upper(project_number) FROM t_pnnl_projects));
        End If;

        If Not _infoOnly Then
            ----------------------------------------------------------
            -- Merge new/updated projects
            ----------------------------------------------------------

            _currentLocation := 'Merge data';

            SELECT COUNT(Project_Number)
            INTO _countBeforeMerge
            FROM t_pnnl_projects;

            MERGE INTO t_pnnl_projects AS Target
            USING (SELECT Project_Number, Project_Num, Setup_Date, Resp_Employee_Id, Resp_Username, Resp_Hid, Resp_Cost_Code,
                          Project_Title, Effective_Date, Inactive_Date, Deactivated, Deactivated_Date, Invalid, Last_Change_Date
                   FROM T_Tmp_PNNL_Projects
                  ) AS Source
            ON (target.Project_Number = source.Project_Number)
            WHEN MATCHED AND
                 (target.project_number   IS DISTINCT FROM source.project_number OR
                  target.project_num      IS DISTINCT FROM source.project_num OR
                  target.setup_date       IS DISTINCT FROM source.setup_date OR
                  target.resp_employee_id IS DISTINCT FROM source.resp_employee_id OR
                  target.resp_username    IS DISTINCT FROM source.resp_username OR
                  target.resp_hid         IS DISTINCT FROM source.resp_hid OR
                  target.resp_cost_code   IS DISTINCT FROM source.resp_cost_code OR
                  target.project_title    IS DISTINCT FROM source.project_title OR
                  target.effective_date   IS DISTINCT FROM source.effective_date OR
                  target.inactive_date    IS DISTINCT FROM source.inactive_date OR
                  target.deactivated      IS DISTINCT FROM source.deactivated OR
                  target.deactivated_date IS DISTINCT FROM source.deactivated_date OR
                  target.invalid          IS DISTINCT FROM source.invalid OR
                  target.last_change_date IS DISTINCT FROM source.last_change_date
                )
            THEN UPDATE SET
                    project_number   = source.project_number,
                    project_num      = source.project_num,
                    setup_date       = source.setup_date,
                    resp_employee_id = source.resp_employee_id,
                    resp_username    = source.resp_username,
                    resp_hid         = source.resp_hid,
                    resp_cost_code   = source.resp_cost_code,
                    project_title    = source.project_title,
                    effective_date   = source.effective_date,
                    inactive_date    = source.inactive_date,
                    deactivated      = source.deactivated,
                    deactivated_date = source.deactivated_date,
                    invalid          = source.invalid,
                    last_change_date = source.last_change_date,
                    last_affected    = CURRENT_TIMESTAMP
            WHEN NOT MATCHED
                THEN INSERT (Project_Number, Project_Num, Setup_Date, Resp_Employee_Id, Resp_Username, Resp_Hid, Resp_Cost_Code,
                             Project_Title, Effective_Date, Inactive_Date, Deactivated, Deactivated_Date, Invalid, Last_Change_Date, last_affected)
                     VALUES (source.Project_Number, source.Project_Num, source.Setup_Date, source.Resp_Employee_Id, source.Resp_Username, source.Resp_Hid, source.Resp_Cost_Code,
                             source.Project_Title, source.Effective_Date, source.Inactive_Date, source.Deactivated, source.Deactivated_Date, source.Invalid, source.Last_Change_Date,
                             CURRENT_TIMESTAMP
                            );

            GET DIAGNOSTICS _mergeCount = ROW_COUNT;

            SELECT COUNT(Project_Number)
            INTO _countAfterMerge
            FROM t_pnnl_projects;

            _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

            If _mergeCount > 0 Then
                _mergeUpdateCount := _mergeCount - _mergeInsertCount;
            Else
                _mergeUpdateCount := 0;
            End If;

            If _mergeUpdateCount > 0 Or _mergeInsertCount > 0 Then
                _message := format('Updated t_pnnl_projects: %s added, %s updated', _mergeInsertCount, _mergeUpdateCount);

                CALL post_log_entry ('Normal', _message, 'update_pnnl_projects_from_warehouse');

                _message := '';
            End If;

            DROP TABLE Tmp_Projects_Explicit;
            DROP TABLE T_Tmp_PNNL_Projects;

            RETURN;
        End If;

        ----------------------------------------------------------
        -- Preview the updates
        ----------------------------------------------------------

        UPDATE T_Tmp_PNNL_Projects target
        SET Update_Status =
                CASE WHEN source.Deactivated > 0 And Coalesce(target.Deactivated, 0) = 0 THEN 'Re-activated existing project'
                     WHEN Coalesce(source.Deactivated, 0) = 0 And target.Deactivated > 0 THEN 'Deactivated existing project'
                     WHEN source.Setup_Date            IS DISTINCT FROM target.Setup_Date OR
                          source.Resp_Employee_Id      IS DISTINCT FROM target.Resp_Employee_Id OR
                          source.Resp_Username         IS DISTINCT FROM target.Resp_Username OR
                          source.Resp_Hid              IS DISTINCT FROM target.Resp_Hid OR
                          source.Resp_Cost_Code        IS DISTINCT FROM target.Resp_Cost_Code OR
                          source.Project_Title         IS DISTINCT FROM target.Project_Title OR
                          source.Effective_Date        IS DISTINCT FROM target.Effective_Date OR
                          source.Inactive_Date         IS DISTINCT FROM target.Inactive_Date OR
                          source.Deactivated           IS DISTINCT FROM target.Deactivated OR
                          source.Deactivated_Date      IS DISTINCT FROM target.Deactivated_Date OR
                          source.Invalid               IS DISTINCT FROM target.Invalid
                          THEN 'Updated existing project'
                     ELSE 'Unchanged existing project'
                END
        FROM t_pnnl_projects source
        WHERE target.Project_Number = source.Project_Number;

        UPDATE T_Tmp_PNNL_Projects
        SET Update_Status = 'New project'
        WHERE Update_Status = '';

        RAISE INFO '';

        _formatSpecifier := '%-30s %-14s %-14s %-14s %-20s %-20s %-17s %-17s %-12s %-12s %-18s %-18s %-50s %-50s %-18s %-18s %-17s %-17s %-15s %-15s %-20s %-20s %-11s %-11s';

        _infoHead := format(_formatSpecifier,
                            'Update_Status',
                            'Project_Number',
                            'Setup_Date_Old',
                            'Setup_Date_New',
                            'Resp_Employee_Id_Old',
                            'Resp_Employee_Id_New',
                            'Resp_Username_Old',
                            'Resp_Username_New',
                            'Resp_Hid_Old',
                            'Resp_Hid_New',
                            'Resp_Cost_Code_Old',
                            'Resp_Cost_Code_New',
                            'Project_Title_Old',
                            'Project_Title_New',
                            'Effective_Date_Old',
                            'Effective_Date_New',
                            'Inactive_Date_Old',
                            'Inactive_Date_New',
                            'Deactivated_Old',
                            'Deactivated_New',
                            'Deactivated_Date_Old',
                            'Deactivated_Date_New',
                            'Invalid_Old',
                            'Invalid_New'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------------------------',
                                     '--------------',
                                     '--------------',
                                     '--------------',
                                     '--------------------',
                                     '--------------------',
                                     '-----------------',
                                     '-----------------',
                                     '------------',
                                     '------------',
                                     '------------------',
                                     '------------------',
                                     '--------------------------------------------------',
                                     '--------------------------------------------------',
                                     '------------------',
                                     '------------------',
                                     '-----------------',
                                     '-----------------',
                                     '---------------',
                                     '---------------',
                                     '--------------------',
                                     '--------------------',
                                     '-----------',
                                     '-----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Update_Status,
                   New.Project_Number,
                   Old.Setup_Date::date AS Setup_Date_old,             New.Setup_Date::date AS Setup_Date_new,
                   Old.Resp_Employee_Id AS Resp_Employee_Id_old,       New.Resp_Employee_Id AS Resp_Employee_Id_new,
                   Old.Resp_Username AS Resp_Username_old,             New.Resp_Username AS Resp_Username_new,
                   Old.Resp_Hid AS Resp_Hid_old,                       New.Resp_Hid AS Resp_Hid_new,
                   Old.Resp_Cost_Code AS Resp_Cost_Code_old,           New.Resp_Cost_Code AS Resp_Cost_Code_new,
                   Left(Old.Project_Title, 50) AS Project_Title_old,   Left(New.Project_Title, 50) AS Project_Title_new,
                   Old.Effective_Date ::date AS Effective_Date_old,    New.Effective_Date::date AS Effective_Date_new,
                   Old.Inactive_Date::date AS Inactive_Date_old,       New.Inactive_Date::date AS Inactive_Date_new,
                   Old.Deactivated AS Deactivated_old,                 New.Deactivated AS Deactivated_new,
                   Old.Deactivated_Date::date AS Deactivated_Date_old, New.Deactivated_Date::date AS Deactivated_Date_new,
                   Old.Invalid AS Invalid_old,                         New.Invalid AS Invalid_new
            FROM T_Tmp_PNNL_Projects New LEFT OUTER JOIN
                 t_pnnl_projects Old
                   ON New.Project_Number = Old.Project_Number
            WHERE _infoOnly AND NOT _onlyShowChanged OR
                  _infoOnly AND     _onlyShowChanged AND New.Update_Status NOT LIKE 'Unchanged%'
            ORDER BY New.Update_Status, New.Project_Number
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Update_Status,
                                _previewData.Project_Number,
                                _previewData.Setup_Date_Old,
                                _previewData.Setup_Date_New,
                                _previewData.Resp_Employee_Id_Old,
                                _previewData.Resp_Employee_Id_New,
                                _previewData.Resp_Username_Old,
                                _previewData.Resp_Username_New,
                                _previewData.Resp_Hid_Old,
                                _previewData.Resp_Hid_New,
                                _previewData.Resp_Cost_Code_Old,
                                _previewData.Resp_Cost_Code_New,
                                _previewData.Project_Title_Old,
                                _previewData.Project_Title_New,
                                _previewData.Effective_Date_Old,
                                _previewData.Effective_Date_New,
                                _previewData.Inactive_Date_Old,
                                _previewData.Inactive_Date_New,
                                _previewData.Deactivated_Old,
                                _previewData.Deactivated_New,
                                _previewData.Deactivated_Date_Old,
                                _previewData.Deactivated_Date_New,
                                _previewData.Invalid_Old,
                                _previewData.Invalid_New
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Projects_Explicit;
        DROP TABLE T_Tmp_PNNL_Projects;

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

    DROP TABLE IF EXISTS Tmp_Projects_Explicit;
    DROP TABLE IF EXISTS T_Tmp_PNNL_Projects;
END
$$;


ALTER PROCEDURE public.update_pnnl_projects_from_warehouse(IN _infoonly boolean, IN _updateall boolean, IN _onlyshowchanged boolean, IN _explicitprojectlist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_pnnl_projects_from_warehouse(IN _infoonly boolean, IN _updateall boolean, IN _onlyshowchanged boolean, IN _explicitprojectlist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_pnnl_projects_from_warehouse(IN _infoonly boolean, IN _updateall boolean, IN _onlyshowchanged boolean, IN _explicitprojectlist text, INOUT _message text, INOUT _returncode text) IS 'UpdatePNNLProjectsFromWarehouse';

