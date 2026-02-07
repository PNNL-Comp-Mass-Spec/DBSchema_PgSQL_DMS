--
-- Name: trigfn_t_emsl_dms_instrument_mapping_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_emsl_dms_instrument_mapping_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected in trigfn_t_emsl_dms_instrument_mapping
**
**  Auth:   mem
**  Date:   02/02/2026 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_emsl_dms_instrument_mapping
    SET last_affected = CURRENT_TIMESTAMP
    WHERE t_emsl_dms_instrument_mapping.eus_instrument_id = NEW.eus_instrument_id AND
          t_emsl_dms_instrument_mapping.dms_instrument_id = NEW.dms_instrument_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_emsl_dms_instrument_mapping_after_update() OWNER TO d3l243;

