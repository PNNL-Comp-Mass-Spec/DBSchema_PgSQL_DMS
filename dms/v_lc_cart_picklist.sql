--
-- Name: v_lc_cart_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_picklist AS
 SELECT t_lc_cart.cart_id AS id,
    t_lc_cart.cart_name AS name
   FROM public.t_lc_cart
  WHERE (t_lc_cart.cart_state_id = 2);


ALTER TABLE public.v_lc_cart_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_picklist TO readaccess;

