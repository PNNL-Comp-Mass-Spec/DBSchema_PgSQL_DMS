--
-- Name: t_shared_results; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_shared_results (
    results_name public.citext NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE sw.t_shared_results OWNER TO d3l243;

--
-- Name: t_shared_results pk_t_shared_results; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_shared_results
    ADD CONSTRAINT pk_t_shared_results PRIMARY KEY (results_name);

ALTER TABLE sw.t_shared_results CLUSTER ON pk_t_shared_results;

--
-- Name: TABLE t_shared_results; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_shared_results TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_shared_results TO writeaccess;

