--
-- Name: udf_get_filename(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.udf_get_filename(_filepath text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Examines _filePath to look for a filename
**  If found, returns the filename, otherwise, returns _filePath
**
**  Works with both \ and / as path separators
**
**  Auth: mem
**  Date: 01/14/2020
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


ALTER FUNCTION public.udf_get_filename(_filepath text) OWNER TO d3l243;

