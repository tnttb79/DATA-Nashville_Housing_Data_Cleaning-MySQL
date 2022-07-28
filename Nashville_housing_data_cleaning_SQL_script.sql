-- Nashville_housing_data_cleaning_project
RENAME TABLE `nashville housing data for data cleaning` TO nashville_housing;
SELECT * FROM mydatabase.nashville_housing;

-- SaleDate 
SELECT SaleDate FROM nashville_housing;

UPDATE nashville_housing 
SET 
    SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

ALTER TABLE nashville_housing 
MODIFY COLUMN SaleDate date;

-- PropertyAddress
-- POPULATING THE NULL VALUES IN PropertyAddess
UPDATE nashville_housing 
SET 
    PropertyAddress = NULLIF(PropertyAddress, '');
    
SELECT 
    *
FROM
    nashville_housing
WHERE
    PropertyAddress IS NULL;

SELECT 
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM
    nashville_housing a
        JOIN
    nashville_housing b ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
WHERE
    a.PropertyAddress IS NULL;

SET AUTOCOMMIT = 0;
START TRANSACTION;
UPDATE nashville_housing a
        JOIN
    nashville_housing b ON (a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID) 
SET 
    a.PropertyAddress = b.PropertyAddress
WHERE
    a.PropertyAddress IS NULL;
COMMIT;

-- SPLITTING ADDRESSES-----
-- PropertyAddress--
SELECT * FROM nashville_housing;

SELECT PropertyAddress , substring_index(PropertyAddress, ',', 1) AS Address, substring_index(PropertyAddress, ',', -1) AS City
FROM nashville_housing;

ALTER TABLE nashville_housing 
ADD splitted_address VARCHAR(100),
ADD splitted_city VARCHAR(50);

 UPDATE nashville_housing
 SET 
 splitted_address = substring_index(PropertyAddress, ',', 1),
 splitted_city = substring_index(PropertyAddress, ',', -1);
 
ALTER TABLE nashville_housing
MODIFY COLUMN splitted_address VARCHAR(100) AFTER PropertyAddress,
MODIFY COLUMN splitted_city VARCHAR (50) AFTER splitted_address;

-- OwnerAddress--
SELECT OwnerAddress FROM nashville_housing;

SELECT OwnerAddress, substring_index(OwnerAddress, ',', 1) AS owner_splitted_address, substring_index(substring_index(OwnerAddress, ',', 2),',', -1) AS owner_splitted_city, substring_index(substring_index(OwnerAddress, ',', -2),',', -1) AS owner_splitted_state
FROM nashville_housing;

ALTER TABLE nashville_housing 
ADD owner_splitted_address VARCHAR(100) AFTER OwnerAddress,
ADD owner_splitted_city VARCHAR(50) AFTER owner_splitted_address,
ADD owner_splitted_state VARCHAR(20) AFTER owner_splitted_city;

UPDATE nashville_housing
SET 
 owner_splitted_address = substring_index(OwnerAddress, ',', 1),
 owner_splitted_city = substring_index(substring_index(OwnerAddress, ',', 2),',', -1),
 owner_splitted_state = substring_index(substring_index(OwnerAddress, ',', -2),',', -1); 
 
-- CHANGING SoldAsVacant Y/N TO YES/NO--
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM nashville_housing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);

SET AUTOCOMMIT = 0;
START TRANSACTION;
UPDATE nashville_housing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'YES'
    WHEN SoldAsVacant = 'N' THEN 'NO'
    ELSE SoldAsVacant
    END;
COMMIT;
SET AUTOCOMMIT = 1;

-- REMOVING DUPLICATES RECORDS 

SET AUTOCOMMIT = 0;
START TRANSACTION;

DELETE FROM nashville_housing
WHERE UniqueID IN(
	SELECT 
		UniqueID 
	FROM
    (SELECT *, 
			ROW_NUMBER() OVER(
				PARTITION BY 
					ParcelID,
					LandUse,  
					PropertyAddress, 
					SaleDate, 
					SalePrice, 
					LegalReference, 
					SoldAsVacant, 
					OwnerName, 
					OwnerAddress,
					Acreage, 
					TaxDistrict, 
					LandValue, 
					BuildingValue, 
					TotalValue, 
					YearBuilt, 
					Bedrooms, 
					FullBath, 
					HalfBath
					ORDER BY UniqueID) row_num
	FROM nashville_housing) t
    WHERE row_num > 1
    );
COMMIT;

-- REMOVING UNUSED COLUMNS
ALTER TABLE nashville_housing 
RENAME COLUMN splitted_address TO property_splitter_address,
RENAME COLUMN splitted_city TO property_splitted_city;

ALTER TABLE nashville_housing
DROP COLUMN PropertyAddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN OwnerAddress;
						