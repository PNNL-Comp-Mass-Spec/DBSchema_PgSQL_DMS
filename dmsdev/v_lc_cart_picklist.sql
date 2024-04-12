--
-- Name: v_lc_cart_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_picklist AS
 SELECT cart_id AS id,
    cart_name AS name
   FROM public.t_lc_cart
  WHERE (cart_state_id = 2);


ALTER VIEW public.v_lc_cart_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_picklist TO writeaccess;

