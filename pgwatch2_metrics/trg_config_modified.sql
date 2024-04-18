--
-- Name: trg_config_modified(); Type: FUNCTION; Schema: public; Owner: pgwatch2
--

CREATE OR REPLACE FUNCTION public.trg_config_modified() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.last_modified_on = now();
  return new;
end;
$$;


ALTER FUNCTION public.trg_config_modified() OWNER TO pgwatch2;

