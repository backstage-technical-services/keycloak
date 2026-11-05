import { describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import { buildTestMatrix, expectsClientAccess } from './lib/realm-config.js'

describe.each(buildTestMatrix())('clients $realm', ({ realm, config }) => {
  const clients = config.clients ?? []

  if (clients.length === 0) {
    it('has no clients in YAML', () => {
      expect(clients.length).toBe(0)
    })
    return
  }

  it.each(clients)('client $name matches YAML', async (expected) => {
    const kc = await getAuthenticatedAdmin()
    const found = await kc.clients.find({ realm, clientId: expected.name, max: 1 })
    expect(found.length).toBe(1)
    const client = found[0]!
    expect(client.clientId).toBe(expected.name)
    if (expected['display-name']) {
      expect(client.name).toBe(expected['display-name'])
    }
    expect(client.publicClient).toBe(!!expected.public)

    const flows = expected['auth-flows'] ?? {}
    expect(client.standardFlowEnabled).toBe(!!flows.standard)
    expect(client.implicitFlowEnabled).toBe(!!flows.implicit)
    expect(client.serviceAccountsEnabled).toBe(!!flows['client-credentials'])
    expect(client.directAccessGrantsEnabled).toBe(!!flows['direct-access-grants'])
    // Keycloak may omit this field when false (undefined) instead of false.
    expect(!!(client as Record<string, unknown>).oauth2DeviceAuthorizationGrantEnabled).toBe(
      !!flows['oauth-device-authorization'],
    )

    expect([...(client.redirectUris ?? [])].sort()).toEqual(
      [...(expected['redirect-urls'] ?? [])].sort(),
    )
    const logoutUris = client.attributes?.['post.logout.redirect.uris'] as string | undefined
    expect((logoutUris ? logoutUris.split('##') : []).sort()).toEqual(
      [...(expected['logout-redirect-urls'] ?? [])].sort(),
    )
    expect(client.webOrigins).toEqual(['+'])

    const roles = await kc.clients.listRoles({ realm, id: client.id! })
    const roleNames = roles.map((r) => r.name)
    if (expectsClientAccess(config, expected)) {
      expect(roleNames).toContain('client-access')
    } else {
      expect(roleNames).not.toContain('client-access')
    }
    for (const role of expected.roles ?? []) {
      expect(roleNames).toContain(role.name)
    }
  })

  const withServiceAccountRoles = clients.filter(
    (c) => c['auth-flows']?.['client-credentials'] && (c['service-account-roles'] ?? []).length > 0,
  )
  if (withServiceAccountRoles.length > 0) {
    it.each(withServiceAccountRoles)('client $name service account has its roles', async (expected) => {
      const kc = await getAuthenticatedAdmin()
      const [client] = await kc.clients.find({ realm, clientId: expected.name, max: 1 })
      const serviceAccount = await kc.clients.getServiceAccountUser({ realm, id: client!.id! })

      for (const role of expected['service-account-roles'] ?? []) {
        const [roleClient] = await kc.clients.find({ realm, clientId: role.client, max: 1 })
        expect(roleClient?.id, role.client).toBeDefined()
        const mapped = await kc.users.listClientRoleMappings({
          realm,
          id: serviceAccount.id!,
          clientUniqueId: roleClient!.id!,
        })
        expect(mapped.map((r) => r.name)).toContain(role.name)
      }
    })
  }
})
