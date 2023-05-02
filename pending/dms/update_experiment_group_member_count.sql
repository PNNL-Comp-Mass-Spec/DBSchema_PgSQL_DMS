--
CREATE OR REPLACE PROCEDURE public.update_experiment_group_member_count
(
    _groupID int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the MemberCount value for either the
**      specific experiment group or for all experiment groups
**
**  Arguments:
**    _groupID   0 to Update all groups
**
**  Auth:   mem
**  Date:   12/06/2018 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _memberCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    _groupID := Coalesce(_groupID, 0);
    _message := '';
    _returnCode:= '';

    If _groupID <= 0 Then

        UPDATE t_experiment_groups
        SET member_count = LookupQ.member_count
        FROM t_experiment_groups EG

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_experiment_groups
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_experiment_groups.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN ( SELECT group_id, COUNT(*) AS MemberCount
                          FROM t_experiment_group_members
                          GROUP BY group_id) LookupQ
               ON EG.group_id = LookupQ.group_id
        WHERE EG.MemberCount <> LookupQ.MemberCount
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _message := 'Updated member counts for ' || Cast(_myRowCount As text) || ' groups in t_experiment_groups';
            RAISE INFO '%', _message;
        Else
            _message := 'Member counts were already up-to-date for all groups in t_experiment_groups';
        End If;
    Else

        SELECT COUNT(*)
        INTO _memberCount
        FROM t_experiment_group_members
        WHERE group_id = _groupID
        GROUP BY group_id

        UPDATE t_experiment_groups
        SET member_count = Coalesce(_memberCount, 0)
        WHERE group_id = _groupID
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := 'Experiment group ' || Cast(_groupID As text) || ' now has ' || Cast(_myRowCount As text) || ' members';
    End If;
END
$$;

COMMENT ON PROCEDURE public.update_experiment_group_member_count IS 'UpdateExperimentGroupMemberCount';
