--
-- Name: v_wellplate_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_wellplate_picklist AS
 SELECT (((w.wellplate)::text || ',  '::text) || COALESCE(
        CASE
            WHEN (char_length((w.description)::text) > 48) THEN "substring"((w.description)::text, 1, 48)
            ELSE (w.description)::text
        END, ''::text)) AS val,
    w.wellplate AS ex
   FROM public.t_wellplates w;


ALTER TABLE public.v_wellplate_picklist OWNER TO d3l243;

--
-- Name: TABLE v_wellplate_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_wellplate_picklist TO readaccess;

