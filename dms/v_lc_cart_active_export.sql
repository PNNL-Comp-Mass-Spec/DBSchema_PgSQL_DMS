--
-- Name: v_lc_cart_active_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_active_export AS
 SELECT cart.cart_id AS id,
    cart.cart_name,
    cart.cart_description,
    cartstate.cart_state AS state,
    cart.created
   FROM (public.t_lc_cart cart
     JOIN public.t_lc_cart_state_name cartstate ON ((cart.cart_state_id = cartstate.cart_state_id)))
  WHERE ((cart.cart_id > 1) AND (NOT (cartstate.cart_state OPERATOR(public.=) 'Retired'::public.citext)));


ALTER TABLE public.v_lc_cart_active_export OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_active_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_active_export TO readaccess;

