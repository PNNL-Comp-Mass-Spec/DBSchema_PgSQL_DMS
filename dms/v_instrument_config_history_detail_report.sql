--
-- Name: v_instrument_config_history_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_config_history_detail_report AS
 SELECT h.entry_id AS id,
    h.instrument,
    (h.date_of_change)::date AS date_of_change,
        CASE
            WHEN (u.username IS NULL) THEN h.entered_by
            ELSE u.name_with_username
        END AS entered_by,
    h.entered,
    h.description,
    h.note
   FROM (public.t_instrument_config_history h
     LEFT JOIN public.t_users u ON ((h.entered_by OPERATOR(public.=) u.username)));


ALTER VIEW public.v_instrument_config_history_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_config_history_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_config_history_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_config_history_detail_report TO writeaccess;

