;; Brand Transparency Contract
;; Provides fashion brand transparency and supply chain visibility

(define-map brand-products
  { product-id: uint }
  {
    brand-name: (string-ascii 100),
    product-name: (string-ascii 100),
    batch-id: uint,
    material-ids: (list 10 uint),
    manufacturer-id: uint,
    retail-price: uint,
    sustainability-rating: uint,
    carbon-footprint: uint,
    created-by: principal,
    creation-date: uint
  }
)

(define-map supply-chain-trace
  { trace-id: uint }
  {
    product-id: uint,
    stage: (string-ascii 50),
    location: (string-ascii 100),
    timestamp: uint,
    verified: bool,
    verifier: principal
  }
)

(define-data-var next-product-id uint u1)
(define-data-var next-trace-id uint u1)

;; Error constants
(define-constant ERR-PRODUCT-NOT-FOUND (err u500))
(define-constant ERR-TRACE-NOT-FOUND (err u501))
(define-constant ERR-INVALID-RATING (err u502))

;; Create brand product
(define-public (create-brand-product
  (brand-name (string-ascii 100))
  (product-name (string-ascii 100))
  (batch-id uint)
  (material-ids (list 10 uint))
  (manufacturer-id uint)
  (retail-price uint)
  (carbon-footprint uint)
)
  (let ((product-id (var-get next-product-id)))
    (map-set brand-products
      { product-id: product-id }
      {
        brand-name: brand-name,
        product-name: product-name,
        batch-id: batch-id,
        material-ids: material-ids,
        manufacturer-id: manufacturer-id,
        retail-price: retail-price,
        sustainability-rating: u0,
        carbon-footprint: carbon-footprint,
        created-by: tx-sender,
        creation-date: block-height
      }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Add supply chain trace
(define-public (add-supply-chain-trace
  (product-id uint)
  (stage (string-ascii 50))
  (location (string-ascii 100))
)
  (let ((trace-id (var-get next-trace-id)))
    (map-set supply-chain-trace
      { trace-id: trace-id }
      {
        product-id: product-id,
        stage: stage,
        location: location,
        timestamp: block-height,
        verified: false,
        verifier: tx-sender
      }
    )
    (var-set next-trace-id (+ trace-id u1))
    (ok trace-id)
  )
)

;; Update sustainability rating
(define-public (update-sustainability-rating (product-id uint) (rating uint))
  (match (map-get? brand-products { product-id: product-id })
    product-data
    (begin
      (asserts! (<= rating u100) ERR-INVALID-RATING)
      (map-set brand-products
        { product-id: product-id }
        (merge product-data { sustainability-rating: rating })
      )
      (ok true)
    )
    ERR-PRODUCT-NOT-FOUND
  )
)

;; Get product details
(define-read-only (get-brand-product (product-id uint))
  (map-get? brand-products { product-id: product-id })
)

;; Get supply chain trace
(define-read-only (get-supply-chain-trace (trace-id uint))
  (map-get? supply-chain-trace { trace-id: trace-id })
)

;; Calculate transparency score
(define-read-only (calculate-transparency-score (product-id uint))
  (match (map-get? brand-products { product-id: product-id })
    product-data
    (let (
      (sustainability (get sustainability-rating product-data))
      (carbon (get carbon-footprint product-data))
    )
      (ok {
        transparency-score: (if (> carbon u0)
                             (/ (* sustainability u100) carbon)
                             sustainability),
        environmental-impact: carbon
      })
    )
    ERR-PRODUCT-NOT-FOUND
  )
)
