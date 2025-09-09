;; ------------------------------------------------------------
;; SmartCert - Blockchain Academic Certificate Verification
;; ------------------------------------------------------------

;; ------------------------
;; ERROR CODES (uint)
;; ------------------------
(define-constant ERR_UNAUTHORIZED       u100)
(define-constant ERR_NOT_FOUND          u101)
(define-constant ERR_ALREADY_EXISTS     u102)
(define-constant ERR_INVALID_UNIVERSITY u103)
(define-constant ERR_INVALID_STUDENT    u104)
(define-constant ERR_INVALID_INPUT      u105)

;; Replace with your deployer principal before deployment:
(define-constant CONTRACT_OWNER 'SP000000000000000000002Q6VF78)

;; ------------------------
;; INPUT VALIDATION CONSTANTS
;; ------------------------
(define-constant MIN_NAME_LENGTH u1)
(define-constant MAX_NAME_LENGTH u50)
(define-constant MIN_METADATA_LENGTH u0)
(define-constant MAX_METADATA_LENGTH u100)
(define-constant MIN_DEGREE_LENGTH u1)
(define-constant MAX_DEGREE_LENGTH u50)
(define-constant MIN_YEAR u1900)
(define-constant MAX_YEAR u2100)

;; ------------------------
;; DATA STRUCTURES
;; ------------------------
(define-map universities
  { id: principal }
  { name: (string-ascii 50), verified: bool, metadata: (string-ascii 100) })

(define-map students
  { id: principal }
  { name: (string-ascii 50), metadata: (string-ascii 100) })

(define-map degrees
  { id: uint }
  { student: principal, university: principal, degree: (string-ascii 50), year: uint })

(define-data-var degree-counter uint u0)

;; ------------------------
;; VALIDATION FUNCTIONS
;; ------------------------

;; Validate string length
(define-private (is-valid-string-length (str (string-ascii 100)) (min-len uint) (max-len uint))
  (let ((str-len (len str)))
    (and (>= str-len min-len) (<= str-len max-len))))

;; Validate name input
(define-private (is-valid-name (name (string-ascii 50)))
  (is-valid-string-length name MIN_NAME_LENGTH MAX_NAME_LENGTH))

;; Validate metadata input
(define-private (is-valid-metadata (metadata (string-ascii 100)))
  (is-valid-string-length metadata MIN_METADATA_LENGTH MAX_METADATA_LENGTH))

;; Validate degree input
(define-private (is-valid-degree (degree (string-ascii 50)))
  (is-valid-string-length degree MIN_DEGREE_LENGTH MAX_DEGREE_LENGTH))

;; Validate year input
(define-private (is-valid-year (year uint))
  (and (>= year MIN_YEAR) (<= year MAX_YEAR)))

;; Validate principal (basic check for non-standard principal)
(define-private (is-valid-principal (addr principal))
  (not (is-eq addr 'SP000000000000000000002Q6VF78)))

;; ------------------------
;; FUNCTIONS
;; ------------------------

;; Add a university (only owner)
(define-public (add-university (univ principal) (name (string-ascii 50)) (metadata (string-ascii 100)))
  (begin
    ;; Added input validation for security
    ;; Validate inputs
    (asserts! (is-valid-principal univ) (err ERR_INVALID_INPUT))
    (asserts! (is-valid-name name) (err ERR_INVALID_INPUT))
    (asserts! (is-valid-metadata metadata) (err ERR_INVALID_INPUT))
    
    ;; only owner
    (asserts! (is-eq tx-sender CONTRACT_OWNER) (err ERR_UNAUTHORIZED))
    ;; must not already exist
    (asserts! (is-none (map-get? universities { id: univ })) (err ERR_ALREADY_EXISTS))

    (map-set universities { id: univ } { name: name, verified: true, metadata: metadata })
    (print { event: "university-added", university: univ, name: name })
    (ok true)
  )
)

;; Verify or unverify a university (only owner)
(define-public (set-university-status (univ principal) (verified bool))
  (begin
    ;; Added input validation
    (asserts! (is-valid-principal univ) (err ERR_INVALID_INPUT))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) (err ERR_UNAUTHORIZED))

    (match (map-get? universities { id: univ })
      uni
      (begin
        ;; uni is the map entry object; extract fields
        (let (
              (current-name (get name uni))
              (current-metadata (get metadata uni))
             )
          (map-set universities { id: univ } { name: current-name, verified: verified, metadata: current-metadata })
          (print { event: "university-updated", university: univ, verified: verified })
          (ok true)
        )
      )
      ;; none-case
      (err ERR_NOT_FOUND))
  )
)

;; Register a student
(define-public (register-student (student principal) (name (string-ascii 50)) (metadata (string-ascii 100)))
  (begin
    ;; Added comprehensive input validation
    ;; Validate inputs
    (asserts! (is-valid-principal student) (err ERR_INVALID_INPUT))
    (asserts! (is-valid-name name) (err ERR_INVALID_INPUT))
    (asserts! (is-valid-metadata metadata) (err ERR_INVALID_INPUT))
    
    ;; must not already exist
    (asserts! (is-none (map-get? students { id: student })) (err ERR_ALREADY_EXISTS))

    (map-set students { id: student } { name: name, metadata: metadata })
    (print { event: "student-registered", student: student, name: name })
    (ok true)
  )
)

;; Issue a degree (only by a verified university)
(define-public (issue-degree (student principal) (degree (string-ascii 50)) (year uint))
  (begin
    ;; Added input validation for all parameters
    ;; Validate inputs
    (asserts! (is-valid-principal student) (err ERR_INVALID_INPUT))
    (asserts! (is-valid-degree degree) (err ERR_INVALID_INPUT))
    (asserts! (is-valid-year year) (err ERR_INVALID_INPUT))
    
    ;; Verify student exists
    (asserts! (is-some (map-get? students { id: student })) (err ERR_INVALID_STUDENT))

    ;; Verify the caller is a registered & verified university
    (match (map-get? universities { id: tx-sender })
      uni
      (begin
        ;; ensure the university is verified
        (asserts! (get verified uni) (err ERR_INVALID_UNIVERSITY))

        ;; mint degree record
        (let ((new-id (+ (var-get degree-counter) u1)))
          (map-set degrees { id: new-id } { student: student, university: tx-sender, degree: degree, year: year })
          (var-set degree-counter new-id)
          (print { event: "certificate-issued", student: student, degree: degree, year: year, id: new-id })
          (ok new-id)
        )
      )
      ;; none-case (caller is not a registered university)
      (err ERR_INVALID_UNIVERSITY))
  )
)

;; Verify a degree (read-only)
(define-read-only (verify-degree (id uint))
  (begin
    ;; Added basic validation for degree ID
    (asserts! (> id u0) (err ERR_INVALID_INPUT))
    (match (map-get? degrees { id: id })
      d (ok d)
      (err ERR_NOT_FOUND))
  )
)

;; ------------------------
;; READ-ONLY HELPER FUNCTIONS
;; ------------------------

;; Get university info
(define-read-only (get-university (univ principal))
  (map-get? universities { id: univ }))

;; Get student info
(define-read-only (get-student (student principal))
  (map-get? students { id: student }))

;; Get current degree counter
(define-read-only (get-degree-counter)
  (var-get degree-counter))

;; Check if university is verified
(define-read-only (is-university-verified (univ principal))
  (match (map-get? universities { id: univ })
    uni (get verified uni)
    false))
