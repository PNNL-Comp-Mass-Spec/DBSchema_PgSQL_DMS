--
-- Name: v_file_attachment_stats_by_id; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_file_attachment_stats_by_id AS
 SELECT t_file_attachment.entity_type,
    t_file_attachment.entity_id AS id,
    count(t_file_attachment.attachment_id) AS attachments
   FROM public.t_file_attachment
  WHERE (t_file_attachment.active > 0)
  GROUP BY t_file_attachment.entity_type, t_file_attachment.entity_id;


ALTER TABLE public.v_file_attachment_stats_by_id OWNER TO d3l243;

--
-- Name: TABLE v_file_attachment_stats_by_id; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_file_attachment_stats_by_id TO readaccess;
GRANT SELECT ON TABLE public.v_file_attachment_stats_by_id TO writeaccess;

