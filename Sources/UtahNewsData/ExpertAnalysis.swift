//
//  ExpertAnalysis.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//

/*
 # ExpertAnalysis Model
 
 This file defines the ExpertAnalysis model, which represents expert opinions, analyses,
 and commentary in the UtahNewsData system. Expert analyses provide authoritative
 perspectives on news events, topics, and issues from qualified individuals.
 
 ## Key Features:
 
 1. Expert attribution (who provided the analysis)
 2. Credential tracking (qualifications of the expert)
 3. Topic categorization
 4. Relationship tracking with other entities
 
 ## Usage:
 
 ```swift
 // Create an expert
 let expert = Person(
     name: "Dr. Jane Smith",
     details: "Economics Professor at University of Utah"
 )
 
 // Create an expert analysis
 let analysis = ExpertAnalysis(
     expert: expert,
     date: Date(),
     topics: [Category(name: "Economy"), Category(name: "Inflation")]
 )
 
 // Add credentials to the expert
 analysis.credentials = [.PhD, .CFA]
 
 // Associate with a news story
 let relationship = Relationship(
     id: newsStory.id,
     type: .newsStory,
     displayName: "Analysis of"
 )
 analysis.relationships.append(relationship)
 ```
 
 The ExpertAnalysis model implements AssociatedData, allowing it to maintain
 relationships with other entities in the system, such as news stories, events,
 or other related content.
 */

import SwiftUI

/// Represents an expert's analysis or commentary on a topic or news event.
/// Expert analyses provide authoritative perspectives from qualified individuals.
public struct ExpertAnalysis: AssociatedData, Codable {
    /// Unique identifier for the expert analysis
    public var id: String
    
    /// Relationships to other entities in the system
    public var relationships: [Relationship] = []
    
    /// The expert providing the analysis
    public var expert: Person
    
    /// When the analysis was provided
    public var date: Date
    
    /// Categories or topics covered in the analysis
    public var topics: [Category] = []
    
    /// Professional credentials of the expert relevant to this analysis
    public var credentials: [Credential] = []
    
    /// The name property required by the AssociatedData protocol.
    /// Returns a descriptive name based on the expert and date.
    public var name: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Analysis by \(expert.name) on \(formatter.string(from: date))"
    }

    /// Creates a new expert analysis with the specified properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the analysis (defaults to a new UUID string)
    ///   - expert: The expert providing the analysis
    ///   - date: When the analysis was provided
    public init(id: String = UUID().uuidString, expert: Person, date: Date) {
        self.id = id
        self.expert = expert
        self.date = date
    }
}

/// Represents professional credentials, degrees, and certifications.
/// Used to establish the qualifications and expertise of individuals
/// providing expert analysis.
public enum Credential: String, Codable {
    // Academic Degrees
    /// Doctor of Philosophy
    case PhD = "Doctor of Philosophy"
    /// Doctor of Medicine
    case MD = "Doctor of Medicine"
    /// Juris Doctor (law degree)
    case JD = "Juris Doctor"
    /// Doctor of Dental Surgery
    case DDS = "Doctor of Dental Surgery"
    /// Doctor of Veterinary Medicine
    case DVM = "Doctor of Veterinary Medicine"
    /// Master of Science
    case MS = "Master of Science"
    /// Master of Arts
    case MA = "Master of Arts"
    /// Master of Business Administration
    case MBA = "Master of Business Administration"
    /// Bachelor of Science
    case BS = "Bachelor of Science"
    /// Bachelor of Arts
    case BA = "Bachelor of Arts"
    /// Bachelor of Business Administration
    case BBA = "Bachelor of Business Administration"
    /// Bachelor of Engineering
    case BEng = "Bachelor of Engineering"
    /// Bachelor of Fine Arts
    case BFA = "Bachelor of Fine Arts"
    /// Bachelor of Commerce
    case BCom = "Bachelor of Commerce"
    /// Bachelor of Architecture
    case BArch = "Bachelor of Architecture"
    /// Bachelor of Business Administration in Marketing
    case BBA_Marketing = "Bachelor of Business Administration in Marketing"
    /// Bachelor of Business Administration in Finance
    case BBA_Finance = "Bachelor of Business Administration in Finance"
    
