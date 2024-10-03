
-- 1. Which disease has the highest number of reported cases in each region, and what is the total number of cases for that disease in that region?

SELECT psi.Region, d.Name AS DiseaseName, COUNT(dc.CaseID) AS TotalCases
FROM DiseaseCase dc
JOIN Disease d ON dc.DiseaseID = d.DiseaseID
JOIN PandemicSeverityIndex psi ON dc.DiseaseID = psi.DiseaseID
GROUP BY psi.Region, d.Name
HAVING COUNT(dc.CaseID) = (
    SELECT MAX(CaseCount)
    FROM (
        SELECT psi.Region, COUNT(dc.CaseID) AS CaseCount
        FROM DiseaseCase dc
        JOIN PandemicSeverityIndex psi ON dc.DiseaseID = psi.DiseaseID
        GROUP BY psi.Region
    ) AS RegionCaseCounts
    WHERE RegionCaseCounts.Region = psi.Region
);


-- 2. What is the average severity level of symptoms reported for each disease?

SELECT d.DiseaseName, AVG(sr.SeverityLevel) AS AverageSeverity  -- Aggregation: AVG()
FROM SymptomReport sr
JOIN DiseaseCase dc ON sr.DiseaseCaseID = dc.DiseaseCaseID  -- Join 1 
JOIN Disease d ON dc.DiseaseID = d.DiseaseID  -- Join 2
JOIN MedicalProfessional mp ON dc.MedicalProfessionalID = mp.MedicalProfessionalID  -- Join 3
GROUP BY d.DiseaseName;  -- Group By

-- 3. List the hospitals that have more patients than the average number of patients across all hospitals.

SELECT h.HospitalName 
FROM Hospital h
JOIN MedicalProfessional mp ON h.HospitalID = mp.HospitalID  -- Join 1
JOIN DiseaseCase dc ON mp.MedicalProfessionalID = dc.MedicalProfessionalID  -- Join 2
JOIN Disease d ON dc.DiseaseID = d.DiseaseID  -- Join 3
GROUP BY h.HospitalName  -- Group By
HAVING COUNT(dc.DiseaseCaseID) > (  -- Having clause
    SELECT AVG(PatientCount)   -- Aggregation: AVG()
    FROM (
        SELECT h.HospitalID, COUNT(dc.DiseaseCaseID) AS PatientCount
        FROM Hospital h
        JOIN MedicalProfessional mp ON h.HospitalID = mp.HospitalID
        JOIN DiseaseCase dc ON mp.MedicalProfessionalID = dc.MedicalProfessionalID
        GROUP BY h.HospitalID
    ) AS AvgPatients
);

-- 4. Which health authority has issued the most health alerts, and what is the average severity factor of the diseases in the regions where those alerts were issued?

SELECT ha.HealthAuthorityID, r.Region, 
       COUNT(hal.HealthAlertID) AS NumberOfAlerts,  -- Aggregation: COUNT()
       AVG(psi.SeverityFactor) AS AverageSeverityFactor  -- Aggregation: AVG()
FROM HealthAuthority ha
JOIN HealthAlert hal ON ha.HealthAuthorityID = hal.HealthAuthorityID  -- Join 1
JOIN PandemicSeverityIndex psi ON ha.HealthAuthorityID = psi.HealthAuthorityID  -- Join 2
JOIN Region r ON psi.Region = r.RegionID  -- Join 3
GROUP BY ha.HealthAuthorityID, r.Region  -- Group By
HAVING COUNT(hal.HealthAlertID) = (  -- Having clause
    SELECT MAX(AlertCount)
    FROM (
        SELECT ha.HealthAuthorityID, COUNT(hal.HealthAlertID) AS AlertCount
        FROM HealthAuthority ha
        JOIN HealthAlert hal ON ha.HealthAuthorityID = hal.HealthAuthorityID
        GROUP BY ha.HealthAuthorityID
    ) AS MaxAlerts
);

-- 5. Show the average transmissibility rate for each disease over time, including the number of disease cases reported in the region where the transmissibility data was recorded.

SELECT d.DiseaseName, t.ReportDate, 
       AVG(t.TransmissionRate) AS AverageTransmissibility,  -- Aggregation: AVG()
       COUNT(dc.DiseaseCaseID) AS NumberOfCases  -- Aggregation: COUNT()
FROM Transmissibility t
JOIN Disease d ON t.DiseaseID = d.DiseaseID  -- Join 1
JOIN PandemicSeverityIndex psi ON t.DiseaseID = psi.DiseaseID  -- Join 2
JOIN Region r ON psi.Region = r.RegionID  -- Join 3
JOIN DiseaseCase dc ON d.DiseaseID = dc.DiseaseID AND r.RegionID = dc.Region  -- Join 4 (with condition)
GROUP BY d.DiseaseName, t.ReportDate  -- Group By
ORDER BY d.DiseaseName, t.ReportDate;

-- 6. How many users are there for each role (PublicUser, MedicalProfessional, etc.), and what is the average number of symptom reports submitted by public users in each location?

SELECT u.Role, COUNT(u.UserID) AS NumberOfUsers,  -- Aggregation: COUNT()
       AVG(CASE WHEN u.Role = 'PublicUser' THEN 1 ELSE 0 END) AS AverageSymptomReports  -- Aggregation: AVG() with conditional logic
FROM User u
LEFT JOIN PublicUser pu ON u.UserID = pu.UserID  -- Join 1 (using LEFT JOIN to include all users)
LEFT JOIN SymptomReport sr ON pu.UserID = sr.UserID  -- Join 2 (using LEFT JOIN as not all users submit reports)
GROUP BY u.Role  -- Group By
HAVING AVG(CASE WHEN u.Role = 'PublicUser' THEN 1 ELSE 0 END) > 0;  -- Having clause

-- 7. Which symptoms most frequently occur together in symptom reports, and how many disease cases are associated with those symptom pairs?

SELECT sr1.SymptomType, sr2.SymptomType, 
       COUNT(*) AS Co_occurrence,  -- Aggregation: COUNT()
       COUNT(DISTINCT dc.DiseaseCaseID) AS AssociatedCases  -- Aggregation: COUNT(DISTINCT)
FROM SymptomReport sr1
JOIN SymptomReport sr2 ON sr1.DiseaseCaseID = sr2.DiseaseCaseID AND sr1.SymptomType < sr2.SymptomType  -- Join 1 (with condition)
JOIN DiseaseCase dc ON sr1.DiseaseCaseID = dc.DiseaseCaseID  -- Join 2
JOIN Disease d ON dc.DiseaseID = d.DiseaseID  -- Join 3
GROUP BY sr1.SymptomType, sr2.SymptomType  -- Group By
ORDER BY `Co-occurrence` DESC;

-- 8. Show how the average severity factor for a specific disease has changed over time in a particular region, also showing the number of health alerts issued for that disease in that region.

SELECT psi.DateIssued, 
       AVG(psi.SeverityFactor) AS AverageSeverity,  -- Aggregation: AVG()
       COUNT(ha.HealthAuthorityID) AS NumberOfAlerts  -- Aggregation: COUNT()
FROM PandemicSeverityIndex psi

