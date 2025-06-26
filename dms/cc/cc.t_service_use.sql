--
-- Name: t_service_use; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_use (
    entry_id integer NOT NULL,
    report_id integer NOT NULL,
    ticket_number public.citext NOT NULL,
    charge_code public.citext DEFAULT ''::public.citext NOT NULL,
    service_type_id integer DEFAULT 0 NOT NULL,
    transaction_date timestamp without time zone,
    transaction_units real,
    is_held public.citext DEFAULT 'N'::public.citext NOT NULL,
    comment public.citext DEFAULT ''::public.citext
);


ALTER TABLE cc.t_service_use OWNER TO d3l243;

--
-- Name: TABLE t_service_use; Type: COMMENT; Schema: cc; Owner: d3l243
--

COMMENT ON TABLE cc.t_service_use IS 'Ticket_number is dataset_id and requested_run id; transaction_date is dataset Acq_Start time; transaction units is total_rate_per_run * 1 for non-MALDI or total_rate_per_run * acq_length_hours for MALDI (minimum 15 minutes)';

--
-- Name: t_service_use_entry_id_seq; Type: SEQUENCE; Schema: cc; Owner: d3l243
--

ALTER TABLE cc.t_service_use ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cc.t_service_use_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_use pk_t_service_use; Type: CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_use
    ADD CONSTRAINT pk_t_service_use PRIMARY KEY (entry_id);

--
-- Name: t_service_use fk_t_service_use_t_service_type; Type: FK CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_use
    ADD CONSTRAINT fk_t_service_use_t_service_type FOREIGN KEY (service_type_id) REFERENCES cc.t_service_type(service_type_id);

--
-- Name: TABLE t_service_use; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE cc.t_service_use TO readaccess;
GRANT SELECT ON TABLE cc.t_service_use TO writeaccess;

