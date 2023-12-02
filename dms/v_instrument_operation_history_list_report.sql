--
-- Name: v_instrument_operation_history_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_operation_history_list_report AS
 SELECT h.entry_id AS id,
    h.instrument,
    h.entered,
    h.note,
    u.name_with_username AS posted_by
   FROM (public.t_instrument_operation_history h
     LEFT JOIN public.t_users u ON ((h.entered_by OPERATOR(public.=) u.username)));


ALTER VIEW public.v_instrument_operation_history_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_operation_history_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_operation_history_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_operation_history_list_report TO writeaccess;

