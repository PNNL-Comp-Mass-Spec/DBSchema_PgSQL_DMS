--
-- Name: t_aux_info_allowed_values; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_aux_info_allowed_values (
    aux_info_id integer NOT NULL,
    value public.citext NOT NULL
);


ALTER TABLE public.t_aux_info_allowed_values OWNER TO d3l243;

--
-- Name: t_aux_info_allowed_values pk_t_aux_info_allowed_values; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_allowed_values
    ADD CONSTRAINT pk_t_aux_info_allowed_values PRIMARY KEY (aux_info_id, value);

--
-- Name: t_aux_info_allowed_values fk_t_aux_info_allowed_values_t_aux_info_description; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_aux_info_allowed_values
    ADD CONSTRAINT fk_t_aux_info_allowed_values_t_aux_info_description FOREIGN KEY (aux_info_id) REFERENCES public.t_aux_info_description(aux_description_id);

--
-- Name: TABLE t_aux_info_allowed_values; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_aux_info_allowed_values TO readaccess;

