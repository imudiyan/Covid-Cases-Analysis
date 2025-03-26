--Check the row count of each table to verify data import
SELECT COUNT(*)
FROM Covid_Cases_Analysis.dbo.CovidDeaths$;

SELECT COUNT(*)
FROM Covid_Cases_Analysis.dbo.CovidVaccinations$;

--Total Cases Vs Total Deaths for Sri Lanka
SELECT cd.location
	,cd.DATE
	,cd.total_cASes
	,cd.total_deaths
	,(cd.total_deaths / NULLIF(cd.total_cASes, 0)) * 100 AS DeathPercentage
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
WHERE cd.location LIKE '%Lanka%'
ORDER BY 1
	,2;

---Total infected percentage OVER population
SELECT cd.location
	,cd.DATE
	,cd.total_cASes
	,cd.population
	,round((cd.total_cASes / NULLIF(cd.population, 0)), 6) * 100 AS InfectedPercentageOVERPopulation
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
WHERE cd.location LIKE '%Lanka%'
ORDER BY 1
	,2;

-- Countries WITH Highest Infection Rate compared to Population
SELECT cd.location
	,cd.population
	,max(cd.total_cASes) AS HighestInfection
	,(Max(round((cd.total_cASes / NULLIF(cd.population, 0)), 6) * 100)) AS InfectedPercentageOVERPopulation
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
WHERE continent IS NOT NULL
-- AND cd.location LIKE '%anka%'
GROUP BY cd.location
	,cd.population
ORDER BY InfectedPercentageOVERPopulation DESC;

--Countries WITH Highest Death Count per Population
SELECT cd.location
	,cd.population
	,max(cd.total_deaths) AS HighestNoofDeaths
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.location
	,cd.population
ORDER BY HighestNoofDeaths DESC;

--Showing contintents WITH the highest death count per population
SELECT cd.location
	,max(cd.total_deaths) AS TotalDeaths
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
WHERE cd.continent IS NULL
GROUP BY cd.location
ORDER BY TotalDeaths DESC;

--global total cASes, total deaths and deaths percentage
SELECT SUM(cd.new_cASes) AS TotalCASes
	,SUM(cd.new_deaths) AS TotalDeaths
	,(SUM(cd.new_deaths) / SUM(cd.new_cASes)) * 100 AS DeathPercentage
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
WHERE cd.continent IS NOT NULL;

--Total population vs vaccination
SELECT cd.continent
	,cd.location
	,cd.DATE
	,cd.population
	,cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (
		PARTITION BY cd.location ORDER BY cd.location
			,cd.DATE
			--rows unbounded preceding
		) AS RollingPeopleVaccinated
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
JOIN Covid_Cases_Analysis.dbo.CovidVaccinations$ AS cv ON cd.location = cv.location
	AND cd.DATE = cv.DATE
WHERE cd.continent IS NOT NULL
ORDER BY 2
	,3;

--Calculating total vaccinated percentage OVER population
--Using CTE
WITH VaccinationTemp
AS (
	SELECT cd.continent
		,cd.location
		,cd.DATE
		,cd.population
		,cv.new_vaccinations
		,SUM(cv.new_vaccinations) OVER (
			PARTITION BY cd.location ORDER BY cd.location
				,cd.DATE
				--rows unbounded preceding
			) AS RollingPeopleVaccinated
	FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
	JOIN Covid_Cases_Analysis.dbo.CovidVaccinations$ AS cv ON cd.location = cv.location
		AND cd.DATE = cv.DATE
	WHERE cd.continent IS NOT NULL
	)
SELECT continent
	,location
	,population
	,Max((RollingPeopleVaccinated / NULLIF(population, 0)) * 100) AS VaccinatedPercehtage
FROM VaccinationTemp
WHERE location LIKE '%Lanka%'
GROUP BY continent
	,location
	,population;

--using temporary table to store data
DROP TABLE

IF EXISTS #tempVaccinatedSUMmary
	CREATE TABLE #tempVaccinatedSUMmary (
		Continent NVARCHAR(255)
		,Location NVARCHAR(255)
		,DATE DATETIME
		,Population NUMERIC
		,New_Vaccination NUMERIC
		,RollingPeopleVaccinated NUMERIC
		)

INSERT INTO #tempVaccinatedSUMmary
SELECT 	cd.continent
		,cd.location
		,cd.DATE
		,cd.population
		,cv.new_vaccinations
		,SUM(cv.new_vaccinations) OVER (
			PARTITION BY cd.location ORDER BY cd.location
				,cd.DATE
				--rows unbounded preceding
			) AS RollingPeopleVaccinated
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
JOIN Covid_Cases_Analysis.dbo.CovidVaccinations$ AS cv ON cd.location = cv.location
	AND cd.DATE = cv.DATE;

--WHERE cd.continent is not null
SELECT Continent
		,Location
		,Population
	,Max((RollingPeopleVaccinated / NULLIF(population, 0)) * 100) AS VaccinatedPercettage
FROM #tempVaccinatedSUMmary
WHERE Continent IS NOT NULL
-- and location LIKE '%Lanka%' 
GROUP BY Continent
		,Location
		,Population;


--using a view
CREATE VIEW VaccinatedSUMmary
AS
SELECT cd.continent
	,cd.location
	,cd.DATE
	,cd.population
	,cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (
		PARTITION BY cd.location ORDER BY cd.location
			,cd.DATE
			--rows unbounded preceding
		) AS RollingPeopleVaccinated
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
JOIN Covid_Cases_Analysis.dbo.CovidVaccinations$ AS cv ON cd.location = cv.location
	AND cd.DATE = cv.DATE
WHERE cd.continent IS NOT NULL;

SELECT continent
	,location
	,population
	,Max((RollingPeopleVaccinated / NULLIF(population, 0)) * 100) AS VaccinatedPercehtage
FROM VaccinatedSUMmary
--WHERE location LIKE '%Lanka%' 
GROUP BY continent
	,location
	,population;



-- comparison between smoking % vs death %
CREATE VIEW SmokingEffect
AS
SELECT cd.continent
	,cd.location
	,max(cd.total_cASes) AS TotalCASes
	,max(cd.total_deaths) AS TotalDeaths
	,(max(cd.total_deaths) / NULLIF(max(cd.total_cASes), 0)) * 100 AS DeathPercentage
	,max(cv.female_smokers) AS FemaleSmakers
	,max(cv.male_smokers) AS MaleSmokers
FROM Covid_Cases_Analysis.dbo.CovidDeaths$ AS cd
JOIN Covid_Cases_Analysis.dbo.CovidVaccinations$ AS cv ON cd.location = cv.location
	AND cd.DATE = cv.DATE
WHERE cd.continent IS NOT NULL
--and cd.location LIKE '%China%'
GROUP BY cd.continent
	,cd.location

--ORDER BY DeathPercentage desc
SELECT *
FROM SmokingEffect
