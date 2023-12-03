--
CREATE OR REPLACE PROCEDURE public.auto_update_taxonomy_all_organisms
(
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Auto-defines the taxonomy for all organisms, using the NCBI_Taxonomy_ID value defined for each organism
**
**  Arguments:
**    _infoOnly     When true, preview results
**    _message      Output message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/31/2021 mem - Expand OrganismName to varchar(128)
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _organismInfo record;
    _organism record;

    _orgDomain text,
    _orgKingdom text,
    _orgPhylum text,
    _orgClass text,
    _orgOrder text,
    _orgFamily text,
    _orgGenus text,
    _orgSpecies text,
    _orgStrain text
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create a temporary table for previewing the results
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_OrganismsToUpdate (
        OrganismID int not null,
        OrganismName text not null,
        NCBITaxonomyID int not null,
        OldDomain text,
        NewDomain text,
        OldKingdom text,
        NewKingdom text,
        OldPhylum text,
        NewPhylum text,
        OldClass text,
        NewClass text,
        OldOrder text,
        NewOrder text,
        OldFamily text,
        NewFamily text,
        OldGenus text,
        NewGenus text,
        OldSpecies text,
        NewSpecies text,
        OldStrain text,
        NewStrain  text
    )

    ---------------------------------------------------
    -- Loop over the organism entries
    ---------------------------------------------------

    FOR _organismInfo IN
        SELECT ncbi_taxonomy_id AS NcbiTaxonomyID,
               organism AS OrganismName,
               organism_id AS OrganismID,
               Coalesce(domain, '')  AS OldDomain,
               Coalesce(kingdom, '') AS OldKingdom,
               Coalesce(phylum, '')  AS OldPhylum,
               Coalesce(class, '')   AS OldClass,
               Coalesce(order, '')   AS OldOrder,
               Coalesce(family, '')  AS OldFamily,
               Coalesce(genus, '')   AS OldGenus,
               Coalesce(species, '') AS OldSpecies,
               Coalesce(strain, '')  AS OldStrain
        FROM t_organisms
        WHERE NOT ncbi_taxonomy_id IS NULL
        ORDER BY organism_id
    LOOP
        ---------------------------------------------------
        -- Auto-define the taxonomy terms
        ---------------------------------------------------

        _orgDomain  := _organismInfo.OldDomain;
        _orgKingdom := _organismInfo.OldKingdom;
        _orgPhylum  := _organismInfo.OldPhylum;
        _orgClass   := _organismInfo.OldClass;
        _orgOrder   := _organismInfo.OldOrder;
        _orgFamily  := _organismInfo.OldFamily;
        _orgGenus   := _organismInfo.OldGenus;
        _orgSpecies := _organismInfo.OldSpecies;
        _orgStrain  := _organismInfo.OldStrain;

        CALL public.get_taxonomy_value_by_taxonomy_id (
                        _ncbiTaxonomyID,
                        _orgDomain      => _orgDomain,      -- Output
                        _orgKingdom     => _orgKingdom,     -- Output
                        _orgPhylum      => _orgPhylum,      -- Output
                        _orgClass       => _orgClass,       -- Output
                        _orgOrder       => _orgOrder,       -- Output
                        _orgFamily      => _orgFamily,      -- Output
                        _orgGenus       => _orgGenus,       -- Output
                        _orgSpecies     => _orgSpecies,     -- Output
                        _orgStrain      => _orgStrain,      -- Output
                        _previewResults => false);

        If  _orgDomain  <> _organismInfo.OldDomain  Or
            _orgKingdom <> _organismInfo.OldKingdom Or
            _orgPhylum  <> _organismInfo.OldPhylum  Or
            _orgClass   <> _organismInfo.OldClass   Or
            _orgOrder   <> _organismInfo.OldOrder   Or
            _orgFamily  <> _organismInfo.OldFamily  Or
            _orgGenus   <> _organismInfo.OldGenus   Or
            _orgSpecies <> _organismInfo.OldSpecies Or
            _orgStrain  <> _organismInfo.OldStrain Then

            ---------------------------------------------------
            -- New data to preview or store
            ---------------------------------------------------

            If _infoOnly Then
                -- Previewing changes; store in Tmp_OrganismsToUpdate
                --
                INSERT INTO Tmp_OrganismsToUpdate (
                                OrganismID, OrganismName, NCBITaxonomyID,
                                OldDomain,  NewDomain,
                                OldKingdom, NewKingdom,
                                OldPhylum,  NewPhylum,
                                OldClass,   NewClass,
                                OldOrder,   NewOrder,
                                OldFamily,  NewFamily,
                                OldGenus,   NewGenus,
                                OldSpecies, NewSpecies,
                                OldStrain,  NewStrain )
                VALUES ( _organismID, _organismName, _ncbiTaxonomyID,
                         _organismInfo.OldDomain,  _orgDomain,
                         _organismInfo.OldKingdom, _orgKingdom,
                         _organismInfo.OldPhylum,  _orgPhylum,
                         _organismInfo.OldClass,   _orgClass,
                         _organismInfo.OldOrder,   _orgOrder,
                         _organismInfo.OldFamily,  _orgFamily,
                         _organismInfo.OldGenus,   _orgGenus,
                         _organismInfo.OldSpecies, _orgSpecies,
                         _organismInfo.OldStrain,  _orgStrain);
            Else

                UPDATE t_organisms
                SET domain =  _orgDomain,
                    kingdom = _orgKingdom,
                    phylum =  _orgPhylum,
                    class =   _orgClass,
                    order =   _orgOrder,
                    family =  _orgFamily,
                    genus =   _orgGenus,
                    species = _orgSpecies,
                    strain =  _orgStrain
                WHERE organism_id = _organismID;

            End If;
        End If;

    END LOOP;

    If _infoOnly Then

        -- ToDo: Show this using RAISE INFO

        FOR _organism IN
            SELECT OrganismID,
                   OrganismName,
                   NCBITaxonomyID,
                   OldDomain,
                   NewDomain,
                   OldKingdom,
                   NewKingdom,
                   OldPhylum,
                   NewPhylum,
                   OldClass,
                   NewClass,
                   OldOrder,
                   NewOrder,
                   OldFamily,
                   NewFamily,
                   OldGenus,
                   NewGenus,
                   OldSpecies,
                   NewSpecies,
                   OldStrain,
                   NewStrain
            FROM Tmp_OrganismsToUpdate
            ORDER BY OrganismID
        LOOP

        END LOOP;

    End If;

    DROP TABLE Tmp_OrganismsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_update_taxonomy_all_organisms IS 'AutoUpdateTaxonomyAllOrganisms';
