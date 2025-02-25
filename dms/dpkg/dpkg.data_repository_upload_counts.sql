--
-- Name: data_repository_upload_counts(integer); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.data_repository_upload_counts(_filtermode integer DEFAULT 1) RETURNS TABLE(upload_month date, datasets integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get dataset counts, by month, for data uploaded to data repositories
**
**  Arguments:
**    _filterMode     Filter mode:
**                      0: no filter
**                      1: ProteomeXchange and MassIVE only
**                      2: CPTAC, MoTrPAC, and TEDDY only
**
**  Example usage:
**      -- All data repositories
**      SELECT * FROM dpkg.data_repository_upload_counts(0);
**
**      -- ProteomeXchange and MassIVE only
**      SELECT * FROM dpkg.data_repository_upload_counts(1);
**
**  Returns:
**      Dataset counts, by month
**
**  Auth:   mem
**  Date:   01/30/2025 mem - Initial version
**
*****************************************************/
DECLARE
    _currentDate date;
    _endDate date;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _filterMode := Coalesce(_filterMode, 0);

    If Not _filterMode IN (0, 1, 2) Then
        RAISE WARNING 'Changed filter mode from % to 0 since must be 0, 1, or 2', _filterMode;
        _filterMode := 0;
    End If;

    CREATE TEMP TABLE Tmp_Dates (
        upload_month date CONSTRAINT pk_tmp_dates_upload_month PRIMARY KEY
    );

    If _filterMode In (0, 1) Then
        -- Start date for ProteomeXchange and MassIVE
        _currentDate := '2013-01-01';
    Else
        -- Start date for CPTAC, MoTrPAC, and TEDDY
        _currentDate := '2018-01-01';
    End If;

    _endDate := current_timestamp::date;

    ---------------------------------------------------
    -- Populate Tmp_Dates with the first day of each month that starts each quarter, starting with _currentDate
    ---------------------------------------------------

    /*
    -- Option 1: use generate_series(), which works, but is a little cryptic
    --
    INSERT INTO Tmp_Dates (upload_month)
    SELECT start_month + make_interval(months => month_addon)
    FROM ( SELECT _currentDate AS start_month,
                  generate_series(0, MonthCountQ.Value, 3) AS Month_Addon
           FROM (SELECT months_between AS Value
                 FROM public.months_between(_currentDate::timestamp, _endDate::timestamp)
                ) MonthCountQ
         ) SourceQ;
    */

    -- Option 2: use a while loop
    --
    WHILE _currentDate <= _endDate
    LOOP
        INSERT INTO Tmp_Dates (upload_month)
        VALUES (_currentDate);

        _currentDate := _currentDate + Interval '3 months';
    END LOOP;

    RETURN QUERY
    SELECT Tmp_Dates.upload_month,
           Coalesce(StatsQ.Datasets, 0)::int As Datasets
    FROM Tmp_Dates
         LEFT OUTER JOIN (
            SELECT OuterQ.upload_month,
                   Count(*) AS Datasets
            FROM ( SELECT format('%s-%s-01', "Year", "Month")::date AS Upload_Month,
                          InnerQ.Dataset_ID
                   FROM ( SELECT Extract(year from Upload_Date) AS "Year",
                                 CASE
                                     WHEN Extract(month from Upload_Date) IN (1, 2, 3) THEN 1
                                     WHEN Extract(month from Upload_Date) IN (4, 5, 6) THEN 4
                                     WHEN Extract(month from Upload_Date) IN (7, 8, 9) THEN 7
                                     ELSE 10
                                 END AS "Month",
                                 DistinctQ.Dataset_ID
                          FROM ( SELECT DS.Dataset_ID,
                                        Max(Upload_Date) AS Upload_Date
                                 FROM dpkg.t_data_repository_uploads U
                                      INNER JOIN dpkg.t_data_repository_data_packages DP
                                        ON U.Upload_ID = DP.Upload_ID
                                      INNER JOIN dpkg.t_data_package_datasets DS
                                        ON DS.Data_Pkg_ID = DP.Data_Pkg_ID
                                      INNER JOIN dpkg.t_data_repository Repo
                                        ON U.Repository_ID = Repo.Repository_ID
                                 WHERE _filterMode = 0 Or
                                       _filterMode = 1 And U.Repository_ID In (1, 2) Or
                                       _filterMode = 2 And U.Repository_ID In (3, 4, 5)
                                 GROUP BY DS.Dataset_ID
                               ) DistinctQ
                       ) InnerQ
                 ) OuterQ
            GROUP BY OuterQ.Upload_Month
    ) StatsQ On Tmp_Dates.Upload_Month = StatsQ.Upload_Month
    ORDER BY Tmp_Dates.Upload_Month;

    DROP TABLE Tmp_Dates;
END
$$;


ALTER FUNCTION dpkg.data_repository_upload_counts(_filtermode integer) OWNER TO d3l243;

