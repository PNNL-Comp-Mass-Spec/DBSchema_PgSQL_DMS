--
-- Name: v_lc_cart_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_entry AS
 SELECT cart.cart_id AS id,
    cart.cart_name,
    cartstate.cart_state,
    cart.cart_description
   FROM (public.t_lc_cart cart
     JOIN public.t_lc_cart_state_name cartstate ON ((cart.cart_state_id = cartstate.cart_state_id)));


ALTER TABLE public.v_lc_cart_entry OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_entry TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_entry TO writeaccess;

