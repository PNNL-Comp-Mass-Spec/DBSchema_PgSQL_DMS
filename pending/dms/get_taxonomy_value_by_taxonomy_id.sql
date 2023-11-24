--
CREATE OR REPLACE PROCEDURE public.get_taxonomy_value_by_taxonomy_id
(
    _ncbiTaxonomyID int,
    INOUT _orgDomain text = '' ,
    INOUT _orgKingdom text = '',
    INOUT _orgPhylum text = '' ,
    INOUT _orgClass text = ''  ,
    INOUT _orgOrder text = ''  ,
    INOUT _orgFamily text = '' ,
    INOUT _orgGenus text = '' ,
    INOUT _orgSpecies text = '',
    INOUT _orgStrain text = '',
    _previewResults boolean = false,
    _previewOrganismID int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks up taxonomy values for the given TaxonomyID
**
**  Arguments:
**    _ncbiTaxonomyID       TaxonomyID value to lookup; ignored if _previewResults is true and _previewOrganismID is non-zero (and NCBI_Taxonomy_ID is defined in T_Organisms for the given organism)
**    _orgDomain            Output: domain
**    _orgKingdom           Output: kingdom
**    _orgPhylum            Output: phylum
**    _orgClass             Output: class
**    _orgOrder             Output: order
**    _orgFamily            Output: family
**    _orgGenus             Output: genus
**    _orgSpecies           Output: species
**    _orgStrain            Output: strain
**    _previewResults       True to preview the results
**    _previewOrganismID    When _previewResults is true, if this is non-zero, retrieves the information for the give organism by ID (provided the organism has NCBI_Taxonomy_ID defined)
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/03/2016 mem - Auto define Phylum as Community when _nCBITaxonomyID is 48479
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          08/08/2022 mem - Use Substring instead of Replace when removing genus name from species name
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _organismName text := '[No Organism]';
    _newNCBITaxonomyID int;
    _message text;
    _newDomain text;
    _newKingdom text;
    _newPhylum text;
    _newClass text;
    _newOrder text;
    _newFamily text;
    _newGenus text;
    _newSpecies text;
    _newStrain text;
    _taxonomyName text;
    _taxonomyRank text;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _ncbiTaxonomyID := Coalesce(_ncbiTaxonomyID, 0);

    _orgDomain      := Trim(Coalesce(_orgDomain, ''));
    _orgKingdom     := Trim(Coalesce(_orgKingdom, ''));
    _orgPhylum      := Trim(Coalesce(_orgPhylum, ''));
    _orgClass       := Trim(Coalesce(_orgClass, ''));
    _orgOrder       := Trim(Coalesce(_orgOrder, ''));
    _orgFamily      := Trim(Coalesce(_orgFamily, ''));
    _orgGenus       := Trim(Coalesce(_orgGenus, ''));
    _orgSpecies     := Trim(Coalesce(_orgSpecies, ''));
    _orgStrain      := Trim(Coalesce(_orgStrain, ''));

    _previewResults := Coalesce(_previewResults, false);
    _previewOrganismID := Coalesce(_previewOrganismID, 0)

    If _previewResults Then

        SELECT ncbi_taxonomy_id,
               organism,
               domain,
               kingdom,
               phylum,
               class,
               "order",
               family,
               genus,
               species,
               strain
        INTO _newNCBITaxonomyID,
             _organismName,
             _orgDomain,
             _orgKingdom,
             _orgPhylum,
             _orgClass,
             _orgOrder,
             _orgFamily,
             _orgGenus,
             _orgSpecies,
             _orgStrain
        FROM t_organisms
        WHERE organism_id = _previewOrganismID;

        If Not FOUND Then
            _message := format('Organism ID %s not found; nothing to preview', _previewResults);
            RAISE EXCEPTION '%', _message;
        End If;

        If Coalesce(_newNCBITaxonomyID, 0) > 0 Then
            _ncbiTaxonomyID := _newNCBITaxonomyID;
        End If;

    End If;

    If _ncbiTaxonomyID = 0 Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Store values in the _new variables
    ---------------------------------------------------

    _newDomain  := _orgDomain;
    _newKingdom := _orgKingdom;
    _newPhylum  := _orgPhylum;
    _newClass   := _orgClass;
    _newOrder   := _orgOrder;
    _newFamily  := _orgFamily;
    _newGenus   := _orgGenus;
    _newSpecies := _orgSpecies;
    _newStrain  := _orgStrain;

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_TaxonomyInfo (
        Entry_ID int not null,
        Rank text not null,
        Name text not null
    )

    ---------------------------------------------------
    -- Lookup the taxonomy data
    ---------------------------------------------------

    INSERT INTO Tmp_TaxonomyInfo( Entry_ID, Rank, Name )
    SELECT Entry_ID,
           Rank,
           Name
    FROM ont.get_taxid_taxonomy_table(_ncbiTaxonomyID);

    If FOUND Then
        ---------------------------------------------------
        -- Populate the taxonomy variables
        ---------------------------------------------------

        -- Superkingdom
        CALL public.update_taxonomy_item_if_defined ('superkingdom',  _value => _newDomain);

        -- Subkingdom, Kingdom
        CALL public.update_taxonomy_item_if_defined ('subkingdom', _value => _newKingdom);
        CALL public.update_taxonomy_item_if_defined ('kingdom', _value => _newKingdom);

        If _newKingdom = '' And _newDomain::citext = 'bacteria' Then
            _newKingdom := 'Prokaryote';
        End If;

        -- Subphylum, phylum
        CALL public.update_taxonomy_item_if_defined ('subphylum', _value => _newPhylum);
        CALL public.update_taxonomy_item_if_defined ('phylum', _value => _newPhylum);

        -- Subclass, superclass, class
        CALL public.update_taxonomy_item_if_defined ('subclass', _value => _newClass);
        CALL public.update_taxonomy_item_if_defined ('superclass', _value => _newClass);
        CALL public.update_taxonomy_item_if_defined ('class', _value => _newClass);

        -- Suborder, superorder, order
        CALL public.update_taxonomy_item_if_defined ('suborder', _value => _newOrder);
        CALL public.update_taxonomy_item_if_defined ('superorder', _value => _newOrder);
        CALL public.update_taxonomy_item_if_defined ('order', _value => _newOrder);

        -- Subfamily, superfamily, family
        CALL public.update_taxonomy_item_if_defined ('subfamily', _value => _newFamily);
        CALL public.update_taxonomy_item_if_defined ('superfamily', _value => _newFamily);
        CALL public.update_taxonomy_item_if_defined ('family', _value => _newFamily);

        -- Subgenus, Genus
        CALL public.update_taxonomy_item_if_defined ('subgenus', _value => _newGenus);
        CALL public.update_taxonomy_item_if_defined ('genus', _value => _newGenus);

        -- Subspecies, species
        CALL public.update_taxonomy_item_if_defined ('subspecies', _value => _newSpecies);
        CALL public.update_taxonomy_item_if_defined ('species', _value => _newSpecies);

        -- If the species name starts with the genus name, remove it
        If _newSpecies::citext Like (_newGenus || ' %')::citext And char_length(_newSpecies) > char_length(_newGenus) + 1 Then
            _newSpecies := Substring(_newSpecies, char_length(_newGenus) + 2, 200);
        End If;

        SELECT Name, Rank
        INTO _taxonomyName, _taxonomyRank
        FROM Tmp_TaxonomyInfo
        WHERE Entry_ID = 1;

        If _taxonomyRank::citext = 'no rank' And _taxonomyName::citext <> 'environmental samples' Then
            _newStrain := _taxonomyName;

            -- Remove genus and species if present
            _newStrain := LTrim(Replace(LTrim(Replace(_newStrain, _newGenus, '')), _newSpecies, ''));
        End If;

    End If;

    ---------------------------------------------------
    -- Auto-define some values when the Taxonomy ID is 48479 (environmental samples)
    ---------------------------------------------------

    If _ncbiTaxonomyID = 48479 Then
        -- Auto-define Phylum as Community if Phlyum is empty
        If Lower(Coalesce(_newPhylum, '')) In ('na', '') Then
            _newPhylum := 'Community';
        End If;

        If Coalesce(_newClass, '') = '' Then
            _newClass := 'na';
        End If;

        If Coalesce(_newOrder, '') = '' Then
            _newOrder := 'na';
        End If;

        If Coalesce(_newFamily, '') = '' Then
            _newFamily := 'na';
        End If;

        If Coalesce(_newGenus, '') = '' Then
            _newGenus := 'na';
        End If;

        If Coalesce(_newSpecies, '') = '' Then
            _newSpecies := 'na';
        End If;

    End If;

    ---------------------------------------------------
    -- Possibly preview the old / new values
    ---------------------------------------------------

    If _previewResults Then
        SELECT  Case When _previewOrganismID > 0 Then _previewOrganismID Else 0 End AS OrganismID,
                _organismName AS Organism,
                _ncbiTaxonomyID AS NCBITaxonomyID,
                _orgDomain AS Domain,
                _newDomain AS Domain_New,
                _orgKingdom AS Kingdom,
                _newKingdom AS Kingdom_New,
                _orgPhylum AS Phylum,
                _newPhylum AS Phylum_New,
                _orgClass AS Class,
                _newClass AS Class_New,
                _orgOrder AS Order,
                _newOrder AS Order_New,
                _orgFamily AS Family,
                _newFamily AS Family_New,
                _orgGenus AS Genus,
                _newGenus AS Genus_New,
                _orgSpecies AS Species,
                _newSpecies AS Species_New,
                _orgStrain AS Strain,
                _newStrain AS Strain_New;
    End If;

    ---------------------------------------------------
    -- Update the output variables
    ---------------------------------------------------

    _orgDomain  := _newDomain;
    _orgKingdom := _newKingdom;
    _orgPhylum  := _newPhylum;
    _orgClass   := _newClass;
    _orgOrder   := _newOrder;
    _orgFamily  := _newFamily;
    _orgGenus   := _newGenus;
    _orgSpecies := _newSpecies;
    _orgStrain  := _newStrain;

    DROP TABLE Tmp_TaxonomyInfo;
END
$$;

COMMENT ON PROCEDURE public.get_taxonomy_value_by_taxonomy_id IS 'GetTaxonomyValueByTaxonomyID';
