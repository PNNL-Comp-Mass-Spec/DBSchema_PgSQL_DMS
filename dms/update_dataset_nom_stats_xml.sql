--
-- Name: update_dataset_nom_stats_xml(integer, xml, integer, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_nom_stats_xml(IN _datasetid integer DEFAULT 0, IN _nomstatsxml xml DEFAULT NULL::xml, IN _nomannotationjob integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the natural organic stats metrics in table t_dataset_nom_stats for the dataset specified by _datasetID
**
**      If _datasetID is 0, will use the dataset name defined in _nomStatsXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <NOMStats>
**        <Dataset>QC_SRFAII_25_01_D_WEOM_r2_54_1_31253</Dataset>
**        <metrics>
**          <intrinsic_c13_pair_count>2193</intrinsic_c13_pair_count>
**          <intrinsic_c13_pair_intensity_sum>118025754916</intrinsic_c13_pair_intensity_sum>
**          <intrinsic_c13_to_cl37_pair_intensity_ratio>3.70838</intrinsic_c13_to_cl37_pair_intensity_ratio>
**          <intrinsic_c13_to_cl37_pair_ratio>1.54437</intrinsic_c13_to_cl37_pair_ratio>
**          <intrinsic_chloride_cluster_count>404</intrinsic_chloride_cluster_count>
**          <intrinsic_chloride_cluster_intensity_percent>19.2243</intrinsic_chloride_cluster_intensity_percent>
**          <intrinsic_chloride_cluster_intensity_sum>159049075111</intrinsic_chloride_cluster_intensity_sum>
**          <intrinsic_chloride_cluster_max_length>7</intrinsic_chloride_cluster_max_length>
**          <intrinsic_chloride_cluster_mean_length>3.5124</intrinsic_chloride_cluster_mean_length>
**          <intrinsic_chloride_cluster_peak_count>1419</intrinsic_chloride_cluster_peak_count>
**          <intrinsic_chloride_cluster_peak_percent>14.19</intrinsic_chloride_cluster_peak_percent>
**          <intrinsic_cl37_pair_count>1420</intrinsic_cl37_pair_count>
**          <intrinsic_cl37_pair_intensity_sum>31826812208</intrinsic_cl37_pair_intensity_sum>
**          <intrinsic_inorganic_count>199</intrinsic_inorganic_count>
**          <intrinsic_inorganic_intensity_sum>8720938803</intrinsic_inorganic_intensity_sum>
**          <intrinsic_mz_kurtosis>-0.23282</intrinsic_mz_kurtosis>
**          <intrinsic_mz_median>459.6278</intrinsic_mz_median>
**          <intrinsic_mz_skewness>0.1377</intrinsic_mz_skewness>
**          <intrinsic_organic_count>9797</intrinsic_organic_count>
**          <intrinsic_organic_intensity_sum>818551292935</intrinsic_organic_intensity_sum>
**          <intrinsic_organic_to_inorganic_count_ratio>49.23116</intrinsic_organic_to_inorganic_count_ratio>
**          <intrinsic_organic_to_inorganic_intensity_ratio>93.86046</intrinsic_organic_to_inorganic_intensity_ratio>
**          <intrinsic_peak_count>10000</intrinsic_peak_count>
**        </metrics>
**      </NOMStats>
**
**  Arguments:
**    _datasetID            If this value is 0, determines the dataset name using the contents of _nomStatsXML
**    _nomStatsXML          XML describing the natural organic matter metrics for a single dataset
**    _nomAnnotationJob     NOM Annotation analysis job number
**    _message              Status message
**    _returnCode           Return code
**    _infoOnly             When true, preview updates
**
**  Auth:   mem
**  Date:   03/26/2026 mem - Initial version
**          03/31/2026 mem - Convert NaN values to null
**          04/06/2026 mem - Add NOM annotation metrics
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetName text;
    _datasetIDCheck int;
    _msg text;

    _usageMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _currentLocation text := 'Start';
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetID           := Coalesce(_datasetID, 0);
        _infoOnly            := Coalesce(_infoOnly, false);

        ---------------------------------------------------
        -- Examine the XML to determine the dataset name and update or validate _datasetID
        ---------------------------------------------------

        _currentLocation := 'Call get_dataset_details_from_dataset_info_xml';

        CALL public.get_dataset_details_from_dataset_info_xml (
                        _datasetInfoXML => _nomStatsXML,
                        _rootElement    => 'NOMStats',
                        _datasetID      => _datasetID,     -- Input/Output
                        _datasetName    => _datasetName,   -- Output
                        _message        => _message,       -- Output
                        _returnCode     => _returnCode);   -- Output

        If _returnCode <> '' Then
            RETURN;
        End If;

        If Coalesce(_datasetID, 0) = 0 Then
            If Coalesce(_message, '') = '' Then
                _message := 'Procedure get_dataset_details_from_dataset_info_xml returned 0 for dataset ID; unable to continue';
            End If;

            _returnCode := '5201';
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Create temporary tables to hold the data
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_NOM_Stats (
            Dataset_ID                            int NULL,
            Dataset_Name                          text NOT NULL,
            MZ_Ion_Count                          int NULL,
            MZ_Median                             numeric NULL,
            MZ_Skew                               numeric NULL,
            MZ_Kurtosis                           numeric NULL,
            Organic_Count                         int NULL,
            Organic_Intensity_Sum                 numeric NULL,
            Inorganic_Count                       int NULL,
            Inorganic_Intensity_Sum               numeric NULL,
            Organic_to_Inorganic_Count_Ratio      numeric NULL,
            Organic_to_Inorganic_Intensity_Ratio  numeric NULL,
            C13_Pair_Count                        int NULL,
            C13_Pair_Intensity_Sum                numeric NULL,
            Cl37_Pair_Count                       int NULL,
            Cl37_Pair_Intensity_Sum               numeric NULL,
            C13_to_Cl37_Pair_Ratio                numeric NULL,
            C13_to_Cl37_Pair_Intensity_Ratio      numeric NULL,
            Chloride_Cluster_Count                int NULL,
            Chloride_Cluster_Max_Length           int NULL,
            Chloride_Cluster_Mean_Length          numeric NULL,
            Chloride_Cluster_Peak_Count           int NULL,
            Chloride_Cluster_Peak_Percent         numeric NULL,
            Chloride_Cluster_Intensity_Sum        numeric NULL,
            Chloride_Cluster_Intensity_Percent    numeric NULL,
            Calibration_Points                    int NULL,
            Calibration_Raw_Error_Median          numeric NULL,
            Calibration_Raw_Error_Stdev           numeric NULL,
            Calibration_RMS                       numeric NULL,
            Total_Features                        int NULL,
            Annotated_Features                    int NULL,
            Percent_Features_Annotated            numeric NULL,
            Total_Intensity                       numeric NULL,
            Annotated_Intensity                   numeric NULL,
            Percent_Intensity_Annotated           numeric NULL,
            Assigned_Mz_Error_RMS_PPM             numeric NULL,
            Signed_Mean_PPM_Error                 numeric NULL,
            Mean_PPM_Error                        numeric NULL,
            Median_PPM_Error                      numeric NULL,
            Weighted_OC                           numeric NULL,
            Weighted_HC                           numeric NULL,
            Weighted_NOSC                         numeric NULL,
            Weighted_Aimod                        numeric NULL,
            Descriptor_Feature_Count              int NULL,
            Descriptor_Intensity_Fraction_Percent numeric NULL
        );

        ---------------------------------------------------
        -- Parse the contents of _nomStatsXML to populate Tmp_NOM_Stats
        --
        -- Extract values using xpath() since XMLTABLE can only extract all of the nodes below a given parent node,
        -- and we need to extract data from multiple sections
        --
        -- Note that "text()" means to return the text inside each node (e.g., 53435 from <ScanCount>53435</ScanCount>)
        -- [1] is used to select the first match, since xpath() returns an array
        ---------------------------------------------------

        _currentLocation := 'Parse _nomStatsXML and populate Tmp_NOM_Stats';

        INSERT INTO Tmp_NOM_Stats (
            Dataset_ID,
            Dataset_Name,
            MZ_Ion_Count,
            MZ_Median,
            MZ_Skew,
            MZ_Kurtosis,
            Organic_Count,
            Organic_Intensity_Sum,
            Inorganic_Count,
            Inorganic_Intensity_Sum,
            Organic_to_Inorganic_Count_Ratio,
            Organic_to_Inorganic_Intensity_Ratio,
            C13_Pair_Count,
            C13_Pair_Intensity_Sum,
            Cl37_Pair_Count,
            Cl37_Pair_Intensity_Sum,
            C13_to_Cl37_Pair_Ratio,
            C13_to_Cl37_Pair_Intensity_Ratio,
            Chloride_Cluster_Count,
            Chloride_Cluster_Max_Length,
            Chloride_Cluster_Mean_Length,
            Chloride_Cluster_Peak_Count,
            Chloride_Cluster_Peak_Percent,
            Chloride_Cluster_Intensity_Sum,
            Chloride_Cluster_Intensity_Percent,
            Calibration_Points,
            Calibration_Raw_Error_Median,
            Calibration_Raw_Error_Stdev,
            Calibration_RMS,
            Total_Features,
            Annotated_Features,
            Percent_Features_Annotated,
            Total_Intensity,
            Annotated_Intensity,
            Percent_Intensity_Annotated,
            Assigned_Mz_Error_RMS_PPM,
            Signed_Mean_PPM_Error,
            Mean_PPM_Error,
            Median_PPM_Error,
            Weighted_OC,
            Weighted_HC,
            Weighted_NOSC,
            Weighted_Aimod,
            Descriptor_Feature_Count,
            Descriptor_Intensity_Fraction_Percent
        )
        SELECT _datasetID AS DatasetID,
               _datasetName AS Dataset,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_peak_count/text()',                           _nomStatsXML))[1]::text, 0)          AS MZ_Ion_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_mz_median/text()',                            _nomStatsXML))[1]::text, 0::numeric) AS MZ_Median,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_mz_skewness/text()',                          _nomStatsXML))[1]::text, 0::numeric) AS MZ_Skew,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_mz_kurtosis/text()',                          _nomStatsXML))[1]::text, 0::numeric) AS MZ_Kurtosis,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_organic_count/text()',                        _nomStatsXML))[1]::text, 0)          AS Organic_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_organic_intensity_sum/text()',                _nomStatsXML))[1]::text, 0::numeric) AS Organic_Intensity_Sum,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_inorganic_count/text()',                      _nomStatsXML))[1]::text, 0)          AS Inorganic_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_inorganic_intensity_sum/text()',              _nomStatsXML))[1]::text, 0::numeric) AS Inorganic_Intensity_Sum,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_organic_to_inorganic_count_ratio/text()',     _nomStatsXML))[1]::text, 0::numeric) AS Organic_to_Inorganic_Count_Ratio,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_organic_to_inorganic_intensity_ratio/text()', _nomStatsXML))[1]::text, 0::numeric) AS Organic_to_Inorganic_Intensity_Ratio,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_c13_pair_count/text()',                       _nomStatsXML))[1]::text, 0)          AS C13_Pair_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_c13_pair_intensity_sum/text()',               _nomStatsXML))[1]::text, 0::numeric) AS C13_Pair_Intensity_Sum,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_cl37_pair_count/text()',                      _nomStatsXML))[1]::text, 0)          AS Cl37_Pair_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_cl37_pair_intensity_sum/text()',              _nomStatsXML))[1]::text, 0::numeric) AS Cl37_Pair_Intensity_Sum,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_c13_to_cl37_pair_ratio/text()',               _nomStatsXML))[1]::text, 0::numeric) AS C13_to_Cl37_Pair_Ratio,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_c13_to_cl37_pair_intensity_ratio/text()',     _nomStatsXML))[1]::text, 0::numeric) AS C13_to_Cl37_Pair_Intensity_Ratio,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_count/text()',               _nomStatsXML))[1]::text, 0)          AS Chloride_Cluster_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_max_length/text()',          _nomStatsXML))[1]::text, 0)          AS Chloride_Cluster_Max_Length,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_mean_length/text()',         _nomStatsXML))[1]::text, 0::numeric) AS Chloride_Cluster_Mean_Length,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_peak_count/text()',          _nomStatsXML))[1]::text, 0)          AS Chloride_Cluster_Peak_Count,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_peak_percent/text()',        _nomStatsXML))[1]::text, 0::numeric) AS Chloride_Cluster_Peak_Percent,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_intensity_sum/text()',       _nomStatsXML))[1]::text, 0::numeric) AS Chloride_Cluster_Intensity_Sum,
               public.try_cast((xpath('//NOMStats/metrics/intrinsic_chloride_cluster_intensity_percent/text()',   _nomStatsXML))[1]::text, 0::numeric) AS Chloride_Cluster_Intensity_Percent,
               public.try_cast((xpath('//NOMStats/metrics/calibration_point_count/text()',                        _nomStatsXML))[1]::text, 0)          AS Calibration_Points,
               public.try_cast((xpath('//NOMStats/metrics/calibration_raw_error_median_ppm/text()',               _nomStatsXML))[1]::text, 0::numeric) AS Calibration_Raw_Error_Median,
               public.try_cast((xpath('//NOMStats/metrics/calibration_raw_error_std_ppm/text()',                  _nomStatsXML))[1]::text, 0::numeric) AS Calibration_Raw_Error_Stdev,
               public.try_cast((xpath('//NOMStats/metrics/calibration_fit_rms_ppm/text()',                        _nomStatsXML))[1]::text, 0::numeric) AS Calibration_RMS,
               public.try_cast((xpath('//NOMStats/metrics/annotation_feature_total_count/text()',                 _nomStatsXML))[1]::text, 0)          AS Total_Features,
               public.try_cast((xpath('//NOMStats/metrics/annotation_feature_assigned_count/text()',              _nomStatsXML))[1]::text, 0)          AS Annotated_Features,
               public.try_cast((xpath('//NOMStats/metrics/annotation_feature_assigned_percent/text()',            _nomStatsXML))[1]::text, 0::numeric) AS Percent_Features_Annotated,
               public.try_cast((xpath('//NOMStats/metrics/annotation_intensity_total_sum/text()',                 _nomStatsXML))[1]::text, 0::numeric) AS Total_Intensity,
               public.try_cast((xpath('//NOMStats/metrics/annotation_intensity_assigned_sum/text()',              _nomStatsXML))[1]::text, 0::numeric) AS Annotated_Intensity,
               public.try_cast((xpath('//NOMStats/metrics/annotation_intensity_assigned_percent/text()',          _nomStatsXML))[1]::text, 0::numeric) AS Percent_Intensity_Annotated,
               public.try_cast((xpath('//NOMStats/metrics/annotation_mz_error_abs_rms_ppm/text()',                _nomStatsXML))[1]::text, 0::numeric) AS Assigned_Mz_Error_RMS_PPM,
               public.try_cast((xpath('//NOMStats/metrics/annotation_mz_error_signed_mean_ppm/text()',            _nomStatsXML))[1]::text, 0::numeric) AS Signed_Mean_PPM_Error,
               public.try_cast((xpath('//NOMStats/metrics/annotation_mz_error_abs_mean_ppm/text()',               _nomStatsXML))[1]::text, 0::numeric) AS Mean_PPM_Error,
               public.try_cast((xpath('//NOMStats/metrics/annotation_mz_error_abs_median_ppm/text()',             _nomStatsXML))[1]::text, 0::numeric) AS Median_PPM_Error,
               public.try_cast((xpath('//NOMStats/metrics/annotation_weighted_oc_ratio/text()',                   _nomStatsXML))[1]::text, 0::numeric) AS Weighted_Oc,
               public.try_cast((xpath('//NOMStats/metrics/annotation_weighted_hc_ratio/text()',                   _nomStatsXML))[1]::text, 0::numeric) AS Weighted_Hc,
               public.try_cast((xpath('//NOMStats/metrics/annotation_weighted_nosc/text()',                       _nomStatsXML))[1]::text, 0::numeric) AS Weighted_Nosc,
               public.try_cast((xpath('//NOMStats/metrics/annotation_weighted_ai_mod/text()',                     _nomStatsXML))[1]::text, 0::numeric) AS Weighted_Aimod,
               public.try_cast((xpath('//NOMStats/metrics/annotation_non_isotopologue_feature_count/text()',              _nomStatsXML))[1]::text, 0)          AS Descriptor_Feature_Count,
               public.try_cast((xpath('//NOMStats/metrics/annotation_non_isotopologue_intensity_fraction_percent/text()', _nomStatsXML))[1]::text, 0::numeric) AS Descriptor_Intensity_Fraction_Percent;

        ---------------------------------------------------
        -- Make sure Dataset_ID is up-to-date in Tmp_NOM_Stats
        ---------------------------------------------------

        UPDATE Tmp_NOM_Stats
        SET Dataset_ID = _datasetID;

        ---------------------------------------------------
        -- Replace NaN ratio values with Null
        ---------------------------------------------------

        UPDATE Tmp_NOM_Stats
        SET Organic_to_Inorganic_Count_Ratio = Null
        WHERE Organic_to_Inorganic_Count_Ratio = 'NaN'::real;

        UPDATE Tmp_NOM_Stats
        SET Organic_to_Inorganic_Intensity_Ratio = Null
        WHERE Organic_to_Inorganic_Intensity_Ratio = 'NaN'::real;

        UPDATE Tmp_NOM_Stats
        SET C13_to_Cl37_Pair_Ratio = Null
        WHERE C13_to_Cl37_Pair_Ratio = 'NaN'::real;

        UPDATE Tmp_NOM_Stats
        SET C13_to_Cl37_Pair_Intensity_Ratio = Null
        WHERE C13_to_Cl37_Pair_Intensity_Ratio = 'NaN'::real;

        If _infoOnly Then
            -----------------------------------------------
            -- Preview the data, then exit
            -----------------------------------------------

            _currentLocation := 'Preview data';

            RAISE INFO '';
            RAISE INFO 'Dataset NOM Stats for Dataset ID %: %', _datasetID, _datasetName;
            RAISE INFO '';

            _formatSpecifier := '%-12s %-10s %-10s %-11s %-13s %-21s %-15s %-23s %-32s %-36s %-14s %-15s %-22s %-32s %-22s %-27s %-28s %-27s %-29s %-34s';

            _infoHead := format(_formatSpecifier,
                                'MZ_Ion_Count',
                                'MZ_Median',
                                'MZ_Skew',
                                'MZ_Kurtosis',
                                'Organic_Count',
                                'Organic_Intensity_Sum',
                                'Inorganic_Count',
                                'Inorganic_Intensity_Sum',
                                'Organic_to_Inorganic_Count_Ratio',
                                'Organic_to_Inorganic_Intensity_Ratio',
                                'C13_Pair_Count',
                                'Cl37_Pair_Count',
                                'C13_to_Cl37_Pair_Ratio',
                                'C13_to_Cl37_Pair_Intensity_Ratio',
                                'Chloride_Cluster_Count',
                                'Chloride_Cluster_Max_Length',
                                'Chloride_Cluster_Mean_Length',
                                'Chloride_Cluster_Peak_Count',
                                'Chloride_Cluster_Peak_Percent',
                                'Chloride_Cluster_Intensity_Percent'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '------------',
                                         '----------',
                                         '----------',
                                         '-----------',
                                         '-------------',
                                         '---------------------',
                                         '---------------',
                                         '-----------------------',
                                         '--------------------------------',
                                         '------------------------------------',
                                         '--------------',
                                         '---------------',
                                         '----------------------',
                                         '--------------------------------',
                                         '----------------------',
                                         '---------------------------',
                                         '----------------------------',
                                         '---------------------------',
                                         '-----------------------------',
                                         '----------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT NOMStats.MZ_Ion_Count                            AS MZIonCount,
                       NOMStats.MZ_Median                               AS MZMedian,
                       NOMStats.MZ_Skew                                 AS MZSkew,
                       NOMStats.MZ_Kurtosis                             AS MZKurtosis,
                       NOMStats.Organic_Count                           AS OrganicCount,
                       NOMStats.Organic_Intensity_Sum                   AS OrganicIntensitySum,
                       NOMStats.Inorganic_Count                         AS InorganicCount,
                       NOMStats.Inorganic_Intensity_Sum                 AS InorganicIntensitySum,
                       NOMStats.Organic_to_Inorganic_Count_Ratio        AS OrganictoInorganicCountRatio,
                       NOMStats.Organic_to_Inorganic_Intensity_Ratio    AS OrganictoInorganicIntensityRatio,
                       NOMStats.C13_Pair_Count                          AS C13PairCount,
                       NOMStats.Cl37_Pair_Count                         AS Cl37PairCount,
                       NOMStats.C13_to_Cl37_Pair_Ratio                  AS C13toCl37PairRatio,
                       NOMStats.C13_to_Cl37_Pair_Intensity_Ratio        AS C13toCl37PairIntensityRatio,
                       NOMStats.Chloride_Cluster_Count                  AS ChlorideClusterCount,
                       NOMStats.Chloride_Cluster_Max_Length             AS ChlorideClusterMaxLength,
                       NOMStats.Chloride_Cluster_Mean_Length            AS ChlorideClusterMeanLength,
                       NOMStats.Chloride_Cluster_Peak_Count             AS ChlorideClusterPeakCount,
                       NOMStats.Chloride_Cluster_Peak_Percent           AS ChlorideClusterPeakPercent,
                       NOMStats.Chloride_Cluster_Intensity_Percent      AS ChlorideClusterIntensityPercent
                FROM Tmp_NOM_Stats NOMStats
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.MZIonCount,
                                    _previewData.MZMedian,
                                    _previewData.MZSkew,
                                    _previewData.MZKurtosis,
                                    _previewData.OrganicCount,
                                    _previewData.OrganicIntensitySum,
                                    _previewData.InorganicCount,
                                    _previewData.InorganicIntensitySum,
                                    _previewData.OrganictoInorganicCountRatio,
                                    _previewData.OrganictoInorganicIntensityRatio,
                                    _previewData.C13PairCount,
                                    _previewData.Cl37PairCount,
                                    _previewData.C13toCl37PairRatio,
                                    _previewData.C13toCl37PairIntensityRatio,
                                    _previewData.ChlorideClusterCount,
                                    _previewData.ChlorideClusterMaxLength,
                                    _previewData.ChlorideClusterMeanLength,
                                    _previewData.ChlorideClusterPeakCount,
                                    _previewData.ChlorideClusterPeakPercent,
                                    _previewData.ChlorideClusterIntensityPercent
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_NOM_Stats;
            RETURN;
        End If;

        -----------------------------------------------
        -- Add/update t_dataset_nom_stats using a merge statement
        -----------------------------------------------

        _currentLocation := 'Update t_dataset_nom_stats using a merge';

        MERGE INTO t_dataset_nom_stats AS target
        USING (SELECT Dataset_ID, Dataset_Name, MZ_Ion_Count, MZ_Median, MZ_Skew, MZ_Kurtosis,
                      Organic_Count, Organic_Intensity_Sum,
                      Inorganic_Count, Inorganic_Intensity_Sum,
                      Organic_to_Inorganic_Count_Ratio, Organic_to_Inorganic_Intensity_Ratio,
                      C13_Pair_Count, C13_Pair_Intensity_Sum,
                      Cl37_Pair_Count, Cl37_Pair_Intensity_Sum,
                      C13_to_Cl37_Pair_Ratio, C13_to_Cl37_Pair_Intensity_Ratio,
                      Chloride_Cluster_Count, Chloride_Cluster_Max_Length, Chloride_Cluster_Mean_Length,
                      Chloride_Cluster_Peak_Count, Chloride_Cluster_Peak_Percent, Chloride_Cluster_Intensity_Sum, Chloride_Cluster_Intensity_Percent,
                      _nomAnnotationJob AS NOM_Annotation_Job,
                      Calibration_Points, Calibration_Raw_Error_Median, Calibration_Raw_Error_Stdev, Calibration_RMS,
                      Total_Features, Annotated_Features, Percent_Features_Annotated,
                      Total_Intensity, Annotated_Intensity, Percent_Intensity_Annotated,
                      Assigned_Mz_Error_RMS_PPM, Signed_Mean_PPM_Error, Mean_PPM_Error, Median_PPM_Error,
                      Weighted_OC, Weighted_HC, Weighted_NOSC, Weighted_Aimod,
                      Descriptor_Feature_Count, Descriptor_Intensity_Fraction_Percent
               FROM Tmp_NOM_Stats
              ) AS Source
        ON (target.dataset_id = Source.dataset_id)
        WHEN MATCHED THEN
            UPDATE SET
                mz_ion_count                          = Source.mz_ion_count,
                mz_median                             = Source.mz_median,
                mz_skew                               = Source.mz_skew,
                mz_kurtosis                           = Source.mz_kurtosis,
                organic_count                         = Source.organic_count,
                organic_intensity_sum                 = Source.organic_intensity_sum,
                inorganic_count                       = Source.inorganic_count,
                inorganic_intensity_sum               = Source.inorganic_intensity_sum,
                organic_to_inorganic_count_ratio      = Source.organic_to_inorganic_count_ratio,
                organic_to_inorganic_intensity_ratio  = Source.organic_to_inorganic_intensity_ratio,
                c13_pair_count                        = Source.c13_pair_count,
                c13_pair_intensity_sum                = Source.c13_pair_intensity_sum,
                cl37_pair_count                       = Source.cl37_pair_count,
                cl37_pair_intensity_sum               = Source.cl37_pair_intensity_sum,
                c13_to_cl37_pair_ratio                = Source.c13_to_cl37_pair_ratio,
                c13_to_cl37_pair_intensity_ratio      = Source.c13_to_cl37_pair_intensity_ratio,
                chloride_cluster_count                = Source.chloride_cluster_count,
                chloride_cluster_max_length           = Source.chloride_cluster_max_length,
                chloride_cluster_mean_length          = Source.chloride_cluster_mean_length,
                chloride_cluster_peak_count           = Source.chloride_cluster_peak_count,
                chloride_cluster_peak_percent         = Source.chloride_cluster_peak_percent,
                chloride_cluster_intensity_sum        = Source.chloride_cluster_intensity_sum,
                chloride_cluster_intensity_percent    = Source.chloride_cluster_intensity_percent,
                nom_annotation_job                    = Coalesce(Source.nom_annotation_job, target.nom_annotation_job),
                calibration_points                    = Coalesce(Source.calibration_points, target.calibration_points),
                calibration_raw_error_median          = Coalesce(Source.calibration_raw_error_median, target.calibration_raw_error_median),
                calibration_raw_error_stdev           = Coalesce(Source.calibration_raw_error_stdev, target.calibration_raw_error_stdev),
                calibration_rms                       = Coalesce(Source.calibration_rms, target.calibration_rms),
                total_features                        = Coalesce(Source.total_features, target.total_features),
                annotated_features                    = Coalesce(Source.annotated_features, target.annotated_features),
                percent_features_annotated            = Coalesce(Source.percent_features_annotated, target.percent_features_annotated),
                total_intensity                       = Coalesce(Source.total_intensity, target.total_intensity),
                annotated_intensity                   = Coalesce(Source.annotated_intensity, target.annotated_intensity),
                percent_intensity_annotated           = Coalesce(Source.percent_intensity_annotated, target.percent_intensity_annotated),
                assigned_mz_error_rms_ppm             = Coalesce(Source.assigned_mz_error_rms_ppm, target.assigned_mz_error_rms_ppm),
                signed_mean_ppm_error                 = Coalesce(Source.signed_mean_ppm_error, target.signed_mean_ppm_error),
                mean_ppm_error                        = Coalesce(Source.mean_ppm_error, target.mean_ppm_error),
                median_ppm_error                      = Coalesce(Source.median_ppm_error, target.median_ppm_error),
                weighted_oc                           = Coalesce(Source.weighted_oc, target.weighted_oc),
                weighted_hc                           = Coalesce(Source.weighted_hc, target.weighted_hc),
                weighted_nosc                         = Coalesce(Source.weighted_nosc, target.weighted_nosc),
                weighted_aimod                        = Coalesce(Source.weighted_aimod, target.weighted_aimod),
                descriptor_feature_count              = Coalesce(Source.descriptor_feature_count, target.descriptor_feature_count),
                descriptor_intensity_fraction_percent = Coalesce(Source.descriptor_intensity_fraction_percent, target.descriptor_intensity_fraction_percent),
                last_affected                         = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (dataset_id, mz_ion_count, mz_median, mz_skew, mz_kurtosis,
                    organic_count, organic_intensity_sum,
                    inorganic_count, inorganic_intensity_sum,
                    organic_to_inorganic_count_ratio, organic_to_inorganic_intensity_ratio,
                    c13_pair_count, c13_pair_intensity_sum, cl37_pair_count, cl37_pair_intensity_sum,
                    c13_to_cl37_pair_ratio, c13_to_cl37_pair_intensity_ratio,
                    chloride_cluster_count, chloride_cluster_max_length, chloride_cluster_mean_length,
                    chloride_cluster_peak_count, chloride_cluster_peak_percent,
                    chloride_cluster_intensity_sum, chloride_cluster_intensity_percent,
                    NOM_Annotation_Job,
                    Calibration_Points, Calibration_Raw_Error_Median, Calibration_Raw_Error_Stdev, Calibration_RMS,
                    Total_Features, Annotated_Features, Percent_Features_Annotated,
                    Total_Intensity, Annotated_Intensity, Percent_Intensity_Annotated,
                    Assigned_Mz_Error_RMS_PPM, Signed_Mean_PPM_Error, Mean_PPM_Error, Median_PPM_Error,
                    Weighted_OC, Weighted_HC, Weighted_NOSC, Weighted_Aimod,
                    Descriptor_Feature_Count, Descriptor_Intensity_Fraction_Percent,
                    last_affected)
            VALUES (Source.dataset_id,
                    Source.mz_ion_count,
                    Source.mz_median,
                    Source.mz_skew,
                    Source.mz_kurtosis,
                    Source.organic_count,
                    Source.organic_intensity_sum,
                    Source.inorganic_count,
                    Source.inorganic_intensity_sum,
                    Source.organic_to_inorganic_count_ratio,
                    Source.organic_to_inorganic_intensity_ratio,
                    Source.c13_pair_count,
                    Source.c13_pair_intensity_sum,
                    Source.cl37_pair_count,
                    Source.cl37_pair_intensity_sum,
                    Source.c13_to_cl37_pair_ratio,
                    Source.c13_to_cl37_pair_intensity_ratio,
                    Source.chloride_cluster_count,
                    Source.chloride_cluster_max_length,
                    Source.chloride_cluster_mean_length,
                    Source.chloride_cluster_peak_count,
                    Source.chloride_cluster_peak_percent,
                    Source.chloride_cluster_intensity_sum,
                    Source.chloride_cluster_intensity_percent,
                    _nomAnnotationJob,
                    Source.Calibration_Points,
                    Source.Calibration_Raw_Error_Median,
                    Source.Calibration_Raw_Error_Stdev,
                    Source.Calibration_RMS,
                    Source.Total_Features,
                    Source.Annotated_Features,
                    Source.Percent_Features_Annotated,
                    Source.Total_Intensity,
                    Source.Annotated_Intensity,
                    Source.Percent_Intensity_Annotated,
                    Source.Assigned_Mz_Error_RMS_PPM,
                    Source.Signed_Mean_PPM_Error,
                    Source.Mean_PPM_Error,
                    Source.Median_PPM_Error,
                    Source.Weighted_OC,
                    Source.Weighted_HC,
                    Source.Weighted_NOSC,
                    Source.Weighted_Aimod,
                    Source.Descriptor_Feature_Count,
                    Source.Descriptor_Intensity_Fraction_Percent,
                    CURRENT_TIMESTAMP
                   );

        _message := 'Dataset NOM stats update successful';

        If Trim(Coalesce(_message, '')) <> '' And _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        ---------------------------------------------------
        -- Log SP usage
        ---------------------------------------------------

        _currentLocation := 'Call post_usage_log_entry';

        If Coalesce(_datasetName, '') = '' Then
            _usageMessage := format('Dataset ID: %s', _datasetId);
        Else
            _usageMessage := format('Dataset: %s', _datasetName);
        End If;

        If Not _infoOnly Then
            CALL post_usage_log_entry ('update_dataset_nom_stats_xml', _usageMessage);
        End If;

        DROP TABLE Tmp_NOM_Stats;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_NOM_Stats;
    END;
END
$$;


ALTER PROCEDURE public.update_dataset_nom_stats_xml(IN _datasetid integer, IN _nomstatsxml xml, IN _nomannotationjob integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

