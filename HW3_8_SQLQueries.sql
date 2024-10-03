
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



-- 2. List the hospitals that have more patients than the average number of patients across all hospitals.

SELECT h.Name AS HospitalName
FROM Hospital h
JOIN MedicalProfessional mp ON h.HospitalID = mp.HospitalID
JOIN DiseaseCase dc ON mp.MedicalProfessionalID = dc.MedicalProfessionalID
GROUP BY h.Name
HAVING COUNT(dc.CaseID) > (
    SELECT AVG(PatientCount)
    FROM (
        SELECT h.HospitalID, COUNT(dc.CaseID) AS PatientCount
        FROM Hospital h
        JOIN MedicalProfessional mp ON h.HospitalID = mp.HospitalID
        JOIN DiseaseCase dc ON mp.MedicalProfessionalID = dc.MedicalProfessionalID
        GROUP BY h.HospitalID
    ) AS AvgPatients
);


-- 3. Which health authority has issued the most health alerts, and what is the average severity factor of the diseases in the regions where those alerts were issued?

WITH AuthorityAlerts AS (
    SELECT 
        hal.HealthAuthorityID, 
        COUNT(hal.AlertID) AS NumberOfAlerts
    FROM 
        HealthAlert hal
    GROUP BY 
        hal.HealthAuthorityID
    ORDER BY 
        NumberOfAlerts DESC
    LIMIT 1
)

SELECT 
    ha.HealthAuthorityID, 
    aa.NumberOfAlerts,
    AVG(psi.SeverityFactor) AS AverageSeverityFactor
FROM 
    AuthorityAlerts aa
JOIN 
    HealthAuthority ha ON ha.HealthAuthorityID = aa.HealthAuthorityID
JOIN 
    HealthAlert hal ON ha.HealthAuthorityID = hal.HealthAuthorityID
JOIN 
    PandemicSeverityIndex psi ON hal.DiseaseID = psi.DiseaseID AND hal.Region = psi.Region
GROUP BY 
    ha.HealthAuthorityID;


-- 4. Show the average transmissibility rate for each disease over time, including the number of disease cases reported in the same region.
SELECT d.Name AS DiseaseName, t.ReportDate, 
       AVG(t.TransmissionRate) AS AverageTransmissibility,  -- Aggregation: AVG()
       COUNT(dc.CaseID) AS NumberOfCases  -- Aggregation: COUNT()
FROM Transmissibility t
JOIN Disease d ON t.DiseaseID = d.DiseaseID  -- Disease to Transmissibility
JOIN PandemicSeverityIndex psi ON t.DiseaseID = psi.DiseaseID  -- Transmissibility to PandemicSeverityIndex
JOIN DiseaseCase dc ON dc.DiseaseID = d.DiseaseID  -- DiseaseCase to Disease
WHERE psi.Region = (SELECT Region FROM HealthAlert WHERE DiseaseID = t.DiseaseID LIMIT 1) -- Matching Region from HealthAlert
GROUP BY d.Name, t.ReportDate  -- Grouping by Disease and Date
ORDER BY d.Name, t.ReportDate;


-- 5. How many users there are for each role and the average number of symptom reports submitted by public users in each location.
SELECT u.Role, COUNT(u.UserID) AS NumberOfUsers,  
       AVG(sr.CountReports) AS AverageSymptomReports
FROM User u
LEFT JOIN (
    SELECT UserID, COUNT(SymptomID) AS CountReports
    FROM SymptomReport
    GROUP BY UserID
) sr ON u.UserID = sr.UserID
GROUP BY u.Role;


-- 6. Show how the average severity factor for a specific disease has changed over time in a specific region, also showing the number of health alerts issued for that disease in that region.

SELECT 
    psi.DateIssued,
    psi.Region,
    d.Name AS DiseaseName,
    AVG(psi.SeverityFactor) AS AverageSeverity,  -- Aggregation: AVG()
    COUNT(ha.AlertID) AS NumberOfAlerts  -- Aggregation: COUNT()
FROM 
    PandemicSeverityIndex psi
JOIN 
    Disease d ON psi.DiseaseID = d.DiseaseID  -- Ensure we are referencing the correct disease
LEFT JOIN 
    HealthAlert ha ON ha.DiseaseID = psi.DiseaseID AND ha.Region = psi.Region  -- Count alerts for the same disease and region
WHERE 
    d.Name = 'Specific Disease' AND  -- Placeholder: Replace 'Specific Disease' with the actual disease name
    psi.Region = 'Specific Region'  -- Placeholder: Replace 'Specific Region' with the actual region
GROUP BY 
    psi.DateIssued, psi.Region
ORDER BY 
    psi.DateIssued;

-- 7. Group the occurence of the disease by the region

SELECT d.DiseaseID, ha.Region, 
    COUNT(d.DiseaseID) AS DiseaseCases
FROM Disease d
JOIN HealthAlert ha ON d.DiseaseID = ha.DiseaseID
GROUP BY d.DiseaseID, ha.Region;

-- 8. Information about the hospital where the Public Health ranking of the hospitals is maximum.
SELECT *
FROM Hospital
WHERE PublicHealthRanking = (SELECT MAX(PublicHealthRanking) FROM Hospital);

-- 9. All records of symptoms and personal information related of all users
SELECT u.*, sr.*
FROM User u
JOIN SymptomReport sr ON u.UserID = sr.UserID;


