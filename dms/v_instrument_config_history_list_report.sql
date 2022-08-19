--
-- Name: v_instrument_config_history_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_config_history_list_report AS
 SELECT h.entry_id AS id,
    h.instrument,
    (h.date_of_change)::date AS date_of_change,
    h.description,
        CASE
            WHEN (char_length((h.note)::text) <= 150) THEN (h.note)::text
            ELSE ("left"((h.note)::text, 150) || ' (more...)'::text)
        END AS note,
    h.entered,
        CASE
            WHEN (u.username IS NULL) THEN h.entered_by
            ELSE u.name_with_username
        END AS entered_by,
    h.note AS "#NoteFull"
   FROM (public.t_instrument_config_history h
     LEFT JOIN public.t_users u ON ((h.entered_by OPERATOR(public.=) u.username)));


ALTER TABLE public.v_instrument_config_history_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_config_history_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_config_history_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_config_history_list_report TO writeaccess;

