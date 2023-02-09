--
-- Name: v_mrm_list_attachment_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mrm_list_attachment_entry AS
 SELECT t_attachments.attachment_id AS id,
    t_attachments.attachment_type,
    t_attachments.attachment_name,
    t_attachments.attachment_description,
    t_attachments.owner_username,
    t_attachments.active,
    t_attachments.contents,
    t_attachments.file_name
   FROM public.t_attachments;


ALTER TABLE public.v_mrm_list_attachment_entry OWNER TO d3l243;

--
-- Name: TABLE v_mrm_list_attachment_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mrm_list_attachment_entry TO readaccess;
GRANT SELECT ON TABLE public.v_mrm_list_attachment_entry TO writeaccess;

