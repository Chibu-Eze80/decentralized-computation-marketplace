
;; title: decentralized-computation-marketplace
;; Constants and Error Codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-TASK-NOT-FOUND (err u102))
(define-constant ERR-INVALID-TASK-STATE (err u103))
(define-constant ERR-VERIFICATION-FAILED (err u104))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u105))
(define-constant ERR-STAKE-REQUIRED (err u106))
(define-constant ERR-CHALLENGE-PERIOD-ACTIVE (err u107))

;; Task States (Enhanced)
(define-constant TASK-CREATED u0)
(define-constant TASK-ASSIGNED u1)
(define-constant TASK-SUBMITTED u2)
(define-constant TASK-VERIFICATION-PERIOD u3)
(define-constant TASK-COMPLETED u4)
(define-constant TASK-VERIFIED u5)
(define-constant TASK-DISPUTED u6)
(define-constant TASK-CANCELED u7)

;; Advanced Task Structure
(define-map tasks
  {task-id: uint}
  {
    creator: principal,
    bounty: uint,
    stake-requirement: uint,
    description: (string-utf8 500),
    computational-requirements: (string-utf8 200),
    complexity-score: uint,
    max-workers: uint,
    state: uint,
    assigned-workers: (list 5 principal),
    result-submissions: (list 5 {
      worker: principal,
      result-hash: (buff 32),
      submission-timestamp: uint,
      stake: uint
    }),
    verification-threshold: uint,
    challenge-period-end: uint,
    privacy-level: uint,
    resource-requirements: {
      cpu-cores: uint,
      ram-gb: uint,
      storage-gb: uint,
      gpu-requirement: bool
    }
  }
)

;; Enhanced Reputation System
(define-map worker-reputation
  principal
  {
    total-tasks-attempted: uint,
    total-tasks-completed: uint,
    successful-verifications: uint,
    failed-tasks: uint,
    disputes-raised: uint,
    reputation-score: uint,
    skill-tags: (list 10 (string-utf8 50)),
    last-active-block: uint
  }
)

;; Worker Stake Tracking
(define-map worker-stakes
  {task-id: uint, worker: principal}
  {
    stake-amount: uint,
    stake-timestamp: uint
  }
)

;; Task Verification Tracking
(define-map task-verifications
  {task-id: uint, verifier: principal}
  {
    verification-hash: (buff 32),
    verification-timestamp: uint,
    verification-stake: uint
  }
)

;; Skills and Certification Tracking
(define-map worker-skills
  principal
  {
    certified-skills: (list 10 (string-utf8 50)),
    skill-levels: (list 10 uint)
  }
)

;; Dynamic Pricing Mechanism
(define-map task-pricing
  {task-id: uint}
  {
    base-price: uint,
    dynamic-multiplier: uint,
    price-adjusted-timestamp: uint
  }
)

;; Advanced Worker Registration with Skills
(define-public (register-worker-skills 
  (skills (list 10 (string-utf8 50)))
  (skill-levels (list 10 uint))
)
  (begin
    ;; Validate input lengths match
    (asserts! (is-eq (len skills) (len skill-levels)) ERR-UNAUTHORIZED)
    
    ;; Register skills for worker
    (map-set worker-skills 
      tx-sender 
      {
        certified-skills: skills,
        skill-levels: skill-levels
      }
    )
    
    (ok true)
  )
)

;; Comprehensive Verification Mechanism
(define-public (verify-task-result 
  (task-id uint)
  (selected-result-hash (buff 32))
  (verifier-stake uint)
)
  (let 
    ((task (unwrap! (map-get? tasks {task-id: task-id}) ERR-TASK-NOT-FOUND))
     (current-state (get state task))
     (result-submissions (get result-submissions task))
     (verification-threshold (get verification-threshold task))
    )
    
    ;; Verification period checks
    (asserts! (is-eq current-state TASK-SUBMITTED) ERR-INVALID-TASK-STATE)
    (asserts! (< stacks-block-height (get challenge-period-end task)) ERR-CHALLENGE-PERIOD-ACTIVE)
    
    ;; Record verification
    (map-set task-verifications
      {task-id: task-id, verifier: tx-sender}
      {
        verification-hash: selected-result-hash,
        verification-timestamp: stacks-block-height,
        verification-stake: verifier-stake
      }
    )
    
    ;; Update task state if verification threshold met
    (map-set tasks 
      {task-id: task-id}
      (merge task {state: TASK-VERIFIED})
    )
    
    (ok true)
  )
)

;; Read-only functions for retrieving comprehensive information
(define-read-only (get-task-details (task-id uint))
  (map-get? tasks {task-id: task-id})
)

(define-read-only (get-worker-reputation (worker principal))
  (map-get? worker-reputation worker)
)

(define-read-only (get-worker-skills (worker principal))
  (map-get? worker-skills worker)
)


