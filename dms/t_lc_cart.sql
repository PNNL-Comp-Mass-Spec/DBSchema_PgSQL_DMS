--
-- Name: t_lc_cart; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_lc_cart (
    cart_id integer NOT NULL,
    cart_name public.citext NOT NULL,
    cart_state_id integer NOT NULL,
    cart_description public.citext,
    created timestamp without time zone
);


ALTER TABLE public.t_lc_cart OWNER TO d3l243;

--
-- Name: t_lc_cart_cart_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_lc_cart ALTER COLUMN cart_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_lc_cart_cart_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_lc_cart pk_t_lc_cart; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_lc_cart
    ADD CONSTRAINT pk_t_lc_cart PRIMARY KEY (cart_id);

--
-- Name: TABLE t_lc_cart; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_lc_cart TO readaccess;

