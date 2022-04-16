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
-- Name: TABLE t_instrument_data_type_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_data_type_name TO readaccess;

