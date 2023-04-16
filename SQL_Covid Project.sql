/*
Title: Data Exploration with COVID19 data
Data: https://ourworldindata.org/covid-deaths
	  https://ourworldindata.org/covid-vaccinations
Skills: JOIN, CTE, Temp Table, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- See the data based on the location(country) and date.
-- Continent has null values which show the aggregated data by continent and worldwide.
-- So let's focus on the data by countries.

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY location, date

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent is not null
ORDER BY location, date

-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY Location, date

-- Total Cases vs Total Deaths in the US
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
      AND location like '%states%'
ORDER BY Location, date

-- Total Cases vs Population in the US
-- Shows what percentage of population got covid

SELECT Location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
      AND Location like '%states%'
ORDER BY Location, date

-- Which country has the most cases and the most cases per population?
-- Looking at countries with highest infection rate compared to pupulation

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected Desc

-- which country has the most death cases per population?
-- Showing countries with highest death count per population

SELECT Location, MAX(CAST(Total_deaths as int)) as HighestDeathCount, MAX(CAST(Total_deaths as int)/population)*100 as HighestDeathPerPopulation
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not NULL --location이 continent인 경우를 배제하기 위함
GROUP BY Location
ORDER BY HighestDeathPerPopulation Desc

-- Breaking things down by continent
-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(Total_deaths as int)) as TotalDeathCount, MAX(CAST(Total_deaths as int)/population)*100 as DeathPerPopulation
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY DeathPerPopulation DESC

-- Cases and deaths worldwide

SELECT SUM(new_cases) as all_cases, SUM(CAST(new_deaths as int)) as all_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY all_cases, all_deaths

-- Total Population vs Vaccination
-- Shows percentage of population that has received at least one COVID vaccine.
-- Using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, VaccinatedByCountry)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
       , SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as VaccinatedByCountry
--       , (VaccinatedByCountry/population)*100 as VaccinatedRate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (VaccinatedByCountry/population)*100 as VaccinatedRate
FROM PopvsVac
ORDER BY VaccinatedRate DESC

-- Using Temp Table

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
VaccinatedByCountry numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
       , SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as VaccinatedByCountry
--       , (VaccinatedByCountry/population)*100 as VaccinatedRate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (VaccinatedByCountry/Population)*100 as VaccinatedRate
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PopulationVsVaccination as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
       , SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as VaccinatedByCountry
--       , (VaccinatedByCountry/population)*100 as VaccinatedRate
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null