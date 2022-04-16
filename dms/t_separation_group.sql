--
-- Name: t_separation_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_separation_group (
    separation_group public.citext NOT NULL,
    comment public.citext,
    active smallint NOT NULL,
    sample_prep_visible smallint NOT NULL,
    fraction_count smallint NOT NULL
);


ALTER TABLE public.t_separation_group OWNER TO d3l243;

--
-- Name: TABLE t_separation_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_separation_group TO readaccess;

