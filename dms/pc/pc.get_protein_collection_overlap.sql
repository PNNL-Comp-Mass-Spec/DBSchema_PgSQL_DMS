--
-- Name: get_protein_collection_overlap(integer, integer); Type: FUNCTION; Schema: pc; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION pc.get_protein_collection_overlap(_collectiononeid integer, _collectiontwoid integer) RETURNS TABLE(protein_collection_id integer, collection_name public.citext, proteins integer, proteins_in_common integer, proteins_only_in_given_collection integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Compares the proteins in two protein collections, reporting the number in common (exact same sequence), plus the number only in collection A or only in collection B
**
**      This is an overloaded verison of function pc.get_protein_collection_overlap(), which accepts either protein collection name or protein collection ID
**
**  Example usage:
**      SELECT * FROM pc.get_protein_collection_overlap(2257, 4009);
**
**  Arguments:
**    _collectionOneID    First protein collection's integer ID
**    _collectionTwoID    Second protein collection's integer ID
**
**  Auth:   mem
**  Date:   02/05/2025 mem - Initial version
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT PCO.protein_collection_id,
           PCO.collection_name,
           PCO.proteins,
           PCO.proteins_in_common,
           PCO.proteins_only_in_given_collection
    FROM pc.get_protein_collection_overlap(_collectionOneID::text, _collectionTwoID::text) PCO;
END
$$;


ALTER FUNCTION pc.get_protein_collection_overlap(_collectiononeid integer, _collectiontwoid integer) OWNER TO d3l243;

--
-- Name: get_protein_collection_overlap(text, text); Type: FUNCTION; Schema: pc; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION pc.get_protein_collection_overlap(_collectiononenameorid text, _collectiontwonameorid text) RETURNS TABLE(protein_collection_id integer, collection_name public.citext, proteins integer, proteins_in_common integer, proteins_only_in_given_collection integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Compares the proteins in two protein collections, reporting the number in common (exact same sequence), plus the number only in collection A or only in collection B
**
**  Example usage:
**      SELECT * FROM pc.get_protein_collection_overlap('3996', '3909');
**      SELECT * FROM pc.get_protein_collection_overlap('3996', 'H_sapiens_UniProt_SPROT_2023-09-01');
**      SELECT * FROM pc.get_protein_collection_overlap('H_sapiens_UniProt_SPROT_2024-09-12', 'H_sapiens_UniProt_SPROT_2023-09-01');
**
**  Arguments:
**    _collectionOneNameOrID    First protein collection's name or integer ID
**    _collectionTwoNameOrID    Second protein collection's name or integer ID
**
**  Auth:   mem
**  Date:   02/05/2025 mem - Initial version
**
*****************************************************/
DECLARE
    _collectionIdA int;
    _collectionIdB int;
    _collectionNameA citext;
    _collectionNameB citext;

    _proteinCountA int;
    _proteinCountB int;
    _proteinCountInBoth int;
    _proteinCountOnlyA int;
    _proteinCountOnlyB int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _collectionOneNameOrID := Trim(Coalesce(_collectionOneNameOrID, ''));
        _collectionTwoNameOrID := Trim(Coalesce(_collectionTwoNameOrID, ''));

        If _collectionOneNameOrID = '' Then
            RETURN QUERY
            SELECT 0 AS protein_collection_id,
                   'Invalid protein collection name: _collectionOneNameOrID is an empty string'::citext,
                   0 AS proteins,
                   0 AS proteins_in_common,
                   0 AS proteins_only_in_given_collection;

            RETURN;
        End If;

        If _collectionTwoNameOrID = '' Then
            RETURN QUERY
            SELECT 0 AS protein_collection_id,
                   'Invalid protein collection name: _collectionTwoNameOrID is an empty string'::citext,
                   0 AS proteins,
                   0 AS proteins_in_common,
                   0 AS proteins_only_in_given_collection;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Resolve protein collection names and/or IDs
        ---------------------------------------------------

        _collectionIdA := public.try_cast(_collectionOneNameOrID, null::int);
        _collectionIdB := public.try_cast(_collectionTwoNameOrID, null::int);

        If _collectionIdA Is Null Then
            SELECT PC.protein_collection_id
            INTO _collectionIdA
            FROM pc.t_protein_collections PC
            WHERE PC.collection_name = _collectionOneNameOrID::citext;

            If FOUND Then
                _collectionNameA := _collectionOneNameOrID;
            Else
                RETURN QUERY
                SELECT 0 AS protein_collection_id,
                       format('Invalid protein collection name: %s', _collectionOneNameOrID)::citext,
                       0 AS proteins,
                       0 AS proteins_in_common,
                       0 AS proteins_only_in_given_collection;

                RETURN;
            End If;
        Else
            SELECT PC.collection_name
            INTO _collectionNameA
            FROM pc.t_protein_collections PC
            WHERE PC.protein_collection_id = _collectionIdA;

            If Not FOUND Then
                RETURN QUERY
                SELECT 0 AS protein_collection_id,
                       format('Invalid protein collection ID: %s', _collectionIdA)::citext,
                       0 AS proteins,
                       0 AS proteins_in_common,
                       0 AS proteins_only_in_given_collection;

                RETURN;
            End If;
        End If;

        If _collectionIdB Is Null Then
            SELECT PC.protein_collection_id
            INTO _collectionIdB
            FROM pc.t_protein_collections PC
            WHERE PC.collection_name = _collectionTwoNameOrID::citext;

            If FOUND Then
                _collectionNameB := _collectionTwoNameOrID;
            Else
                RETURN QUERY
                SELECT 0 AS protein_collection_id,
                       format('Invalid protein collection name: %s', _collectionTwoNameOrID)::citext,
                       0 AS proteins,
                       0 AS proteins_in_common,
                       0 AS proteins_only_in_given_collection;

                RETURN;
            End If;
        Else
            SELECT PC.collection_name
            INTO _collectionNameB
            FROM pc.t_protein_collections PC
            WHERE PC.protein_collection_id = _collectionIdB;

            If Not FOUND Then
                RETURN QUERY
                SELECT 0 AS protein_collection_id,
                       format('Invalid protein collection ID: %s', _collectionIdB)::citext,
                       0 AS proteins,
                       0 AS proteins_in_common,
                       0 AS proteins_only_in_given_collection;

                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Compare protein collection members
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _proteinCountA
        FROM pc.v_protein_collection_member_ids PCM
        WHERE PCM.protein_collection_id = _collectionIdA;

        SELECT COUNT(*)
        INTO _proteinCountB
        FROM pc.v_protein_collection_member_ids PCM
        WHERE PCM.protein_collection_id = _collectionIdB;

        SELECT COUNT(*)
        INTO _proteinCountInBoth
        FROM ( SELECT PCM.protein_id
               FROM pc.v_protein_collection_member_ids PCM
               WHERE PCM.protein_collection_id = _collectionIdA
             ) AS CollA
             INNER JOIN ( SELECT PCM.protein_id
                          FROM pc.v_protein_collection_member_ids PCM
                          WHERE PCM.protein_collection_id = _collectionIdB
                        ) AS CollB
               ON CollB.protein_id = CollA.protein_id;

        SELECT COUNT(*)
        INTO _proteinCountOnlyA
        FROM ( SELECT PCM.protein_id
               FROM pc.v_protein_collection_member_ids PCM
               WHERE PCM.protein_collection_id = _collectionIdA
             ) AS CollA
             LEFT OUTER JOIN ( SELECT PCM.protein_id
                               FROM pc.v_protein_collection_member_ids PCM
                               WHERE PCM.protein_collection_id = _collectionIdB
                             ) AS CollB
               ON CollB.protein_id = CollA.protein_id
        WHERE CollB.protein_id Is Null;

        SELECT COUNT(*)
        INTO _proteinCountOnlyB
        FROM ( SELECT PCM.protein_id
               FROM pc.v_protein_collection_member_ids PCM
               WHERE PCM.protein_collection_id = _collectionIdA
             ) AS CollA
             RIGHT OUTER JOIN ( SELECT PCM.protein_id
                                FROM pc.v_protein_collection_member_ids PCM
                                WHERE PCM.protein_collection_id = _collectionIdB
                              ) AS CollB
               ON CollB.protein_id = CollA.protein_id
        WHERE CollA.protein_id Is Null;

        ---------------------------------------------------
        -- Return the results
        ---------------------------------------------------

        RETURN QUERY
        SELECT _collectionIdA AS protein_collection_id,
               _collectionNameA AS collection_name,
               _proteinCountA AS proteins,
               _proteinCountInBoth AS proteins_in_common,
               _proteinCountOnlyA AS proteins_only_in_given_collection
        UNION
        SELECT _collectionIdB AS protein_collection_id,
               _collectionNameB AS collection_name,
               _proteinCountB AS proteins,
               _proteinCountInBoth AS proteins_in_common,
               _proteinCountOnlyB AS proteins_only_in_given_collection
        ORDER BY 1;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        RAISE WARNING '%', _exceptionMessage;
    END;
END
$$;


ALTER FUNCTION pc.get_protein_collection_overlap(_collectiononenameorid text, _collectiontwonameorid text) OWNER TO d3l243;

