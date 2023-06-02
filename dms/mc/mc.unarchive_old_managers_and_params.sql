--
-- Name: unarchive_old_managers_and_params(text, boolean, boolean); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.unarchive_old_managers_and_params(_mgrlist text, _infoonly boolean DEFAULT true, _enablecontrolfromwebsite boolean DEFAULT false) RETURNS TABLE(message text, mgr_name public.citext, control_from_website smallint, manager_type_id integer, param_name public.citext, entry_id integer, param_type_id integer, param_value public.citext, mgr_id integer, comment public.citext, last_affected timestamp without time zone, entered_by public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Moves managers from mc.t_old_managers to mc.t_mgrs and
**      moves manager parameters from mc.t_param_value_old_managers to mc.t_param_value
**
**      See also procedure mc.archive_old_managers_and_params
**
**  Arguments:
**    _mgrList                    One or more manager names (comma-separated list); supports wildcards because uses stored procedure Parse_Manager_Name_List
**    _infoOnly                   False to perform the update, true to preview
**    _enableControlFromWebsite   If true, set control_from_website to 1 when storing the manager info in mc.t_mgrs
**
**  Example usage:
**
**      SELECT * FROM mc.unarchive_old_managers_and_params('Pub-10-1', _infoOnly => true,  _enableControlFromWebsite => true);
**      SELECT * FROM mc.unarchive_old_managers_and_params('Pub-10-1', _infoOnly => false, _enableControlFromWebsite => true);
**      SELECT * FROM mc.t_mgrs WHERE mgr_name = 'pub-10-1';
**
**  Auth:   mem
**  Date:   02/25/2016 mem - Initial version
**          04/22/2016 mem - Now updating M_Comment in mc.t_mgrs
**          01/29/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**          03/23/2022 mem - Remove check for "control_from_web > 0" in delete query
**                         - Abort restore if the manager already exists in mc.t_mgrs
**                         - Use mc schema when calling Parse_Manager_Name_List
**          04/16/2022 mem - Use new procedure name
**          08/20/2022 mem - Update warnings shown when an exception occurs
**                         - Drop temp tables before exiting the function
**          08/21/2022 mem - Parse manager names using function parse_manager_name_list
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _infoOnly and _enableControlFromWebsite from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**          05/12/2023 mem - Rename variables
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _message text;
    _newSeqValue int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _mgrList := Coalesce(_mgrList, '');
    _infoOnly := Coalesce(_infoOnly, true);
    _enableControlFromWebsite := Coalesce(_enableControlFromWebsite, true);

    CREATE TEMP TABLE Tmp_ManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL,
        control_from_web smallint null
    );

    CREATE TEMP TABLE Tmp_WarningMessages (
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        message text,
        manager_name citext
    );

    ---------------------------------------------------
    -- Populate Tmp_ManagerList with the managers in _mgrList
    -- Setting _remove_unknown_managers to 0 so that this procedure can be called repeatedly without raising an error
    ---------------------------------------------------
    --
    INSERT INTO Tmp_ManagerList (manager_name)
    SELECT manager_name
    FROM mc.parse_manager_name_list (_mgrList, _remove_unknown_managers => 0);

    If Not FOUND Then
        _message := '_mgrList did not match any managers in mc.t_mgrs: ';
        Raise Info 'Warning: %', _message;

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
        DROP TABLE Tmp_WarningMessages;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate the manager names
    ---------------------------------------------------

    UPDATE Tmp_ManagerList
    SET mgr_id = M.mgr_id,
        control_from_web = CASE WHEN _enableControlFromWebsite THEN 1 ELSE 0 END
    FROM mc.t_old_managers M
    WHERE Tmp_ManagerList.Manager_Name = M.mgr_name;

    If Exists (SELECT * FROM Tmp_ManagerList MgrList WHERE MgrList.mgr_id Is Null) Then
        INSERT INTO Tmp_WarningMessages (message, manager_name)
        SELECT 'Unknown manager (not in mc.t_old_managers)',
               MgrList.manager_name
        FROM Tmp_ManagerList MgrList
        WHERE MgrList.mgr_id Is Null
        ORDER BY MgrList.manager_name;
    End If;

    If Exists (SELECT * FROM Tmp_ManagerList MgrList WHERE MgrList.manager_name ILike '%Params%') Then
        INSERT INTO Tmp_WarningMessages (message, manager_name)
        SELECT 'Will not process managers with "Params" in the name (for safety)',
               MgrList.manager_name
        FROM Tmp_ManagerList MgrList
        WHERE MgrList.manager_name ILike '%Params%'
        ORDER BY MgrList.manager_name;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM Tmp_WarningMessages WarnMsgs);
    End If;

    DELETE FROM Tmp_ManagerList
    WHERE Tmp_ManagerList.mgr_id Is Null;

    If Exists (SELECT * FROM Tmp_ManagerList Src INNER JOIN mc.t_mgrs Target ON Src.Manager_Name = Target.mgr_name) Then
        INSERT INTO Tmp_WarningMessages (message, manager_name)
        SELECT format('Manager already exists in t_mgrs with Mgr_Name %s; cannot restore', Target.mgr_name),
               manager_name
        FROM Tmp_ManagerList Src
             INNER JOIN mc.t_old_managers Target
               ON Src.Manager_Name = Target.mgr_name;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM Tmp_WarningMessages WarnMsgs);
    End If;

    If Exists (SELECT * FROM Tmp_ManagerList Src INNER JOIN mc.t_mgrs Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO Tmp_WarningMessages (message, manager_name)
        SELECT format('Manager already exists in t_mgrs with Mgr_ID %s; cannot restore', Target.mgr_id),
               manager_name
        FROM Tmp_ManagerList Src
             INNER JOIN mc.t_old_managers Target
               ON Src.mgr_id = Target.mgr_id;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM Tmp_WarningMessages WarnMsgs);
    End If;

    If Exists (SELECT * FROM Tmp_ManagerList Src INNER JOIN mc.t_param_value Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO Tmp_WarningMessages (message, manager_name)
        SELECT format('Manager already has parameters in mc.t_param_value with Mgr_ID %s; cannot restore', Src.mgr_id),
               manager_name
        FROM Tmp_ManagerList Src
             INNER JOIN mc.t_param_value_old_managers Target
               ON Src.mgr_id = Target.mgr_id;

        DELETE FROM Tmp_ManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM Tmp_WarningMessages WarnMsgs);
    End If;

    If _infoOnly OR NOT EXISTS (SELECT * FROM Tmp_ManagerList) Then
        RETURN QUERY
        SELECT ' To be restored' as message,
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
             LEFT OUTER JOIN mc.v_old_param_value PV
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
        FROM Tmp_WarningMessages WarnMsgs
        ORDER BY message ASC, manager_name, param_name;

        DROP TABLE Tmp_ManagerList;
        DROP TABLE Tmp_WarningMessages;

        RETURN;
    End If;

    RAISE Info 'Insert into t_mgrs';

    INSERT INTO mc.t_mgrs (
                         mgr_id,
                         mgr_name,
                         mgr_type_id,
                         param_value_changed,
                         control_from_website,
                         comment )
    OVERRIDING SYSTEM VALUE
    SELECT M.mgr_id,
           M.mgr_name,
           M.mgr_type_id,
           M.param_value_changed,
           Src.control_from_web,
           M.comment
    FROM mc.t_old_managers M
         INNER JOIN Tmp_ManagerList Src
           ON M.mgr_id = Src.mgr_id;

    -- Set the manager ID sequence's current value to the maximum manager ID
    --
    SELECT MAX(mc.t_mgrs.mgr_id)
    INTO _newSeqValue
    FROM mc.t_mgrs;

    PERFORM setval('mc.t_mgrs_mgr_id_seq', _newSeqValue);
    RAISE INFO 'Sequence mc.t_mgrs_mgr_id_seq set to %', _newSeqValue;

    RAISE Info 'Insert into t_param_value';

    INSERT INTO mc.t_param_value (
             entry_id,
             param_type_id,
             value,
             mgr_id,
             comment,
             last_affected,
             entered_by )
    OVERRIDING SYSTEM VALUE
    SELECT PV.entry_id,
           PV.param_type_id,
           PV.value,
           PV.mgr_id,
           PV.comment,
           PV.last_affected,
           PV.entered_by
    FROM mc.t_param_value_old_managers PV
    WHERE PV.entry_id IN ( SELECT Max(PV.entry_ID)
                           FROM mc.t_param_value_old_managers PV
                                INNER JOIN Tmp_ManagerList Src
                                  ON PV.mgr_id = Src.mgr_id
                           GROUP BY PV.mgr_id, PV.param_type_id
                         );

    -- Set the entry_id sequence's current value to the maximum entry_id
    --
    SELECT MAX(PV.entry_id)
    INTO _newSeqValue
    FROM mc.t_param_value PV;

    PERFORM setval('mc.t_param_value_entry_id_seq', _newSeqValue);
    RAISE INFO 'Sequence mc.t_param_value_entry_id_seq set to %', _newSeqValue;

    DELETE FROM mc.t_param_value_old_managers
    WHERE mc.t_param_value_old_managers.mgr_id IN (SELECT MgrList.mgr_id FROM Tmp_ManagerList MgrList);

    DELETE FROM mc.t_old_managers
    WHERE mc.t_old_managers.mgr_id IN (SELECT MgrList.mgr_id FROM Tmp_ManagerList MgrList);

    RAISE Info 'Restore succeeded; returning results';

    RETURN QUERY
    SELECT 'Moved to mc.t_mgrs and mc.t_param_value' as Message,
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
    ORDER BY Src.Manager_Name, param_name;

    DROP TABLE Tmp_ManagerList;
    DROP TABLE Tmp_WarningMessages;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
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
    DROP TABLE IF EXISTS Tmp_WarningMessages;
END
$$;


ALTER FUNCTION mc.unarchive_old_managers_and_params(_mgrlist text, _infoonly boolean, _enablecontrolfromwebsite boolean) OWNER TO d3l243;

--
-- Name: FUNCTION unarchive_old_managers_and_params(_mgrlist text, _infoonly boolean, _enablecontrolfromwebsite boolean); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.unarchive_old_managers_and_params(_mgrlist text, _infoonly boolean, _enablecontrolfromwebsite boolean) IS 'UnarchiveOldManagersAndParams';

