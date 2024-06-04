--
-- Name: trigfn_t_requested_run_after_insert_or_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_requested_run_after_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates various columns for new or updated requested run(s)
**
**  Auth:   mem
**  Date:   08/05/2010 mem - Initial version
**          08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**          12/12/2011 mem - Now updating t_event_log
**          06/27/2018 mem - Update the Updated column
**          08/06/2018 mem - Rename Operator PRN column to requester_prn
**          10/20/2020 mem - Change Queue_State to 3 (Analyzed) if the requested run status is Completed
**          06/22/2022 mem - No longer pass the username of the batch owner to GetRequestedRunNameCode
**          08/06/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the OLD and NEW variables directly instead of using transition tables (which contain every updated row, not just the current row)
**          08/10/2022 mem - Update t_event_log when inserting a new row
**          08/16/2022 mem - Log renamed requested runs
**                         - Log dataset_id changes (ignoring change from null to a value)
**                         - Log exp_id changes
**                         - Log requested runs that have the same dataset_id
**          02/08/2023 mem - Switch from PRN to username
**          02/21/2023 mem - Pass batch group ID to get_requested_run_name_code
**          05/31/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _batchInfo record;
    _requestNameCode text;
    _stateIdOld int;
    _stateIdNew int;
    _datasetNameOld text;
    _datasetNameNew text;
    _experimentNameOld text;
    _experimentNameNew text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> for request_name, created, requester_username, and batch_id since they are never null
    -- For the others, use IS DISTINCT FROM
    If TG_OP = 'INSERT' Or
       OLD.request_name       <> NEW.request_name Or
       OLD.created            <> NEW.created Or
       OLD.requester_username <> NEW.requester_username Or
       OLD.batch_id           <> NEW.batch_id Or
       OLD.request_name_code  IS DISTINCT FROM NEW.request_name_code Or
       OLD.request_type_id    IS DISTINCT FROM NEW.request_type_id Or
       OLD.separation_group   IS DISTINCT FROM NEW.separation_group
    Then
        SELECT batch, created, batch_group_id
        INTO _batchInfo
        FROM t_requested_run_batches
        WHERE batch_id = NEW.batch_id;

        _requestNameCode := public.get_requested_run_name_code(
                                        NEW.request_name, NEW.created, NEW.requester_username,
                                        NEW.batch_id, _batchInfo.batch, _batchInfo.batch_group_id, _batchInfo.created,
                                        NEW.request_type_id, NEW.separation_group);

        If _requestNameCode IS DISTINCT FROM NEW.request_name_code Then
            UPDATE t_requested_run
            SET request_name_code = _requestNameCode
            WHERE t_requested_run.request_id = NEW.request_id;
        End If;

        -- The following can be used to verify that request_name_code is up-to-date for all requested runs

        /*

        UPDATE t_requested_run
        SET request_name_code = public.get_requested_run_name_code(
                                        request_name, t_requested_run.created, requester_username,
                                        t_requested_run.batch_id, rrb.batch, rrb.batch_group_id, rrb.created,
                                        request_type_id, separation_group)
        FROM t_requested_run_batches RRB
        WHERE t_requested_run.batch_id = RRB.batch_id AND
              request_name_code IS DISTINCT FROM public.get_requested_run_name_code(
                                        request_name, t_requested_run.created, requester_username,
                                        t_requested_run.batch_id, rrb.batch, rrb.batch_group_id, rrb.created,
                                        request_type_id, separation_group);
        */

    End If;

    If TG_OP = 'INSERT' Then

        SELECT state_id
        INTO _stateIdNew
        FROM t_requested_run_state_name
        WHERE state_name = NEW.state_name;

        INSERT INTO t_event_log (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered
        )
        SELECT 11 AS target_type,
               NEW.request_id,
               _stateIdNew,
               0,
               CURRENT_TIMESTAMP;

    ElsIf OLD.state_name <> NEW.state_name Then     -- Use <> since state_name is never null

        SELECT state_id
        INTO _stateIdOld
        FROM t_requested_run_state_name
        WHERE state_name = OLD.state_name;

        SELECT state_id
        INTO _stateIdNew
        FROM t_requested_run_state_name
        WHERE state_name = NEW.state_name;

        INSERT INTO t_event_log (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered
        )
        SELECT 11 AS target_type,
               NEW.request_id,
               _stateIdNew,
               _stateIdOld,
               CURRENT_TIMESTAMP;

    End If;

    -- Update these three columns for inserts and updates (which are filtered with a WHEN clause in the trigger definition)
    UPDATE t_requested_run
    SET Updated = CURRENT_TIMESTAMP,
        Queue_State = CASE WHEN NEW.state_name = 'Completed' THEN 3 ELSE NEW.Queue_State END,
        Updated_By = SESSION_USER
    WHERE t_requested_run.request_id = NEW.request_id;

    If TG_OP = 'UPDATE' Then

        -- Check for renamed requested run
        -- Use <> since request_name is never null
        If OLD.request_name <> NEW.request_name Then

            INSERT INTO T_Entity_Rename_Log (
                target_type,
                target_id,
                old_name,
                new_name
            )
            VALUES (11,
                    NEW.request_id,
                    OLD.request_name,
                    NEW.request_name);

        End If;

        -- Check for updated Dataset ID (including changing to null)
        If Not OLD.dataset_id Is Null And OLD.dataset_id IS DISTINCT FROM NEW.dataset_id Then

            SELECT dataset
            INTO _datasetNameOld
            FROM t_dataset
            WHERE dataset_id = OLD.dataset_id;

            SELECT dataset
            INTO _datasetNameNew
            FROM t_dataset
            WHERE dataset_id = NEW.dataset_id;

            INSERT INTO T_Entity_Rename_Log (
                target_type,
                target_id,
                old_name,
                new_name
            )
            VALUES (14,
                    NEW.request_id,
                    format('%s: %s', OLD.dataset_id, COALESCE(_datasetNameOld, '??')),
                    CASE
                        WHEN NEW.dataset_id IS NULL THEN 'null'
                        ELSE format('%s: %s', NEW.dataset_id, COALESCE(_datasetNameNew, '??'))
                    END
                   );
        End If;

        -- Check for updated Experiment ID
        If OLD.exp_id <> NEW.exp_id then

            SELECT experiment
            INTO _experimentNameOld
            FROM t_experiments
            WHERE exp_id = OLD.exp_id;

            SELECT experiment
            INTO _experimentNameNew
            FROM t_experiments
            WHERE exp_id = NEW.exp_id;

            INSERT INTO t_entity_rename_log (
                target_type,
                target_id,
                old_name,
                new_name
            )
            VALUES (15,
                    NEW.request_id,
                    format('%s: %s', OLD.exp_id, _experimentNameOld),
                    format('%s: %s', NEW.exp_id, _experimentNameNew)
                   );

        End If;

    End If;

    If TG_OP = 'INSERT' Or Not NEW.dataset_id Is Null And OLD.dataset_id IS DISTINCT FROM NEW.dataset_id Then

        -- Check whether another requested run already has the new Dataset ID
        INSERT INTO t_entity_rename_log (
            target_type,
            target_id,
            old_name,
            new_name
        )
        SELECT 14 AS target_type,
               NEW.request_id,
               format('Dataset ID %s is already referenced by Request ID %s', NEW.dataset_id, RR.request_id),
               format('%s: %s', NEW.dataset_id, COALESCE(NewDataset.dataset, '??'))
        FROM T_Requested_Run RR
             LEFT OUTER JOIN T_Dataset AS NewDataset
               ON RR.dataset_id = NewDataset.dataset_id
        WHERE NEW.dataset_id = RR.dataset_id AND
              NEW.request_id <> RR.request_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_after_insert_or_update() OWNER TO d3l243;

