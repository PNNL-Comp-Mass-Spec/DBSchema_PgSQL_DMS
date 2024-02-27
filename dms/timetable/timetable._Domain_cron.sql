--
-- Name: cron; Type: DOMAIN; Schema: timetable; Owner: d3l243
--

CREATE DOMAIN timetable.cron AS text
	CONSTRAINT cron_check CHECK (((VALUE = '@reboot'::text) OR ((substr(VALUE, 1, 6) = ANY (ARRAY['@every'::text, '@after'::text])) AND ((substr(VALUE, 7))::interval IS NOT NULL)) OR ((VALUE ~ '^(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) +){4}(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) ?)$'::text) AND (timetable.cron_split_to_arrays(VALUE) IS NOT NULL))));


ALTER DOMAIN timetable.cron OWNER TO d3l243;

--
-- Name: DOMAIN cron; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON DOMAIN timetable.cron IS 'Extended CRON-style notation with support of interval values';