(define-constant ERR-MAX-WORKERS-REACHED (err u108))
(define-constant ERR-ALREADY-ASSIGNED (err u109))
(define-constant ERR-NOT-ASSIGNED-WORKER (err u110))
(define-constant ERR-PAYMENT-FAILED (err u111))
(define-constant ERR-DEADLINE-PASSED (err u112))
(define-constant ERR-EMPTY-DESCRIPTION (err u113))

(define-constant ERR-INVALID-RATING (err u114))
(define-constant ERR-ALREADY-RATED (err u115))
(define-constant ERR-INACTIVE-MARKET (err u116))
(define-constant ERR-INVALID-ESCROW (err u117))
(define-constant ERR-BLACKLISTED (err u118))
(define-constant ERR-TASK-LIMIT-EXCEEDED (err u119))
(define-constant ERR-NFT-REQUIRED (err u120))

;; New task states
(define-constant TASK-IN-ARBITRATION u8)
(define-constant TASK-EXPIRED u9)

;; Rating system
(define-map worker-ratings
  {task-id: uint, rater: principal, ratee: principal}
  {
    rating: uint,
    comment: (string-utf8 200),
    timestamp: uint
  }
)

;; Worker blacklist
(define-map blacklisted-workers
  principal
  {
    blacklisted-at: uint,
    reason: (string-utf8 200),
    blacklisted-by: principal
  }
)

;; Task categories and subcategories
(define-map task-categories
  (string-utf8 50)
  {
    subcategories: (list 10 (string-utf8 50)),
    active: bool,
    minimum-reputation: uint
  }
)

;; Market status
(define-data-var market-active bool true)

;; User dashboard stats
(define-map user-stats
  principal
  {
    total-earned: uint,
    total-spent: uint,
    tasks-created: uint,
    tasks-completed: uint,
    avg-task-complexity: uint,
    favorite-categories: (list 3 (string-utf8 50)),
    last-login: uint,
    membership-tier: uint
  }
)

;; Task templates
(define-map task-templates
  {template-id: uint}
  {
    name: (string-utf8 50),
    description: (string-utf8 200),
    default-bounty: uint,
    default-stake: uint,
    default-complexity: uint,
    category: (string-utf8 50),
    creator: principal,
    is-public: bool,
    created-at: uint,
    metadata: (string-utf8 200)
  }
)

;; Template counter
(define-data-var template-id-counter uint u0)

;; Dispute data
(define-map disputes
  {task-id: uint}
  {
    initiator: principal,
    respondent: principal,
    evidence-hash: (buff 32),
    arbiter: (optional principal),
    status: uint,
    created-at: uint,
    resolution: (optional {
      winner: principal,
      resolution-note: (string-utf8 200),
      bounty-distribution: (list 5 {recipient: principal, amount: uint})
    })
  }
)

;; Arbiters registry
(define-map arbiters
  principal
  {
    cases-handled: uint,
    success-rate: uint,
    specialty: (string-utf8 50),
    active: bool,
    stake: uint
  }
)

;; Map to track task escrow funds
(define-map task-escrow
  {task-id: uint}
  {
    total-funds: uint,
    release-conditions: (list 5 {
      milestone: (string-utf8 100),
      percentage: uint,
      released: bool,
      release-approved-by: (optional principal)
    }),
    deposit-history: (list 10 {
      contributor: principal,
      amount: uint,
      timestamp: uint
    })
  }
)

;; Map to track collaboration on tasks
(define-map task-collaboration
  {task-id: uint}
  {
    communication-logs: (list 50 {
      sender: principal,
      timestamp: uint,
      message-hash: (buff 32),
      encrypted: bool
    }),
    shared-resources: (list 20 {
      name: (string-utf8 100),
      resource-hash: (buff 32),
      uploader: principal,
      upload-timestamp: uint,
      access-control: (list 10 principal)
    }),
    revision-history: (list 10 {
      version: uint,
      changes: (string-utf8 200),
      author: principal,
      timestamp: uint
    })
  }
)

;; Map to track worker certifications
(define-map worker-certifications
  principal
  {
    certificates: (list 10 {
      certification-name: (string-utf8 100),
      issuer: principal,
      issue-date: uint,
      expiry-date: uint,
      certification-hash: (buff 32),
      revoked: bool
    }),
    specializations: (list 5 {
      domain: (string-utf8 50),
      expertise-level: uint,
      years-experience: uint,
      endorsements: (list 10 principal)
    })
  }
)

;; Map to track certification authorities
(define-map certification-authorities
  principal
  {
    authority-name: (string-utf8 100),
    domains: (list 10 (string-utf8 50)),
    authority-reputation: uint,
    registered-at: uint,
    authority-stake: uint
  }
)

