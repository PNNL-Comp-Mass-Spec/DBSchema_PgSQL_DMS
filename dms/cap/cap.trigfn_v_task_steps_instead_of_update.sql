--
-- Name: trigfn_v_task_steps_instead_of_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_v_task_steps_instead_of_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Allows for updating the following columns in view cap.v_task_steps
**        state
**        input_folder_name
**        output_folder_name
**        processor
**        start
**        finish
**        completion_code
**        completion_message
**        evaluation_code
**        evaluation_message
**        holdoff_interval_minutes
**        next_try
**        retry_count
**
**  Auth:   mem
**  Date:   06/21/2023 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If TG_OP = 'UPDATE' Then
        UPDATE cap.t_task_steps
        SET state                    = NEW.state,
            input_folder_name        = NEW.input_folder,
            output_folder_name       = NEW.output_folder,
            processor                = NEW.processor,
            start                    = NEW.start,
            finish                   = NEW.finish,
            completion_code          = NEW.completion_code,
            completion_message       = NEW.completion_message,
            evaluation_code          = NEW.evaluation_code,
            evaluation_message       = NEW.evaluation_message,
            holdoff_interval_minutes = NEW.holdoff_interval_minutes,
            next_try                 = NEW.next_try,
            retry_count              = NEW.retry_count
        WHERE job  = OLD.job AND
              step = OLD.step;

        RETURN NEW;
    End If;

    RETURN NEW;
END;
$$;


ALTER FUNCTION cap.trigfn_v_task_steps_instead_of_update() OWNER TO d3l243;

