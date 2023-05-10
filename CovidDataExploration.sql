SELECT *
FROM CovidDeaths
WHERE continent is not null

SELECT *
FROM CovidVacinations
ORDER BY 3,4 


--Loking at Total cases vs Total Deaths
--Shows likelihood of dying in Vietnam
SELECT location, date, total_cases, total_deaths, 
CASE WHEN total_cases = 0 then NULL ELSE (total_deaths/total_cases)*100 
END AS death_percentage
FROM CovidDeaths
WHERE location ='Vietnam'
ORDER BY date desc



--Looking at Total cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases,  
CASE WHEN total_cases = 0 then NULL ELSE (total_cases/population)*100 
END AS cases_percentage
FROM CovidDeaths
WHERE location like '%vietnam%'
ORDER BY date desc

--Looking at Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) TotalInfection, 
MAX((total_cases/population))*100 AS cases_percentage	
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY cases_percentage DESC

-- Showing the country with the highest death count per population
SELECT location, population, MAX(total_deaths) TotalDeaths, 
MAX((total_deaths/population))*100 AS deaths_percentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC

-- BREAK THINGS DOWN BY CONTINENT
SELECT continent, MAX(total_deaths) as TotalDeaths
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeaths DESC

-- Global numbers
SELECT SUM(new_cases) as New_cases, SUM(cast(new_deaths as int)) as New_deaths, 
CASE WHEN SUM(new_cases) <> 0 THEN (SUM(cast(new_deaths as int)) / SUM(new_cases))*100 ELSE 0
END AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--USE CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVacinated)
AS (
-- Loking at total population Vs vacination 
--Use window function
SELECT CD.continent, CD.location, CD.date, CAST(CD.population AS bigint), CV.new_vaccinations, 
SUM(CAST(CV.new_vaccinations AS real)) 
OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) as RollingPeopleVaccinated
FROM CovidDeaths CD
JOIN CovidVacinations CV
ON CD.location = CV.location and CD.date = CV.date
WHERE CD.continent is not null
--ORDER BY 2,3
)
SELECT *, CAST((RollingPeopleVacinated/Population) AS REAL) * 100  AS PercentageVacinated
FROM PopVsVac

--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVacinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CAST(CD.population AS bigint), CV.new_vaccinations, 
SUM(CAST(CV.new_vaccinations AS real)) 
OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) as RollingPeopleVaccinated
FROM CovidDeaths CD
JOIN CovidVacinations CV
ON CD.location = CV.location and CD.date = CV.date
--WHERE CD.continent is not null
--ORDER BY 2,3
SELECT *, CAST((RollingPeopleVacinated/Population) AS REAL) * 100  AS PercentageVacinated
FROM #PercentPopulationVaccinated

--Creating View to store data later for Visualization
Create View PercentPopulationVaccinated as
SELECT CD.continent, CD.location, CD.date, CAST(CD.population AS bigint) AS population, CV.new_vaccinations, 
SUM(CAST(CV.new_vaccinations AS real)) OVER (PARTITION BY CD.Location ORDER BY CD.Location, CD.Date) as RollingPeopleVaccinated
FROM CovidDeaths CD
JOIN CovidVacinations CV
ON CD.location = CV.location and CD.date = CV.date
WHERE CD.continent is not null
--ORDER BY 2,3