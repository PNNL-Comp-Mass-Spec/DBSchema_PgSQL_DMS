--
-- Name: t_instrument_data_type_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_data_type_name (
    raw_data_type_id integer NOT NULL,
    raw_data_type_name public.citext NOT NULL,
    is_folder smallint NOT NULL,
    required_file_extension public.citext NOT NULL,
    comment public.citext
);


ALTER TABLE public.t_instrument_data_type_name OWNER TO d3l243;

--
-- Name: t_instrument_data_type_name_raw_data_type_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_instrument_data_type_name ALTER COLUMN raw_data_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_instrument_data_type_name_raw_data_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_instrument_data_type_name pk_t_instrument_data_type_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_data_type_name
    ADD CONSTRAINT pk_t_instrument_data_type_name PRIMARY KEY (raw_data_type_id);

--
-- Name: TABLE t_instrument_data_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_data_type_name TO readaccess;

