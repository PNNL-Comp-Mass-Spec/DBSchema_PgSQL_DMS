--
-- Name: people; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.people (
    first_name public.citext,
    last_name public.citext,
    height_cm numeric,
    height_in numeric GENERATED ALWAYS AS ((height_cm / 2.54)) STORED
);


ALTER TABLE public.people OWNER TO d3l243;
