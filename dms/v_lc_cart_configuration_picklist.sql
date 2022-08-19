--
-- Name: v_lc_cart_configuration_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_configuration_picklist AS
 SELECT config.cart_config_name AS name,
    config.description AS "desc",
    COALESCE(config.dataset_usage_last_year, 0) AS dataset_count,
    COALESCE(config.dataset_usage_count, 0) AS datasets_all_time,
    cart.cart_name AS cart,
    config.cart_config_id AS id,
        CASE
            WHEN (COALESCE(config.dataset_usage_count, 0) > 0) THEN (config.dataset_usage_count + 1000000)
            ELSE COALESCE(config.dataset_usage_last_year, 0)
        END AS sortkey
   FROM (public.t_lc_cart_configuration config
     JOIN public.t_lc_cart cart ON ((config.cart_id = cart.cart_id)))
  WHERE (config.cart_config_state OPERATOR(public.=) 'Active'::public.citext);


ALTER TABLE public.v_lc_cart_configuration_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_configuration_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_configuration_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_configuration_picklist TO writeaccess;

