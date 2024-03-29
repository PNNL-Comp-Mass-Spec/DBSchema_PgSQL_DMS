--
-- Name: v_lc_cart_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_detail_report AS
 SELECT cart.cart_id AS id,
    cart.cart_name,
    cart.cart_description AS description,
    cartstate.cart_state AS state,
    COALESCE(cartconfigq.configcount, (0)::bigint) AS configuration_count
   FROM ((public.t_lc_cart cart
     JOIN public.t_lc_cart_state_name cartstate ON ((cart.cart_state_id = cartstate.cart_state_id)))
     LEFT JOIN ( SELECT t_lc_cart_configuration.cart_id,
            count(t_lc_cart_configuration.cart_config_id) AS configcount
           FROM public.t_lc_cart_configuration
          GROUP BY t_lc_cart_configuration.cart_id) cartconfigq ON ((cartconfigq.cart_id = cart.cart_id)));


ALTER VIEW public.v_lc_cart_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_detail_report TO writeaccess;

