--
-- Name: t_cv_uo; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_uo (
    entry_id integer NOT NULL,
    term_pk public.citext NOT NULL,
    term_name public.citext NOT NULL,
    identifier public.citext NOT NULL,
    is_leaf smallint NOT NULL,
    parent_term_name public.citext NOT NULL,
    parent_term_id public.citext NOT NULL,
    grandparent_term_name public.citext,
    grandparent_term_id public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE ont.t_cv_uo OWNER TO d3l243;

--
-- Name: t_cv_uo_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_cv_uo ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_cv_uo_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cv_uo pk_t_cv_uo; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_uo
    ADD CONSTRAINT pk_t_cv_uo PRIMARY KEY (entry_id);

ALTER TABLE ont.t_cv_uo CLUSTER ON pk_t_cv_uo;

--
-- Name: TABLE t_cv_uo; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_cv_uo TO readaccess;
GRANT SELECT ON TABLE ont.t_cv_uo TO writeaccess;

