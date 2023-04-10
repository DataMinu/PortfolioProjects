/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing



-- If it doesn't Update properly







 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM PortfolioProject.dbo.Nashvillehousing
WHERE PropertyAddress is null

SELECT *
FROM PortfolioProject.dbo.Nashvillehousing
ORDER BY ParcelID
-- if ParcelID is the same, the PropertyAddress is also the same

-- so, we are going to self-join in order to fill the empty address based on the same parcelID
-- first, let's join. in this case, join on parcelID but the uniqueId shouldn't be the same.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelId, b.PropertyAddress
FROM PortfolioProject.dbo.Nashvillehousing a
JOIN PortfolioProject.dbo.Nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.uniqueID <> b.uniqueID
-- we can see the hypothesis that the same parcelID means the same PropertyAddress.
-- now let's see the empty PropertyAddresses
SELECT a.ParcelID, a.PropertyAddress, b.ParcelId, b.PropertyAddress
FROM PortfolioProject.dbo.Nashvillehousing a
JOIN PortfolioProject.dbo.Nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.uniqueID <> b.uniqueID
WHERE a.PropertyAddress is null
-- so now we have to replace empty a.propertyaddress into b.propertyaddress
SELECT a.ParcelID, a.PropertyAddress, b.ParcelId, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Nashvillehousing a
JOIN PortfolioProject.dbo.Nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.uniqueID <> b.uniqueID
WHERE a.PropertyAddress is null
-- we checked it works. let's update the table
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Nashvillehousing a
JOIN PortfolioProject.dbo.Nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.uniqueID <> b.uniqueID
WHERE a.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
-- Address contains Address, City, State.
-- let's make address first
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
FROM PortfolioProject.dbo.NashvilleHousing
-- don't want to include ','. so -1
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
FROM PortfolioProject.dbo.NashvilleHousing
-- seperate city as the same way
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM PortfolioProject.dbo.NashvilleHousing

-- now let's update this into the table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
-- And check if it's looking good
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-- now let's do the same thing for the OwnerAddress

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing
-- it contains address, city, state
-- let's use parsename to seperate the address based on the '.'
-- so we need to replace , into .
-- also parsename returns values backwards, which is weird but still.
SELECT
PARSENAME(Replace(OwnerAddress, ',', '.'), 3)
, PARSENAME(Replace(OwnerAddress, ',', '.'), 2)
, PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

-- now let's check if it's looking good
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-- of cousre you can alter all together and update all together
--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

-- let's see how it looks like
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

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



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- let's find where the duplicates are
-- we need to partition by on the things that should be unique to each row
-- which means, columns that comes after the partition are the same, then it's the duplicates
SELECT *
, ROW_NUMBER() OVER(
					PARTITION BY ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
					ORDER BY UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID
-- we can see ParcelID(090 15 072 00) has duplicates

WITH RowNumCTE AS
(
SELECT *
, ROW_NUMBER() OVER(
					PARTITION BY ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
					ORDER BY UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 -- it's duplicate if row_num is greater than 1
ORDER BY PropertyAddress
-- so they are all the duplicates

-- let's delete duplicates
WITH RowNumCTE AS
(
SELECT *
, ROW_NUMBER() OVER(
					PARTITION BY ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
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

-- let's delete for example
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress



-- So these are the cleaning data process




















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO

















