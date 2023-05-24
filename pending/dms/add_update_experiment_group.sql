--
CREATE OR REPLACE PROCEDURE public.add_update_experiment_group
(
    INOUT _id int,
    _groupType text,
    _groupName text,
    _description text,
    _experimentList text,
    _parentExp text,
    _researcher text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing Experiment Group
**
**  Arguments:
**    _groupName    User-defined name for this experiment group (previously _tab)
**    _mode         'add' or 'update'
**
**  Auth:   grk
**  Date:   07/11/2006
**          09/13/2011 grk - Added Researcher
**          11/10/2011 grk - Removed character size limit from experiment list
**          11/10/2011 grk - Added Tab field
**          02/20/2013 mem - Now reporting invalid experiment names
**          06/13/2017 mem - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**          12/06/2018 mem - Call UpdateExperimentGroupMemberCount to update T_Experiment_Groups
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          11/18/2022 mem - Rename parameter to _groupName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _parentExpID int := 0;
    _count int;
    _invalidExperiments text := '';
    _userID int;
    _matchCount int;
    _newUsername text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Resolve parent experiment name to ID
    ---------------------------------------------------

    --
    If _parentExp <> '' Then

        SELECT exp_id
        INTO _parentExpID
        FROM t_experiments
        WHERE experiment = _parentExp;

    End If;

    If _parentExpID = 0 Then
        SELECT exp_id
        INTO _parentExpID
        FROM t_experiments
        Where experiment = 'Placeholder'

        If Coalesce(_parentExpID, 0) = 0 Then
            _logErrors := true;
            _message := 'Unable to determine the Exp_ID for the Placeholder experiment';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Cannot update a non-existent entry
        --
        If Not Exists (SELECT group_id FROM t_experiment_groups WHERE group_id = _id) Then
            _message := format('Cannot update: GroupID does not exist in database: %s', _id)
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    _logErrors := true;

    ---------------------------------------------------
    -- Create temporary table for experiments in list
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_Experiments (
        Experiment text,
        Exp_ID     int
    )

    ---------------------------------------------------
    -- Populate temporary table from list
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Experiments ( Experiment,
                                  Exp_ID )
    SELECT value AS Experiment,
           0 AS Exp_ID
    FROM public.parse_delimited_list ( _experimentList )

    ---------------------------------------------------
    -- Resolve experiment name to ID in temp table
    ---------------------------------------------------

    UPDATE Tmp_Experiments T
    SET T.exp_id = S.exp_id
    FROM t_experiments S
    WHERE T.experiment = S.experiment;

    ---------------------------------------------------
    -- Check status of prospective member experiments
    ---------------------------------------------------

    -- Do all experiments in list actually exist?
    --
    _count := 0;
    --
    SELECT COUNT(*)
    INTO _count
    FROM Tmp_Experiments
    WHERE Exp_ID = 0;

    If _count <> 0 Then
        SELECT string_agg(Experiment, ',')
        INTO _invalidExperiments
        FROM Tmp_Experiments
        WHERE Exp_ID = 0

        _logErrors := false;
        _message := format('Experiment run list contains experiments that do not exist: %s', _invalidExperiments);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        DROP TABLE Tmp_Experiments;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve researcher username
    ---------------------------------------------------

    _userID := public.get_user_id (_researcher);

    If _userID > 0 Then
        -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that _researcher contains simply the username
        --
        SELECT username
        INTO _researcher
        FROM t_users
        WHERE user_id = _userID;
    Else
        -- Could not find entry in database for username _researcher
        -- Try to auto-resolve the name

        CALL auto_resolve_name_to_username (_researcher, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

        If _matchCount = 1 Then
            -- Single match found; update _researcher
            _researcher := _newUsername;
        Else
            _logErrors := false;
            _message := format('Could not find entry in database for researcher username "%s"', _researcher);
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            DROP TABLE Tmp_Experiments;
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If _mode = 'add' Then

        INSERT INTO t_experiment_groups (
            group_type,
            created,
            description,
            parent_exp_id,
            researcher,
            group_name
        ) VALUES (
            _groupType,
            CURRENT_TIMESTAMP,
            _description,
            _parentExpID,
            _researcher,
            _groupName
        )
        RETURNING group_id
        INTO _id;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then

        UPDATE t_experiment_groups
        SET group_type = _groupType,
            description = _description,
            parent_exp_id = _parentExpID,
            researcher = _researcher,
            group_name = _groupName
        WHERE group_id = _id;

    End If;

    ---------------------------------------------------
    -- Update member experiments
    ---------------------------------------------------

    If _mode = 'add' OR _mode = 'update' Then

        -- Remove any existing group members that are not in the temporary table
        --
        DELETE FROM t_experiment_group_members
        WHERE (group_id = _id) AND
              (exp_id NOT IN ( SELECT exp_id FROM Tmp_Experiments ))

        -- Add group members from temporary table that are not already members
        --
        INSERT INTO t_experiment_group_members(
            group_id,
            exp_id
        )
        SELECT _id,
               Tmp_Experiments.exp_id
        FROM Tmp_Experiments
        WHERE Tmp_Experiments.exp_id NOT IN ( SELECT exp_id
                                              FROM t_experiment_group_members
                                              WHERE group_id = _id )

        -- Update MemberCount
        --
        CALL update_experiment_group_member_count (_groupID => _id)

    End If;

    DROP TABLE Tmp_Experiments;
END
$$;

COMMENT ON PROCEDURE public.add_update_experiment_group IS 'AddUpdateExperimentGroup';
