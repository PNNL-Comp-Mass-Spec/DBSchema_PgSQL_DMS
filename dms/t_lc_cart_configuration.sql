--
-- Name: t_lc_cart_configuration; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart_configuration (
    cart_config_id integer NOT NULL,
    cart_config_name public.citext NOT NULL,
    cart_id integer NOT NULL,
    description public.citext,
    autosampler public.citext,
    custom_valve_config public.citext,
    pumps public.citext,
    primary_injection_volume public.citext,
    primary_mobile_phases public.citext,
    primary_trap_column public.citext,
    primary_trap_flow_rate public.citext,
    primary_trap_time public.citext,
    primary_trap_mobile_phase public.citext,
    primary_analytical_column public.citext,
    primary_column_temperature public.citext,
    primary_analytical_flow_rate public.citext,
    primary_gradient public.citext,
    mass_spec_start_delay public.citext,
    upstream_injection_volume public.citext,
    upstream_mobile_phases public.citext,
    upstream_trap_column public.citext,
    upstream_trap_flow_rate public.citext,
    upstream_analytical_column public.citext,
    upstream_column_temperature public.citext,
    upstream_analytical_flow_rate public.citext,
    upstream_fractionation_profile public.citext,
    upstream_fractionation_details public.citext,
    cart_config_state public.citext NOT NULL,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext NOT NULL,
    updated timestamp without time zone,
    updated_by public.citext,
    dataset_usage_count integer,
    dataset_usage_last_year integer
);


ALTER TABLE public.t_lc_cart_configuration OWNER TO d3l243;

--
-- Name: TABLE t_lc_cart_configuration; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart_configuration TO readaccess;

