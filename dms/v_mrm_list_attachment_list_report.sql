--
-- Name: v_mrm_list_attachment_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mrm_list_attachment_list_report AS
 SELECT t_attachments.attachment_id AS id,
    t_attachments.attachment_name AS name,
    t_attachments.attachment_description AS description,
    t_attachments.owner_username AS owner,
    t_attachments.active,
    t_attachments.created
   FROM public.t_attachments
  WHERE (t_attachments.attachment_type OPERATOR(public.=) 'MRM Transition List'::public.citext);


ALTER VIEW public.v_mrm_list_attachment_list_report OWNER TO d3l243;

--
-- Name: TABLE v_mrm_list_attachment_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mrm_list_attachment_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_mrm_list_attachment_list_report TO writeaccess;

