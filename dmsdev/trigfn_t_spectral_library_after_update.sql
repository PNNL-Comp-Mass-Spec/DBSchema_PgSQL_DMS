--
-- Name: trigfn_t_spectral_library_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_spectral_library_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected if library_state_id is changed
**
**  Auth:   mem
**  Date:   03/18/2023 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_spectral_library
    SET last_affected = CURRENT_TIMESTAMP
    WHERE library_id = NEW.library_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_spectral_library_after_update() OWNER TO d3l243;

