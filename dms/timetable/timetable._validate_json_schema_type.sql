--
-- Name: _validate_json_schema_type(text, jsonb); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable._validate_json_schema_type(type text, data jsonb) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  IF type = 'integer' THEN
    IF jsonb_typeof(data) != 'number' THEN
      RETURN false;
    END IF;
    IF trunc(data::text::numeric) != data::text::numeric THEN
      RETURN false;
    END IF;
  ELSE
    IF type != jsonb_typeof(data) THEN
      RETURN false;
    END IF;
  END IF;
  RETURN true;
END;
$$;


ALTER FUNCTION timetable._validate_json_schema_type(type text, data jsonb) OWNER TO d3l243;