;; Function to register as certification authority
(define-public (register-certification-authority
  (authority-name (string-utf8 100))
  (domains (list 10 (string-utf8 50)))
  (authority-stake uint)
)
  (begin
    ;; Transfer stake to contract
    (try! (stx-transfer? authority-stake tx-sender (as-contract tx-sender)))
    
    ;; Register authority
    (map-set certification-authorities
      tx-sender
      {
        authority-name: authority-name,
        domains: domains,
        authority-reputation: u0,
        registered-at: stacks-block-height,
        authority-stake: authority-stake
      }
    )
    
    (ok true)
  )
)

;; Map to track task marketplace data
(define-map task-marketplace
  {task-id: uint}
  {
    tags: (list 10 (string-utf8 50)),
    visibility: uint,  ;; 0=private, 1=public, 2=invite-only
    listing-expiry: uint,
    promoted: bool,
    promotion-cost: uint,
    views: uint,
    applications: (list 20 {
      applicant: principal,
      application-text: (string-utf8 200),
      proposed-price: uint,
      proposed-timeframe: uint,
      status: uint  ;; 0=pending, 1=accepted, 2=rejected
    })
  }
)

;; Map to track task recommendations
(define-map task-recommendations
  principal
  {
    recommended-tasks: (list 10 uint),
    recommendation-reason: (list 10 (string-utf8 100)),
    recommendation-score: (list 10 uint),
    last-updated: uint
  }
)

;; Map to track automated task execution
(define-map automated-task-execution
  {task-id: uint}
  {
    execution-conditions: (list 5 {
      condition-type: uint,  ;; 0=time, 1=event, 2=data
      condition-data: (buff 32),
      condition-met: bool,
      condition-met-at: uint
    }),
    execution-hooks: (list 5 {
      hook-type: uint,  ;; 0=notification, 1=payment, 2=state-change
      hook-data: (buff 32),
      hook-executed: bool,
      hook-executed-at: uint
    }),
    validation-rules: (list 5 {
      rule-type: uint,  ;; 0=hash-match, 1=threshold, 2=consensus
      rule-data: (buff 32),
      validation-result: bool,
      validated-at: uint
    }),
    status: uint  ;; 0=pending, 1=executing, 2=validated, 3=failed
  }
)

;; Function to set up automated task execution
(define-public (setup-automated-execution
  (task-id uint)
  (execution-conditions (list 5 {
    condition-type: uint,
    condition-data: (buff 32),
    condition-met: bool,
    condition-met-at: uint
  }))
  (validation-rules (list 5 {
    rule-type: uint,
    rule-data: (buff 32),
    validation-result: bool,
    validated-at: uint
  }))
)
  (let 
    ((task (unwrap! (map-get? tasks {task-id: task-id}) ERR-TASK-NOT-FOUND)))
    
    ;; Verify caller is task creator
    (asserts! (is-eq tx-sender (get creator task)) ERR-UNAUTHORIZED)
    
    ;; Set up automation
    (map-set automated-task-execution
      {task-id: task-id}
      {
        execution-conditions: execution-conditions,
        execution-hooks: (list),
        validation-rules: validation-rules,
        status: u0
      }
    )
    
    (ok true)
  )
)

;; Function to trigger automated task execution
(define-public (trigger-automated-execution
  (task-id uint)
  (execution-proof (buff 32))
)
  (let 
    ((task (unwrap! (map-get? tasks {task-id: task-id}) ERR-TASK-NOT-FOUND))
     (automation (unwrap! (map-get? automated-task-execution {task-id: task-id}) ERR-UNAUTHORIZED))
    )
    
    ;; Update automation status
    (map-set automated-task-execution
      {task-id: task-id}
      (merge automation {status: u1})
    )
    
    ;; Update task state
    (map-set tasks
      {task-id: task-id}
      (merge task {state: TASK-ASSIGNED})
    )
    
    (ok true)
  )
)

;; Function to validate automated task execution
(define-public (validate-automated-execution
  (task-id uint)
  (validation-proof (buff 32))
)
  (let 
    ((task (unwrap! (map-get? tasks {task-id: task-id}) ERR-TASK-NOT-FOUND))
     (automation (unwrap! (map-get? automated-task-execution {task-id: task-id}) ERR-UNAUTHORIZED))
    )
    
    ;; Update automation status
    (map-set automated-task-execution
      {task-id: task-id}
      (merge automation {status: u2})
    )
    
    ;; Update task state
    (map-set tasks
      {task-id: task-id}
      (merge task {state: TASK-VERIFIED})
    )
    
    (ok true)
  )
)

;; Map to track governance proposals
(define-map governance-proposals
  {proposal-id: uint}
  {
    proposer: principal,
    proposal-type: uint,  ;; 0=parameter, 1=feature, 2=rule
    proposal-description: (string-utf8 500),
    proposal-data: (buff 32),
    votes-for: uint,
    votes-against: uint,
    voting-deadline: uint,
    status: uint,  ;; 0=active, 1=passed, 2=rejected
    executed: bool,
    execution-data: (optional (buff 32))
  }
)