--
CREATE OR REPLACE PROCEDURE public.delete_experiment
(
    _experimentName text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes given Experiment from the Experiment table
**      and all referencing tables.  Experiment may not
**      have any associated datasets or requested runs
**
**  Auth:   grk
**  Date:   05/11/2004
**          06/16/2005 grk - added delete for experiment group members table
**          02/27/2006 grk - added delete for experiment group table
**          08/31/2006 jds - added check for requested runs (Ticket #199)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          02/26/2010 mem - Merged T_Requested_Run_History with T_Requested_Run
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2018 mem - Call UpdateExperimentGroupMemberCount to update T_Experiment_Groups
**          09/10/2019 mem - Delete from T_Experiment_Plex_Members if mapped to Plex_Exp_ID
**                         - Prevent deletion if the experiment is a plex channel in T_Experiment_Plex_Members
**                         - Add _infoOnly
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _experimentId int;
    _state int;
    _result int;
    _dsCount int := 0;
    _rrCount int := 0;
    _rrhCount int := 0;
    _plexMemberCount int := 0;
    _transName text := 'DeleteExperiment';
    _groupID int := 0;
    _stateID int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

    _experimentName := Coalesce(_experimentName, '');
    _infoOnly := Coalesce(_infoOnly, false);

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
    -- Get ExperimentID and current state
    ---------------------------------------------------

    SELECT exp_id
    INTO _experimentId
    FROM t_experiments
    WHERE experiment = _experimentName;

    If Not FOUND Then
        _message := 'Could not get Id for Experiment "' || _experimentName || '"';
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that has any datasets
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _dsCount
    FROM t_dataset
    WHERE (exp_id = _experimentId)

    If _dsCount > 0 Then
        _message := 'Cannot delete experiment that has associated datasets';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that has a requested run
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _rrCount
    FROM t_requested_run
    WHERE (exp_id = _experimentId);

    If _rrCount > 0 Then
        _message := 'Cannot delete experiment that has associated requested runs';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that has requested run history
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _rrhCount
    FROM t_requested_run
    WHERE (exp_id = _experimentId) AND NOT (dataset_id IS NULL);

    If _rrhCount > 0 Then
        _message := 'Cannot delete experiment that has associated requested run history';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that is mapped to a channel in a plex
    ---------------------------------------------------

    --
    SELECT COUNT(*)
    INTO _plexMemberCount
    FROM t_experiment_plex_members
    WHERE (exp_id = _experimentId);

    If _plexMemberCount > 0 Then
        _message := 'Cannot delete experiment that is mapped to a plex channel; see https://dms2.pnl.gov/experiment_plex_members_tsv/report/-/-/-/' || _experimentName || '/-/-/-';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    Begin Transaction _transName

    ---------------------------------------------------
    -- Delete any entries for the Experiment from the
    -- biomaterial map table
    ---------------------------------------------------

    If _infoOnly Then
        SELECT *
        FROM T_Experiment_Biomaterial
        WHERE Exp_ID = _experimentId
    Else
        DELETE FROM T_Experiment_Biomaterial
        WHERE Exp_ID = _experimentId
    End If;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Delete any entries for the Experiment from
    -- experiment group map table
    ---------------------------------------------------

    SELECT group_id
    INTO _groupID
    FROM t_experiment_group_members
    WHERE exp_id = _experimentId;

    If FOUND And _groupID > 0 Then
        If _infoOnly Then
            SELECT *
            FROM t_experiment_group_members
            WHERE exp_id = _experimentId
        Else
            DELETE FROM t_experiment_group_members
            WHERE exp_id = _experimentId
        End If;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If Not _infoOnly Then
            -- Update MemberCount
            --
            Call update_experiment_group_member_count (_groupID => _groupID);

        End If;
    End If;

    ---------------------------------------------------
    -- Remove any reference to this experiment as a
    -- parent experiment in the experiment groups table
    ---------------------------------------------------

    If _infoOnly Then
        SELECT *
        FROM t_experiment_groups
        WHERE parent_exp_id = _experimentId
    Else
        UPDATE t_experiment_groups
        SET parent_exp_id = 15
        WHERE parent_exp_id = _experimentId
    End If;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Delete experiment plex info
    ---------------------------------------------------

    If _infoOnly Then
        SELECT *
        FROM t_experiment_plex_members
        WHERE plex_exp_id = _experimentId
    Else
        DELETE FROM t_experiment_plex_members
        WHERE plex_exp_id = _experimentId
    End If;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        Select 'exec DeleteAuxInfo for ' || _experimentName
    Else
        ---------------------------------------------------
        -- Delete any auxiliary info associated with Experiment
        ---------------------------------------------------

        Call delete_aux_info ('Experiment', _experimentName, _message => _message, _returnCode => _returnCode);

        If _returnCode <> '' Then
            ROLLBACK;

            _message := 'Delete auxiliary information was unsuccessful for Experiment: ' || _message;
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Delete experiment from experiment table
    ---------------------------------------------------

    If _infoOnly Then
        SELECT *
        FROM t_experiments
        WHERE exp_id = _experimentId
    Else
        DELETE FROM t_experiments
        WHERE exp_id = _experimentId
    End If;

    -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
    If Not _infoOnly And char_length(_callingUser) > 0 Then

        Call alter_event_log_entry_user (3, _experimentId, _stateID, _callingUser);
    End If;

END
$$;

COMMENT ON PROCEDURE public.delete_experiment IS 'DeleteExperiment';
