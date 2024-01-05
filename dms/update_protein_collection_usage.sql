--
-- Name: update_protein_collection_usage(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_protein_collection_usage(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update data in t_protein_collection_usage
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   09/11/2012 mem - Initial version
**          11/20/2012 mem - Now updating Job_Usage_Count_Last12Months
**          08/14/2014 mem - Fixed bug updating Job_Usage_Count_Last12Months (occurred when a protein collection had not been used in the last year)
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Use tables T_Cached_Protein_Collection_List_Map and T_Cached_Protein_Collection_List_Members to minimize calls to Make_Table_From_List_Delim
**          10/23/2017 mem - Use S_V_Protein_Collections_by_Organism instead of S_V_Protein_Collection_Picker since S_V_Protein_Collection_Picker only includes active protein collections
**          08/30/2018 mem - Tabs to spaces
**          07/27/2022 mem - Switch from FileName to Collection_Name when querying S_V_Protein_Collections_by_Organism
**          12/31/2022 mem - Ported to PostgreSQL
**          05/07/2023 mem - Remove unused variable
**          05/19/2023 mem - Remove redundant parentheses
**          07/10/2023 mem - Use COUNT(J.job) instead of COUNT(*)
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**
*****************************************************/
DECLARE

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        -- Use a MERGE Statement to synchronize t_protein_collection_usage with V_Protein_Collections_by_Organism

        MERGE INTO t_protein_collection_usage AS target
        USING (SELECT DISTINCT protein_collection_id AS ID, Collection_Name AS Name
               FROM pc.V_Protein_Collections_by_Organism
            ) AS Source ( Protein_Collection_ID, Name)
        ON (target.protein_collection_id = source.protein_collection_id)
        WHEN MATCHED AND ( Target.name <> Source.name ) THEN
            UPDATE Set
                  name = Source.name
        WHEN NOT MATCHED THEN
            INSERT ( protein_collection_id, name, job_usage_count)
            VALUES ( Source.protein_collection_id, Source.name, 0)
        ;

        -- Delete rows from t_protein_collection_usage that are not in V_Protein_Collections_by_Organism

        DELETE FROM t_protein_collection_usage target
        WHERE NOT EXISTS (SELECT PC.protein_collection_id
                          FROM pc.V_Protein_Collections_by_Organism PC
                          WHERE target.protein_collection_id = PC.protein_collection_id);

        ---------------------------------------------------
        -- Update the usage counts in t_protein_collection_usage
        -- We use tables t_cached_protein_collection_list_map and
        -- t_cached_protein_collection_list_members to
        -- minimize calls to public.parse_delimited_list
        ---------------------------------------------------

        -- First add any missing protein collection lists to t_cached_protein_collection_list_map

        INSERT INTO t_cached_protein_collection_list_map( protein_collection_list )
        SELECT target.protein_collection_list
        FROM t_cached_protein_collection_list_map Target
             RIGHT OUTER JOIN ( SELECT J.protein_collection_list
                                FROM t_analysis_job J
                                GROUP BY J.protein_collection_list ) Source
               ON Target.protein_collection_list = Source.protein_collection_list
        WHERE Target.protein_collection_list IS NULL
        ORDER BY target.protein_collection_list;

        -- Next add missing rows to t_cached_protein_collection_list_members

        INSERT INTO t_cached_protein_collection_list_members( protein_collection_list_id,
                                                              protein_collection_name )
        SELECT DISTINCT SourceQ.protein_collection_list_id,
                        ProteinCollections.Value
        FROM ( SELECT DISTINCT PCLMap.protein_collection_list_id,
                               PCLMap.protein_collection_list
               FROM t_cached_protein_collection_list_map PCLMap
                    LEFT OUTER JOIN t_cached_protein_collection_list_members PCLMembers
                      ON PCLMap.protein_collection_list_id = PCLMembers.protein_collection_list_id
               WHERE PCLMembers.protein_collection_name IS NULL
             ) SourceQ
             JOIN LATERAL (
                 SELECT value
                 FROM public.parse_delimited_list(SourceQ.protein_collection_list)
                 ) AS ProteinCollections On True;

        -- Update the usage counts in t_protein_collection_usage

        UPDATE t_protein_collection_usage target
        SET job_usage_count_last12months = UsageQ.job_usage_count_last12months,
            job_usage_count = UsageQ.job_usage_count,
            most_recently_used = UsageQ.Most_Recent_Date
        FROM ( SELECT PCLMembers.Protein_Collection_Name AS ProteinCollection,
                      Sum(Jobs) AS Job_Usage_Count,
                      Sum(Job_Usage_Count_Last12Months) AS Job_Usage_Count_Last12Months,
                      MAX(NewestJob) AS Most_Recent_Date
               FROM ( SELECT J.protein_collection_list,
                             COUNT(J.job) AS Jobs,
                             Sum(CASE WHEN COALESCE(J.created, J.start, J.finish) >= CURRENT_TIMESTAMP - INTERVAL '1 year'
                                      THEN 1
                                      ELSE 0
                                 END) AS Job_Usage_Count_Last12Months,
                             MAX(COALESCE(J.created, J.start, J.finish)) AS NewestJob
                      FROM t_analysis_job J
                      GROUP BY J.protein_collection_list
                    ) CountQ
                    INNER JOIN t_cached_protein_collection_list_map PCLMap
                      ON CountQ.protein_collection_list = PCLMap.protein_collection_list
                    INNER JOIN t_cached_protein_collection_list_members PCLMembers
                      ON PCLMap.protein_collection_list_id = PCLMembers.protein_collection_list_id
               GROUP BY PCLMembers.protein_collection_name
             ) AS UsageQ
        WHERE target.Name = UsageQ.ProteinCollection AND
              (
                target.job_usage_count_last12months IS DISTINCT FROM UsageQ.job_usage_count_last12months or
                target.job_usage_count IS DISTINCT FROM UsageQ.job_usage_count or
                target.most_recently_used IS DISTINCT FROM UsageQ.Most_Recent_Date
              );

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.update_protein_collection_usage(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_protein_collection_usage(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_protein_collection_usage(INOUT _message text, INOUT _returncode text) IS 'UpdateProteinCollectionUsage';

