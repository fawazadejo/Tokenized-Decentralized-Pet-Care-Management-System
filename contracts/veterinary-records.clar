;; Veterinary Records Contract
;; Maintains comprehensive health histories

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_EXISTS (err u202))
(define-constant ERR_INVALID_INPUT (err u203))

;; Data Variables
(define-data-var next-record-id uint u1)
(define-data-var contract-active bool true)

;; Data Maps
(define-map veterinarians
  { vet-address: principal }
  {
    name: (string-ascii 50),
    license-number: (string-ascii 20),
    clinic-name: (string-ascii 50),
    registered-at: uint,
    is-active: bool
  }
)

(define-map medical-records
  { record-id: uint }
  {
    pet-id: uint,
    veterinarian: principal,
    record-type: (string-ascii 20),
    procedure: (string-ascii 100),
    diagnosis: (string-ascii 200),
    treatment: (string-ascii 200),
    medications: (string-ascii 200),
    visit-date: uint,
    follow-up-date: (optional uint),
    notes: (string-ascii 500),
    created-at: uint
  }
)

(define-map vaccinations
  { vaccination-id: uint }
  {
    pet-id: uint,
    veterinarian: principal,
    vaccine-name: (string-ascii 50),
    vaccine-type: (string-ascii 30),
    administered-date: uint,
    expiry-date: uint,
    batch-number: (string-ascii 20),
    manufacturer: (string-ascii 50),
    notes: (string-ascii 200)
  }
)

(define-map pet-health-summary
  { pet-id: uint }
  {
    total-records: uint,
    total-vaccinations: uint,
    last-visit: uint,
    current-medications: (string-ascii 300),
    allergies: (string-ascii 200),
    chronic-conditions: (string-ascii 300)
  }
)

(define-map authorized-access
  { pet-id: uint, accessor: principal }
  { granted-by: principal, granted-at: uint, access-type: (string-ascii 20) }
)

;; Private Variables
(define-data-var next-vaccination-id uint u1)

;; Public Functions

;; Register a veterinarian
(define-public (register-veterinarian
    (name (string-ascii 50))
    (license-number (string-ascii 20))
    (clinic-name (string-ascii 50)))
  (let
    (
      (current-time block-height)
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len license-number) u0) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? veterinarians { vet-address: tx-sender })) ERR_ALREADY_EXISTS)

    (map-set veterinarians
      { vet-address: tx-sender }
      {
        name: name,
        license-number: license-number,
        clinic-name: clinic-name,
        registered-at: current-time,
        is-active: true
      }
    )

    (ok true)
  )
)

;; Add medical record
(define-public (add-medical-record
    (pet-id uint)
    (record-type (string-ascii 20))
    (procedure (string-ascii 100))
    (diagnosis (string-ascii 200))
    (treatment (string-ascii 200))
    (medications (string-ascii 200))
    (visit-date uint)
    (follow-up-date (optional uint))
    (notes (string-ascii 500)))
  (let
    (
      (record-id (var-get next-record-id))
      (current-time block-height)
      (vet-data (unwrap! (map-get? veterinarians { vet-address: tx-sender }) ERR_UNAUTHORIZED))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (get is-active vet-data) ERR_UNAUTHORIZED)
    (asserts! (> (len record-type) u0) ERR_INVALID_INPUT)
    (asserts! (> (len procedure) u0) ERR_INVALID_INPUT)

    ;; Create medical record
    (map-set medical-records
      { record-id: record-id }
      {
        pet-id: pet-id,
        veterinarian: tx-sender,
        record-type: record-type,
        procedure: procedure,
        diagnosis: diagnosis,
        treatment: treatment,
        medications: medications,
        visit-date: visit-date,
        follow-up-date: follow-up-date,
        notes: notes,
        created-at: current-time
      }
    )

    ;; Update pet health summary
    (update-health-summary pet-id medications)

    ;; Increment record ID
    (var-set next-record-id (+ record-id u1))

    (ok record-id)
  )
)

