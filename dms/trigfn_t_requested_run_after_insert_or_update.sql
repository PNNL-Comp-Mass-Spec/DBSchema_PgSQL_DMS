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
**
*****************************************************/
DECLARE
    _requestNameCode text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> for request_name, created, requester_prn, and batch_id since they are never null
    -- For the others, use IS DISTINCT FROM
    If TG_OP = 'INSERT' OR
       OLD.request_name      <> NEW.request_name OR
       OLD.created           <> NEW.created OR
       OLD.requester_prn     <> NEW.requester_prn OR
       OLD.batch_id          <> NEW.batch_id OR
       OLD.request_name_code IS DISTINCT FROM NEW.request_name_code OR
       OLD.request_type_id   IS DISTINCT FROM NEW.request_type_id OR
       OLD.separation_group  IS DISTINCT FROM NEW.separation_group Then

        SELECT public.get_requested_run_name_code(N.request_name, N.created, N.requester_prn,
                                                  N.batch_id, RRB.batch, RRB.created,
                                                  N.request_type_id, N.separation_group)
        INTO _requestNameCode
        FROM NEW as N
             LEFT OUTER JOIN t_requested_run_batches RRB
               ON RRB.batch_id = N.batch_id;

        If _requestNameCode IS DISTINCT FROM NEW.request_name_code Then
            UPDATE t_requested_run
            SET request_name_code = _requestNameCode
            FROM NEW as N
            WHERE t_requested_run.request_id = N.request_id;
        End If;

    End If;

    -- Use <> since state_name is never null
    If TG_OP = 'UPDATE' AND
       OLD.state_name <> NEW.state_name Then

        INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
        SELECT 11 AS target_type,
               N.request_id,
               NewStateInfo.state_id,
               OldStateInfo.state_id, CURRENT_TIMESTAMP
        FROM OLD as O INNER JOIN
             NEW as N ON O.request_id = N.request_id
             INNER JOIN t_requested_run_state_name OldStateInfo
               ON O.state_name = OldStateInfo.state_name
             INNER JOIN t_requested_run_state_name NewStateInfo
               ON N.state_name = NewStateInfo.state_name
        ORDER BY N.request_id;

    End If;

    If TG_OP = 'INSERT' OR
       OLD.batch_id             <> NEW.batch_id OR
       OLD.cart_id              <> NEW.cart_id OR
       OLD.eus_usage_type_id    <> NEW.eus_usage_type_id OR
       OLD.exp_id               <> NEW.exp_id OR
       OLD.origin               <> NEW.origin OR
       OLD.queue_state          <> NEW.queue_state OR
       OLD.request_name         <> NEW.request_name OR
       OLD.requester_prn        <> NEW.requester_prn OR
       OLD.state_name           <> NEW.state_name OR
       OLD.block                IS DISTINCT FROM NEW.block OR
       OLD.blocking_factor      IS DISTINCT FROM NEW.blocking_factor OR
       OLD.cart_column          IS DISTINCT FROM NEW.cart_column OR
       OLD.cart_config_id       IS DISTINCT FROM NEW.cart_config_id OR
       OLD.comment              IS DISTINCT FROM NEW.comment OR
       OLD.dataset_id           IS DISTINCT FROM NEW.dataset_id OR
       OLD.eus_proposal_id      IS DISTINCT FROM NEW.eus_proposal_id OR
       OLD.instrument_group     IS DISTINCT FROM NEW.instrument_group OR
       OLD.instrument_setting   IS DISTINCT FROM NEW.instrument_setting OR
       OLD.location_id          IS DISTINCT FROM NEW.location_id OR
       OLD.mrm_attachment       IS DISTINCT FROM NEW.mrm_attachment OR
       OLD.note                 IS DISTINCT FROM NEW.note OR
       OLD.priority             IS DISTINCT FROM NEW.priority OR
       OLD.queue_date           IS DISTINCT FROM NEW.queue_date OR
       OLD.queue_instrument_id  IS DISTINCT FROM NEW.queue_instrument_id OR
       OLD.request_internal_standard IS DISTINCT FROM NEW.request_internal_standard OR
       OLD.request_run_finish   IS DISTINCT FROM NEW.request_run_finish OR
       OLD.request_run_start    IS DISTINCT FROM NEW.request_run_start OR
       OLD.request_type_id      IS DISTINCT FROM NEW.request_type_id OR
       OLD.run_order            IS DISTINCT FROM NEW.run_order OR
       OLD.separation_group     IS DISTINCT FROM NEW.separation_group OR
       OLD.special_instructions IS DISTINCT FROM NEW.special_instructions OR
       OLD.vialing_conc         IS DISTINCT FROM NEW.vialing_conc OR
       OLD.vialing_vol          IS DISTINCT FROM NEW.vialing_vol OR
       OLD.well                 IS DISTINCT FROM NEW.well OR
       OLD.wellplate            IS DISTINCT FROM NEW.wellplate OR
       OLD.work_package         IS DISTINCT FROM NEW.work_package Then

        UPDATE t_requested_run
        SET Updated = CURRENT_TIMESTAMP,
            Queue_State = CASE WHEN N.state_name = 'Completed' THEN 3 ELSE N.Queue_State END,
            Updated_By = SESSION_USER
        FROM NEW as N
        WHERE t_requested_run.request_id = N.request_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_after_insert_or_update() OWNER TO d3l243;

