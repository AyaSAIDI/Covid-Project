SELECT * 
FROM dbo.CovidDeaths$ As CD
Where Continent is not NULL
Order by 3,4

SELECT *
FROM dbo.CovidVaccinations$ AS CV

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM dbo.CovidDeaths$ As CD
ORDER BY 1,2

-- Looking at the Total Cases vs Total Deaths

SELECT CD.Location, date, (total_deaths/total_cases)*100 AS PercentageDeaths
FROM dbo.CovidDeaths$ AS CD

--Looking at the Total deaths by location
SELECT
    CD.Location,
    SUM(ISNULL(TRY_CAST(CD.total_cases AS BIGINT), 0)) AS TotalCases,
    SUM(ISNULL(TRY_CAST(CD.total_deaths AS BIGINT), 0)) AS TotalDeaths
FROM
    dbo.CovidDeaths$ AS CD

GROUP BY CD.Location


-- Looking at the location with the maximum total of deaths
WITH CTE_COVID_DEATHS as (
    SELECT
        CD.Location AS Location,
        SUM(ISNULL(TRY_CAST(CD.total_cases AS BIGINT), 0)) AS TotalCases,
        SUM(ISNULL(TRY_CAST(CD.total_deaths AS BIGINT), 0)) AS TotalDeaths
    FROM
        dbo.CovidDeaths$ AS CD
    GROUP BY
        CD.Location
)
SELECT 
    CDD.Location,
    CDD.TotalDeaths
FROM 
    CTE_COVID_DEATHS AS CDD
WHERE 
    CDD.TotalDeaths = (SELECT MAX(TotalDeaths) FROM CTE_COVID_DEATHS WHERE Location <> 'World');

-- Shows likelihood of dying if you contract Covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths$ 
--Where location like '%Morocco%'
order by 1,2

-- Looking at Total Cases Vs Population
-- Shows what percentage of population got Covid
Select Location, date, total_cases, population, (total_cases/population)*100 as CasesRate
FROM CovidDeaths$ 
--Where location like '%Morocco%'
order by 1,2

--Looking at countries with highest infection rate compared to population
Select Location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as CasesRate
FROM CovidDeaths$ 
--Where location like '%Morocco%'
GROUP BY Population, Location
order by 4 desc

-- Let discover the numbers by continent
Select location, MAX(cast(total_deaths as int)) As TotalDeathsCount
FROM CovidDeaths$ 
--Where location like '%Morocco%'
Where Continent is NULL AND location <> 'World'
GROUP BY location
order by 2 desc

--OR

Select continent , MAX(cast(total_deaths as int)) As TotalDeathsCount
FROM CovidDeaths$ 
--Where location like '%Morocco%'
Where Continent is NOT NULL
GROUP BY continent
order by 2 desc

-- Showing the countries with the highest death count per population
Select Location, MAX(cast(total_deaths as int)) As TotalDeathsCount
FROM CovidDeaths$ 
--Where location like '%Morocco%'
Where Continent is not NULL
GROUP BY Location
order by 2 desc

-- Global Numbers
Select date, SUM(new_cases) AS totalcases, SUM(cast(new_deaths as int)) as totaldeaths , (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM CovidDeaths$ 
WHERE continent is NOT NULL
--Group by date
--order by 1


-- Looking at Total populaton vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccination

FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location AND  dea.date = vac.date
WHERE dea.continent is NOT NULL
Order by 2,3

-- USE CTE 
WITH PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingpeopleVaccinated)
AS (Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccination

FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location AND  dea.date = vac.date
WHERE dea.continent is NOT NULL
)
Select * ,  (RollingpeopleVaccinated/Population)*100 AS PerPopVac
FROM PopVsVac

-- USE TEMP TABLE
--DROP TABLE IF EXISTS

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(250),
Location nvarchar(250),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccination

FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location AND  dea.date = vac.date
WHERE dea.continent is NOT NULL



Select *, (RollingPeopleVaccinated/Population)*100 AS PerPopVac
FROM #PercentPopulationVaccinated 

-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated 
AS Select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccination

FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location AND  dea.date = vac.date
WHERE dea.continent is NOT NULL

Select * 
FROM PercentPopulationVaccinated