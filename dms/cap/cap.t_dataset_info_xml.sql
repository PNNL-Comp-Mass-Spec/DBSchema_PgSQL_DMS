--
-- Name: t_dataset_info_xml; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_dataset_info_xml (
    dataset_id integer NOT NULL,
    ds_info_xml xml,
    cache_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ignore boolean DEFAULT false NOT NULL
);


ALTER TABLE cap.t_dataset_info_xml OWNER TO d3l243;

--
-- Name: t_dataset_info_xml pk_t_dataset_info_xml; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_dataset_info_xml
    ADD CONSTRAINT pk_t_dataset_info_xml PRIMARY KEY (dataset_id);

