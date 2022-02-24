/*
Covid-19 Vaccination Data Exploration 
Skills used: Aggregate Functions, CTEs, Table Altering,  Unions
Source: https://data.cdc.gov/Vaccinations/COVID-19-Vaccinations-in-the-United-States-Jurisdi/unsk-b7fc
*/

--Altering the US Census data to include a column stating the country is USA
ALTER TABLE [COVID].[dbo].[us census bureau regions and divisions]
ADD Country varchar(3);

UPDATE [COVID].[dbo].[us census bureau regions and divisions] 
SET [Country] = 'USA';

--Creating a CTE to calculate various Total Population sizes to create weighted averages when accessing data based on regions and to join US Census data into our COVID-19 dataset
With PopulationCTE AS 
(
Select
	
	([Series_Complete_Yes]/NULLIF([Series_Complete_Pop_Pct],0))*100 as 'Total Population',
	([Series_Complete_5Plus]/NULLIF([Series_Complete_5PlusPop_Pct],0))*100 as 'Total Population 5+',
	([Series_Complete_12Plus]/NULLIF([Series_Complete_12PlusPop_Pct],0))*100 as 'Total Population 12+',
	([Series_Complete_18Plus]/NULLIF([Series_Complete_18PlusPop_Pct],0))*100 as 'Total Population 18+',
	([Series_Complete_65Plus]/NULLIF([Series_Complete_65PlusPop_Pct],0))*100 as 'Total Population 65+',
	*
FROM [COVID].[dbo].[COVID-19_Vaccinations_in_the_United_States_Jurisdiction]
JOIN [COVID].[dbo].[us census bureau regions and divisions] ON [Location]=[State Code]
)

--Using the CTE, we create three queries to aggregate data at the state,region, and country level which are also unioned together
SELECT 
	[Date],
	[Region],

	ISNULL(SUM([Series_Complete_Yes])/SUM([Total Population]),0) as 'Percent of Population Fully Vaccinated', 
	SUM([Series_Complete_Yes]) as 'Total Population Fully Vaccinated',
	SUM([Series_Complete_Pfizer]) as 'Total Population Fully vaccinated with Pfizer vaccine', 
    SUM([Series_Complete_Moderna]) as 'Total Population Fully vaccinated with Moderna vaccine',
    SUM([Series_Complete_Janssen]) as 'Total Population Fully vaccinated with J&J/Janssen vaccine',
    SUM([Series_Complete_Unk_Manuf]) as 'Total Population Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_5Plus])/SUM([Total Population 5+]),0) as 'Percent of Population 5+ Fully Vaccinated',
	SUM([Series_Complete_5Plus]) as 'Total Population 5+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_5Plus]) as 'Total Population 5+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_5Plus]) as 'Total Population 5+ Fully vaccinated with Moderna vaccine',
    SUM([Series_Complete_Janssen_5Plus]) as 'Total Population 5+ Fully vaccinated with J&J/Janssen vaccine',
    SUM([Series_Complete_Unk_Manuf_5Plus]) as 'Total Population 5+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_12Plus])/SUM([Total Population 12+]),0) as 'Percent of Population 12+ Fully Vaccinated',
	SUM([Series_Complete_12Plus]) as 'Total Population 12+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_12Plus]) as 'Total Population 12+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_12Plus]) as 'Total Population 12+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_12Plus]) as 'Total Population 12+ Fully vaccinated with J&J/Janssen vaccine',  
    SUM([Series_Complete_Unk_Manuf_12Plus]) as 'Total Population 12+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_18Plus])/SUM([Total Population 18+]),0) as 'Percent of Population 18+ Fully Vaccinated',
	SUM([Series_Complete_18Plus]) as 'Total Population 18+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_18Plus]) as 'Total Population 18+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_18Plus]) as 'Total Population 18+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_18Plus]) as 'Total Population 18+ Fully vaccinated with J&J/Janssen vaccine',
    SUM([Series_Complete_Unk_Manuf_18Plus]) as 'Total Population 18+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_65Plus])/SUM([Total Population 65+]),0) as 'Percent of Population 65+ Fully Vaccinated',
	SUM([Series_Complete_65Plus]) as 'Total Population 65+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_65Plus]) as 'Total Population 65+ Fully vaccinated with Pfizer vaccine',
    SUM([Series_Complete_Moderna_65Plus]) as 'Total Population 65+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_65Plus]) as 'Total Population 65+ Fully vaccinated with J&J/Janssen vaccine',
    SUM([Series_Complete_Unk_Manuf_65Plus])  as 'Total Population 65+ Fully vaccinated with an unknown two-dose vaccine manufacturer'
    
    
FROM PopulationCTE
GROUP BY [Region], [Date]

UNION 

