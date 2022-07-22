--
-- Name: v_lc_cart_configuration_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_configuration_detail_report AS
 SELECT config.cart_config_id AS id,
    config.cart_config_name AS config_name,
    cart.cart_name AS cart,
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
    config.dataset_usage_count AS dataset_usage,
    config.dataset_usage_last_year,
    config.cart_config_state,
    cart.cart_id,
    config.entered,
    u1.name_with_username AS entered_by,
    config.updated,
    u2.name_with_username AS updated_by
   FROM (((public.t_lc_cart_configuration config
     JOIN public.t_lc_cart cart ON ((config.cart_id = cart.cart_id)))
     JOIN public.t_users u1 ON ((config.entered_by OPERATOR(public.=) u1.username)))
     LEFT JOIN public.t_users u2 ON ((config.updated_by OPERATOR(public.=) u2.username)));


ALTER TABLE public.v_lc_cart_configuration_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_configuration_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_configuration_detail_report TO readaccess;

