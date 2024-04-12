--
-- Name: v_file_attachment_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_file_attachment_export AS
 SELECT fa.attachment_id,
    fa.file_name,
    fa.description,
    fa.entity_type,
    fa.entity_id,
    u.name_with_username AS owner,
    fa.file_size_kb,
    fa.created,
    fa.last_affected,
    fa.archive_folder_path,
    fa.active
   FROM (public.t_file_attachment fa
     JOIN public.t_users u ON ((fa.owner_username OPERATOR(public.=) u.username)));


ALTER VIEW public.v_file_attachment_export OWNER TO d3l243;

--
-- Name: TABLE v_file_attachment_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_file_attachment_export TO readaccess;
GRANT SELECT ON TABLE public.v_file_attachment_export TO writeaccess;

