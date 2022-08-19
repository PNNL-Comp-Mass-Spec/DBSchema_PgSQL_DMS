--
-- Name: v_lc_cart_config_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_config_export AS
 SELECT config.cart_config_id,
    config.cart_config_name,
    cart.cart_name,
    config.description,
    config.autosampler,
    config.pumps,
    config.dataset_usage_count,
    config.dataset_usage_last_year,
    config.cart_config_state,
    cartstate.cart_state
   FROM ((public.t_lc_cart_configuration config
     JOIN public.t_lc_cart cart ON ((config.cart_id = cart.cart_id)))
     JOIN public.t_lc_cart_state_name cartstate ON ((cart.cart_state_id = cartstate.cart_state_id)));


ALTER TABLE public.v_lc_cart_config_export OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_config_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_config_export TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_config_export TO writeaccess;

