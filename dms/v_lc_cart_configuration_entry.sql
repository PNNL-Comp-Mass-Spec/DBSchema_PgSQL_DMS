--
-- Name: v_lc_cart_configuration_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_configuration_entry AS
 SELECT config.cart_config_id AS id,
    config.cart_config_name AS config_name,
    config.description,
    config.autosampler,
    config.custom_valve_config,
    config.pumps,
    config.primary_injection_volume,
    config.primary_mobile_phases,
    config.primary_trap_column,
    config.primary_trap_flow_rate,
    config.primary_trap_time,
    config.primary_trap_mobile_phase,
    config.primary_analytical_column,
    config.primary_column_temperature,
    config.primary_analytical_flow_rate,
    config.primary_gradient,
    config.mass_spec_start_delay,
    config.upstream_injection_volume,
    config.upstream_mobile_phases,
    config.upstream_trap_column,
    config.upstream_trap_flow_rate,
    config.upstream_analytical_column,
    config.upstream_column_temperature,
    config.upstream_analytical_flow_rate,
    config.upstream_fractionation_profile,
    config.upstream_fractionation_details,
    config.cart_config_state,
    config.entered_by
   FROM (public.t_lc_cart_configuration config
     JOIN public.t_lc_cart cart ON ((config.cart_id = cart.cart_id)));


ALTER TABLE public.v_lc_cart_configuration_entry OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_configuration_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_configuration_entry TO readaccess;

