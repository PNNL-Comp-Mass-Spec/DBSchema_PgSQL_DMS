--
-- Name: v_file_attachment_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_file_attachment_list_report AS
 SELECT fa.attachment_id AS id,
    fa.file_name,
    fa.description,
    fa.entity_type,
    fa.entity_id,
    u.name_with_username AS owner,
    fa.file_size_kb AS size_kb,
    fa.created,
    fa.last_affected
   FROM (public.t_file_attachment fa
     JOIN public.t_users u ON ((fa.owner_prn OPERATOR(public.=) u.username)))
  WHERE (fa.active > 0);


ALTER TABLE public.v_file_attachment_list_report OWNER TO d3l243;

--
-- Name: TABLE v_file_attachment_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_file_attachment_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_file_attachment_list_report TO writeaccess;

