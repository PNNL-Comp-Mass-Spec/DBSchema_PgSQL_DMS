--
-- Name: get_filename(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_filename(_filepath text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**  Examines _filePath to look for a filename
**  If found, returns the filename, otherwise, returns _filePath
**
**  Works with both \ and / as path separators
**
**  Auth:   mem
**  Date:   05/18/2017
**          01/14/2020 mem - Ported to PostgreSQL

*****************************************************/
DECLARE
    _filename TEXT;
BEGIN
    _filename := '';

    If Trim(Coalesce(_filePath, '')) <> '' Then
        _filename := regexp_replace(_filePath, '^.+[/\\]', '');
    End If;

    RETURN _filename;
END
$$;


ALTER FUNCTION public.get_filename(_filepath text) OWNER TO d3l243;

--
-- Name: FUNCTION get_filename(_filepath text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_filename(_filepath text) IS 'GetFilename';

