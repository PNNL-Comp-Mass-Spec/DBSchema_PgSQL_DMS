--
-- Name: t_enzymes; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_enzymes (
    enzyme_id integer NOT NULL,
    enzyme_name public.citext NOT NULL,
    description public.citext NOT NULL,
    p1 public.citext NOT NULL,
    p1_exception public.citext NOT NULL,
    p2 public.citext NOT NULL,
    p2_exception public.citext NOT NULL,
    cleavage_method public.citext NOT NULL,
    cleavage_offset smallint NOT NULL,
    sequest_enzyme_index integer,
    protein_collection_name public.citext,
    comment public.citext
);


ALTER TABLE public.t_enzymes OWNER TO d3l243;

--
-- Name: TABLE t_enzymes; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_enzymes TO readaccess;

