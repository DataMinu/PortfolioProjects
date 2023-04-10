SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

-- Select Data that we are going to be using

SELECT Location, date,total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at the Total Cases vs Population
-- Shows what percentage of population got covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to pupulation

SELECT Location, population, MAX(total_cases) as highestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected Desc

-- Showing countries with highest death count per population

SELECT continent, MAX(CAST(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not NULL --location이 continent인 경우를 배제하기 위함
GROUP BY continent
ORDER BY TotalDeathCount Desc

-- Global Numbers

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2


-- Looking at total population vs vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
, MAX(RollingPeopleVaccinated/population)*100 --RollingPeopleVaccinated는 현재 구문 안에서 진행 중이므로, 그 구문을 대상으로 calculation 할 수 없다. 따라서 cte 나 temp table을 이용해야 한다. 시도해봐라
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, MAX(RollingPeopleVaccinated/population)*100 --RollingPeopleVaccinated는 현재 구문 안에서 진행 중이므로, 그 구문을 대상으로 calculation 할 수 없다. 따라서 cte 나 temp table을 이용해야 한다. 시도해봐라
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Temp Table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, MAX(RollingPeopleVaccinated/population)*100 --RollingPeopleVaccinated는 현재 구문 안에서 진행 중이므로, 그 구문을 대상으로 calculation 할 수 없다. 따라서 cte 나 temp table을 이용해야 한다. 시도해봐라
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, MAX(RollingPeopleVaccinated/population)*100 --RollingPeopleVaccinated는 현재 구문 안에서 진행 중이므로, 그 구문을 대상으로 calculation 할 수 없다. 따라서 cte 나 temp table을 이용해야 한다. 시도해봐라
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated