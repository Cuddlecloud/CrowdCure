CREATE DATABASE CrowdCure;
USE CrowdCure;

CREATE TABLE User (
    UserID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Role ENUM('PublicUser', 'MedicalProfessional', 'HealthAuthority', 'LaboratoryWorker') NOT NULL,
    Location VARCHAR(255) NOT NULL,  -- Assuming every user has a location
    DateJoined DATE NOT NULL DEFAULT CURDATE(),
    CHECK (CHAR_LENGTH(Name) >= 2),  -- Ensures that a name has at least 2 characters
    CHECK (Email LIKE '%_@__%.__%')  -- Ensures that email has a valid format
    
);

CREATE TABLE PublicUser (
    UserID INT PRIMARY KEY,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
);

CREATE TABLE MedicalProfessional (
    MedicalProfessionalID INT PRIMARY KEY,
    HospitalID INT NOT NULL,  -- Assuming every MedicalProfessional must be linked to a Hospital
    FOREIGN KEY (MedicalProfessionalID) REFERENCES User(UserID),
    FOREIGN KEY (HospitalID) REFERENCES Hospital(HospitalID),
    CHECK (HospitalID > 0)  -- HospitalID must be a positive integer
);

CREATE TABLE HealthAuthority (
    HealthAuthorityID INT PRIMARY KEY,
    FOREIGN KEY (HealthAuthorityID) REFERENCES User(UserID)
);

CREATE TABLE LaboratoryWorker (
    LaboratoryWorkerID INT PRIMARY KEY,
    FOREIGN KEY (LaboratoryWorkerID) REFERENCES User(UserID)
);

CREATE TABLE SymptomReport (
    SymptomID INT PRIMARY KEY,
    ReportDate DATE NOT NULL,
    SymptomType VARCHAR(255) NOT NULL,  -- Symptom type must be specified
    SeverityLevel INT NOT NULL,  -- Severity level is essential for tracking
    Location VARCHAR(255) NOT NULL,  -- Location is critical for tracking outbreaks
    UserID INT NOT NULL,
    FOREIGN KEY (UserID) REFERENCES PublicUser(UserID),
    CHECK (SeverityLevel BETWEEN 1 AND 10),  -- Severity level must be between 1 and 10
    CHECK (ReportDate <= CURDATE())  -- Report date cannot be in the future
);

CREATE TABLE Disease (
    DiseaseID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,  -- Every disease must have a name
    Type ENUM('Viral', 'Bacterial', 'Fungal', 'Parasitic') NOT NULL,  -- Type is crucial for classification
    Symptoms TEXT NOT NULL,  -- A disease must have symptoms listed
    IncubationPeriod INT NOT NULL,  -- Incubation period is important for disease tracking
    TransmissionMethod VARCHAR(255) NOT NULL,  -- How the disease spreads is critical
    CHECK (IncubationPeriod > 0),  -- Incubation period must be positive
    CHECK (Type IN ('Viral', 'Bacterial', 'Fungal', 'Parasitic'))  -- Ensures valid disease type
);

CREATE TABLE DiseaseCase (
    CaseID INT PRIMARY KEY,
    DiseaseID INT NOT NULL,
    DateDiagnosed DATE NOT NULL,
    CaseSeverity INT NOT NULL,  -- Severity of the case must be tracked
    MedicalProfessionalID INT NOT NULL,
    FOREIGN KEY (DiseaseID) REFERENCES Disease(DiseaseID),
    FOREIGN KEY (MedicalProfessionalID) REFERENCES MedicalProfessional(MedicalProfessionalID),
    CHECK (CaseSeverity BETWEEN 1 AND 10),  -- Case severity must be between 1 and 10
    CHECK (DateDiagnosed <= CURDATE()),  -- Diagnosis date cannot be in the future
    CHECK (MedicalProfessionalID > 0)  -- Ensures valid reference to MedicalProfessionalID
);

CREATE TABLE LabTestReport (
    LabTestID INT PRIMARY KEY,
    TestType VARCHAR(255) NOT NULL,  -- The type of test must be defined
    DateTested DATE NOT NULL,  -- The date of the test must be provided
    Result VARCHAR(255) NOT NULL,  -- The result of the test must be provided
    CaseID INT NOT NULL,
    LaboratoryWorkerID INT NOT NULL,
    UserID INT NOT NULL,
    HospitalID INT NOT NULL,
    HealthAuthorityID INT NOT NULL,
    FOREIGN KEY (CaseID) REFERENCES DiseaseCase(CaseID),
    FOREIGN KEY (LaboratoryWorkerID) REFERENCES LaboratoryWorker(LaboratoryWorkerID),
    FOREIGN KEY (UserID) REFERENCES PublicUser(UserID),
    FOREIGN KEY (HospitalID) REFERENCES Hospital(HospitalID),
    FOREIGN KEY (HealthAuthorityID) REFERENCES HealthAuthority(HealthAuthorityID),
    CHECK (CHAR_LENGTH(Result) > 0),  -- Result cannot be empty
    CHECK (DateTested <= CURDATE())  -- Test date cannot be in the future
);

CREATE TABLE HealthAlert (
    AlertID INT PRIMARY KEY,
    DateIssued DATE NOT NULL,
    Region VARCHAR(255) NOT NULL,  -- The region where the alert applies must be specified
    Description TEXT NOT NULL,  -- The description of the alert must be provided
    DiseaseID INT NOT NULL,
    HealthAuthorityID INT NOT NULL,
    AlertSeverity INT NOT NULL,  -- The severity of the alert must be recorded
    FOREIGN KEY (DiseaseID) REFERENCES Disease(DiseaseID),
    FOREIGN KEY (HealthAuthorityID) REFERENCES HealthAuthority(HealthAuthorityID),
    CHECK (AlertSeverity BETWEEN 1 AND 10),  -- Alert severity must be between 1 and 10
    CHECK (DateIssued <= CURDATE())  -- Alert date cannot be in the future
);

CREATE TABLE Hospital (
    HospitalID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,  -- Every hospital must have a name
    Location VARCHAR(255) NOT NULL,  -- Every hospital must have a location
    Capacity INT NOT NULL,  -- The capacity of the hospital is important for resource tracking
    PublicHealthRanking INT NOT NULL,  -- Ranking helps in assessing the quality of service
    DeathToll INT NOT NULL,  -- Tracking the number of deaths at the hospital is critical
    Equipments TEXT NOT NULL,  -- Hospitals must have a list of equipment
    Medicine TEXT NOT NULL,  -- Hospitals must have details of available medicines
    CHECK (Capacity > 0),  -- Capacity must be positive
    CHECK (PublicHealthRanking BETWEEN 1 AND 100),  -- Public health ranking must be between 1 and 100
    CHECK (DeathToll >= 0)  -- Death toll cannot be negative
);

CREATE TABLE Transmissibility (
    TransmissibilityID INT PRIMARY KEY,
    DiseaseID INT NOT NULL,
    HealthAuthorityID INT NOT NULL,
    SpreadFactor FLOAT NOT NULL,  -- Spread factor must be tracked to assess transmissibility
    TransmissionRate FLOAT NOT NULL,  -- Transmission rate is essential for tracking
    FOREIGN KEY (DiseaseID) REFERENCES Disease(DiseaseID),
    FOREIGN KEY (HealthAuthorityID) REFERENCES HealthAuthority(HealthAuthorityID),
    CHECK (SpreadFactor > 0),  -- Spread factor must be positive
    CHECK (TransmissionRate >= 1)  -- Transmission rate must be between >=1
);

CREATE TABLE PandemicSeverityIndex (
    IndexID INT PRIMARY KEY,
    HealthAuthorityID INT NOT NULL,
    DateIssued DATE NOT NULL,
    Region VARCHAR(255) NOT NULL,  -- The region must be identified
    DiseaseID INT NOT NULL,
    SeverityFactor INT NOT NULL,  -- The severity of the pandemic must be tracked
    FOREIGN KEY (HealthAuthorityID) REFERENCES HealthAuthority(HealthAuthorityID),
    FOREIGN KEY (DiseaseID) REFERENCES Disease(DiseaseID),
    CHECK (SeverityFactor BETWEEN 1 AND 10),  -- Severity factor must be between 1 and 10
    CHECK (DateIssued <= CURDATE())  -- Issue date cannot be in the future
);

