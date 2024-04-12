--
-- Name: v_lc_cart_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_list_report AS
 SELECT cart.cart_id AS id,
    cart.cart_name,
    cart.cart_description AS description,
    cartstate.cart_state AS state,
    cart.created
   FROM (public.t_lc_cart cart
     JOIN public.t_lc_cart_state_name cartstate ON ((cart.cart_state_id = cartstate.cart_state_id)))
  WHERE (cart.cart_id > 1);


ALTER VIEW public.v_lc_cart_list_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_list_report TO writeaccess;

