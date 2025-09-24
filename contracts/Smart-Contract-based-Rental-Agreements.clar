(define-data-var next-property-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_PROPERTY_NOT_AVAILABLE (err u104))
(define-constant ERR_LEASE_NOT_ACTIVE (err u105))
(define-constant ERR_LEASE_EXPIRED (err u106))
(define-constant ERR_PAYMENT_NOT_DUE (err u107))
(define-constant ERR_INSUFFICIENT_DEPOSIT (err u108))
(define-constant ERR_ALREADY_PAID (err u109))
(define-constant ERR_INVALID_DURATION (err u110))

(define-map properties
    { property-id: uint }
    {
        landlord: principal,
        rent-amount: uint,
        deposit-amount: uint,
        available: bool,
        property-address: (string-ascii 100),
    }
)

(define-map leases
    { property-id: uint }
    {
        tenant: principal,
        start-block: uint,
        end-block: uint,
        monthly-rent: uint,
        security-deposit: uint,
        last-payment-block: uint,
        active: bool,
        deposit-paid: bool,
    }
)

(define-map lease-requests
    {
        property-id: uint,
        requester: principal,
    }
    {
        requested-duration: uint,
        requested-start: uint,
        status: (string-ascii 20),
    }
)

(define-map rent-payments
    {
        property-id: uint,
        payment-id: uint,
    }
    {
        amount: uint,
        payment-block: uint,
        late-fee: uint,
        tenant: principal,
    }
)

(define-map disputes
    { property-id: uint }
    {
        dispute-reason: (string-ascii 200),
        filed-by: principal,
        filed-at: uint,
        resolved: bool,
        resolution: (string-ascii 200),
    }
)

(define-read-only (get-property (property-id uint))
    (map-get? properties { property-id: property-id })
)

(define-read-only (get-lease (property-id uint))
    (map-get? leases { property-id: property-id })
)

(define-read-only (get-lease-request
        (property-id uint)
        (requester principal)
    )
    (map-get? lease-requests {
        property-id: property-id,
        requester: requester,
    })
)

(define-read-only (get-dispute (property-id uint))
    (map-get? disputes { property-id: property-id })
)

(define-read-only (get-next-property-id)
    (var-get next-property-id)
)

(define-read-only (is-lease-active (property-id uint))
    (match (get-lease property-id)
        lease-data (and (get active lease-data) (< stacks-block-height (get end-block lease-data)))
        false
    )
)

(define-read-only (is-rent-due (property-id uint))
    (match (get-lease property-id)
        lease-data (and
            (get active lease-data)
            (>= stacks-block-height (+ (get last-payment-block lease-data) u144))
        )
        false
    )
)

(define-read-only (calculate-late-fee (property-id uint))
    (match (get-lease property-id)
        lease-data (let ((blocks-late (- stacks-block-height (+ (get last-payment-block lease-data) u144))))
            (if (> blocks-late u0)
                (/ (* (get monthly-rent lease-data) blocks-late) u1440)
                u0
            )
        )
        u0
    )
)

(define-public (list-property
        (rent-amount uint)
        (deposit-amount uint)
        (property-address (string-ascii 100))
    )
    (let ((property-id (var-get next-property-id)))
        (asserts! (> rent-amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= deposit-amount rent-amount) ERR_INVALID_AMOUNT)
        (map-set properties { property-id: property-id } {
            landlord: tx-sender,
            rent-amount: rent-amount,
            deposit-amount: deposit-amount,
            available: true,
            property-address: property-address,
        })
        (var-set next-property-id (+ property-id u1))
        (ok property-id)
    )
)

