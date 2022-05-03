--
-- Name: t_dataset_device; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_device (
    device_id integer NOT NULL,
    device_type public.citext NOT NULL,
    device_number integer NOT NULL,
    device_name public.citext NOT NULL,
    device_model public.citext NOT NULL,
    serial_number public.citext NOT NULL,
    software_version public.citext NOT NULL,
    device_description public.citext NOT NULL
);


ALTER TABLE public.t_dataset_device OWNER TO d3l243;

--
-- Name: t_dataset_device_device_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_dataset_device ALTER COLUMN device_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_dataset_device_device_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dataset_device pk_t_dataset_device; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_device
    ADD CONSTRAINT pk_t_dataset_device PRIMARY KEY (device_id);

--
-- Name: ix_t_dataset_device_type_name_model_serial_software; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_dataset_device_type_name_model_serial_software ON public.t_dataset_device USING btree (device_type, device_name, device_model, serial_number, software_version);

--
-- Name: TABLE t_dataset_device; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_device TO readaccess;

