;; Manufacturer Verification Contract
;; Validates and manages textile manufacturers in the supply chain

(define-map manufacturers
  { manufacturer-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    certification-level: uint,
    verified: bool,
    verifier: principal,
    verification-date: uint
  }
)

(define-map manufacturer-counter principal uint)

(define-data-var next-manufacturer-id uint u1)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MANUFACTURER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VERIFIED (err u102))

;; Register a new manufacturer
(define-public (register-manufacturer (name (string-ascii 100)) (location (string-ascii 100)))
  (let ((manufacturer-id (var-get next-manufacturer-id)))
    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      {
        name: name,
        location: location,
        certification-level: u0,
        verified: false,
        verifier: tx-sender,
        verification-date: block-height
      }
    )
    (var-set next-manufacturer-id (+ manufacturer-id u1))
    (ok manufacturer-id)
  )
)

;; Verify a manufacturer
(define-public (verify-manufacturer (manufacturer-id uint) (certification-level uint))
  (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
    manufacturer-data
    (if (get verified manufacturer-data)
      ERR-ALREADY-VERIFIED
      (begin
        (map-set manufacturers
          { manufacturer-id: manufacturer-id }
          (merge manufacturer-data {
            verified: true,
            certification-level: certification-level,
            verifier: tx-sender,
            verification-date: block-height
          })
        )
        (ok true)
      )
    )
    ERR-MANUFACTURER-NOT-FOUND
  )
)

;; Get manufacturer details
(define-read-only (get-manufacturer (manufacturer-id uint))
  (map-get? manufacturers { manufacturer-id: manufacturer-id })
)

;; Check if manufacturer is verified
(define-read-only (is-manufacturer-verified (manufacturer-id uint))
  (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
    manufacturer-data (ok (get verified manufacturer-data))
    ERR-MANUFACTURER-NOT-FOUND
  )
)
