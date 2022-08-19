--
-- Name: v_lc_cart_config_history_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lc_cart_config_history_list_report AS
 SELECT tih.entry_id AS id,
    tih.cart,
    tih.date_of_change,
    tih.description,
        CASE
            WHEN (length((tih.note)::text) < 150) THEN (tih.note)::text
            ELSE ("substring"((tih.note)::text, 1, 150) || ' (more...)'::text)
        END AS note,
    tih.entered,
    tu.name_with_username AS entered_by,
    attachmentstats.files
   FROM ((public.t_lc_cart_config_history tih
     LEFT JOIN public.t_users tu ON ((tih.entered_by OPERATOR(public.=) tu.username)))
     LEFT JOIN ( SELECT v_file_attachment_stats_by_id.id,
            v_file_attachment_stats_by_id.attachments AS files
           FROM public.v_file_attachment_stats_by_id
          WHERE (v_file_attachment_stats_by_id.entity_type OPERATOR(public.=) 'lc_cart_config_history'::public.citext)) attachmentstats ON (((tih.entry_id)::text = (attachmentstats.id)::text)));


ALTER TABLE public.v_lc_cart_config_history_list_report OWNER TO d3l243;

--
-- Name: TABLE v_lc_cart_config_history_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lc_cart_config_history_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_lc_cart_config_history_list_report TO writeaccess;

