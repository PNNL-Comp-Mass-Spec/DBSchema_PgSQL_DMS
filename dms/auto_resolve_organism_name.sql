--
-- Name: auto_resolve_organism_name(text, integer, text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_resolve_organism_name(IN _namesearchspec text, INOUT _matchcount integer DEFAULT 0, INOUT _matchingorganismname text DEFAULT ''::text, INOUT _matchingorganismid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for entries in t_organisms that match _nameSearchSpec
**      First check organism name then check short_name
**
**      Search logic:
**      - Check for an exact match to _nameSearchSpec, which allows for matching organism 'Mus_musculus' even though we have other organisms whose names start with Mus_musculus
**      - If no match, but _nameSearchSpec contains a % sign, check whether it matches a single organism
**      - If no match, append a % sign and check again
**
**      If one more more entries is found, update _matchingOrganismName and _matchingOrganismID with the first match
**
**  Arguments:
**    _nameSearchSpec         Organism name to find; use % for a wildcard; note that a % will be appended to _nameSearchSpec if an exact match is not found
**    _matchCount             Output: Number of entries in t_organisms that match _nameSearchSpec
**    _matchingOrganismName   Output: If _nameSearchSpec > 0, the organism name of the first match in t_organisms
**    _matchingOrganismID     Output: If _nameSearchSpec > 0, the organism ID of the first match
**    _message                Status message
**    _returnCode             Return code
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial Version
**          03/31/2021 mem - Expand _nameSearchSpec and _matchingOrganismName to varchar(128)
**          12/30/2023 mem - Update logic for finding a matching organism (see above)
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSearchSpec text;
    _iteration int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate _nameSearchSpec and initialize the outputs
    ---------------------------------------------------

    _nameSearchSpec       := Trim(Coalesce(_nameSearchSpec, ''));
    _matchCount           := 0;
    _matchingOrganismName := '';
    _matchingOrganismID   := 0;

    FOR _iteration IN 1 .. 3
    LOOP
        If _iteration = 1 Then
            _currentSearchSpec := _nameSearchSpec;
        ElsIf _iteration = 2 Then
            If Position('%' IN _nameSearchSpec) = 0 Then
                -- Wildcard symbol not found
                -- Move on to the next iteration
                CONTINUE;
            End If;

            _currentSearchSpec := _nameSearchSpec;
        Else
            If _nameSearchSpec SIMILAR TO '%[%]' Then
                _currentSearchSpec := _nameSearchSpec;
            Else
                _currentSearchSpec := _nameSearchSpec || '%';
            End If;

        End If;

        SELECT COUNT(organism_id)
        INTO _matchCount
        FROM t_organisms
        WHERE organism ILIKE _currentSearchSpec;

        If _iteration <= 2 And _matchCount = 1 Or _iteration > 2 And _matchCount > 0 Then
            -- Update _matchingOrganismName and _matchingOrganismID

            SELECT organism, organism_id
            INTO _matchingOrganismName, _matchingOrganismID
            FROM t_organisms
            WHERE organism ILIKE _currentSearchSpec
            ORDER BY organism_id
            LIMIT 1;

            RETURN;
        End If;

        SELECT COUNT(organism_id)
        INTO _matchCount
        FROM t_organisms
        WHERE short_name ILIKE _currentSearchSpec;

        If _iteration <= 2 And _matchCount = 1 Or _iteration > 2 And _matchCount > 0 Then
            -- Update _matchingOrganismName and _matchingOrganismID

            SELECT organism, organism_id
            INTO _matchingOrganismName, _matchingOrganismID
            FROM t_organisms
            WHERE short_name ILIKE _currentSearchSpec
            ORDER BY organism_id
            LIMIT 1;

            RETURN;
        End If;

    END LOOP;
END
$$;


ALTER PROCEDURE public.auto_resolve_organism_name(IN _namesearchspec text, INOUT _matchcount integer, INOUT _matchingorganismname text, INOUT _matchingorganismid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_resolve_organism_name(IN _namesearchspec text, INOUT _matchcount integer, INOUT _matchingorganismname text, INOUT _matchingorganismid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_resolve_organism_name(IN _namesearchspec text, INOUT _matchcount integer, INOUT _matchingorganismname text, INOUT _matchingorganismid integer, INOUT _message text, INOUT _returncode text) IS 'AutoResolveOrganismName';

