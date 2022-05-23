/*
Video Game Sales Analysis Project
Skills used: Unpivot, Functions, Identifying Nulls and Duplicates , Global Search & Replace, JOIN
Sources: 
https://www.kaggle.com/datasets/rush4ratio/video-game-sales-with-ratings
https://en.wikipedia.org/wiki/List_of_best-selling_game_consoles_by_region
*/

-- #1 We union the separate regional tables we have on various video game console sales as well perform preliminary data cleaning. We create a new table with the unioned values

SELECT * 
INTO [Video Game Data].[dbo].[Video Game Console Sales Data] 
FROM 
(
SELECT [Manufacturer]
      ,TRIM('#' FROM [Console]) as [Console]
      ,[Released]
      ,CAST(TRIM('[<>]' FROM REPLACE(REPLACE([Units sold],',',''),'(estimated)','')) as FLOAT) as 'Units Sold'
      ,[Date of figure]  
	  ,[Country]
FROM 
(
SELECT *, 'Australia' as Country
  FROM [Video Game Data].[dbo].[Australia]
  UNION
SELECT *, 'Brazil' as Country
  FROM [Video Game Data].[dbo].[Brazil]
  UNION
SELECT *, 'Canada' as Country
  FROM [Video Game Data].[dbo].[Canada]
  UNION
SELECT *, 'China' as Country
  FROM [Video Game Data].[dbo].[China]
  UNION
SELECT *, 'Europe' as Country
  FROM [Video Game Data].[dbo].[Europe]
  UNION
SELECT *, 'France' as Country
  FROM [Video Game Data].[dbo].[France]
  UNION
SELECT *, 'Germany' as Country
  FROM [Video Game Data].[dbo].[Germany]
  UNION
SELECT *, 'Japan' as Country
  FROM [Video Game Data].[dbo].[Japan]
  UNION
SELECT *, 'South Africa' as Country
  FROM [Video Game Data].[dbo].[South Africa]  
  UNION
SELECT *, 'South Korea' as Country
  FROM [Video Game Data].[dbo].[South Korea]
  UNION
SELECT *, 'Spain' as Country
  FROM [Video Game Data].[dbo].[Spain]
  UNION
SELECT *, 'United Kingdom' as Country
  FROM [Video Game Data].[dbo].[United Kingdom]
  UNION
SELECT *, 'United States' as Country
  FROM [Video Game Data].[dbo].[United States]
  UNION
SELECT *, 'Unknown regions' as Country
  FROM [Video Game Data].[dbo].[Unknown regions]
  UNION
SELECT *, 'Mexio' as Country
  FROM [Video Game Data].[dbo].[Mexico]  
) as A
) as B

--#2 We check for null & duplicate data rows. We also then remove any unwanted rows
--Checking for null rows in the Video Game Sales dataset, and dropping them accordingly 
SELECT *
	FROM [Video Game Data].[dbo].[Video_Games_Sales_as_at_22_Dec_$]
	WHERE [Name] iS NULL OR [Year_of_Release] IS NULL OR [Genre] IS NULL

DELETE
	FROM [Video Game Data].[dbo].[Video_Games_Sales_as_at_22_Dec_$]
	WHERE [Name] iS NULL OR [Year_of_Release] IS NULL OR [Genre] IS NULL

--Checking for duplicate rows in the Video Game Sales dataset, and dropping rows accordingly 
SELECT 
	[Name]
	,[Platform]
	,COUNT([Name])
	FROM [Video Game Data].[dbo].[Video_Games_Sales_as_at_22_Dec_$]
	GROUP BY [Name],[Platform]
	HAVING COUNT([Name]) > 1

DELETE 
	FROM [Video Game Data].[dbo].[Video_Games_Sales_as_at_22_Dec_$]
	WHERE [Name] = 'Madden NFL 13' AND [NA_Sales] = 0

--Checking for duplicate rows in the Video Game Console Sales, and dropping rows accordingly 
SELECT 
	[Console]
	,[Country]
	,COUNT([Console])
	FROM [Video Game Data].[dbo].[Video Game Console Sales Data]
	GROUP BY [Console],[Country]
	HAVING COUNT([Console]) > 1

DELETE
	FROM [Video Game Data].[dbo].[Video Game Console Sales Data]
	WHERE [Console] = 'PlayStation 2' AND [Country]= 'United Kingdom' AND [Units Sold] ='1000000'


