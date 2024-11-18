# Canadian Median Incomes by Forward Sorting Area

This repository is the sandbox for a project done as part of the Developing Data Products course offered by Johns Hopkins University, delivered through Coursera as part of the Data Science: Statistics and Machine Learning Specialization.

## Introduction

This data presents and summarizes data from the [2021 Canadian Census of Population](https://www12.statcan.gc.ca/census-recensement/index-eng.cfm). All data was taken from Statistics Canada:

> Statistics Canada. 2023. Census Profile. 2021 Census of Population. Statistics Canada Catalogue number 98-316-X2021001. Ottawa. Released November 15, 2023. https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/index.cfm?Lang=E (accessed November 18, 2024).

The idea is very loosely based on the Harvard T.H. Chan School of Public Health article "Zip code better predictor of health than genetic code" (https://www.hsph.harvard.edu/news/features/zip-code-better-predictor-of-health-than-genetic-code/, accessed November 18, 2024). If someone were to try and replicate this analysis in a Canadian context, the first data they would need are demographic characteristics by Forward Sortation Area (the closest Canadian analogue to 'zip code' that are available in the Census data). It is difficult to do this for particular Census Metropolitan Areas, as the data at the FSA level does not list the corresponding CMA. The output from this project is an app that allows the user to select the CMA from a drop-down menu so that they can see a map of the FSAs that intersect that CMA (coloured by median household income) and also download the underlying data (FSAs and incomes).