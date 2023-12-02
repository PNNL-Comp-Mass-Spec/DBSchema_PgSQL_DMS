--
-- Name: v_lc_cart_state_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_state_name_picklist AS
 SELECT t_lc_cart_state_name.cart_state_id AS id,
    t_lc_cart_state_name.cart_state
   FROM public.t_lc_cart_state_name
  WHERE (t_lc_cart_state_name.cart_state_id > 1);


ALTER VIEW public.v_lc_cart_state_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_state_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_state_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_state_name_picklist TO writeaccess;

