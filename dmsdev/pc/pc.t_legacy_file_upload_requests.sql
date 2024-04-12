--
-- Name: t_legacy_file_upload_requests; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_legacy_file_upload_requests (
    upload_request_id integer NOT NULL,
    legacy_file_id integer NOT NULL,
    legacy_file_name public.citext,
    date_requested timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_uploaded timestamp without time zone,
    upload_completed smallint DEFAULT 0 NOT NULL,
    authentication_hash public.citext DEFAULT ''::public.citext
);


ALTER TABLE pc.t_legacy_file_upload_requests OWNER TO d3l243;

--
-- Name: t_legacy_file_upload_requests_upload_request_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_legacy_file_upload_requests ALTER COLUMN upload_request_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_legacy_file_upload_requests_upload_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_legacy_file_upload_requests pk_t_legacy_file_upload_requests; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_legacy_file_upload_requests
    ADD CONSTRAINT pk_t_legacy_file_upload_requests PRIMARY KEY (upload_request_id);

--
-- Name: TABLE t_legacy_file_upload_requests; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_legacy_file_upload_requests TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_legacy_file_upload_requests TO writeaccess;

