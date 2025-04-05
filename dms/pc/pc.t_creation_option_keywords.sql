--
-- Name: t_creation_option_keywords; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_creation_option_keywords (
    keyword_id integer NOT NULL,
    keyword public.citext NOT NULL,
    display public.citext NOT NULL,
    description public.citext,
    default_value public.citext,
    is_required smallint DEFAULT 0 NOT NULL
);


ALTER TABLE pc.t_creation_option_keywords OWNER TO d3l243;

--
-- Name: t_creation_option_keywords_keyword_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_creation_option_keywords ALTER COLUMN keyword_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_creation_option_keywords_keyword_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_creation_option_keywords pk_t_creation_option_keywords; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_creation_option_keywords
    ADD CONSTRAINT pk_t_creation_option_keywords PRIMARY KEY (keyword_id);

ALTER TABLE pc.t_creation_option_keywords CLUSTER ON pk_t_creation_option_keywords;

--
-- Name: TABLE t_creation_option_keywords; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_creation_option_keywords TO readaccess;
GRANT SELECT ON TABLE pc.t_creation_option_keywords TO writeaccess;

