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
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_organisms_change_history OWNER TO d3l243;

--
-- Name: t_organisms_change_history_event_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_organisms_change_history ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_organisms_change_history_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_organisms_change_history pk_t_organisms_change_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organisms_change_history
    ADD CONSTRAINT pk_t_organisms_change_history PRIMARY KEY (event_id);

--
-- Name: ix_t_organisms_change_history; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_organisms_change_history ON public.t_organisms_change_history USING btree (organism_id);

--
-- Name: TABLE t_organisms_change_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organisms_change_history TO readaccess;
GRANT SELECT ON TABLE public.t_organisms_change_history TO writeaccess;

