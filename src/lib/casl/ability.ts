import { AbilityBuilder, createMongoAbility, type MongoAbility } from '@casl/ability'
import type { Role } from '@/lib/constants'

type Actions = 'create' | 'read' | 'update' | 'delete' | 'manage'
type Subjects =
  | 'Member'
  | 'Subscription'
  | 'Payment'
  | 'CheckIn'
  | 'Group'
  | 'Staff'
  | 'Dashboard'
  | 'DashboardFull'
  | 'Audit'
  | 'Settings'
  | 'all'

export type AppAbility = MongoAbility<[Actions, Subjects]>

export function defineAbilityFor(role: Role): AppAbility {
  const { can, build } = new AbilityBuilder<AppAbility>(createMongoAbility)

  switch (role) {
    case 'admin':
      can('manage', 'all')
      break

    case 'manager':
      can('manage', 'Member')
      can('manage', 'Subscription')
      can('manage', 'Payment')
      can('manage', 'CheckIn')
      can('manage', 'Group')
      can('manage', 'Staff')
      can('read', 'Dashboard')
      can('read', 'DashboardFull')
      can('read', 'Audit')
      break

    case 'front_desk':
      can('create', 'Member')
      can('read', 'Member')
      can('create', 'Subscription')
      can('read', 'Subscription')
      can('create', 'Payment')
      can('read', 'Payment')
      can('manage', 'CheckIn')
      can('read', 'Group')
      can('read', 'Dashboard')
      break

    case 'coach':
      can('read', 'Member')
      can('read', 'Subscription')
      break

    case 'member':
      can('read', 'Member')
      can('read', 'Subscription')
      can('read', 'Payment')
      break
  }

  return build()
}
