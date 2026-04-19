export const APP_NAME = 'FitClub'

export const ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  FRONT_DESK: 'front_desk',
  COACH: 'coach',
  MEMBER: 'member',
} as const

export type Role = (typeof ROLES)[keyof typeof ROLES]

export const STAFF_ROLES: Role[] = [ROLES.ADMIN, ROLES.MANAGER, ROLES.FRONT_DESK, ROLES.COACH]

export const MEMBER_STATUSES = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  EXPIRED: 'expired',
  SUSPENDED: 'suspended',
  FLAGGED: 'flagged',
} as const

export const PAYMENT_METHODS = {
  CASH: 'cash',
  CARD: 'card',
} as const

export const STALE_TIMES = {
  DEFAULT: 60_000,
  DASHBOARD: 30_000,
  PLANS: 300_000,
} as const
