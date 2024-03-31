--
-- Name: v_mrm_list_attachment_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mrm_list_attachment_entry AS
 SELECT attachment_id AS id,
    attachment_type,
    attachment_name,
    attachment_description,
    owner_username,
    active,
    contents,
    file_name
   FROM public.t_attachments;


ALTER VIEW public.v_mrm_list_attachment_entry OWNER TO d3l243;

--
-- Name: TABLE v_mrm_list_attachment_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mrm_list_attachment_entry TO readaccess;
GRANT SELECT ON TABLE public.v_mrm_list_attachment_entry TO writeaccess;

