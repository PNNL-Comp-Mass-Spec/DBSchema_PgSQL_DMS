--
-- Name: t_dataset_nom_stats_xml; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_dataset_nom_stats_xml (
    dataset_id integer NOT NULL,
    nom_stats_xml xml,
    cache_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ignore boolean DEFAULT false NOT NULL
);


ALTER TABLE cap.t_dataset_nom_stats_xml OWNER TO d3l243;

--
-- Name: t_dataset_nom_stats_xml pk_t_dataset_nom_stats_xml; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_dataset_nom_stats_xml
    ADD CONSTRAINT pk_t_dataset_nom_stats_xml PRIMARY KEY (dataset_id);

ALTER TABLE cap.t_dataset_nom_stats_xml CLUSTER ON pk_t_dataset_nom_stats_xml;

--
-- Name: TABLE t_dataset_nom_stats_xml; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_dataset_nom_stats_xml TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_dataset_nom_stats_xml TO writeaccess;

