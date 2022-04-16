--
-- Name: t_entity_rename_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_entity_rename_log (
    entry_id integer NOT NULL,
    target_type integer NOT NULL,
    target_id integer NOT NULL,
    old_name public.citext,
    new_name public.citext,
    entered timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_entity_rename_log OWNER TO d3l243;

--
-- Name: TABLE t_entity_rename_log; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_entity_rename_log TO readaccess;

