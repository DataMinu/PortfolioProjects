/*

Title: Data Cleaning with Nashville Housing data
Data: https://www.kaggle.com/datasets/tmthyjames/nashville-housing-data
Skills: JOIN, SUBSTRING, CASE, CTE, Windows Functions, Converting Data Types

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

-- Check the SaleData and see how should it be converted.
SELECT SaleDate
FROM PortfolioProject.dbo.NashvilleHousing

-- First, Make a new column for the converted SaleDate.
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- Put converted SaleDate into the newly made column.
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Check if it worked well.
SELECT SaleDate, SaleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data & Fill the null values in Propertyaddress

SELECT *
FROM PortfolioProject.dbo.Nashvillehousing
WHERE PropertyAddress is null

-- In order to fill the null values in PropertyAddress,
-- we will Self-Join the NashvilleHousing table with the values having the same ParcelID and different UniqueID.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelId, b.PropertyAddress
FROM PortfolioProject.dbo.Nashvillehousing a
JOIN PortfolioProject.dbo.Nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.uniqueID <> b.uniqueID
	WHERE a.PropertyAddress is null
ORDER BY a.ParcelID
-- Now we can see they have the same address when the same ParcelID.

-- so now we have to replace empty a.propertyaddress into b.propertyaddress

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Nashvillehousing a
JOIN PortfolioProject.dbo.Nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.uniqueID <> b.uniqueID
WHERE a.PropertyAddress is null

-- Let's check if it worked well.

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
-- PropertyAddress consists of Address, City

-- let's make address first
SELECT PropertyAddress
     , SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
FROM PortfolioProject.dbo.NashvilleHousing

-- Then the city, as the same way
SELECT PropertyAddress
     , SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
     , SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM PortfolioProject.dbo.NashvilleHousing

-- now let's update this into the table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)
  , PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
  , PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- And check if it's looking good
SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM PortfolioProject.dbo.NashvilleHousing

-- now let's do the same thing for the OwnerAddress

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

-- it contains address, city, state
-- let's use parsename to seperate the address based on the '.'

SELECT
PARSENAME(Replace(OwnerAddress, ',', '.'), 3)
, PARSENAME(Replace(OwnerAddress, ',', '.'), 2)
, PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)
  , OwnerSplitCity Nvarchar(255)
  , OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)
  , OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)
  , OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

-- now let's check if it's looking good
SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

-- let's see how it looks like
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

-- we can change with case statement
SELECT SoldAsVacant
     , CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
	        Else SoldAsVacant
       END
FROM PortfolioProject.dbo.NashvilleHousing

-- and change it
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
	                    Else SoldAsVacant
                   END
				   FROM PortfolioProject.dbo.NashvilleHousing

-- let's check if it worked well
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- let's find where the duplicates are
-- we need to partition by on the things that should be unique to each row

SELECT *
     , ROW_NUMBER() OVER(
					     PARTITION BY ParcelID
								    , PropertyAddress
								    , SalePrice
								    , SaleDate
								    , LegalReference
					     ORDER BY UniqueID
					     ) row_num
FROM PortfolioProject.dbo.NashvilleHousing
-- now we can assume that the row_num with greater than 1 is the duplicates.
-- for example, we can see ParcelID(090 15 072 00) has duplicates

-- let's find the duplicates.
WITH RowNumCTE AS
(
SELECT *
     , ROW_NUMBER() OVER(
					     PARTITION BY ParcelID
								    , PropertyAddress
								    , SalePrice
								    , SaleDate
								    , LegalReference
					     ORDER BY UniqueID
					     ) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY ParcelID

-- let's delete duplicates
WITH RowNumCTE AS
(
SELECT *
     , ROW_NUMBER() OVER(
					     PARTITION BY ParcelID
								    , PropertyAddress
								    , SalePrice
								    , SaleDate
								    , LegalReference
					     ORDER BY UniqueID
					     ) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


---------------------------------------------------------------------------------------------------------


-- Delete Unused Columns
-- *don't do this to your raw data

-- example of deleting unused columns.
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