(define-public (delist-property (property-id uint))
    (match (get-property property-id)
        property-data (begin
            (asserts! (is-eq (get landlord property-data) tx-sender)
                ERR_UNAUTHORIZED
            )
            (asserts! (not (is-lease-active property-id)) (err u111))
            (map-set properties { property-id: property-id }
                (merge property-data { available: false })
            )
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

(define-public (request-lease
        (property-id uint)
        (duration-blocks uint)
        (start-block uint)
    )
    (match (get-property property-id)
        property-data (begin
            (asserts! (get available property-data) ERR_PROPERTY_NOT_AVAILABLE)
            (asserts! (> duration-blocks u0) ERR_INVALID_DURATION)
            (asserts! (>= start-block stacks-block-height) ERR_INVALID_DURATION)
            (asserts! (is-none (get-lease-request property-id tx-sender))
                ERR_ALREADY_EXISTS
            )
            (map-set lease-requests {
                property-id: property-id,
                requester: tx-sender,
            } {
                requested-duration: duration-blocks,
                requested-start: start-block,
                status: "pending",
            })
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

(define-public (approve-lease-request
        (property-id uint)
        (tenant principal)
    )
    (match (get-property property-id)
        property-data (match (get-lease-request property-id tenant)
            request-data (begin
                (asserts! (is-eq (get landlord property-data) tx-sender)
                    ERR_UNAUTHORIZED
                )
                (asserts! (get available property-data)
                    ERR_PROPERTY_NOT_AVAILABLE
                )
                (let (
                        (start-block (get requested-start request-data))
                        (end-block (+ (get requested-start request-data)
                            (get requested-duration request-data)
                        ))
                    )
                    (map-set leases { property-id: property-id } {
                        tenant: tenant,
                        start-block: start-block,
                        end-block: end-block,
                        monthly-rent: (get rent-amount property-data),
                        security-deposit: (get deposit-amount property-data),
                        last-payment-block: start-block,
                        active: true,
                        deposit-paid: false,
                    })
                    (map-set properties { property-id: property-id }
                        (merge property-data { available: false })
                    )
                    (map-delete lease-requests {
                        property-id: property-id,
                        requester: tenant,
                    })
                    (ok true)
                )
            )
            ERR_NOT_FOUND
        )
        ERR_NOT_FOUND
    )
)

(define-public (reject-lease-request
        (property-id uint)
        (tenant principal)
    )
    (match (get-property property-id)
        property-data (begin
            (asserts! (is-eq (get landlord property-data) tx-sender)
                ERR_UNAUTHORIZED
            )
            (asserts! (is-some (get-lease-request property-id tenant))
                ERR_NOT_FOUND
            )
            (map-set lease-requests {
                property-id: property-id,
                requester: tenant,
            }
                (merge
                    (unwrap! (get-lease-request property-id tenant) ERR_NOT_FOUND) { status: "rejected" }
                ))
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

(define-public (pay-security-deposit (property-id uint))
    (match (get-lease property-id)
        lease-data (match (get-property property-id)
            property-data (begin
                (asserts! (is-eq (get tenant lease-data) tx-sender)
                    ERR_UNAUTHORIZED
                )
                (asserts! (get active lease-data) ERR_LEASE_NOT_ACTIVE)
                (asserts! (not (get deposit-paid lease-data)) ERR_ALREADY_PAID)
                (try! (stx-transfer? (get security-deposit lease-data) tx-sender
                    (get landlord property-data)
                ))
                (map-set leases { property-id: property-id }
                    (merge lease-data { deposit-paid: true })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
        ERR_NOT_FOUND
    )
)

(define-public (pay-rent (property-id uint))
    (match (get-lease property-id)
        lease-data (match (get-property property-id)
            property-data (begin
                (asserts! (is-eq (get tenant lease-data) tx-sender)
                    ERR_UNAUTHORIZED
                )
                (asserts! (get active lease-data) ERR_LEASE_NOT_ACTIVE)
                (asserts! (get deposit-paid lease-data) ERR_INSUFFICIENT_DEPOSIT)
                (asserts! (is-rent-due property-id) ERR_PAYMENT_NOT_DUE)
                (let (
                        (late-fee (calculate-late-fee property-id))
                        (total-amount (+ (get monthly-rent lease-data) late-fee))
                    )
                    (try! (stx-transfer? total-amount tx-sender
                        (get landlord property-data)
                    ))
                    (map-set leases { property-id: property-id }
                        (merge lease-data { last-payment-block: stacks-block-height })
                    )
                    (ok true)
                )
            )
            ERR_NOT_FOUND
        )
        ERR_NOT_FOUND
    )
)

(define-public (terminate-lease (property-id uint))
    (match (get-lease property-id)
        lease-data (match (get-property property-id)
            property-data (begin
                (asserts!
                    (or (is-eq (get tenant lease-data) tx-sender) (is-eq (get landlord property-data) tx-sender))
                    ERR_UNAUTHORIZED
                )
                (asserts! (get active lease-data) ERR_LEASE_NOT_ACTIVE)
                (map-set leases { property-id: property-id }
                    (merge lease-data { active: false })
                )
                (map-set properties { property-id: property-id }
                    (merge property-data { available: true })
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
        ERR_NOT_FOUND
    )
)

(define-public (refund-deposit
        (property-id uint)
        (refund-amount uint)
    )
    (match (get-lease property-id)
        lease-data (match (get-property property-id)
            property-data (begin
                (asserts! (is-eq (get landlord property-data) tx-sender)
                    ERR_UNAUTHORIZED
                )
                (asserts! (not (get active lease-data)) ERR_LEASE_NOT_ACTIVE)
                (asserts! (<= refund-amount (get security-deposit lease-data))
                    ERR_INVALID_AMOUNT
                )
                (try! (stx-transfer? refund-amount tx-sender (get tenant lease-data)))
                (ok true)
            )
            ERR_NOT_FOUND
        )
        ERR_NOT_FOUND
    )
)

(define-public (file-dispute
        (property-id uint)
        (reason (string-ascii 200))
    )
    (match (get-lease property-id)
        lease-data (match (get-property property-id)
            property-data (begin
                (asserts!
                    (or (is-eq (get tenant lease-data) tx-sender) (is-eq (get landlord property-data) tx-sender))
                    ERR_UNAUTHORIZED
                )
                (asserts! (get active lease-data) ERR_LEASE_NOT_ACTIVE)
                (asserts! (is-none (get-dispute property-id)) ERR_ALREADY_EXISTS)
                (map-set disputes { property-id: property-id } {
                    dispute-reason: reason,
                    filed-by: tx-sender,
                    filed-at: stacks-block-height,
                    resolved: false,
                    resolution: "",
                })
                (ok true)
            )
            ERR_NOT_FOUND
        )
        ERR_NOT_FOUND
    )
)

(define-public (resolve-dispute
        (property-id uint)
        (resolution (string-ascii 200))
    )
    (match (get-dispute property-id)
        dispute-data (begin
            (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
            (asserts! (not (get resolved dispute-data)) ERR_ALREADY_EXISTS)
            (map-set disputes { property-id: property-id }
                (merge dispute-data {
                    resolved: true,
                    resolution: resolution,
                })
            )
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

(define-public (transfer-ownership
        (property-id uint)
        (new-landlord principal)
    )
    (match (get-property property-id)
        property-data (begin
            (asserts! (is-eq (get landlord property-data) tx-sender)
                ERR_UNAUTHORIZED
            )
            (asserts! (not (is-lease-active property-id)) (err u112))
            (map-set properties { property-id: property-id }
                (merge property-data { landlord: new-landlord })
            )
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

(define-public (update-rent
        (property-id uint)
        (new-rent uint)
    )
    (match (get-property property-id)
        property-data (begin
            (asserts! (is-eq (get landlord property-data) tx-sender)
                ERR_UNAUTHORIZED
            )
            (asserts! (not (is-lease-active property-id)) (err u113))
            (asserts! (> new-rent u0) ERR_INVALID_AMOUNT)
            (map-set properties { property-id: property-id }
                (merge property-data { rent-amount: new-rent })
            )
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

(define-read-only (get-lease-status (property-id uint))
    (match (get-lease property-id)
        lease-data (if (get active lease-data)
            (if (>= stacks-block-height (get end-block lease-data))
                (ok "expired")
                (ok "active")
            )
            (ok "terminated")
        )
        (ok "no-lease")
    )
)
