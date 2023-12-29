--
-- Name: update_experiment_group_member_count(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_experiment_group_member_count(IN _groupid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the MemberCount value for either the specific experiment group or for all experiment groups
**
**  Arguments:
**    _groupID      Experiment group ID to update; 0 to update all groups
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   12/06/2018 mem - Initial version
**          12/03/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int := 0;
    _memberCount int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _groupID := Coalesce(_groupID, 0);

    If _groupID <= 0 Then

        UPDATE t_experiment_groups EG
        SET member_count = LookupQ.MemberCount
        FROM ( SELECT group_id, COUNT(exp_id) AS MemberCount
               FROM t_experiment_group_members
               GROUP BY group_id) LookupQ
        WHERE EG.group_id = LookupQ.group_id AND
              EG.member_count <> LookupQ.MemberCount;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Updated member counts for %s %s in t_experiment_groups', _updateCount, public.check_plural(_updateCount, 'group', 'groups'));
            RAISE INFO '%', _message;
        Else
            _message := 'Member counts are already up-to-date for all groups in t_experiment_groups';
        End If;
    Else

        SELECT COUNT(exp_id)
        INTO _memberCount
        FROM t_experiment_group_members
        WHERE group_id = _groupID
        GROUP BY group_id;

        UPDATE t_experiment_groups
        SET member_count = Coalesce(_memberCount, 0)
        WHERE group_id = _groupID;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Experiment group %s now has %s %s', _groupID, _memberCount, public.check_plural(_memberCount, 'member', 'members'));
    End If;
END
$$;


ALTER PROCEDURE public.update_experiment_group_member_count(IN _groupid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_experiment_group_member_count(IN _groupid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_experiment_group_member_count(IN _groupid integer, INOUT _message text, INOUT _returncode text) IS 'UpdateExperimentGroupMemberCount';

