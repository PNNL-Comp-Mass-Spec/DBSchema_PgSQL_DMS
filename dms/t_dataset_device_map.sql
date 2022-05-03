--
-- Name: t_dataset_device_map; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_device_map (
    dataset_id integer NOT NULL,
    device_id integer NOT NULL
);


ALTER TABLE public.t_dataset_device_map OWNER TO d3l243;

--
-- Name: t_dataset_device_map pk_t_dataset_device_map; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_device_map
    ADD CONSTRAINT pk_t_dataset_device_map PRIMARY KEY (dataset_id, device_id);

--
-- Name: TABLE t_dataset_device_map; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_device_map TO readaccess;

