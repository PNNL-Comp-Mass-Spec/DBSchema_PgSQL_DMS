--
CREATE OR REPLACE PROCEDURE public.auto_resolve_organism_name
(
    _nameSearchSpec text,
    INOUT _matchCount int=0,
    INOUT _matchingOrganismName text = '',
    _matchingOrganismID int=0 output
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for entries in T_Organisms that match _nameSearchSpec
**      First checks OG_name then checks OG_Short_Name
**      Updates _matchCount with the number of matching entries
**
**      If one more more entries is found, updates _matchingOrganismName and _matchingOrganismID for the first match
**
**  Arguments:
**    _nameSearchSpec         Used to search OG_name and OG_Short_Name in T_Organisms; use % for a wildcard; note that a % will be appended to _nameSearchSpec if it doesn't end in one
**    _matchCount             Number of entries in T_Organisms that match _nameSearchSpec
**    _matchingOrganismName   If _nameSearchSpec > 0, the Organism name of the first match in T_Organisms
**    _matchingOrganismID     If _nameSearchSpec > 0, the ID of the first match in T_Organisms
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial Version
**          03/31/2021 mem - Expand _nameSearchSpec and _matchingOrganismName to varchar(128)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _matchCount := 0;

    If Not _nameSearchSpec SIMILAR TO '%[%]' Then
        _nameSearchSpec := _nameSearchSpec || '%';
    End If;

    SELECT COUNT(*)
    INTO _matchCount
    FROM t_organisms
    WHERE organism LIKE _nameSearchSpec;

    If _matchCount > 0 Then
        -- Update _matchingOrganismName and _matchingOrganismID
        --
        SELECT organism, organism_id
        INTO _matchingOrganismName, _matchingOrganismID
        FROM t_organisms
        WHERE organism LIKE _nameSearchSpec
        ORDER BY organism_id
        LIMIT 1;
    End If;

    If _matchCount = 0 Then
        SELECT COUNT(*)
        INTO _matchCount
        FROM t_organisms
        WHERE short_name LIKE _nameSearchSpec;

        If _matchCount > 0 Then
            -- Update _matchingOrganismName and _matchingOrganismID
            --
            SELECT organism, organism_id
            INTO _matchingOrganismName, _matchingOrganismID
            FROM t_organisms
            WHERE short_name LIKE _nameSearchSpec
            ORDER BY organism_id
            LIMIT 1;
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.auto_resolve_organism_name IS 'AutoResolveOrganismName';
