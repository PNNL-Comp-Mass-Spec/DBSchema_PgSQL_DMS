--
-- Name: update_cached_bto_names(boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.update_cached_bto_names(_infoonly boolean DEFAULT true) RETURNS TABLE(task public.citext, identifier public.citext, term_name public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Updates data in ont.t_cv_bto_cached_names
**
**  Auth:   mem
**  Date:   09/01/2017 mem - Initial version
**          04/07/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          04/04/2023 mem - Use char_length() to determine string length
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text := '';
    _message2 text := '';
    _rowsUpdated int := 0;
BEGIN
    _infoOnly := Coalesce(_infoOnly, true);

    If Not _infoOnly Then
        ---------------------------------------------------
        -- Update cached names
        ---------------------------------------------------

        INSERT INTO ont.t_cv_bto_cached_names (identifier, term_name)
        SELECT s.identifier,
               s.term_name
        FROM ( SELECT cvbto.identifier AS identifier,
                      Min(cvbto.term_name) AS term_name
               FROM ont.t_cv_bto cvbto
               GROUP BY cvbto.identifier ) AS s
             LEFT OUTER JOIN ont.t_cv_bto_cached_names t
               ON t.identifier = s.identifier AND
                  t.term_name = s.term_name
        WHERE t.identifier IS NULL
        ORDER BY s.identifier;

        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _rowsUpdated := _rowsUpdated + _myRowCount;
            _message := format('Added %s rows to ont.t_cv_bto_cached_names using ont.t_cv_bto', Cast(_myRowCount as varchar(9)));
        End If;

        DELETE FROM ont.t_cv_bto_cached_names
        WHERE entry_id IN ( SELECT t.entry_id
                            FROM ont.t_cv_bto_cached_names t
                                 LEFT OUTER JOIN ( SELECT cvbto.identifier AS identifier,
                                                          Min(cvbto.term_name) AS term_name
                                                   FROM ont.t_cv_bto cvbto
                                                   GROUP BY cvbto.identifier ) AS s
                                   ON t.identifier = s.identifier AND
                                      t.term_name = s.term_name
                            WHERE s.identifier IS NULL );

        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _rowsUpdated := _rowsUpdated + _myRowCount;
            _message2 := format('Deleted %s extra rows from ont.t_cv_bto_cached_names', Cast(_myRowCount as varchar(9)));

            If char_length(_message) > 0 Then
                _message := _message || '; ' || _message2;
            Else
                _message := _message2;
            End If;
        End If;

        If _rowsUpdated = 0 Then
            _message := 'Cached names in ont.t_cv_bto_cached_names are already up-to-date';

            RETURN QUERY
            SELECT _message::citext AS Task,
                   ''::citext,
                   ''::citext;

        Else
            RETURN QUERY
            SELECT 'Updated cached names'::citext AS Task,
                   _message::citext,
                   _message2::citext;
        End If;

    Else
        ---------------------------------------------------
        -- Preview rows to add or delete
        ---------------------------------------------------

        RETURN QUERY
        SELECT 'Delete from cache'::citext AS Task,
               target.identifier,
               target.term_name
        FROM ont.t_cv_bto_cached_names target
             LEFT OUTER JOIN ( SELECT cvbto.identifier AS identifier,
                                      MIN(cvbto.term_name) AS term_name
                               FROM ont.t_cv_bto cvbto
                               GROUP BY cvbto.identifier ) source
               ON target.identifier = source.identifier AND
                  target.term_name = source.term_name
        WHERE (source.identifier IS NULL)
        UNION
        SELECT 'Add to cache'::citext AS Task,
               source.identifier,
               source.term_name
        FROM ont.t_cv_bto_cached_names target
             RIGHT OUTER JOIN ( SELECT cvbto.identifier AS identifier,
                                       MIN(cvbto.term_name) AS term_name
                                FROM ont.t_cv_bto cvbto
                                GROUP BY cvbto.identifier ) source
               ON target.identifier = source.identifier AND
                  target.term_name = source.term_name
        WHERE (target.identifier IS NULL)
        ORDER BY Task, identifier;

        If Not FOUND Then
            RETURN QUERY
            SELECT 'Cached names are already up-to-date'::citext,
                   ''::citext,
                   ''::citext;
        End If;

    End If;

END
$$;


ALTER FUNCTION ont.update_cached_bto_names(_infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION update_cached_bto_names(_infoonly boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.update_cached_bto_names(_infoonly boolean) IS 'UpdateCachedBTONames';

