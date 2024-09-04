--
-- Name: trigfn_v_spectral_library_instead_of_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_v_spectral_library_instead_of_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Allows for updating two columns in view public.v_spectral_library:
**        sl.library_state_id,
**        sl.comment
**
**  Auth:   mem
**  Date:   09/04/2024 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If TG_OP = 'UPDATE' Then
        UPDATE public.t_spectral_library
        SET library_state_id = NEW.library_state_id,
            comment          = NEW.comment
        WHERE library_id = OLD.library_id;

        RETURN NEW;
    End If;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigfn_v_spectral_library_instead_of_update() OWNER TO d3l243;

