### Overview
Introduced the `SmartCert` Clarity smart contract, enabling universities to issue 
tamper-proof academic certificates on-chain. Students and third parties can verify 
credentials securely without intermediaries.

### Key Features
- **University Registry**  
  - Contract owner can add and verify universities.  
  - Supports updating verification status.  

- **Student Registry**  
  - Secure registration of students with name and metadata.  
  - Prevents duplicate entries.  

- **Degree Issuance**  
  - Verified universities can issue degrees to registered students.  
  - Each degree is stored immutably with metadata (student, degree type, year).  

- **Verification**  
  - Read-only `verify-degree` allows public validation of issued degrees.  
  - Utility views for fetching university, student, and degree info.  

### Security Enhancements
- Input validation for names, metadata, degree length, and year range.  
- Ownership restrictions for sensitive operations (e.g., university management).  
- Error codes for consistent failure handling.  

This commit lays the foundation for a decentralized, verifiable academic credential system, 
ensuring trust and transparency in education records.
