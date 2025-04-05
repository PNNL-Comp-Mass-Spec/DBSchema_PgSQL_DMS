--
-- Name: t_data_analysis_request_data_package_ids; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_analysis_request_data_package_ids (
    request_id integer NOT NULL,
    data_pkg_id integer NOT NULL
);


ALTER TABLE public.t_data_analysis_request_data_package_ids OWNER TO d3l243;

--
-- Name: t_data_analysis_request_data_package_ids pk_t_data_analysis_request_request_data_pkg_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_data_package_ids
    ADD CONSTRAINT pk_t_data_analysis_request_request_data_pkg_id PRIMARY KEY (request_id, data_pkg_id);

ALTER TABLE public.t_data_analysis_request_data_package_ids CLUSTER ON pk_t_data_analysis_request_request_data_pkg_id;

--
-- Name: ix_t_data_analysis_request_data_package_ids; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_data_analysis_request_data_package_ids ON public.t_data_analysis_request_data_package_ids USING btree (data_pkg_id, request_id);

--
-- Name: t_data_analysis_request_data_package_ids fk_t_data_analysis_request_data_package_ids_t_data_package; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_data_package_ids
    ADD CONSTRAINT fk_t_data_analysis_request_data_package_ids_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id);

--
-- Name: t_data_analysis_request_data_package_ids fk_t_data_analysis_request_data_pkg_ids_t_data_analysis_request; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_analysis_request_data_package_ids
    ADD CONSTRAINT fk_t_data_analysis_request_data_pkg_ids_t_data_analysis_request FOREIGN KEY (request_id) REFERENCES public.t_data_analysis_request(request_id);

--
-- Name: TABLE t_data_analysis_request_data_package_ids; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_analysis_request_data_package_ids TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_data_analysis_request_data_package_ids TO writeaccess;

