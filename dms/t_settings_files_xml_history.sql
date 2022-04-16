--
-- Name: t_settings_files_xml_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_settings_files_xml_history (
    event_id integer NOT NULL,
    event_action public.citext NOT NULL,
    id integer NOT NULL,
    analysis_tool public.citext NOT NULL,
    file_name public.citext NOT NULL,
    description public.citext,
    contents xml,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext
);


ALTER TABLE public.t_settings_files_xml_history OWNER TO d3l243;

--
-- Name: TABLE t_settings_files_xml_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_settings_files_xml_history TO readaccess;