    // Professional Certifications
    /// Certified Public Accountant
    case CPA = "Certified Public Accountant"
    /// Chartered Financial Analyst
    case CFA = "Chartered Financial Analyst"
    /// Project Management Professional
    case PMP = "Project Management Professional"
    /// Certified Information Security Manager
    case CISM = "Certified Information Security Manager"
    /// Certified Information Systems Security Professional
    case CISSP = "Certified Information Systems Security Professional"
    /// Certified Information Systems Auditor
    case CISA = "Certified Information Systems Auditor"
    /// Certified Cloud Security Professional
    case CCSP = "Certified Cloud Security Professional"
    /// Certified Ethical Hacker
    case CEH = "Certified Ethical Hacker"
    /// Cisco Certified Network Associate
    case CCNA = "Cisco Certified Network Associate"
    /// Cisco Certified Network Professional
    case CCNP = "Cisco Certified Network Professional"
    /// AWS Certified Solutions Architect
    case AWS_SA = "AWS Certified Solutions Architect"
    /// AWS Certified DevOps Engineer
    case AWS_DevOps = "AWS Certified DevOps Engineer"
    /// Google Cloud Professional Cloud Architect
    case GCA = "Google Cloud Professional Cloud Architect"
    /// Microsoft Certified: Azure Administrator Associate
    case AZ_Admin = "Microsoft Certified: Azure Administrator Associate"
    /// Information Technology Infrastructure Library
    case ITIL = "Information Technology Infrastructure Library"
    /// Society for Human Resource Management Certified Professional
    case SHRM_CP = "Society for Human Resource Management Certified Professional"
    /// Society for Human Resource Management Senior Certified Professional
    case SHRM_SCP = "Society for Human Resource Management Senior Certified Professional"
    /// Lean Six Sigma Black Belt
    case LSSBB = "Lean Six Sigma Black Belt"
    /// Lean Six Sigma Green Belt
    case LSSGB = "Lean Six Sigma Green Belt"
    /// PRINCE2 Practitioner
    case PRINCE2 = "PRINCE2 Practitioner"
    /// The Open Group Architecture Framework
    case TOGAF = "The Open Group Architecture Framework"
    
    // Scrum Certifications
    /// Certified ScrumMaster
    case CSM = "Certified ScrumMaster (CSM)"
    /// Certified Scrum Product Owner
    case CSPO = "Certified Scrum Product Owner"
    
    // Information Technology
    /// CompTIA A+ Certification
    case CompTIA_A = "CompTIA A+"
    /// CompTIA Network+ Certification
    case CompTIA_Network = "CompTIA Network+"
    /// CompTIA Security+ Certification
    case CompTIA_Security = "CompTIA Security+"
    /// Cisco Certified Internetwork Expert
    case CCIE = "Cisco Certified Internetwork Expert"
    /// Microsoft Certified: Solutions Expert
    case Microsoft_Solutions_Expert = "Microsoft Certified: Solutions Expert"
    /// Oracle Certified Professional
    case Oracle_Professional = "Oracle Certified Professional"
    /// Red Hat Certified Engineer
    case RHCE = "Red Hat Certified Engineer"
    /// Certified Kubernetes Administrator
    case CKA = "Certified Kubernetes Administrator"
    /// Certified Artificial Intelligence Engineer
    case CAI_E = "Certified Artificial Intelligence Engineer"
    /// Certified Data Scientist
    case CDS = "Certified Data Scientist"
    /// Certified Machine Learning Professional
    case CMLP = "Certified Machine Learning Professional"
    /// Certified Blockchain Developer
    case CBlockchain_Dev = "Certified Blockchain Developer"
    /// Certified Virtualization Professional
    case CVirtualization_Prof = "Certified Virtualization Professional"
    /// Certified Internet of Things Specialist
    case CIoT_Specialist = "Certified Internet of Things Specialist"
    
    // Healthcare Certifications
    /// Registered Nurse
    case RN = "Registered Nurse"
    /// Nurse Practitioner
    case NP = "Nurse Practitioner"
    /// Certified Registered Nurse Anesthetist
    case CRNA = "Certified Registered Nurse Anesthetist"
    /// Doctor of Nursing Practice
    case DNP = "Doctor of Nursing Practice"
    /// Certified Professional in Healthcare Quality
    case CPHQ = "Certified Professional in Healthcare Quality"
    /// Certified in Healthcare Compliance
    case CHC = "Certified in Healthcare Compliance"
    /// Certified Project Manager
    case CPM = "Certified Project Manager"
    /// Certificate of Clinical Competence
    case CCC = "Certificate of Clinical Competence"
    
    // Finance and Accounting
    /// Certified Public Accountant - Chartered Global Management Accountant
    case CPA_CGMA = "Certified Public Accountant - Chartered Global Management Accountant"
    /// Certified Fraud Examiner
    case CFE = "Certified Fraud Examiner"
    /// Certified Management Accountant
    case CMA = "Certified Management Accountant"
    /// Certified Financial Planner
    case CFP = "Certified Financial Planner"
    /// Financial Risk Manager
    case FRM = "Financial Risk Manager"
    /// Chartered Alternative Investment Analyst
    case CAIA = "Chartered Alternative Investment Analyst"
    /// Chartered Financial Analyst Level I
    case CFA_I = "Chartered Financial Analyst Level I"
    /// Chartered Financial Analyst Level II
    case CFA_II = "Chartered Financial Analyst Level II"
    /// Chartered Financial Analyst Level III
    case CFA_III = "Chartered Financial Analyst Level III"
    
    // Marketing and Sales
    /// Chief Marketing Officer Certification
    case CMO = "Chief Marketing Officer Certification"
    /// Certified Social Media Marketing
    case CSMM = "Certified Social Media Marketing"
    /// Certified SEO Professional
    case CSEO = "Certified SEO Professional"
    /// Certified Product Marketing Manager
    case CPPM = "Certified Product Marketing Manager"
    /// Certified Product Information Manager
    case CPIM = "Certified Product Information Manager"
    /// Certified Sales and Marketing Professional
    case CSEM = "Certified Sales and Marketing Professional"
    
