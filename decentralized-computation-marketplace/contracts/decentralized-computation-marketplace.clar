
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