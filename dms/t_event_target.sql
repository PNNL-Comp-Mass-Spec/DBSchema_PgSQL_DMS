--
-- Name: t_event_target; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_event_target (
    target_type_id integer NOT NULL,
    target_type public.citext,
    target_table public.citext,
    target_id_column public.citext,
    target_state_column public.citext
);


ALTER TABLE public.t_event_target OWNER TO d3l243;

--
-- Name: TABLE t_event_target; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_event_target TO readaccess;

