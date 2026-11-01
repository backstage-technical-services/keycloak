import fs from 'node:fs'
import path from 'node:path'
import yaml from 'js-yaml'

import { REPO_ROOT } from './paths.js'

export interface RealmYamlRole {
  name: string
  client?: string
}

export interface RealmYamlClient {
  name: string
  'display-name'?: string
  public?: boolean
  'access-mode'?: string
  'auth-flows'?: {
    standard?: boolean
    implicit?: boolean
    'client-credentials'?: boolean
    'direct-access-grants'?: boolean
    'oauth-device-authorization'?: boolean
  }
  'redirect-urls'?: string[]
  'logout-redirect-urls'?: string[]
  roles?: Array<{ name: string; description?: string }>
  'service-account-roles'?: Array<{ name: string; client: string }>
}

export interface RealmYamlGroup {
  name: string
  roles?: RealmYamlRole[]
}

export interface RealmYaml {
  'display-name': string
  tokens: {
    'access-lifespan': string
  }
  'default-access-mode'?: string
  auth?: {
    'enable-flows'?: boolean
  }
  federation?: {
    'read-only'?: boolean
  }
  groups?: RealmYamlGroup[]
  clients?: RealmYamlClient[]
}

export function listRealms(): string[] {
  return fs
    .readdirSync(path.join(REPO_ROOT, 'realms'))
    .filter((f) => f.endsWith('.yaml'))
    .map((f) => f.slice(0, -'.yaml'.length))
    .sort()
}

export function loadRealmYaml(realm: string): RealmYaml {
  const raw = fs.readFileSync(path.join(REPO_ROOT, 'realms', `${realm}.yaml`), 'utf8')
  return yaml.load(raw) as RealmYaml
}

export function flowsEnabled(config: RealmYaml): boolean {
  return config.auth?.['enable-flows'] !== false
}

export function isFederationReadOnly(config: RealmYaml): boolean {
  return config.federation?.['read-only'] === true
}

export function effectiveAccessMode(config: RealmYaml, client: RealmYamlClient): string {
  return client['access-mode'] ?? config['default-access-mode'] ?? 'open'
}

export function expectsClientAccess(config: RealmYaml, client: RealmYamlClient): boolean {
  return effectiveAccessMode(config, client) !== 'open'
}

export function clientsForAccessModeGroup(config: RealmYaml, groupName: string): string[] {
  return (config.clients ?? [])
    .filter((client) => effectiveAccessMode(config, client) === groupName)
    .map((client) => client.name)
    .sort()
}

export function durationToSeconds(duration: string): number {
  const units: Record<string, number> = { s: 1, m: 60, h: 3600 }
  let total = 0
  for (const [, value, unit] of duration.matchAll(/(\d+)([smh])/g)) {
    total += Number(value) * units[unit!]!
  }
  return total
}

export interface TestMatrixRow {
  realm: string
  config: RealmYaml
}

export function buildTestMatrix(): TestMatrixRow[] {
  return listRealms().map((realm) => ({ realm, config: loadRealmYaml(realm) }))
}
