--
-- Name: v_instrument_operation_history_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_operation_history_detail_report AS
 SELECT h.entry_id AS id,
    h.instrument,
    u.name_with_username AS posted_by,
    h.entered,
    h.note
   FROM (public.t_instrument_operation_history h
     LEFT JOIN public.t_users u ON ((h.entered_by OPERATOR(public.=) u.username)));


ALTER TABLE public.v_instrument_operation_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_operation_history_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_operation_history_detail_report TO readaccess;

