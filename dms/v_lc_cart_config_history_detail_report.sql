--
-- Name: v_lc_cart_config_history_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_config_history_detail_report AS
 SELECT t_lc_cart_config_history.entry_id AS id,
    t_lc_cart_config_history.cart,
    t_lc_cart_config_history.date_of_change,
    t_lc_cart_config_history.description,
    t_lc_cart_config_history.note,
    t_lc_cart_config_history.entered,
    t_lc_cart_config_history.entered_by
   FROM public.t_lc_cart_config_history;


ALTER VIEW public.v_lc_cart_config_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_config_history_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_config_history_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_config_history_detail_report TO writeaccess;

