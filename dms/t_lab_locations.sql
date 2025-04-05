--
-- Name: t_lab_locations; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lab_locations (
    lab_id integer NOT NULL,
    lab_name public.citext NOT NULL,
    lab_description public.citext DEFAULT ''::public.citext NOT NULL,
    lab_active smallint DEFAULT 1 NOT NULL,
    sort_weight integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_lab_locations OWNER TO d3l243;

--
-- Name: t_lab_locations_lab_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_lab_locations ALTER COLUMN lab_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_lab_locations_lab_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_lab_locations pk_t_lab_locations; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lab_locations
    ADD CONSTRAINT pk_t_lab_locations PRIMARY KEY (lab_id);

ALTER TABLE public.t_lab_locations CLUSTER ON pk_t_lab_locations;

--
-- Name: ix_t_lab_locations_active; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_lab_locations_active ON public.t_lab_locations USING btree (lab_active, sort_weight, lab_name) INCLUDE (lab_description);

--
-- Name: ix_t_lab_locations_lab_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_lab_locations_lab_name ON public.t_lab_locations USING btree (lab_name);

--
-- Name: TABLE t_lab_locations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lab_locations TO readaccess;
GRANT SELECT ON TABLE public.t_lab_locations TO writeaccess;

