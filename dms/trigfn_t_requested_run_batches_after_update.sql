--
-- Name: trigfn_t_requested_run_batches_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_requested_run_batches_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column request_name_code for requested runs
**      associated with the updated batches
**
**  Auth:   mem
**  Date:   08/05/2010 mem - Initial version
**          08/10/2010 mem - Now passing dataset type and separation type to GetRequestedRunNameCode
**          06/27/2022 mem - No longer pass the username of the batch owner to GetRequestedRunNameCode
**          08/01/2022 mem - Update column Updated_By
**          08/06/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> for batch and created since they are never null
    -- In contrast, owner could be null
    If OLD.batch <> NEW.batch OR
       OLD.created <> NEW.created Then

        UPDATE t_requested_run
        SET request_name_code = public.get_requested_run_name_code(RR.request_name, RR.created, RR.requester_prn,
                                                                   RR.batch_id, N.batch, N.created,
                                                                   RR.request_type_id, RR.separation_group)
        FROM NEW as N
             INNER JOIN t_requested_run RR
               ON RR.batch_id = N.batch_id
        WHERE t_requested_run.batch_id = N.batch_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_requested_run_batches_after_update() OWNER TO d3l243;

