--
-- Name: add_update_experiment_group(integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_experiment_group(INOUT _id integer, IN _grouptype text, IN _groupname text, IN _description text, IN _experimentlist text, IN _parentexp text, IN _researcher text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing experiment group
**
**      Used by web page https://dms2.pnl.gov/experiment_group/create to group together related experiments as a general experiment group
**      Used by web page https://dms2.pnl.gov/experiment_group/edit to edit both general experiment groups and fraction-based experiment groups
**
**      Note that the DMS website does not allow users to change the parent experiment name when editing an experiment group
**
**  Arguments:
**    _id               Input/output: experiment group ID
**    _groupType        Experiment group type: 'General' or 'Fraction'
**    _groupName        Experiment group name (previously _tab); allowed to be an empty string and allowed to be the same group name as another experiment group
**    _description      Description
**    _experimentList   Comma-separated list of experiment names
**    _parentExp        Parent experiment name; auto-defined as 'Placeholder' by https://dms2.pnl.gov/experiment_group/create
**    _researcher       Researcher username
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
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
**          12/06/2018 mem - Call update_experiment_group_member_count to update T_Experiment_Groups
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          11/18/2022 mem - Rename parameter to _groupName
**          12/11/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
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
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _groupType   := Trim(Coalesce(_groupType, ''));
    _groupName   := Trim(Coalesce(_groupName, ''));
    _description := Trim(Coalesce(_description, ''));
    _parentExp   := Trim(Coalesce(_parentExp, ''));
    _researcher  := Trim(Coalesce(_researcher, ''));
    _mode        := Trim(Lower(Coalesce(_mode, '')));

    If Not _groupType::citext IN ('General', 'Fraction') Then
        _message := format('"%s" is not a valid group type; the only supported group types are "General" or "Fraction"', _groupType);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve parent experiment name to ID
    ---------------------------------------------------

    If _parentExp <> '' Then

        SELECT exp_id
        INTO _parentExpID
        FROM t_experiments
        WHERE experiment = _parentExp::citext;

        If Not FOUND Then
            _message := 'Unable to determine the experiment ID of experiment "%"', _parentExp;
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

    End If;

    If Coalesce(_parentExpID, 0) = 0 Then
        SELECT exp_id
        INTO _parentExpID
        FROM t_experiments
        WHERE experiment = 'Placeholder';

        If Coalesce(_parentExpID, 0) = 0 Then
            _logErrors := true;
            _message := 'Unable to determine the experiment ID of the Placeholder experiment';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Cannot update a non-existent entry

        If Not Exists (SELECT group_id FROM t_experiment_groups WHERE group_id = _id) Then
            _message := format('Cannot update: GroupID %s does not exist in the database', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    _logErrors := true;

    ---------------------------------------------------
    -- Create a temporary table for the experiment names
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Experiments (
        Experiment citext,
        Exp_ID     int
    );

    ---------------------------------------------------
    -- Populate the temporary table
    ---------------------------------------------------

    INSERT INTO Tmp_Experiments ( Experiment,
                                  Exp_ID )
    SELECT Value AS Experiment,
           0 AS Exp_ID
    FROM public.parse_delimited_list(_experimentList);

    If Not Exists (SELECT Exp_ID FROM Tmp_Experiments) Then
        _logErrors := false;
        _message := format('One or more experiment names must be specified');
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        DROP TABLE Tmp_Experiments;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve experiment name to ID
    ---------------------------------------------------

    UPDATE Tmp_Experiments AS Target
    SET exp_id = Src.exp_id
    FROM t_experiments Src
    WHERE Target.experiment = Src.experiment;

    ---------------------------------------------------
    -- Check status of prospective member experiments
    ---------------------------------------------------

    -- Do all experiments in the list actually exist?

    SELECT COUNT(*)
    INTO _count
    FROM Tmp_Experiments
    WHERE Exp_ID = 0;

    If _count <> 0 Then
        SELECT string_agg(Experiment, ',' ORDER BY Experiment)
        INTO _invalidExperiments
        FROM Tmp_Experiments
        WHERE Exp_ID = 0;

        _logErrors := false;

        If _invalidExperiments Like '%,%' Then
            _message := format('These experiments do not exist: %s', _invalidExperiments);
        Else
            _message := format('Experiment does not exist: %s', _invalidExperiments);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5206';
        DROP TABLE Tmp_Experiments;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve researcher username
    ---------------------------------------------------

    _userID := public.get_user_id(_researcher);

    If _userID > 0 Then
        -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that _researcher contains simply the username

        SELECT username
        INTO _researcher
        FROM t_users
        WHERE user_id = _userID;
    Else
        -- Could not find entry in database for username _researcher
        -- Try to auto-resolve the name

        CALL public.auto_resolve_name_to_username (
                        _researcher,
                        _matchCount       => _matchCount,   -- Output
                        _matchingUsername => _newUsername,  -- Output
                        _matchingUserID   => _userID);      -- Output

        If _matchCount = 1 Then
            -- Single match found; update _researcher
            _researcher := _newUsername;
        Else
            _logErrors := false;
            _message := format('Could not find entry in database for researcher username "%s"', _researcher);
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            DROP TABLE Tmp_Experiments;
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_experiment_groups( group_type,
                                         created,
                                         description,
                                         parent_exp_id,
                                         researcher_username,
                                         group_name )
        VALUES(_groupType,
               CURRENT_TIMESTAMP,
               _description,
               _parentExpID,
               _researcher,
               _groupName)
        RETURNING group_id
        INTO _id;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_experiment_groups
        SET group_type             = _groupType,
            description            = _description,
            parent_exp_id          = _parentExpID,
            researcher_username    = _researcher,
            group_name             = _groupName
        WHERE group_id = _id;

    End If;

    ---------------------------------------------------
    -- Update member experiments
    ---------------------------------------------------

    If _mode IN ('add', 'update') Then

        -- Remove any existing group members that are not in the temporary table
        --
        DELETE FROM t_experiment_group_members
        WHERE group_id = _id AND
              NOT exp_id IN ( SELECT exp_id FROM Tmp_Experiments );

        -- Add group members from temporary table that are not already members
        --
        INSERT INTO t_experiment_group_members(
            group_id,
            exp_id
        )
        SELECT _id,
               exp_id
        FROM Tmp_Experiments
        WHERE NOT exp_id IN ( SELECT exp_id
                              FROM t_experiment_group_members
                              WHERE group_id = _id );

        -- Update MemberCount
        --
        CALL public.update_experiment_group_member_count (
                        _groupID    => _id,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

        -- Change _message to an empty string if no errors occurred

        If _returnCode = '' Then
            _message := '';
        End If;

    End If;

    DROP TABLE Tmp_Experiments;
END
$$;


ALTER PROCEDURE public.add_update_experiment_group(INOUT _id integer, IN _grouptype text, IN _groupname text, IN _description text, IN _experimentlist text, IN _parentexp text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_experiment_group(INOUT _id integer, IN _grouptype text, IN _groupname text, IN _description text, IN _experimentlist text, IN _parentexp text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_experiment_group(INOUT _id integer, IN _grouptype text, IN _groupname text, IN _description text, IN _experimentlist text, IN _parentexp text, IN _researcher text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateExperimentGroup';

