import { describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import { buildTestMatrix, isFederationReadOnly } from './lib/realm-config.js'

const LDAP_USER = 'ldap_user'
const LDAP_GROUP = 'crew'

async function findLdapProvider(realm: string) {
  const kc = await getAuthenticatedAdmin()
  const providers = await kc.components.find({
    realm,
    type: 'org.keycloak.storage.UserStorageProvider',
    name: 'openldap',
  })
  expect(providers.length).toBe(1)
  return providers[0]!
}

describe.each(buildTestMatrix())('user federation $realm', ({ realm, config }) => {
  const readOnly = isFederationReadOnly(config)

  it(`has the LDAP provider (${readOnly ? 'read-only' : 'writable'})`, async () => {
    const provider = await findLdapProvider(realm)
    expect(provider.providerId).toBe('ldap')
    expect(provider.config?.connectionUrl).toEqual(['ldap://openldap:1389'])
    expect(provider.config?.usersDn).toEqual(['ou=users,dc=ldap,dc=bts-crew,dc=com'])
    expect(provider.config?.editMode).toEqual([readOnly ? 'READ_ONLY' : 'WRITABLE'])
    expect(provider.config?.importEnabled).toEqual(['true'])
    expect(provider.config?.syncRegistrations).toEqual(['true'])
  })

  it('has the LDAP group mapper', async () => {
    const kc = await getAuthenticatedAdmin()
    const provider = await findLdapProvider(realm)
    const mappers = await kc.components.find({
      realm,
      parent: provider.id!,
      type: 'org.keycloak.storage.ldap.mappers.LDAPStorageMapper',
    })
    const groupMapper = mappers.find((m) => m.name === 'group-mapper')
    expect(groupMapper).toBeDefined()
    expect(groupMapper!.providerId).toBe('group-ldap-mapper')
    expect(groupMapper!.config?.mode).toEqual([readOnly ? 'READ_ONLY' : 'LDAP_ONLY'])
    expect(groupMapper!.config?.['groups.path']).toEqual(['/LDAP'])
  })

  it('imports LDAP users with their LDAP groups', async () => {
    const kc = await getAuthenticatedAdmin()
    const provider = await findLdapProvider(realm)

    const users = await kc.users.find({ realm, username: LDAP_USER, exact: true })
    expect(users.length).toBe(1)
    const user = users[0]!
    expect(user.federationLink).toBe(provider.id)
    expect(user.firstName).toBe('LDAP')
    expect(user.lastName).toBe('User')
    expect(user.email).toBe('ldap_user@example.invalid')

    const groups = await kc.users.listGroups({ realm, id: user.id! })
    expect(groups.map((g) => g.path)).toContain(`/LDAP/${LDAP_GROUP}`)
  })
})
