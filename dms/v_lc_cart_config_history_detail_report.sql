--
-- Name: v_lc_cart_config_history_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_config_history_detail_report AS
 SELECT entry_id AS id,
    cart,
    date_of_change,
    description,
    note,
    entered,
    entered_by
   FROM public.t_lc_cart_config_history;


ALTER VIEW public.v_lc_cart_config_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_config_history_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_config_history_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_config_history_detail_report TO writeaccess;