;; Add vaccination record
(define-public (add-vaccination
    (pet-id uint)
    (vaccine-name (string-ascii 50))
    (vaccine-type (string-ascii 30))
    (administered-date uint)
    (expiry-date uint)
    (batch-number (string-ascii 20))
    (manufacturer (string-ascii 50))
    (notes (string-ascii 200)))
  (let
    (
      (vaccination-id (var-get next-vaccination-id))
      (vet-data (unwrap! (map-get? veterinarians { vet-address: tx-sender }) ERR_UNAUTHORIZED))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (get is-active vet-data) ERR_UNAUTHORIZED)
    (asserts! (> (len vaccine-name) u0) ERR_INVALID_INPUT)
    (asserts! (> expiry-date administered-date) ERR_INVALID_INPUT)

    (map-set vaccinations
      { vaccination-id: vaccination-id }
      {
        pet-id: pet-id,
        veterinarian: tx-sender,
        vaccine-name: vaccine-name,
        vaccine-type: vaccine-type,
        administered-date: administered-date,
        expiry-date: expiry-date,
        batch-number: batch-number,
        manufacturer: manufacturer,
        notes: notes
      }
    )

    ;; Update vaccination count in health summary
    (update-vaccination-count pet-id)

    ;; Increment vaccination ID
    (var-set next-vaccination-id (+ vaccination-id u1))

    (ok vaccination-id)
  )
)

;; Grant access to pet records
(define-public (grant-record-access
    (pet-id uint)
    (accessor principal)
    (access-type (string-ascii 20)))
  (begin
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (> (len access-type) u0) ERR_INVALID_INPUT)

    (map-set authorized-access
      { pet-id: pet-id, accessor: accessor }
      {
        granted-by: tx-sender,
        granted-at: block-height,
        access-type: access-type
      }
    )

    (ok true)
  )
)

;; Update health summary allergies and conditions
(define-public (update-health-conditions
    (pet-id uint)
    (allergies (string-ascii 200))
    (chronic-conditions (string-ascii 300)))
  (let
    (
      (current-summary (get-pet-health-summary pet-id))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)

    (map-set pet-health-summary
      { pet-id: pet-id }
      (merge current-summary {
        allergies: allergies,
        chronic-conditions: chronic-conditions
      })
    )

    (ok true)
  )
)

;; Admin function to toggle contract
(define-public (toggle-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Private Functions

;; Update health summary with new record
(define-private (update-health-summary (pet-id uint) (medications (string-ascii 200)))
  (let
    (
      (current-summary (get-pet-health-summary pet-id))
      (current-time block-height)
    )
    (map-set pet-health-summary
      { pet-id: pet-id }
      (merge current-summary {
        total-records: (+ (get total-records current-summary) u1),
        last-visit: current-time,
        current-medications: medications
      })
    )
  )
)

;; Update vaccination count
(define-private (update-vaccination-count (pet-id uint))
  (let
    (
      (current-summary (get-pet-health-summary pet-id))
    )
    (map-set pet-health-summary
      { pet-id: pet-id }
      (merge current-summary {
        total-vaccinations: (+ (get total-vaccinations current-summary) u1)
      })
    )
  )
)

;; Read-only Functions

;; Get veterinarian information
(define-read-only (get-veterinarian (vet-address principal))
  (map-get? veterinarians { vet-address: vet-address })
)

;; Get medical record
(define-read-only (get-medical-record (record-id uint))
  (map-get? medical-records { record-id: record-id })
)

;; Get vaccination record
(define-read-only (get-vaccination (vaccination-id uint))
  (map-get? vaccinations { vaccination-id: vaccination-id })
)

;; Get pet health summary
(define-read-only (get-pet-health-summary (pet-id uint))
  (default-to
    {
      total-records: u0,
      total-vaccinations: u0,
      last-visit: u0,
      current-medications: "",
      allergies: "",
      chronic-conditions: ""
    }
    (map-get? pet-health-summary { pet-id: pet-id })
  )
)

;; Check access authorization
(define-read-only (check-access (pet-id uint) (accessor principal))
  (map-get? authorized-access { pet-id: pet-id, accessor: accessor })
)

;; Get next record ID
(define-read-only (get-next-record-id)
  (var-get next-record-id)
)

;; Get next vaccination ID
(define-read-only (get-next-vaccination-id)
  (var-get next-vaccination-id)
)

;; Check if contract is active
(define-read-only (is-contract-active)
  (var-get contract-active)
)
