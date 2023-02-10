--
-- Name: v_file_attachment_display; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_file_attachment_display AS
 SELECT fa.attachment_id AS id,
    fa.file_name AS name,
    fa.description,
    fa.entity_type,
    fa.entity_id,
    u.name AS owner,
    fa.file_size_bytes AS bytes,
    fa.last_affected,
    fa.archive_folder_path,
    fa.file_mime_type
   FROM (public.t_file_attachment fa
     JOIN public.t_users u ON ((fa.owner_username OPERATOR(public.=) u.username)))
  WHERE (fa.active > 0);


ALTER TABLE public.v_file_attachment_display OWNER TO d3l243;

--
-- Name: TABLE v_file_attachment_display; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_file_attachment_display TO readaccess;
GRANT SELECT ON TABLE public.v_file_attachment_display TO writeaccess;

