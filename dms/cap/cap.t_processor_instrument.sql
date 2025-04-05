--
-- Name: t_processor_instrument; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_processor_instrument (
    processor_name public.citext NOT NULL,
    instrument_name public.citext NOT NULL,
    enabled smallint NOT NULL,
    comment public.citext NOT NULL
);


ALTER TABLE cap.t_processor_instrument OWNER TO d3l243;

--
-- Name: t_processor_instrument pk_processor_instrument; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_processor_instrument
    ADD CONSTRAINT pk_processor_instrument PRIMARY KEY (processor_name, instrument_name);

ALTER TABLE cap.t_processor_instrument CLUSTER ON pk_processor_instrument;

--
-- Name: TABLE t_processor_instrument; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_processor_instrument TO readaccess;
GRANT SELECT ON TABLE cap.t_processor_instrument TO writeaccess;

