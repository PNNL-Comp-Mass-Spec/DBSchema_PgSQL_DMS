--
CREATE OR REPLACE PROCEDURE pc.get_shared_protein_ids
(
    FROM         dbo.T_Protein_Collection_Members
    WHERE     (Protein_Collection_ID = _collection_1)),
    Collection_2(protein_ID, protein_collection_ID) AS
    (SELECT     Protein_ID, Protein_Collection_ID
    FROM          dbo.T_Protein_Collection_Members
    WHERE      (Protein_Collection_ID = _collection_2))
    SELECT     collection_2.protein_ID
    FROM Collection_1
    INNER JOIN Collection_2
    ON Collection_1.Protein_ID = Collection_2.protein_ID
    END
    -- =============================================
    -- Author:        Ken Auberry
    -- Create date: 2004-04-16
    -- Description:    Shows the Protein_IDs present in
    --                collection_1 that are not in
    --                collection_2
    -- =============================================
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Add the parameters for the stored procedure here
    _collection_1 int = 0,
    _collection_2 int = 0
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    WITH Collection_1 AS
END
$$;

COMMENT ON PROCEDURE pc.get_shared_protein_ids IS 'GetSharedProteinIDs';
