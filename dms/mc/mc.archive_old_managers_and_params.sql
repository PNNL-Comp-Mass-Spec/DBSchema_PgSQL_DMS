--
-- Name: archive_old_managers_and_params(text, boolean); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.archive_old_managers_and_params(_mgrlist text, _infoonly boolean DEFAULT true) RETURNS TABLE(message text, mgr_name public.citext, control_from_website smallint, manager_type_id integer, param_name public.citext, entry_id integer, param_type_id integer, param_value public.citext, mgr_id integer, comment public.citext, last_affected timestamp without time zone, entered_by public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move managers from mc.t_mgrs to mc.t_old_managers and
**      move manager parameters from mc.t_param_value to mc.t_param_value_old_managers
**
**  Arguments:
**    _mgrList    One or more manager names (comma-separated list); supports wildcards
**    _infoOnly   False to perform the update, true to preview
**
**  Example usage:
**
**      UPDATE mc.t_mgrs
**      SET control_from_website = 0
**      WHERE mgr_name = 'pub-10-1' AND control_from_website > 0;
**
**      SELECT * FROM mc.archive_old_managers_and_params('Pub-10-1', _infoOnly => true);
**
**      SELECT * FROM mc.archive_old_managers_and_params('Pub-10-1', _infoOnly => false);
**
**      -- To re-add the manager to t_mgrs, use function mc.unarchive_old_managers_and_params
**      SELECT * FROM mc.unarchive_old_managers_and_params('Pub-10-1', _infoOnly => true,  _enableControlFromWebsite => true);
**      SELECT * FROM mc.unarchive_old_managers_and_params('Pub-10-1', _infoOnly => false, _enableControlFromWebsite => true);
**      SELECT * FROM mc.t_mgrs WHERE mgr_name = 'pub-10-1';
**
**  Auth:   mem
**  Date:   05/14/2015 mem - Initial version
**          02/25/2016 mem - Add Set XACT_ABORT On
**          04/22/2016 mem - Now updating M_Comment in mc.t_old_managers
**          01/29/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**          03/23/2022 mem - Use mc schema when calling Parse_Manager_Name_List
**          04/02/2022 mem - Use new procedure name
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp tables before exiting the function
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**          05/12/2023 mem - Rename variables
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          02/15/2024 mem - Rename temporary table
**
*****************************************************/
DECLARE
    _message text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrList  := Trim(Coalesce(_mgrList, ''));
    _infoOnly := Coalesce(_infoOnly, true);

    CREATE TEMP TABLE Tmp_ManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL,
        control_from_web smallint NULL
    );

    CREATE TEMP TABLE TmpWarningMessages (
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        message text,
        manager_name citext
    );

    ---------------------------------------------------
    -- Populate Tmp_ManagerList with the managers in _mgrList
    -- Setting _remove_unknown_managers to 0 so that this procedure can be called repeatedly without raising an error
    ---------------------------------------------------

    INSERT INTO Tmp_ManagerList (manager_name)
    SELECT manager_name
    FROM mc.parse_manager_name_list (_mgrList, _remove_unknown_managers => 0);

    If Not Exists (SELECT * FROM Tmp_ManagerList) Then
        _message := '_mgrList did not match any managers in mc.t_mgrs: ';
        RAISE INFO 'Warning: %', _message;

        RETURN QUERY
        SELECT '_mgrList did not match any managers in mc.t_mgrs' as Message,
               _mgrList::citext as manager_name,
               0::smallint as control_from_website,
               0 as manager_type_id,
               ''::citext as param_name,
               0 as entry_id,
               0 as param_type_id,
               ''::citext as value,
               0 as mgr_id,
               ''::citext as comment,
               current_timestamp::timestamp as last_affected,
               ''::citext as entered_by;

        DROP TABLE Tmp_ManagerList;
        DROP TABLE TmpWarningMessages;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate the manager names
    ---------------------------------------------------

    UPDATE Tmp_ManagerList
    SET mgr_id = M.mgr_id,
        control_from_web = M.control_from_website
    FROM mc.t_mgrs M
    WHERE Tmp_ManagerList.Manager_Name = M.mgr_name;

    If Exists (SELECT * FROM Tmp_ManagerList MgrList WHERE MgrList.mgr_id IS NULL) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Unknown manager (not in mc.t_mgrs)',
               MgrList.manager_name
        FROM Tmp_ManagerList MgrList
        WHERE MgrList.mgr_id IS NULL
        ORDER BY MgrList.manager_name;
    End If;

    If Exists (SELECT * FROM Tmp_ManagerList MgrList WHERE NOT MgrList.mgr_id IS NULL AND MgrList.control_from_web > 0) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Manager has control_from_website=1; cannot archive',
               MgrList.manager_name
        FROM Tmp_ManagerList MgrList
        WHERE NOT MgrList.mgr_id IS NULL AND MgrList.control_from_web > 0
        ORDER BY MgrList.manager_name;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs WHERE NOT WarnMsgs.message ILIKE 'Note:%');
    End If;

    If Exists (SELECT manager_name FROM Tmp_ManagerList WHERE manager_name ILIKE '%Params%') Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Will not process managers with "Params" in the name (for safety)',
               manager_name
        FROM Tmp_ManagerList
        WHERE manager_name ILIKE '%Params%'
        ORDER BY manager_name;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs WHERE NOT WarnMsgs.message ILIKE 'Note:%');
    End If;

    DELETE FROM Tmp_ManagerList
    WHERE Tmp_ManagerList.mgr_id IS NULL OR
          Tmp_ManagerList.control_from_web > 0;

    If Exists (SELECT * FROM Tmp_ManagerList Src INNER JOIN mc.t_old_managers Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Manager already exists in t_old_managers; cannot archive',
               manager_name
        FROM Tmp_ManagerList Src
             INNER JOIN mc.t_old_managers Target
               ON Src.mgr_id = Target.mgr_id;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs WHERE NOT WarnMsgs.message ILIKE 'Note:%');
    End If;

    If Exists (SELECT * FROM Tmp_ManagerList Src INNER JOIN mc.t_param_value_old_managers Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Note: manager already has parameters in t_param_value_old_managers; will merge values from t_param_value',
               manager_name
        FROM Tmp_ManagerList Src
             INNER JOIN mc.t_param_value_old_managers Target
               ON Src.mgr_id = Target.mgr_id;
    End If;

    If _infoOnly Or Not Exists (SELECT * FROM Tmp_ManagerList) Then
        RETURN QUERY
        SELECT ' To be archived' as message,
               Src.manager_name,
               Src.control_from_web,
               PV.mgr_type_id,
               PV.param_name,
               PV.Entry_ID,
               PV.param_type_id,
               PV.Value,
               PV.mgr_id,
               PV.Comment,
               PV.Last_Affected,
               PV.Entered_By
        FROM Tmp_ManagerList Src
             LEFT OUTER JOIN mc.v_param_value PV
               ON PV.mgr_id = Src.mgr_id
        UNION
        SELECT WarnMsgs.message,
               WarnMsgs.manager_name,
               0::smallint as control_from_website,
               0 as manager_type_id,
               ''::citext as param_name,
               0 as entry_id,
               0 as param_type_id,
               ''::citext as value,
               0 as mgr_id,
               ''::citext as comment,
               current_timestamp::timestamp as last_affected,
               ''::citext as entered_by
        FROM TmpWarningMessages WarnMsgs
        ORDER BY message ASC, manager_name, param_name;

        DROP TABLE Tmp_ManagerList;
        DROP TABLE TmpWarningMessages;
        RETURN;
    End If;

    RAISE INFO 'Insert into t_old_managers';

    INSERT INTO mc.t_old_managers (
        mgr_id,
        mgr_name,
        mgr_type_id,
        param_value_changed,
        control_from_website,
        comment
    )
    SELECT M.mgr_id,
           M.mgr_name,
           M.mgr_type_id,
           M.param_value_changed,
           M.control_from_website,
           M.comment
    FROM mc.t_mgrs M
         INNER JOIN Tmp_ManagerList Src
           ON M.mgr_id = Src.mgr_id
      LEFT OUTER JOIN mc.t_old_managers Target
           ON Src.mgr_id = Target.mgr_id
    WHERE Target.mgr_id IS NULL;

    RAISE INFO 'Insert into t_param_value_old_managers';

    -- The following query uses
    --   ON CONFLICT ON CONSTRAINT pk_t_param_value_old_managers
    -- instead of
    --   ON CONFLICT (entry_id)
    -- to avoid an ambiguous name error with the entry_id field
    -- returned by this function

    INSERT INTO mc.t_param_value_old_managers (
        entry_id,
        param_type_id,
        value,
        mgr_id,
        comment,
        last_affected,
        entered_by
    )
    SELECT PV.entry_id,
           PV.param_type_id,
           PV.value,
           PV.mgr_id,
           PV.comment,
           PV.last_affected,
           PV.entered_by
    FROM mc.t_param_value PV
         INNER JOIN Tmp_ManagerList Src
           ON PV.mgr_id = Src.mgr_id
   ON CONFLICT ON CONSTRAINT pk_t_param_value_old_managers
   DO UPDATE SET
        param_type_id = EXCLUDED.param_type_id,
        value = EXCLUDED.value,
        mgr_id = EXCLUDED.mgr_id,
        comment = EXCLUDED.comment,
        last_affected = EXCLUDED.last_affected,
        entered_by = EXCLUDED.entered_by;

    RAISE INFO 'Delete from mc.t_param_value';

    DELETE FROM mc.t_param_value target
    WHERE target.mgr_id IN (SELECT MgrList.mgr_id FROM Tmp_ManagerList MgrList);

    RAISE INFO 'Delete from mc.t_mgrs';

    DELETE FROM mc.t_mgrs target
    WHERE target.mgr_id IN (SELECT MgrList.mgr_id FROM Tmp_ManagerList MgrList);

    RAISE INFO 'Delete succeeded; returning results';

    RETURN QUERY
    SELECT 'Moved to mc.t_old_managers and mc.t_param_value_old_managers' as Message,
           Src.Manager_Name,
           Src.control_from_web,
           OldMgrs.mgr_type_id,
           PT.param_name,
           PV.entry_id,
           PV.param_type_id,
           PV.value,
           PV.mgr_id,
           PV.comment,
           PV.last_affected,
           PV.entered_by
    FROM Tmp_ManagerList Src
         LEFT OUTER JOIN mc.t_old_managers OldMgrs
           ON OldMgrs.mgr_id = Src.mgr_id
         LEFT OUTER JOIN mc.t_param_value_old_managers PV
           ON PV.mgr_id = Src.mgr_id
         LEFT OUTER JOIN mc.t_param_type PT ON
         PV.param_type_id = PT.param_type_id
    ORDER BY Src.manager_name, param_name;

    DROP TABLE Tmp_ManagerList;
    DROP TABLE TmpWarningMessages;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    format('archive manager parameters for %s', _mgrList),
                    _logError => true);

    RETURN QUERY
    SELECT _message as Message,
           ''::citext as Manager_Name,
           0::smallint as control_from_website,
           0 as manager_type_id,
           ''::citext as param_name,
           0 as entry_id,
           0 as param_type_id,
           ''::citext as value,
           0 as mgr_id,
           ''::citext as comment,
           current_timestamp::timestamp as last_affected,
           ''::citext as entered_by;

    DROP TABLE IF EXISTS Tmp_ManagerList;
    DROP TABLE IF EXISTS TmpWarningMessages;
END
$$;


ALTER FUNCTION mc.archive_old_managers_and_params(_mgrlist text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION archive_old_managers_and_params(_mgrlist text, _infoonly boolean); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.archive_old_managers_and_params(_mgrlist text, _infoonly boolean) IS 'ArchiveOldManagersAndParams';

