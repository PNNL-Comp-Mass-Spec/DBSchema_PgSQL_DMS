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
-- Name: TABLE t_dataset_device; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_device TO readaccess;

