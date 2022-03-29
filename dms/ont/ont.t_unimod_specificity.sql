--
-- Name: t_unimod_specificity; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_unimod_specificity (
    unimod_id integer NOT NULL,
    specificity_entry_id smallint NOT NULL,
    specificity_group_id smallint NOT NULL,
    site public.citext NOT NULL,
    "position" public.citext NOT NULL,
    classification public.citext NOT NULL,
    notes public.citext,
    hidden smallint NOT NULL
);


ALTER TABLE ont.t_unimod_specificity OWNER TO d3l243;

--
-- Name: t_unimod_specificity pk_t_unimod_specificity; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_unimod_specificity
    ADD CONSTRAINT pk_t_unimod_specificity PRIMARY KEY (unimod_id, specificity_entry_id);

