;; Blockchain-based Intellectual Property Protection Contract
;; Version: 1.0.0
;; Author: IP Protection System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-expired (err u105))
(define-constant err-insufficient-payment (err u106))

;; Data Variables
(define-data-var registration-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var next-ip-id uint u1)

;; Data Maps
(define-map intellectual-properties 
  { ip-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    ip-type: (string-ascii 20), ;; patent, trademark, copyright, trade-secret
    hash: (buff 32),
    registration-date: uint,
    expiry-date: uint,
    is-active: bool,
    license-terms: (string-ascii 200)
  }
)

(define-map ip-ownership-history
  { ip-id: uint, transfer-id: uint }
  {
    from: principal,
    to: principal,
    transfer-date: uint,
    transfer-type: (string-ascii 20) ;; sale, license, transfer
  }
)

(define-map ip-licenses
  { ip-id: uint, licensee: principal }
  {
    licensor: principal,
    license-type: (string-ascii 20), ;; exclusive, non-exclusive
    start-date: uint,
    end-date: uint,
    royalty-rate: uint, ;; percentage * 100 (e.g., 500 = 5%)
    is-active: bool
  }
)

(define-map ip-disputes
  { dispute-id: uint }
  {
    ip-id: uint,
    plaintiff: principal,
    defendant: principal,
    dispute-type: (string-ascii 50),
    status: (string-ascii 20), ;; pending, resolved, dismissed
    creation-date: uint
  }
)

(define-map user-profiles
  { user: principal }
  {
    name: (string-ascii 50),
    reputation-score: uint,
    total-ips: uint,
    verification-status: bool
  }
)

;; Private Functions
(define-private (is-valid-ip-type (ip-type (string-ascii 20)))
  (or 
    (is-eq ip-type "patent")
    (is-eq ip-type "trademark")
    (is-eq ip-type "copyright")
    (is-eq ip-type "trade-secret")
  )
)

(define-private (calculate-expiry-date (ip-type (string-ascii 20)) (current-date uint))
  (if (is-eq ip-type "patent")
    (+ current-date u630720000) ;; 20 years in seconds
    (if (is-eq ip-type "trademark")
      (+ current-date u315360000) ;; 10 years in seconds
      (if (is-eq ip-type "copyright")
        (+ current-date u2208988800) ;; 70 years in seconds
        (+ current-date u1576800000) ;; 50 years for trade secrets
      )
    )
  )
)

;; Public Functions

;; Register new intellectual property
(define-public (register-ip 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (ip-type (string-ascii 20))
  (content-hash (buff 32))
  (license-terms (string-ascii 200))
)
  (let (
    (current-ip-id (var-get next-ip-id))
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    (fee (var-get registration-fee))
  )
    (asserts! (is-valid-ip-type ip-type) err-invalid-input)
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    
    ;; Transfer registration fee to contract
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))
    
    ;; Register the IP
    (map-set intellectual-properties
      { ip-id: current-ip-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        ip-type: ip-type,
        hash: content-hash,
        registration-date: current-time,
        expiry-date: (calculate-expiry-date ip-type current-time),
        is-active: true,
        license-terms: license-terms
      }
    )
    
    ;; Update user profile
    (map-set user-profiles
      { user: tx-sender }
      (merge 
        (default-to 
          { name: "", reputation-score: u100, total-ips: u0, verification-status: false }
          (map-get? user-profiles { user: tx-sender })
        )
        { total-ips: (+ (get total-ips (default-to { name: "", reputation-score: u100, total-ips: u0, verification-status: false } (map-get? user-profiles { user: tx-sender }))) u1) }
      )
    )
    
    ;; Increment IP counter
    (var-set next-ip-id (+ current-ip-id u1))
    
    (ok current-ip-id)
  )
)

;; Transfer IP ownership
(define-public (transfer-ip (ip-id uint) (new-owner principal))
  (let (
    (ip-data (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) err-not-found))
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
  )
    (asserts! (is-eq tx-sender (get owner ip-data)) err-unauthorized)
    (asserts! (get is-active ip-data) err-expired)
    
    ;; Update IP ownership
    (map-set intellectual-properties
      { ip-id: ip-id }
      (merge ip-data { owner: new-owner })
    )
    
    ;; Record ownership history
    (map-set ip-ownership-history
      { ip-id: ip-id, transfer-id: u1 }
      {
        from: tx-sender,
        to: new-owner,
        transfer-date: current-time,
        transfer-type: "transfer"
      }
    )
    
    (ok true)
  )
)

;; Create license for IP
(define-public (create-license 
  (ip-id uint)
  (licensee principal)
  (license-type (string-ascii 20))
  (duration-days uint)
  (royalty-rate uint)
)
  (let (
    (ip-data (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) err-not-found))
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
  )
    (asserts! (is-eq tx-sender (get owner ip-data)) err-unauthorized)
    (asserts! (get is-active ip-data) err-expired)
    (asserts! (or (is-eq license-type "exclusive") (is-eq license-type "non-exclusive")) err-invalid-input)
    
    (map-set ip-licenses
      { ip-id: ip-id, licensee: licensee }
      {
        licensor: tx-sender,
        license-type: license-type,
        start-date: current-time,
        end-date: (+ current-time (* duration-days u86400)),
        royalty-rate: royalty-rate,
        is-active: true
      }
    )
    
    (ok true)
  )
)

;; Verify IP ownership
(define-read-only (verify-ownership (ip-id uint) (claimed-owner principal))
  (match (map-get? intellectual-properties { ip-id: ip-id })
    ip-data (is-eq (get owner ip-data) claimed-owner)
    false
  )
)

;; Get IP details
(define-read-only (get-ip-details (ip-id uint))
  (map-get? intellectual-properties { ip-id: ip-id })
)

;; Check IP validity (not expired)
(define-read-only (is-ip-valid (ip-id uint))
  (let (
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
  )
    (match (map-get? intellectual-properties { ip-id: ip-id })
      ip-data (and 
        (get is-active ip-data)
        (< current-time (get expiry-date ip-data))
      )
      false
    )
  )
)

;; Get user's IPs
(define-read-only (get-user-ips (user principal))
  (map-get? user-profiles { user: user })
)

;; Get license details
(define-read-only (get-license (ip-id uint) (licensee principal))
  (map-get? ip-licenses { ip-id: ip-id, licensee: licensee })
)

;; Administrative functions
(define-public (set-registration-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set registration-fee new-fee)
    (ok true)
  )
)

(define-public (deactivate-ip (ip-id uint))
  (let (
    (ip-data (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) err-not-found))
  )
    (asserts! (or (is-eq tx-sender (get owner ip-data)) (is-eq tx-sender contract-owner)) err-unauthorized)
    
    (map-set intellectual-properties
      { ip-id: ip-id }
      (merge ip-data { is-active: false })
    )
    
    (ok true)
  )
)

;; Emergency functions
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Implementation for emergency pause functionality
    (ok true)
  )
)

;; Contract info
(define-read-only (get-contract-info)
  {
    registration-fee: (var-get registration-fee),
    next-ip-id: (var-get next-ip-id),
    contract-owner: contract-owner
  }
)