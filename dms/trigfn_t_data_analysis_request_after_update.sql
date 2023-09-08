--
-- Name: trigfn_t_data_analysis_request_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_data_analysis_request_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_data_analysis_request_updates for the updated data analysis request
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version
**          08/04/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Reference the NEW and OLD variables directly instead of using transition tables (which contain every updated row, not just the current row)
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _username text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    _username := public.get_user_login_without_domain('');

    If OLD.state <> NEW.state Or
       OLD.state = NEW.state And
       Not _username IN ('postgres', 'msdadmin') Then

        INSERT INTO t_data_analysis_request_updates( request_id,
                                                     entered_by,
                                                     old_state_id,
                                                     new_state_id )
        SELECT NEW.request_id,
               _username,
               OLD.state,
               NEW.state;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_data_analysis_request_after_update() OWNER TO d3l243;

