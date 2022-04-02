--
-- Name: archive_old_managers_and_params(text, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.archive_old_managers_and_params(_mgrlist text, _infoonly integer DEFAULT 1) RETURNS TABLE(message text, mgr_name public.citext, control_from_website smallint, manager_type_id integer, param_name public.citext, entry_id integer, param_type_id integer, param_value public.citext, mgr_id integer, comment public.citext, last_affected timestamp without time zone, entered_by public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Moves managers from mc.t_mgrs to mc.t_old_managers and
**      moves manager parameters from mc.t_param_value to mc.t_param_value_old_managers
**
**      To reverse this process, use Function mc.unarchive_old_managers_and_params
**      Select * from mc.unarchive_old_managers_and_params('Pub-10-1', _infoOnly := 1, _enableControlFromWebsite := 0)
**
**  Arguments:
**    _mgrList    One or more manager names (comma-separated list); supports wildcards because uses stored procedure parse_manager_name_list
**    _infoonly   0 to perform the update, 1 to preview
**
**  Auth:   mem
**  Date:   05/14/2015 mem - Initial version
**          02/25/2016 mem - Add Set XACT_ABORT On
**          04/22/2016 mem - Now updating M_Comment in mc.t_old_managers
**          01/29/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**          03/23/2022 mem - Use mc schema when calling ParseManagerNameList
**          04/02/2022 mem - Use new procedure name
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _mgrList := Coalesce(_mgrList, '');
    _infoOnly := Coalesce(_infoOnly, 1);

    DROP TABLE IF EXISTS TmpManagerList;
    DROP TABLE IF EXISTS TmpWarningMessages;

    CREATE TEMP TABLE TmpManagerList (
        manager_name citext NOT NULL,
        mgr_id int NULL,
        control_from_web smallint null
    );

    CREATE TEMP TABLE TmpWarningMessages (
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        message text,
        manager_name citext
    );

    ---------------------------------------------------
    -- Populate TmpManagerList with the managers in _mgrList
    -- Setting _removeUnknownManagers to 0 so that this procedure can be called repeatedly without raising an error
    ---------------------------------------------------
    --
    Call mc.parse_manager_name_list (_mgrList, _removeUnknownManagers => 0, _message => _message);

    If Not Exists (Select * from TmpManagerList) Then
        _message := '_mgrList did not match any managers in mc.t_mgrs: ';
        Raise Info 'Warning: %', _message;

        RETURN QUERY
        SELECT '_mgrList did not match any managers in mc.t_mgrs' as Message,
               _mgrList::citext as manager_name,
               0::smallint as control_from_website,
               0 as manager_type_id,
               ''::citext as param_name,
               0 as entry_id,
               0 as type_id,
               ''::citext as value,
               0 as mgr_id,
               ''::citext as comment,
               current_timestamp::timestamp as last_affected,
               ''::citext as entered_by;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate the manager names
    ---------------------------------------------------

    UPDATE TmpManagerList
    SET mgr_id = M.mgr_id,
        control_from_web = M.control_from_website
    FROM mc.t_mgrs M
    WHERE TmpManagerList.Manager_Name = M.mgr_name;

    If Exists (Select * from TmpManagerList MgrList WHERE MgrList.mgr_id Is Null) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Unknown manager (not in mc.t_mgrs)',
               MgrList.manager_name
        FROM TmpManagerList MgrList
        WHERE MgrList.mgr_id Is Null
        ORDER BY MgrList.manager_name;
    End If;

    If Exists (Select * from TmpManagerList MgrList WHERE NOT MgrList.mgr_id is Null And MgrList.control_from_web > 0) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Manager has control_from_website=1; cannot archive',
               MgrList.manager_name
        FROM TmpManagerList  MgrList
        WHERE NOT MgrList.mgr_id IS NULL And MgrList.control_from_web > 0
        ORDER BY MgrList.manager_name;

        DELETE FROM TmpManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs WHERE NOT WarnMsgs.message ILIKE 'Note:%');
    End If;

    If Exists (Select * From TmpManagerList Where manager_name ILike '%Params%') Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Will not process managers with "Params" in the name (for safety)',
               manager_name
        FROM TmpManagerList
        WHERE manager_name ILike '%Params%'
        ORDER BY manager_name;

        DELETE FROM TmpManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs WHERE NOT WarnMsgs.message ILIKE 'Note:%');
    End If;

    DELETE FROM TmpManagerList
    WHERE TmpManagerList.mgr_id Is Null OR
          TmpManagerList.control_from_web > 0;

    If Exists (Select * From TmpManagerList Src INNER JOIN mc.t_old_managers Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Manager already exists in t_old_managers; cannot archive',
               manager_name
        FROM TmpManagerList Src
             INNER JOIN mc.t_old_managers Target
               ON Src.mgr_id = Target.mgr_id;

        DELETE FROM TmpManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs WHERE NOT WarnMsgs.message ILIKE 'Note:%');
    End If;

    If Exists (Select * From TmpManagerList Src INNER JOIN mc.t_param_value_old_managers Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Note: manager already has parameters in t_param_value_old_managers; will merge values from t_param_value',
               manager_name
        FROM TmpManagerList Src
             INNER JOIN mc.t_param_value_old_managers Target
               ON Src.mgr_id = Target.mgr_id;
    End If;

    If _infoOnly <> 0 OR NOT EXISTS (Select * From TmpManagerList) Then
        RETURN QUERY
        SELECT ' To be archived' as message,
               Src.manager_name,
               Src.control_from_web,
               PV.mgr_type_id,
               PV.param_name,
               PV.Entry_ID,
               PV.type_id,
               PV.Value,
               PV.mgr_id,
               PV.Comment,
               PV.Last_Affected,
               PV.Entered_By
        FROM TmpManagerList Src
             LEFT OUTER JOIN mc.v_param_value PV
               ON PV.mgr_id = Src.mgr_id
        UNION
        SELECT WarnMsgs.message,
               WarnMsgs.manager_name,
               0::smallint as control_from_website,
               0 as manager_type_id,
               ''::citext as param_name,
               0 as entry_id,
               0 as type_id,
               ''::citext as value,
               0 as mgr_id,
               ''::citext as comment,
               current_timestamp::timestamp as last_affected,
               ''::citext as entered_by
        FROM TmpWarningMessages WarnMsgs
        ORDER BY message ASC, manager_name, param_name;
        RETURN;
    End If;

    RAISE Info 'Insert into t_old_managers';

    INSERT INTO mc.t_old_managers(
                               mgr_id,
                               mgr_name,
                               mgr_type_id,
                               param_value_changed,
                               control_from_website,
                               comment )
    SELECT M.mgr_id,
           M.mgr_name,
           M.mgr_type_id,
           M.param_value_changed,
           M.control_from_website,
           M.comment
    FROM mc.t_mgrs M
         INNER JOIN TmpManagerList Src
           ON M.mgr_id = Src.mgr_id
      LEFT OUTER JOIN mc.t_old_managers Target
           ON Src.mgr_id = Target.mgr_id
    WHERE Target.mgr_id IS NULL;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    RAISE Info 'Insert into t_param_value_old_managers';

    -- The following query uses
    --   ON CONFLICT ON CONSTRAINT pk_t_param_value_old_managers
    -- instead of
    --   ON CONFLICT (entry_id)
    -- to avoid an ambiguous name error with the entry_id field
    -- returned by this function

    INSERT INTO mc.t_param_value_old_managers(
             entry_id,
             type_id,
             value,
             mgr_id,
             comment,
             last_affected,
             entered_by )
    SELECT PV.entry_id,
           PV.type_id,
           PV.value,
           PV.mgr_id,
           PV.comment,
           PV.last_affected,
           PV.entered_by
    FROM mc.t_param_value PV
         INNER JOIN TmpManagerList Src
           ON PV.mgr_id = Src.mgr_id
   ON CONFLICT ON CONSTRAINT pk_t_param_value_old_managers
   DO UPDATE SET
        type_id = EXCLUDED.type_id,
        value = EXCLUDED.value,
        mgr_id = EXCLUDED.mgr_id,
        comment = EXCLUDED.comment,
        last_affected = EXCLUDED.last_affected,
        entered_by = EXCLUDED.entered_by;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    RAISE Info 'Delete from mc.t_param_value';

    DELETE FROM mc.t_param_value target
    WHERE target.mgr_id IN (SELECT MgrList.mgr_id FROM TmpManagerList MgrList);

    RAISE Info 'Delete from mc.t_mgrs';

    DELETE FROM mc.t_mgrs target
    WHERE target.mgr_id IN (SELECT MgrList.mgr_id FROM TmpManagerList MgrList);

    RAISE Info 'Delete succeeded; returning results';

    RETURN QUERY
    SELECT 'Moved to mc.t_old_managers and mc.t_param_value_old_managers' as Message,
           Src.Manager_Name,
           Src.control_from_web,
           OldMgrs.mgr_type_id,
           PT.param_name,
           PV.entry_id,
           PV.type_id,
           PV.value,
           PV.mgr_id,
           PV.comment,
           PV.last_affected,
           PV.entered_by
    FROM TmpManagerList Src
         LEFT OUTER JOIN mc.t_old_managers OldMgrs
           ON OldMgrs.mgr_id = Src.mgr_id
         LEFT OUTER JOIN mc.t_param_value_old_managers PV
           ON PV.mgr_id = Src.mgr_id
         LEFT OUTER JOIN mc.t_param_type PT ON
         PV.type_id = PT.param_id
    ORDER BY Src.manager_name, param_name;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error archiving manager parameters for ' || _mgrList || ': ' || _exceptionMessage;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'ArchiveOldManagersAndParams', 'mc');

    RETURN QUERY
    SELECT _message as Message,
           ''::citext as Manager_Name,
           0::smallint as control_from_website,
           0 as manager_type_id,
           ''::citext as param_name,
           0 as entry_id,
           0 as type_id,
           ''::citext as value,
           0 as mgr_id,
           ''::citext as comment,
           current_timestamp::timestamp as last_affected,
           ''::citext as entered_by;
END
$$;


ALTER FUNCTION mc.archive_old_managers_and_params(_mgrlist text, _infoonly integer) OWNER TO d3l243;

--
-- Name: FUNCTION archive_old_managers_and_params(_mgrlist text, _infoonly integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.archive_old_managers_and_params(_mgrlist text, _infoonly integer) IS 'ArchiveOldManagersAndParams';