    // Human Resources
    /// Professional in Human Resources
    case PHR = "Professional in Human Resources"
    /// Senior Professional in Human Resources
    case SPHR = "Senior Professional in Human Resources"
    /// Global Professional in Human Resources
    case GPHR = "Global Professional in Human Resources"
    /// Associate Professional in Human Resources
    case aPHR = "Associate Professional in Human Resources"
    
    // Legal Certifications
    /// Master of Law
    case LLM = "Master of Law"
    /// Bachelor of Civil Law
    case BCL = "Bachelor of Civil Law"
    /// Juris Doctor with Specialization
    case JD_Specialization = "Juris Doctor - Specialization"
    
    // Engineering Certifications
    /// Professional Engineer
    case PE = "Professional Engineer"
    /// Chartered Engineer
    case CEng = "Chartered Engineer"
    /// Certified Professional Engineer
    case CPEng = "Certified Professional Engineer"
    
    // Additional Certifications
    /// Certified Management Consultant
    case CMC = "Certified Management Consultant"
    /// Certified Quality Engineer
    case ASQ_CQE = "Certified Quality Engineer"
    /// Chartered Scientist
    case CSD = "Chartered Scientist"
    /// Member of the Royal Institution of Chartered Surveyors
    case MRICS = "Member of the Royal Institution of Chartered Surveyors"
    /// International Fire Safety Professional
    case IFSP = "International Fire Safety Professional"
    /// Certified Fund Raising Executive
    case CFRE = "Certified Fund Raising Executive"
    /// Certified Treasury Professional
    case CTP = "Certified Treasury Professional"
    /// Certified in Planning and Inventory Management
    case APICS = "Certified in Planning and Inventory Management"
    /// Certified Compliance and Ethics Professional
    case CCEP = "Certified Compliance and Ethics Professional"
    /// Certified Protection Professional
    case CPP = "Certified Protection Professional"
    /// American Institute of Certified Public Accountants
    case AICPA = "American Institute of Certified Public Accountants"
    
    // Emerging and Specialized Fields
    /// Certified Digital Marketing Professional
    case CDMP = "Certified Digital Marketing Professional"
    /// Certified Social Media Manager
    case CSM_Manager = "Certified Social Media Manager"
    /// Certified Content Marketer
    case CCM = "Certified Content Marketer"
    /// Certified Pay-Per-Click Specialist
    case CPP_Specialist = "Certified Pay-Per-Click Specialist"
    /// Certified Email Marketing Specialist
    case CEMP = "Certified Email Marketing Specialist"
    /// Certified Google Ads Specialist
    case CGAS = "Certified Google Ads Specialist"
    /// Certified Facebook Ads Specialist
    case CFAS = "Certified Facebook Ads Specialist"
    /// Certified Twitter Ads Specialist
    case CTAS = "Certified Twitter Ads Specialist"
    /// Certified LinkedIn Ads Specialist
    case CLAS = "Certified LinkedIn Ads Specialist"
    /// Certified Instagram Marketing Specialist
    case CIM_Specialist = "Certified Instagram Marketing Specialist"
    /// Certified YouTube Marketing Specialist
    case CYM_Specialist = "Certified YouTube Marketing Specialist"
    /// Certified TikTok Marketing Specialist
    case CTM_Specialist = "Certified TikTok Marketing Specialist"
    /// Certified Slack Administrator
    case CSL_Admin = "Certified Slack Administrator"
    /// Certified Zoom Administrator
    case CZoom_Admin = "Certified Zoom Administrator"
    /// Certified Microsoft 365 Administrator
    case CMC365_Admin = "Certified Microsoft 365 Administrator"
    /// Certified Google Workspace Administrator
    case CGWS_Admin = "Certified Google Workspace Administrator"
    /// Certified Amazon Web Services Administrator
    case CAWS_Admin = "Certified Amazon Web Services Administrator"
    /// Certified IBM Cloud Professional
    case CIBM_Cloud_Prof = "Certified IBM Cloud Professional"
    /// Certified SAP HANA Professional
    case CSAP_HANA_Prof = "Certified SAP HANA Professional"
    
    // Research and Academia
    /// Clinical Research Associate
    case CRA = "Clinical Research Associate"
    /// Certified Clinical Research Associate
    case CCRA = "Certified Clinical Research Associate"
    /// Certified Associate in Project Management
    case CAPM = "Certified Associate in Project Management"
    /// Program Management Professional
    case PgMP = "Program Management Professional"
    
    // Miscellaneous
    /// Certified Life Coach
    case CLC = "Certified Life Coach"
    /// Chartered Life Underwriter
    case CLU = "Chartered Life Underwriter"
    /// Certified Human Resources Leader
    case CHRL = "Certified Human Resources Leader"
    /// Security Awareness Training
    case SANS = "Security Awareness Training"
    /// Data Protection Officer
    case DPO = "Data Protection Officer"
}
