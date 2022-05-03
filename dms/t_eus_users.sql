--
-- Name: t_eus_users; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_users (
    person_id integer NOT NULL,
    name_fm public.citext,
    hid public.citext,
    site_status smallint NOT NULL,
    last_affected timestamp without time zone,
    last_name public.citext,
    first_name public.citext,
    valid smallint NOT NULL
);


ALTER TABLE public.t_eus_users OWNER TO d3l243;

--
-- Name: t_eus_users pk_t_eus_users; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_eus_users
    ADD CONSTRAINT pk_t_eus_users PRIMARY KEY (person_id);

--
-- Name: ix_t_eus_users_site_status_include_person_id_name_fm_hid; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_eus_users_site_status_include_person_id_name_fm_hid ON public.t_eus_users USING btree (site_status) INCLUDE (person_id, name_fm, hid);

--
-- Name: TABLE t_eus_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_users TO readaccess;

