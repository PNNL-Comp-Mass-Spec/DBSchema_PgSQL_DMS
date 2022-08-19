--
-- Name: v_lc_cart_configuration_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_configuration_list_report AS
 SELECT config.cart_config_id AS id,
    config.cart_config_name AS config_name,
    cart.cart_name AS cart,
    config.description,
    config.autosampler,
    config.pumps,
    config.primary_injection_volume AS primary_inj_vol,
    config.primary_mobile_phases AS primary_mp,
    config.primary_trap_column AS primary_trap_col,
    config.primary_trap_flow_rate AS primary_trap_flow,
    config.primary_trap_time,
    config.primary_trap_mobile_phase AS primary_trap_mp,
    config.primary_analytical_column AS primary_column,
    config.primary_column_temperature AS primary_temp,
    config.primary_analytical_flow_rate AS primary_flow,
    config.mass_spec_start_delay AS ms_start_delay,
    config.upstream_injection_volume AS upstream_inj_vol,
    config.upstream_mobile_phases AS upstream_mp,
    config.upstream_analytical_column AS upstream_column,
    config.upstream_analytical_flow_rate AS upstream_flow,
    config.upstream_fractionation_profile AS upstream_frac_profile,
    config.dataset_usage_count AS dataset_usage,
    config.dataset_usage_last_year AS usage_last_year,
    config.cart_config_state AS state,
    config.entered,
    config.entered_by,
    config.updated,
    config.updated_by
   FROM (public.t_lc_cart_configuration config
     JOIN public.t_lc_cart cart ON ((config.cart_id = cart.cart_id)));


ALTER TABLE public.v_lc_cart_configuration_list_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_configuration_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_configuration_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_configuration_list_report TO writeaccess;

