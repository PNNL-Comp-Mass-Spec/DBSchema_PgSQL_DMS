--
CREATE OR REPLACE PROCEDURE public.auto_resolve_organism_name
(
    _nameSearchSpec text,
    INOUT _matchCount int = 0,
    INOUT _matchingOrganismName text = '',
    INOUT _matchingOrganismID int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',

)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for entries in t_organisms that match _nameSearchSpec
**      First checks organism then checks short_name
**      Updates _matchCount with the number of matching entries
**
**      If one more more entries is found, updates _matchingOrganismName and _matchingOrganismID for the first match
**
**  Arguments:
**    _nameSearchSpec         Organism name to find; use % for a wildcard; note that a % will be appended to _nameSearchSpec if it does not end in one
**    _matchCount             Output: Number of entries in t_organisms that match _nameSearchSpec
**    _matchingOrganismName   Output: If _nameSearchSpec > 0, the organism name of the first match in t_organisms
**    _matchingOrganismID     Output: If _nameSearchSpec > 0, the organism ID of the first match
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial Version
**          03/31/2021 mem - Expand _nameSearchSpec and _matchingOrganismName to varchar(128)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
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

    If Not _nameSearchSpec SIMILAR TO '%[%]' Then
        _nameSearchSpec := _nameSearchSpec || '%';
    End If;

    SELECT COUNT(organism_id)
    INTO _matchCount
    FROM t_organisms
    WHERE organism ILIKE _nameSearchSpec;

    If _matchCount > 0 Then
        -- Update _matchingOrganismName and _matchingOrganismID
        --
        SELECT organism, organism_id
        INTO _matchingOrganismName, _matchingOrganismID
        FROM t_organisms
        WHERE organism ILIKE _nameSearchSpec
        ORDER BY organism_id
        LIMIT 1;
    End If;

    If _matchCount = 0 Then
        SELECT COUNT(organism_id)
        INTO _matchCount
        FROM t_organisms
        WHERE short_name ILIKE _nameSearchSpec;

        If _matchCount > 0 Then
            -- Update _matchingOrganismName and _matchingOrganismID
            --
            SELECT organism, organism_id
            INTO _matchingOrganismName, _matchingOrganismID
            FROM t_organisms
            WHERE short_name ILIKE _nameSearchSpec
            ORDER BY organism_id
            LIMIT 1;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.auto_resolve_organism_name IS 'AutoResolveOrganismName';