--#3 Create a matched pair table for console name abbreviations and full name. From there create a function to replace abbreviations with the full console name

--First we create the table of mached pairs
DROP TABLE IF EXISTS [Video Game Data].[dbo].[ConsoleName]

CREATE TABLE [Video Game Data].[dbo].[ConsoleName] (Consolename NVARCHAR(100),Abbreviation NVARCHAR(10));
INSERT INTO [Video Game Data].[dbo].[ConsoleName] VALUES
 ('Nintendo Entertainment System','NES')
,('Super Nintendo Entertainment System','SNES')
,('Nintendo 64','N64')
,('Gamecube','GC')
,('Nintendo Wii','Wii')
,('Nintendo Wii U','Wii U')
,('Nintendo Switch','Switch')
,('Game Boy Color','GBC')
,('Gameboy','GB')
,('Game Boy Advance','GBA')
,('Nintendo DS','DS')
,('Nintendo 3DS','3DS')
,('PlayStation','PS')
,('PlayStation 2','PS2')
,('PlayStation 3','PS3')
,('PlayStation 4','PS4')
,('PlayStation 5','PS5')
,('Playstation Portable','PSP')
,('Playstation Vita','PSV')
,('PS Vita','PSV')
,('Xbox','XB')
,('Xbox 360','X360')
,('Xbox One','XOne')
,('Xbox Series X # Xbox Series S','XB X|S')
,('Dreamcast','DC')
,('Atari 2600','2600')
,('3DO Interactive Multiplayer','3DO')
,('Game Gear','GG')
,('Neo Geo','NG')
,('PC-FX','PCFX')
,('Saturn','SAT')
,('Sega CD','SCD')
,('TurboGrafx-16 (PC Engine)','TG16')
,('WonderSwan','WS')
,('Genesis (Mega Drive)','GEN')
,('Personal Computer','PC')


--Then we create a function that looks up Console Abbreviations and replaces it with the full console name. The Where clause ensures only exact matches are replaced when the function is called
CREATE FUNCTION dbo.AbbreviationstoConsoleName(@string NVARCHAR(MAX))
RETURNS NVARCHAR(MAX) AS
BEGIN
	SELECT @string=REPLACE(@string,Abbreviation,Consolename)
	FROM [Video Game Data].[dbo].[ConsoleName]
	WHERE @string=Abbreviation;
	RETURN @string;
END
GO

--#4 Using Unpivot we transform column of regional sales to be it's own column. Combing this query and the query before, we create a query that gives the final output. 


--Select the columns we want & clean some of the column headers/data
SELECT 
	TRIM([Name]) as [Name]
	,[ConsoleName]
	,[Year_of_Release]
	,[Manufacturer] as [ConsoleManufacturer]
	,[Genre]
	,REPLACE([Region],'_',' ') as [Region]
	,[Region Sales]
	,[Units Sold] as [TotalConsoleSales]
	,[Critic_Score]
	,[Critic_Count]
	,[User_Score]
	,[User_Count]
	,[Rating]
FROM 
(
	--Using a subquery, we apply our previousuly defined function to replace the abbreviated console names to their full name
	SELECT [Video Game Data].[dbo].[AbbreviationstoConsoleName]([Platform]) AS [ConsoleName],* FROM 
	(
		--Using another subquery, we unpivot our data so each region(NA,EU,JP, etc.)'s sales number has its own individual row
		SELECT *
		FROM [Video Game Data].[dbo].[Video_Games_Sales_as_at_22_Dec_$] 
	) as A
	UNPIVOT 
	(
	  [Region Sales] FOR Region IN 
		(
	  [NA_Sales]
      ,[EU_Sales]
      ,[JP_Sales]
      ,[Other_Sales]
      ,[Global_Sales]
		)
	) as [Unpivoted]
) as B
--We then join our video game sales data with our video game console sales data
JOIN 
(
  SELECT 
	[Manufacturer]
	,[Console]
	,SUM([Units Sold]) as [Units Sold]
	FROM [Video Game Data].[dbo].[Video Game Console Sales Data]
	GROUP BY [Manufacturer],[Console]
) AS C on B.[ConsoleName]=C.[Console]
	ORDER BY [Region Sales] DESC  
  