SELECT
	[Date],
	[Country],
	ISNULL(SUM([Series_Complete_Yes])/SUM([Total Population]),0) as 'Percent of Population Fully Vaccinated', 
	SUM([Series_Complete_Yes]) as 'Total Population Fully Vaccinated',
	SUM([Series_Complete_Pfizer]) as 'Total Population Fully vaccinated with Pfizer vaccine', 
	SUM([Series_Complete_Moderna]) as 'Total Population Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen]) as 'Total Population Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf]) as 'Total Population Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_5Plus])/SUM([Total Population 5+]),0) as 'Percent of Population 5+ Fully Vaccinated',
	SUM([Series_Complete_5Plus]) as 'Total Population 5+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_5Plus]) as 'Total Population 5+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_5Plus]) as 'Total Population 5+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_5Plus]) as 'Total Population 5+ Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf_5Plus]) as 'Total Population 5+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_12Plus])/SUM([Total Population 12+]),0) as 'Percent of Population 12+ Fully Vaccinated',
	SUM([Series_Complete_12Plus]) as 'Total Population 12+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_12Plus]) as 'Total Population 12+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_12Plus]) as 'Total Population 12+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_12Plus]) as 'Total Population 12+ Fully vaccinated with J&J/Janssen vaccine',  
	SUM([Series_Complete_Unk_Manuf_12Plus]) as 'Total Population 12+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_18Plus])/SUM([Total Population 18+]),0) as 'Percent of Population 18+ Fully Vaccinated',
	SUM([Series_Complete_18Plus]) as 'Total Population 18+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_18Plus]) as 'Total Population 18+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_18Plus]) as 'Total Population 18+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_18Plus]) as 'Total Population 18+ Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf_18Plus]) as 'Total Population 18+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_65Plus])/SUM([Total Population 65+]),0) as 'Percent of Population 65+ Fully Vaccinated',
	SUM([Series_Complete_65Plus]) as 'Total Population 65+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_65Plus]) as 'Total Population 65+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_65Plus]) as 'Total Population 65+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_65Plus]) as 'Total Population 65+ Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf_65Plus])  as 'Total Population 65+ Fully vaccinated with an unknown two-dose vaccine manufacturer'
FROM PopulationCTE
GROUP BY [Country],[Date]

UNION 

SELECT
	[Date],
	[State Code],
	ISNULL(SUM([Series_Complete_Yes])/SUM([Total Population]),0) as 'Percent of Population Fully Vaccinated', 
	SUM([Series_Complete_Yes]) as 'Total Population Fully Vaccinated',
	SUM([Series_Complete_Pfizer]) as 'Total Population Fully vaccinated with Pfizer vaccine', 
	SUM([Series_Complete_Moderna]) as 'Total Population Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen]) as 'Total Population Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf]) as 'Total Population Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_5Plus])/SUM([Total Population 5+]),0) as 'Percent of Population 5+ Fully Vaccinated',
	SUM([Series_Complete_5Plus]) as 'Total Population 5+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_5Plus]) as 'Total Population 5+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_5Plus]) as 'Total Population 5+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_5Plus]) as 'Total Population 5+ Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf_5Plus]) as 'Total Population 5+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_12Plus])/SUM([Total Population 12+]),0) as 'Percent of Population 12+ Fully Vaccinated',
	SUM([Series_Complete_12Plus]) as 'Total Population 12+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_12Plus]) as 'Total Population 12+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_12Plus]) as 'Total Population 12+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_12Plus]) as 'Total Population 12+ Fully vaccinated with J&J/Janssen vaccine',  
	SUM([Series_Complete_Unk_Manuf_12Plus]) as 'Total Population 12+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_18Plus])/SUM([Total Population 18+]),0) as 'Percent of Population 18+ Fully Vaccinated',
	SUM([Series_Complete_18Plus]) as 'Total Population 18+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_18Plus]) as 'Total Population 18+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_18Plus]) as 'Total Population 18+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_18Plus]) as 'Total Population 18+ Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf_18Plus]) as 'Total Population 18+ Fully vaccinated with an unknown two-dose vaccine manufacturer',

	ISNULL(SUM([Series_Complete_65Plus])/SUM([Total Population 65+]),0) as 'Percent of Population 65+ Fully Vaccinated',
	SUM([Series_Complete_65Plus]) as 'Total Population 65+ Fully Vaccinated',
	SUM([Series_Complete_Pfizer_65Plus]) as 'Total Population 65+ Fully vaccinated with Pfizer vaccine',
	SUM([Series_Complete_Moderna_65Plus]) as 'Total Population 65+ Fully vaccinated with Moderna vaccine',
	SUM([Series_Complete_Janssen_65Plus]) as 'Total Population 65+ Fully vaccinated with J&J/Janssen vaccine',
	SUM([Series_Complete_Unk_Manuf_65Plus])  as 'Total Population 65+ Fully vaccinated with an unknown two-dose vaccine manufacturer'
FROM PopulationCTE
GROUP BY [State Code],[Date]
ORDER BY [Date] DESC;
