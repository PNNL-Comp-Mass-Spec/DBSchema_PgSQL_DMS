--
-- Name: delete_experiment(text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_experiment(IN _experimentname text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete given experiment from the experiment table and all referencing tables
**
**      The experiment may not have any associated datasets or requested runs
**
**  Arguments:
**    _experimentName   Experiment to delete
**    _infoOnly         When true, preview the updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   05/11/2004
**          06/16/2005 grk - Added delete for experiment group members table
**          02/27/2006 grk - Added delete for experiment group table
**          08/31/2006 jds - Added check for requested runs (Ticket #199)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          02/26/2010 mem - Merged T_Requested_Run_History with T_Requested_Run
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2018 mem - Call update_experiment_group_member_count to update T_Experiment_Groups
**          09/10/2019 mem - Delete from T_Experiment_Plex_Members if mapped to Plex_Exp_ID
**                         - Prevent deletion if the experiment is a plex channel in T_Experiment_Plex_Members
**                         - Add _infoOnly
**          07/11/2023 mem - Remove duplicate query of T_Requested_Run (unnecessary since T_Requested_Run_History was merged with T_Requested_Run in 2010)
**          12/10/2023 mem - Ported to PostgreSQL
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _experimentId int;
    _state int;
    _result int;
    _dsCount int := 0;
    _rrCount int := 0;
    _rrhCount int := 0;
    _plexMemberCount int := 0;
    _groupID int := 0;
    _stateID int := 0;
    _placeholderExpID int;
    _targetType int;
    _alterEnteredByMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _experimentName := Trim(Coalesce(_experimentName, ''));
    _infoOnly       := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

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
        _message := format('Experiment does not exist, cannot delete: %s', _experimentName);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that has any datasets
    ---------------------------------------------------

    SELECT COUNT(dataset_id)
    INTO _dsCount
    FROM t_dataset
    WHERE exp_id = _experimentId;

    If _dsCount > 0 Then
        _message := 'Cannot delete experiment that has associated datasets';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that has a requested run
    ---------------------------------------------------

    SELECT COUNT(request_id)
    INTO _rrCount
    FROM t_requested_run
    WHERE exp_id = _experimentId;

    If _rrCount > 0 Then
        _message := 'Cannot delete experiment that has associated requested runs';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Can't delete experiment that is mapped to a channel in a plex
    ---------------------------------------------------

    SELECT COUNT(plex_exp_id)
    INTO _plexMemberCount
    FROM t_experiment_plex_members
    WHERE exp_id = _experimentId;

    If _plexMemberCount > 0 Then
        _message := format('Cannot delete experiment that is mapped to a plex channel; see https://dms2.pnl.gov/experiment_plex_members_tsv/report/-/-/-/%s/-/-/-', _experimentName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    -- Create a temporary table to track the list of items to delete or update

    CREATE TEMP TABLE T_Tmp_Target_Items (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Action text,
        Item_Type text,
        Item_ID text,
        Item_Name text,
        Comment text
    );

    ---------------------------------------------------
    -- Delete any entries for the Experiment from the
    -- biomaterial map table
    ---------------------------------------------------

    If _infoOnly Then
        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted',
               'Experiment Biomaterial Map',
               Exp_ID,
               format('Biomaterial ID: %s', Biomaterial_ID),
               ''
        FROM t_experiment_biomaterial
        WHERE Exp_ID = _experimentId;
    Else
        DELETE FROM t_experiment_biomaterial
        WHERE Exp_ID = _experimentId;
    End If;

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
            INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
            SELECT 'To be deleted',
                   'Experiment Group Member',
                   exp_id,
                   format('Group_ID: %s', group_id),
                   ''
            FROM t_experiment_group_members
            WHERE exp_id = _experimentId;
        Else
            DELETE FROM t_experiment_group_members
            WHERE exp_id = _experimentId;
        End If;

        If Not _infoOnly Then
            -- Update MemberCount
            CALL public.update_experiment_group_member_count (
                            _groupID    => _groupID,
                            _message    => _message,        -- Output
                            _returnCode => _returnCode);    -- Output
        End If;
    End If;

    ---------------------------------------------------
    -- Remove any reference to this experiment as a
    -- parent experiment in the experiment groups table
    ---------------------------------------------------

    SELECT exp_id
    INTO _placeholderExpID
    FROM t_experiments
    WHERE experiment = 'Placeholder';

    If Not FOUND Then
        DROP TABLE T_Tmp_Target_Items;

        _message := format('Placeholder experiment not found in t_experiments; unable to delete experiment ID %s', _experimentId);
        RAISE EXCEPTION '%', _message;
    End If;

    If _infoOnly Then
        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'Change parent_exp_id to Placeholder ID',
               'Experiment Group',
               group_id,
               format('Group type: %s, Name: %s', group_type, Coalesce(group_name, '')),
               Coalesce(description, '')
        FROM t_experiment_groups
        WHERE parent_exp_id = _experimentId;
    Else
        UPDATE t_experiment_groups
        SET parent_exp_id = _placeholderExpID      -- Associate with the experiment ID of the 'Placeholder' experiment (which should be 15)
        WHERE parent_exp_id = _experimentId;
    End If;

    ---------------------------------------------------
    -- Delete experiment plex info
    ---------------------------------------------------

    If _infoOnly Then
        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted',
               'Experiment Plex Member',
               plex_exp_id,
               format('Channel: %s, Exp_ID %s', channel, exp_id),
               comment
        FROM t_experiment_plex_members
        WHERE plex_exp_id = _experimentId;
    Else
        DELETE FROM t_experiment_plex_members
        WHERE plex_exp_id = _experimentId;
    End If;

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Call Delete_Aux_Info for %', _experimentName;
    Else
        ---------------------------------------------------
        -- Delete any auxiliary info associated with Experiment
        ---------------------------------------------------

        CALL public.delete_aux_info (
                        'Experiment',
                        _experimentName,
                        _message => _message,           -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            ROLLBACK;

            _message := format('Delete auxiliary information was unsuccessful for Experiment: %s', _message);
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';

            DROP TABLE T_Tmp_Target_Items;
            RETURN;
        End If;

        -- Change _message to an empty string if it is of the form 'Aux info values not found for Experiment "Experiment_Name"'

        If _message ILike 'Aux info values not found%' Then
            _message := '';
        End If;
    End If;

    ---------------------------------------------------
    -- Delete experiment from experiment table
    ---------------------------------------------------

    If _infoOnly Then
        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted',
               'Experiment',
               exp_id,
               experiment,
               comment
        FROM t_experiments
        WHERE exp_id = _experimentId;
    Else
        DELETE FROM t_experiments
        WHERE exp_id = _experimentId;
    End If;

    If _infoOnly Then
         -- Show the contents of T_Tmp_Target_Items

        RAISE INFO '';

        _formatSpecifier := '%-40s %-28s %-10s %-60s %-60s';

        _infoHead := format(_formatSpecifier,
                            'Action',
                            'Item_Type',
                            'Item_ID',
                            'Item_Name',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------------------------------',
                                     '----------------------------',
                                     '----------',
                                     '------------------------------------------------------------',
                                     '------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Action, Item_Type, Item_ID, Item_Name, Comment
            FROM T_Tmp_Target_Items
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Action,
                                _previewData.Item_Type,
                                _previewData.Item_ID,
                                _previewData.Item_Name,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    ElsIf Trim(Coalesce(_callingUser, '')) <> '' Then
        -- Call alter_event_log_entry_user to alter the entered_by field in t_event_log

        _targetType := 3;
        CALL public.alter_event_log_entry_user ('public', _targetType, _experimentId, _stateID, _callingUser, _message => _alterEnteredByMessage);
    End If;

    If Not _infoOnly And Coalesce(_message, '') = '' Then
        _message := format('Deleted experiment ID %s: %s', _experimentId, _experimentName);
    End If;

    DROP TABLE T_Tmp_Target_Items;
END
$$;


ALTER PROCEDURE public.delete_experiment(IN _experimentname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_experiment(IN _experimentname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_experiment(IN _experimentname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteExperiment';

