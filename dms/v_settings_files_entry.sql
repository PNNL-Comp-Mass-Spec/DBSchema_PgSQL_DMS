--
-- Name: v_settings_files_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_settings_files_entry AS
 SELECT settings_file_id AS id,
    analysis_tool,
    file_name,
    description,
    active,
    (contents)::text AS contents,
    hms_auto_supersede,
    msgfplus_auto_centroid AS auto_centroid
   FROM public.t_settings_files;


ALTER VIEW public.v_settings_files_entry OWNER TO d3l243;

--
-- Name: TABLE v_settings_files_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_settings_files_entry TO readaccess;
GRANT SELECT ON TABLE public.v_settings_files_entry TO writeaccess;

