import { describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import { buildTestMatrix, clientsForAccessModeGroup } from './lib/realm-config.js'

async function expectClientRoleMappings(
  realm: string,
  groupId: string,
  clientRoles: Record<string, readonly string[]>,
): Promise<void> {
  const kc = await getAuthenticatedAdmin()
  for (const [clientId, roles] of Object.entries(clientRoles)) {
    const clients = await kc.clients.find({ realm, clientId, max: 1 })
    expect(clients[0]?.id, clientId).toBeDefined()
    const mapped = await kc.groups.listClientRoleMappings({
      realm,
      id: groupId,
      clientUniqueId: clients[0]!.id!,
    })
    const names = mapped.map((x) => x.name)
    for (const role of roles) {
      expect(names).toContain(role)
    }
  }
}

describe.each(buildTestMatrix())('groups $realm', ({ realm, config }) => {
  const yamlGroups = config.groups ?? []

  it('has the LDAP group for federated groups', async () => {
    const kc = await getAuthenticatedAdmin()
    const group = await kc.realms.getGroupByPath({ realm, path: '/LDAP' })
    expect(group.id).toBeDefined()
  })

  if (yamlGroups.length === 0) {
    it('has no custom groups in YAML', () => {
      expect(yamlGroups.length).toBe(0)
    })
    return
  }

  it.each(yamlGroups)('group $name has expected role mappings', async (expected) => {
    const kc = await getAuthenticatedAdmin()
    const group = await kc.realms.getGroupByPath({ realm, path: `/${expected.name}` })
    expect(group.id).toBeDefined()

    const clientRoles: Record<string, string[]> = {}
    const realmRoles: string[] = []
    for (const role of expected.roles ?? []) {
      if (role.client) {
        ;(clientRoles[role.client] ??= []).push(role.name)
      } else {
        realmRoles.push(role.name)
      }
    }

    for (const clientId of clientsForAccessModeGroup(config, expected.name)) {
      ;(clientRoles[clientId] ??= []).push('client-access')
    }

    await expectClientRoleMappings(realm, group.id!, clientRoles)

    if (realmRoles.length > 0) {
      const mapped = await kc.groups.listRealmRoleMappings({ realm, id: group.id! })
      const names = mapped.map((x) => x.name)
      for (const role of realmRoles) {
        expect(names).toContain(role)
      }
    }
  })
})
