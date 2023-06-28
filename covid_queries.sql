-- select data to be used

SELECT "Covid_Deaths".location as "deaths_location",
       "Covid_Deaths".date as "deaths_date",
       total_cases,
       new_cases,
       total_deaths,
       population
FROM "Covid_Deaths"
ORDER BY "Covid_Deaths".location, "Covid_Deaths".date;

--looking at total cases vs. total deaths
--shows likelihood of dying from covid if you were living in the United States
SELECT "Covid_Deaths".location as "deaths_location",
       "Covid_Deaths".date as "deaths_date",
       total_cases,
       total_deaths,
       (cast(total_deaths as decimal)/total_cases) *100 as "deaths_percentage"
FROM "Covid_Deaths"
WHERE location = 'United States'
ORDER BY "Covid_Deaths".location, "Covid_Deaths".date;

--looking at total cases vs population
--shows what percentage of US population got covid
SELECT "Covid_Deaths".location as "deaths_location",
       "Covid_Deaths".date as "deaths_date",
       total_cases,
       population,
       (total_cases/cast(population as decimal)) * 100 as "percent_pop_infected"
FROM "Covid_Deaths"
WHERE location = 'United States'
ORDER BY "Covid_Deaths".location, "Covid_Deaths".date;

--looking at countries with highest infection rate by population

SELECT "Covid_Deaths".location as "deaths_location",
       max(total_cases) as "HighestInfectionCount",
       population,
       max((total_cases/cast(population as decimal))) * 100 as "percent_pop_infected"
FROM "Covid_Deaths"
GROUP BY location, population
ORDER BY percent_pop_infected desc;

--showing countries with highest death count per population

SELECT "Covid_Deaths".location as "deaths_location",
       max(total_deaths) as "HighestDeathCount",
       population,
       max((total_deaths/cast(population as decimal))) * 100 as "percent_pop_dead"
FROM "Covid_Deaths"
WHERE "Covid_Deaths".continent is not null
GROUP BY location, population
ORDER BY "HighestDeathCount" desc;

SELECT location,
       max(total_deaths),
       continent
FROM "Covid_Deaths"
WHERE total_deaths is not null
AND continent is not null
GROUP BY continent, location
ORDER BY max(total_deaths), continent desc;

--showing death count by continent using a sub query

SELECT continent,
       sum(k) as HighestDeathCount
FROM
    (SELECT continent, location,
            max(total_deaths) as k
    FROM "Covid_Deaths"
    WHERE continent is not null
    OR location = 'United Nations'
    GROUP BY continent, location) as sub
GROUP BY continent;

--This shows the same thing but does not require a sub query

SELECT location,
       max(total_deaths) as highest_death_count
FROM "Covid_Deaths"
WHERE continent is null
GROUP BY location
ORDER BY highest_death_count desc;

-- Global numbers showing the percentage of people who died if they were recorded to have covid
-- by date

SELECT  date,
        sum(new_cases) as "total cases",
        sum(new_deaths) as "total deaths",
        sum(cast(new_deaths as dec))/sum(new_cases) * 100 as world_death_percentage
FROM    "Covid_Deaths"
WHERE new_cases >= 1
AND new_deaths >= 1
GROUP BY date
ORDER BY date;

-- showing the global percentage of people who died if they had covid

SELECT  sum(new_cases) as "total cases worldwide",
        sum(new_deaths) as "total deaths worldwide",
        sum(cast(new_deaths as dec))/sum(new_cases) * 100 as "world death percentage"
FROM    "Covid_Deaths"
WHERE new_cases >= 1
AND new_deaths >= 1;

-- looking at total population vs. total vaccination

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       sum(cast(cv.new_vaccinations as int))
       OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated

FROM "Covid_Deaths" as cd
JOIN "Covid_Vaccinations" as cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent is not null
ORDER BY 2,3;

-- use CTE

with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
    (SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       sum(cast(cv.new_vaccinations as int))
       OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM "Covid_Deaths" as cd
JOIN "Covid_Vaccinations" as cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent is not null
ORDER BY 2,3)
SELECT *, (cast(RollingPeopleVaccinated as dec)/population) * 100 as percent_vaccinated
FROM PopVsVac;

-- Making a Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
    continent varchar(255),
    location varchar(255),
    date date,
    population numeric,
    new_vaccinations numeric,
    rolling_people_vaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       sum(cast(cv.new_vaccinations as int))
       OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM "Covid_Deaths" as cd
JOIN "Covid_Vaccinations" as cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent is not null
ORDER BY 2,3;

SELECT *, (cast(rolling_people_vaccinated as dec)/population) * 100 as percent_vaccinated
FROM PercentPopulationVaccinated;

-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinatedView as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       sum(cast(cv.new_vaccinations as int))
       OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM "Covid_Deaths" as cd
JOIN "Covid_Vaccinations" as cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent is not null;

SELECT *
FROM PercentPopulationVaccinatedView;