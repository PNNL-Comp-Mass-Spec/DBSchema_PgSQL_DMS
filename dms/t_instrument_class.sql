--
-- Name: t_instrument_class; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_class (
    instrument_class public.citext NOT NULL,
    is_purgeable smallint DEFAULT 0 NOT NULL,
    raw_data_type public.citext DEFAULT 'na'::public.citext NOT NULL,
    requires_preparation smallint DEFAULT 0 NOT NULL,
    params xml,
    comment public.citext
);


ALTER TABLE public.t_instrument_class OWNER TO d3l243;

--
-- Name: t_instrument_class pk_t_instrument_class; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_class
    ADD CONSTRAINT pk_t_instrument_class PRIMARY KEY (instrument_class);

ALTER TABLE public.t_instrument_class CLUSTER ON pk_t_instrument_class;

--
-- Name: t_instrument_class fk_t_instrument_class_t_instrument_data_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_class
    ADD CONSTRAINT fk_t_instrument_class_t_instrument_data_type_name FOREIGN KEY (raw_data_type) REFERENCES public.t_instrument_data_type_name(raw_data_type_name) ON UPDATE CASCADE;

--
-- Name: TABLE t_instrument_class; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_class TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_instrument_class TO writeaccess;

