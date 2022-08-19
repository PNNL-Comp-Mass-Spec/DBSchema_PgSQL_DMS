--
-- Name: t_unimod_specificity_nl; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_unimod_specificity_nl (
    unimod_id integer NOT NULL,
    specificity_entry_id smallint NOT NULL,
    neutral_loss_entry_id smallint NOT NULL,
    mono_mass real NOT NULL,
    avg_mass real NOT NULL,
    composition public.citext NOT NULL,
    flag boolean NOT NULL
);


ALTER TABLE ont.t_unimod_specificity_nl OWNER TO d3l243;

--
-- Name: t_unimod_specificity_nl pk_t_unimod_specificity_nl; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_unimod_specificity_nl
    ADD CONSTRAINT pk_t_unimod_specificity_nl PRIMARY KEY (unimod_id, specificity_entry_id, neutral_loss_entry_id);

--
-- Name: TABLE t_unimod_specificity_nl; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_unimod_specificity_nl TO readaccess;

