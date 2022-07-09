--
-- Name: t_sample_prep_request_items; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_prep_request_items (
    prep_request_item_id integer NOT NULL,
    item_id integer NOT NULL,
    item_name public.citext,
    item_type public.citext NOT NULL,
    status public.citext,
    created timestamp without time zone,
    item_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_sample_prep_request_items OWNER TO d3l243;

--
-- Name: t_sample_prep_request_items pk_t_sample_prep_request_items; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request_items
    ADD CONSTRAINT pk_t_sample_prep_request_items PRIMARY KEY (prep_request_item_id, item_id, item_type);

--
-- Name: t_sample_prep_request_items fk_t_sample_prep_request_items_t_sample_prep_request; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_prep_request_items
    ADD CONSTRAINT fk_t_sample_prep_request_items_t_sample_prep_request FOREIGN KEY (prep_request_item_id) REFERENCES public.t_sample_prep_request(prep_request_id);

--
-- Name: TABLE t_sample_prep_request_items; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_prep_request_items TO readaccess;

