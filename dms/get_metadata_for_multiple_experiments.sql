--
-- Name: get_metadata_for_multiple_experiments(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_metadata_for_multiple_experiments(_experimentlist text) RETURNS TABLE(experiment_name text, biomaterial_name text, attribute_type text, attribute_name text, attribute_value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Dump metadata for experiments in given list
**
**  Arguments:
**    _experimentList   Comma-separated list of experiment names
**
**  Auth:   grk
**  Date:   11/01/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/05/2024 mem - Ported to PostgreSQL (based on stored procedures dump_metadata_for_multiple_experiments and load_metadata_for_multiple_experiments)
**          07/08/2024 mem - Create temp tables instead of persisted tables
**
*****************************************************/
DECLARE
    _experimentCount int;
BEGIN

    ---------------------------------------------------
    -- Create and populate temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Experiments (
        Experiment text NOT NULL
    );

    ---------------------------------------------------
    -- Temporary table to hold metadata
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Metadata (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Experiment_Name text NOT NULL,
        Biomaterial_Name text NULL,
        Attribute_Type text NULL,
        Attribute_Name text NOT NULL,
        Attribute_Value text NULL
    );

    ---------------------------------------------------
    -- Load temporary table with list of experiments
    ---------------------------------------------------

    INSERT INTO Tmp_Experiments (Experiment)
    SELECT DISTINCT Trim(Value)
    FROM public.parse_delimited_list(_experimentList);
    --
    GET DIAGNOSTICS _experimentCount = ROW_COUNT;

    RAISE INFO 'Obtaining metadata for % %', _experimentCount, public.check_plural(_experimentCount, 'experiment', 'experiments');

    ---------------------------------------------------
    -- Load tracking info for the experiments
    ---------------------------------------------------

    INSERT INTO Tmp_Metadata (Experiment_Name, Biomaterial_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT Name,
           '' AS Biomaterial_Name,
           'Experiment',
           Unnest(Array['Name', 'ID',         'Researcher',  'Organism',  'Reason for Experiment',  'Comment',  'Created',                         'Sample Concentration',  'Digestion Enzyme', 'Lab Notebook',   'Campaign',  'Cell Cultures',  'Labelling',  'Predigest Int Std',  'Postdigest Int Std',  'Request']),
           Unnest(Array[MD.Name, MD.ID::text, MD.Researcher, MD.Organism, MD.Reason_for_Experiment, MD.Comment, public.timestamp_text(MD.Created), MD.Sample_Concentration, MD.Digestion_Enzyme, MD.Lab_Notebook, MD.Campaign, MD.Cell_Cultures, MD.Labelling, MD.Predigest_Int_Std, MD.Postdigest_Int_Std, MD.Request::text])
    FROM V_Experiment_Metadata MD
    WHERE Name IN (SELECT Experiment FROM Tmp_Experiments);

    ---------------------------------------------------
    -- Append aux info for the experiments
    ---------------------------------------------------

    INSERT INTO Tmp_Metadata(Experiment_Name, Biomaterial_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT Ex.Experiment,
           '' AS Biomaterial_Name,
           'Experiment',
           format('%s.%s.%s', AI.Category, AI.Subcategory, AI.Item) AS Tag,
           AI.Value
    FROM T_Experiments Ex
         INNER JOIN V_Aux_Info_Value AI
           ON Ex.Exp_ID = AI.Target_ID
    WHERE AI.Target = 'Experiment' AND
          Ex.Experiment IN (SELECT Experiment FROM Tmp_Experiments);

    ---------------------------------------------------
    -- Append biomaterial tracking info for the experiments
    ---------------------------------------------------

    INSERT INTO Tmp_Metadata(Experiment_Name, Biomaterial_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT EX.Experiment,
           MD.Name,
           'Biomaterial',
           Unnest(Array['Name', 'ID',         'Source',  'Source Contact',  'PI',  'Type',  'Reason',  'Comment',  'Campaign']),
           Unnest(Array[MD.Name, MD.ID::text, MD.Source, MD.Source_Contact, MD.PI, MD.Type, MD.Reason, MD.Comment, MD.Campaign])
    FROM T_Experiment_Biomaterial EB
         INNER JOIN T_Experiments EX
           ON EB.Exp_ID = EX.Exp_ID
         INNER JOIN V_Biomaterial_Metadata MD
           ON EB.Biomaterial_ID = MD.ID
    WHERE Ex.Experiment IN (SELECT Experiment FROM Tmp_Experiments);

    ---------------------------------------------------
    -- Append biomaterial aux info for the experiments
    ---------------------------------------------------

    INSERT INTO Tmp_Metadata(Experiment_Name, Biomaterial_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT Ex.Experiment,
           B.Biomaterial_Name,
           'Biomaterial',
           format('%s.%s.%s', AI.Category, AI.Subcategory, AI.Item) AS Tag,
           AI.Value
    FROM T_Biomaterial B
         INNER JOIN V_Aux_Info_Value AI
           ON B.Biomaterial_ID = AI.Target_ID
         INNER JOIN T_Experiment_Biomaterial EB
           ON B.Biomaterial_ID = EB.Biomaterial_ID
         INNER JOIN T_Experiments Ex
           ON EB.Exp_ID = Ex.Exp_ID
    WHERE AI.Target = 'Biomaterial' AND
          Ex.Experiment IN (SELECT Experiment FROM Tmp_Experiments)
    ORDER BY Ex.Experiment, B.Biomaterial_Name;

    ---------------------------------------------------
    -- Return the metadata
    ---------------------------------------------------

    RETURN QUERY
    SELECT Src.Experiment_Name,
           Src.biomaterial_name,
           Src.Attribute_Type,
           Src.Attribute_Name,
           Src.Attribute_Value
    FROM Tmp_Metadata Src
    ORDER BY Src.Experiment_Name, Src.Entry_ID;

    DROP TABLE Tmp_Experiments;
    DROP TABLE Tmp_Metadata;
END;
$$;


ALTER FUNCTION public.get_metadata_for_multiple_experiments(_experimentlist text) OWNER TO d3l243;

