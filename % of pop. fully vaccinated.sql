 /*
Global Vaccination Data
Source: https://ourworldindata.org/covid-deaths
*/
 
 Select
      [continent]
      ,[location]
      ,[date]
	  ,[people_fully_vaccinated]
	  ,[population]
	  ,[people_fully_vaccinated]/[population] as '% of population fully vaccinated'
 FROM [COVID].[dbo].[owid-covid-data]
 WHERE continent <> '' AND [population]!=0
 ORDER BY [continent],[location], [date]
