-- Create a new database called 'Project1'
-- Connect to the 'master' database to run this snippet
USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'Project1'
)
CREATE DATABASE Project1
GO

SELECT *
FROM Project1..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Project1..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows liklihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM Project1..CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of population  got covid
SELECT Location, date, population,total_cases,(total_cases/population)*100 as CasePercentage
FROM Project1..CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

-- Looking at countries with highest ifectious rate compared to population
SELECT Location, population,Max(total_cases) as HighestInfectionCount,Max((total_cases/population))*100 as PercentPopulationInfected
FROM Project1..CovidDeaths
WHERE continent is not NULL
GROUP by Location, population
ORDER BY PercentPopulationInfected DESC

-- Showing countries with highest death count per population
SELECT Location,Max(cast(total_deaths as int)) as TotalDeathCount
FROM Project1..CovidDeaths
WHERE continent is not NULL
GROUP by Location
ORDER BY TotalDeathCount DESC

-- Break down by continent
SELECT location,Max(cast(total_deaths as int)) as TotalDeathCount
FROM Project1..CovidDeaths
WHERE continent is NULL
GROUP by location
ORDER BY TotalDeathCount DESC

-- Showing the continents with the highest death counts
SELECT continent,Max(cast(total_deaths as int)) as TotalDeathCount
FROM Project1..CovidDeaths
WHERE continent is not NULL
GROUP by continent
ORDER BY TotalDeathCount DESC

-- Global numbers 
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM Project1..CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not NULL
GROUP by date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM Project1..CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not NULL
--GROUP by date
ORDER BY 1,2

-- Looking at total population vs vaccinations
SELECT *
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date

-- Use CTE

WITH PopvsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) 
over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 
FROM PopvsVac
ORDER by 2,3

-- Temp table
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    Date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) 
over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not NULL

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated
ORDER by 2,3

-- creating view to store data for later visualizations
GO
CREATE VIEW PercentPopulationVaccinate as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) 
over (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM Project1..CovidDeaths dea
JOIN Project1..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not NULL

SELECT *
FROM PercentPopulationVaccinate