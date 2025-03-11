//
//  ExpertAnalysis.swift
//  NewsCapture
//
//  Created by Mark Evans on 10/25/24.
//
//  Summary: Defines the ExpertAnalysis model which represents expert opinions,
//           analyses, and commentary in the UtahNewsData system. Now conforms to JSONSchemaProvider
//           to provide a static JSON schema for LLM responses.

import Foundation
import SwiftUI

/// Represents an expert's analysis or commentary on a topic or news event.
/// Expert analyses provide authoritative perspectives from qualified individuals.
public struct ExpertAnalysis: AssociatedData, Codable, JSONSchemaProvider, Sendable {
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

    // MARK: - JSON Schema Provider
    /// Provides the JSON schema for ExpertAnalysis.
    public static var jsonSchema: String {
        return """
            {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "relationships": {
                        "type": "array",
                        "items": {"type": "object"}
                    },
                    "expert": {"type": "object"},
                    "date": {"type": "string", "format": "date-time"},
                    "topics": {
                        "type": "array",
                        "items": {"type": "object"}
                    },
                    "credentials": {
                        "type": "array",
                        "items": {"type": "string"}
                    }
                },
                "required": ["id", "expert", "date"]
            }
            """
    }
}

/// Represents professional credentials, degrees, and certifications.
/// Used to establish the qualifications and expertise of individuals
/// providing expert analysis.
public enum Credential: String, Codable, Sendable {
    // Academic Degrees
    case PhD = "Doctor of Philosophy"
    case MD = "Doctor of Medicine"
    case JD = "Juris Doctor"
    case DDS = "Doctor of Dental Surgery"
    case DVM = "Doctor of Veterinary Medicine"
    case MS = "Master of Science"
    case MA = "Master of Arts"
    case MBA = "Master of Business Administration"
    case BS = "Bachelor of Science"
    case BA = "Bachelor of Arts"
    case BBA = "Bachelor of Business Administration"
    case BEng = "Bachelor of Engineering"
    case BFA = "Bachelor of Fine Arts"
    case BCom = "Bachelor of Commerce"
    case BArch = "Bachelor of Architecture"
    case BBA_Marketing = "Bachelor of Business Administration in Marketing"
    case BBA_Finance = "Bachelor of Business Administration in Finance"

    // Professional Certifications
    case CPA = "Certified Public Accountant"
    case CFA = "Chartered Financial Analyst"
    case PMP = "Project Management Professional"
    case CISM = "Certified Information Security Manager"
    case CISSP = "Certified Information Systems Security Professional"
    case CISA = "Certified Information Systems Auditor"
    case CCSP = "Certified Cloud Security Professional"
    case CEH = "Certified Ethical Hacker"
    case CCNA = "Cisco Certified Network Associate"
    case CCNP = "Cisco Certified Network Professional"
    case AWS_SA = "AWS Certified Solutions Architect"
    case AWS_DevOps = "AWS Certified DevOps Engineer"
    case GCA = "Google Cloud Professional Cloud Architect"
    case AZ_Admin = "Microsoft Certified: Azure Administrator Associate"
    case ITIL = "Information Technology Infrastructure Library"
    case SHRM_CP = "Society for Human Resource Management Certified Professional"
    case SHRM_SCP = "Society for Human Resource Management Senior Certified Professional"
    case LSSBB = "Lean Six Sigma Black Belt"
    case LSSGB = "Lean Six Sigma Green Belt"
    case PRINCE2 = "PRINCE2 Practitioner"
    case TOGAF = "The Open Group Architecture Framework"

    // Scrum Certifications
    case CSM = "Certified ScrumMaster (CSM)"
    case CSPO = "Certified Scrum Product Owner"

    // Information Technology
    case CompTIA_A = "CompTIA A+"
    case CompTIA_Network = "CompTIA Network+"
    case CompTIA_Security = "CompTIA Security+"
    case CCIE = "Cisco Certified Internetwork Expert"
    case Microsoft_Solutions_Expert = "Microsoft Certified: Solutions Expert"
    case Oracle_Professional = "Oracle Certified Professional"
    case RHCE = "Red Hat Certified Engineer"
    case CKA = "Certified Kubernetes Administrator"
    case CAI_E = "Certified Artificial Intelligence Engineer"
    case CDS = "Certified Data Scientist"
    case CMLP = "Certified Machine Learning Professional"
    case CBlockchain_Dev = "Certified Blockchain Developer"
    case CVirtualization_Prof = "Certified Virtualization Professional"
    case CIoT_Specialist = "Certified Internet of Things Specialist"

