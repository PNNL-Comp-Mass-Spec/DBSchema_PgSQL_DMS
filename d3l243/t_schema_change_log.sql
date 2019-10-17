--
-- Name: t_schema_change_log; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_schema_change_log (
    schema_change_log_id integer NOT NULL,
    create_date timestamp without time zone NOT NULL,
    login_name public.citext,
    client_addr inet,
    command_tag public.citext NOT NULL,
    object_type public.citext NOT NULL,
    schema_name public.citext,
    object_name public.citext,
    function_name public.citext,
    function_source public.citext
);


ALTER TABLE public.t_schema_change_log OWNER TO d3l243;

--
-- Name: t_schema_change_log_schema_change_log_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_schema_change_log ALTER COLUMN schema_change_log_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_schema_change_log_schema_change_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
