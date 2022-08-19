--
-- Name: t_unimod_bricks; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_unimod_bricks (
    name public.citext NOT NULL,
    full_name public.citext,
    mono_mass real NOT NULL,
    avg_mass real NOT NULL,
    composition public.citext
);


ALTER TABLE ont.t_unimod_bricks OWNER TO d3l243;

--
-- Name: t_unimod_bricks pk_t_unimod_bricks; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_unimod_bricks
    ADD CONSTRAINT pk_t_unimod_bricks PRIMARY KEY (name);

--
-- Name: TABLE t_unimod_bricks; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_unimod_bricks TO readaccess;
GRANT SELECT ON TABLE ont.t_unimod_bricks TO writeaccess;