    // Healthcare Certifications
    case RN = "Registered Nurse"
    case NP = "Nurse Practitioner"
    case CRNA = "Certified Registered Nurse Anesthetist"
    case DNP = "Doctor of Nursing Practice"
    case CPHQ = "Certified Professional in Healthcare Quality"
    case CHC = "Certified in Healthcare Compliance"
    case CPM = "Certified Project Manager"
    case CCC = "Certificate of Clinical Competence"

    // Finance and Accounting
    case CPA_CGMA = "Certified Public Accountant - Chartered Global Management Accountant"
    case CFE = "Certified Fraud Examiner"
    case CMA = "Certified Management Accountant"
    case CFP = "Certified Financial Planner"
    case FRM = "Financial Risk Manager"
    case CAIA = "Chartered Alternative Investment Analyst"
    case CFA_I = "Chartered Financial Analyst Level I"
    case CFA_II = "Chartered Financial Analyst Level II"
    case CFA_III = "Chartered Financial Analyst Level III"

    // Marketing and Sales
    case CMO = "Chief Marketing Officer Certification"
    case CSMM = "Certified Social Media Marketing"
    case CSEO = "Certified SEO Professional"
    case CPPM = "Certified Product Marketing Manager"
    case CPIM = "Certified Product Information Manager"
    case CSEM = "Certified Sales and Marketing Professional"

    // Human Resources
    case PHR = "Professional in Human Resources"
    case SPHR = "Senior Professional in Human Resources"
    case GPHR = "Global Professional in Human Resources"
    case aPHR = "Associate Professional in Human Resources"

    // Legal Certifications
    case LLM = "Master of Law"
    case BCL = "Bachelor of Civil Law"
    case JD_Specialization = "Juris Doctor - Specialization"

    // Engineering Certifications
    case PE = "Professional Engineer"
    case CEng = "Chartered Engineer"
    case CPEng = "Certified Professional Engineer"

    // Additional Certifications
    case CMC = "Certified Management Consultant"
    case ASQ_CQE = "Certified Quality Engineer"
    case CSD = "Chartered Scientist"
    case MRICS = "Member of the Royal Institution of Chartered Surveyors"
    case IFSP = "International Fire Safety Professional"
    case CFRE = "Certified Fund Raising Executive"
    case CTP = "Certified Treasury Professional"
    case APICS = "Certified in Planning and Inventory Management"
    case CCEP = "Certified Compliance and Ethics Professional"
    case CPP = "Certified Protection Professional"
    case AICPA = "American Institute of Certified Public Accountants"

    // Emerging and Specialized Fields
    case CDMP = "Certified Digital Marketing Professional"
    case CSM_Manager = "Certified Social Media Manager"
    case CCM = "Certified Content Marketer"
    case CPP_Specialist = "Certified Pay-Per-Click Specialist"
    case CEMP = "Certified Email Marketing Specialist"
    case CGAS = "Certified Google Ads Specialist"
    case CFAS = "Certified Facebook Ads Specialist"
    case CTAS = "Certified Twitter Ads Specialist"
    case CLAS = "Certified LinkedIn Ads Specialist"
    case CIM_Specialist = "Certified Instagram Marketing Specialist"
    case CYM_Specialist = "Certified YouTube Marketing Specialist"
    case CTM_Specialist = "Certified TikTok Marketing Specialist"
    case CSL_Admin = "Certified Slack Administrator"
    case CZoom_Admin = "Certified Zoom Administrator"
    case CMC365_Admin = "Certified Microsoft 365 Administrator"
    case CGWS_Admin = "Certified Google Workspace Administrator"
    case CAWS_Admin = "Certified Amazon Web Services Administrator"
    case CIBM_Cloud_Prof = "Certified IBM Cloud Professional"
    case CSAP_HANA_Prof = "Certified SAP HANA Professional"

    // Research and Academia
    case CRA = "Clinical Research Associate"
    case CCRA = "Certified Clinical Research Associate"
    case CAPM = "Certified Associate in Project Management"
    case PgMP = "Program Management Professional"

    // Miscellaneous
    case CLC = "Certified Life Coach"
    case CLU = "Chartered Life Underwriter"
    case CHRL = "Certified Human Resources Leader"
    case SANS = "Security Awareness Training"
    case DPO = "Data Protection Officer"
}
