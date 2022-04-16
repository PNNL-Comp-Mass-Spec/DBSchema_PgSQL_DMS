--
-- Name: t_organisms_change_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_organisms_change_history (
    event_id integer NOT NULL,
    organism_id integer NOT NULL,
    organism public.citext NOT NULL,
    description public.citext,
    short_name public.citext,
    domain public.citext,
    kingdom public.citext,
    phylum public.citext,
    class public.citext,
    "order" public.citext,
    family public.citext,
    genus public.citext,
    species public.citext,
    strain public.citext,
    active smallint,
    newt_identifier integer,
    newt_id_list public.citext,
    ncbi_taxonomy_id integer,
    entered timestamp without time zone NOT NULL,
    entered_by public.citext
);


ALTER TABLE public.t_organisms_change_history OWNER TO d3l243;

--
-- Name: TABLE t_organisms_change_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organisms_change_history TO readaccess;

