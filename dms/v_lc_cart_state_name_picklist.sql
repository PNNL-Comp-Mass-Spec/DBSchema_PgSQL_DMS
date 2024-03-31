--
-- Name: v_lc_cart_state_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_state_name_picklist AS
 SELECT cart_state_id AS id,
    cart_state AS name
   FROM public.t_lc_cart_state_name
  WHERE (cart_state_id > 1);


ALTER VIEW public.v_lc_cart_state_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_state_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_state_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_state_name_picklist TO writeaccess;

