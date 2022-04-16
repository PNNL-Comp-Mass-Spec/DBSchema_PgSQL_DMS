--
-- Name: t_wellplates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_wellplates (
    wellplate_id integer NOT NULL,
    wellplate public.citext NOT NULL,
    description public.citext,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_wellplates OWNER TO d3l243;

--
-- Name: TABLE t_wellplates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_wellplates TO readaccess;

