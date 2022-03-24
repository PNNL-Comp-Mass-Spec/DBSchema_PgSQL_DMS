--
-- Name: unarchiveoldmanagersandparams(text, integer, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.unarchiveoldmanagersandparams(_mgrlist text, _infoonly integer DEFAULT 1, _enablecontrolfromwebsite integer DEFAULT 0) RETURNS TABLE(message text, mgr_name public.citext, control_from_website smallint, manager_type_id integer, param_name public.citext, entry_id integer, param_type_id integer, param_value public.citext, mgr_id integer, comment public.citext, last_affected timestamp without time zone, entered_by public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Moves managers from mc.t_old_managers to mc.t_mgrs and
**      moves manager parameters from mc.t_param_value_old_managers to mc.t_param_value
**
**      To reverse this process, use function mc.ArchiveOldManagersAndParams
**      SELECT * FROM mc.ArchiveOldManagersAndParams('Pub-10-1', _infoOnly := 1);
**
**  Arguments:
**    _mgrList   One or more manager names (comma-separated list); supports wildcards because uses stored procedure ParseManagerNameList
**
**  Auth:   mem
**  Date:   02/25/2016 mem - Initial version
**          04/22/2016 mem - Now updating M_Comment in mc.t_mgrs
**          01/29/2020 mem - Ported to PostgreSQL
**          02/04/2020 mem - Rename columns to mgr_id and mgr_name
**                         - Use mc schema when calling ParseManagerNameList
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
    _newSeqValue int;
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
    _enableControlFromWebsite := Coalesce(_enableControlFromWebsite, 1);

    If _enableControlFromWebsite > 0 Then
        _enableControlFromWebsite := 1;
    End If;

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
    Call mc.ParseManagerNameList (_mgrList, _removeUnknownManagers => 0, _message => _message);

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
        control_from_web = _enableControlFromWebsite
    FROM mc.t_old_managers M
    WHERE TmpManagerList.Manager_Name = M.mgr_name;

    If Exists (Select * from TmpManagerList MgrList WHERE MgrList.mgr_id Is Null) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Unknown manager (not in mc.t_old_managers)',
               MgrList.manager_name
        FROM TmpManagerList MgrList
        WHERE MgrList.mgr_id Is Null
        ORDER BY MgrList.manager_name;
    End If;

    If Exists (Select * From TmpManagerList MgrList Where MgrList.manager_name ILike '%Params%') Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Will not process managers with "Params" in the name (for safety)',
               MgrList.manager_name
        FROM TmpManagerList MgrList
        WHERE MgrList.manager_name ILike '%Params%'
        ORDER BY MgrList.manager_name;

        DELETE FROM TmpManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs);
    End If;

    DELETE FROM TmpManagerList
    WHERE TmpManagerList.mgr_id Is Null OR 
          TmpManagerList.control_from_web > 0;

    If Exists (Select * From TmpManagerList Src INNER JOIN mc.t_mgrs Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Manager already exists in t_mgrs; cannot restore',
               manager_name
        FROM TmpManagerList Src
             INNER JOIN mc.t_old_managers Target
               ON Src.mgr_id = Target.mgr_id;

        DELETE FROM TmpManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs);
    End If;

    If Exists (Select * From TmpManagerList Src INNER JOIN mc.t_param_value Target ON Src.mgr_id = Target.mgr_id) Then
        INSERT INTO TmpWarningMessages (message, manager_name)
        SELECT 'Manager already has parameters in mc.t_param_value; cannot restore',
               manager_name
        FROM TmpManagerList Src
             INNER JOIN mc.t_param_value_old_managers Target
               ON Src.mgr_id = Target.mgr_id;

        DELETE FROM TmpManagerList
        WHERE manager_name IN (SELECT WarnMsgs.manager_name FROM TmpWarningMessages WarnMsgs);
    End If;

    If _infoOnly <> 0 OR NOT EXISTS (Select * From TmpManagerList) Then
        RETURN QUERY
        SELECT ' To be restored' as message,
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
             LEFT OUTER JOIN mc.v_old_param_value PV
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
         INNER JOIN TmpManagerList Src
           ON M.mgr_id = Src.mgr_id;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Set the manager ID sequence's current value to the maximum manager ID
    --
    SELECT MAX(mc.t_mgrs.mgr_id) INTO _newSeqValue
    FROM mc.t_mgrs;

    PERFORM setval('mc.t_mgrs_m_id_seq', _newSeqValue);
    RAISE INFO 'Sequence mc.t_mgrs_m_id_seq set to %', _newSeqValue;

    RAISE Info 'Insert into t_param_value';

    INSERT INTO mc.t_param_value (
             entry_id,
             type_id,
             value,
             mgr_id,
             comment,
             last_affected,
             entered_by )
    OVERRIDING SYSTEM VALUE
    SELECT PV.entry_id,
           PV.type_id,
           PV.value,
           PV.mgr_id,
           PV.comment,
           PV.last_affected,
           PV.entered_by
    FROM mc.t_param_value_old_managers PV
    WHERE PV.entry_id IN ( SELECT Max(PV.entry_ID)
                           FROM mc.t_param_value_old_managers PV
                                INNER JOIN TmpManagerList Src
                                  ON PV.mgr_id = Src.mgr_id
                           GROUP BY PV.mgr_id, PV.type_id 
                         );
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -- Set the entry_id sequence's current value to the maximum entry_id
    --
    SELECT MAX(PV.entry_id) INTO _newSeqValue
    FROM mc.t_param_value PV;

    PERFORM setval('mc.t_param_value_entry_id_seq', _newSeqValue);
    RAISE INFO 'Sequence mc.t_param_value_entry_id_seq set to %', _newSeqValue;

    DELETE FROM mc.t_param_value_old_managers
    WHERE mc.t_param_value_old_managers.mgr_id IN (SELECT MgrList.mgr_id FROM TmpManagerList MgrList);

    DELETE FROM mc.t_old_managers
    WHERE mc.t_old_managers.mgr_id IN (SELECT MgrList.mgr_id FROM TmpManagerList MgrList);

    RAISE Info 'Restore succeeded; returning results';

    RETURN QUERY
    SELECT 'Moved to mc.t_mgrs and mc.t_param_value' as Message,
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
    ORDER BY Src.Manager_Name, param_name;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error unarchiving manager parameters for ' || _mgrList || ': ' || _exceptionMessage;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    Call PostLogEntry ('Error', _message, 'UnarchiveOldManagersAndParams', 'mc');

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


ALTER FUNCTION mc.unarchiveoldmanagersandparams(_mgrlist text, _infoonly integer, _enablecontrolfromwebsite integer) OWNER TO d3l243;

--
-- Name: FUNCTION unarchiveoldmanagersandparams(_mgrlist text, _infoonly integer, _enablecontrolfromwebsite integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.unarchiveoldmanagersandparams(_mgrlist text, _infoonly integer, _enablecontrolfromwebsite integer) IS 'UnarchiveOldManagersAndParams';

