import { afterAll, beforeAll, describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import {
  getKeycloakBaseUrl,
  postForm,
  tokenEndpoint,
  wellKnownUrl,
} from './lib/oidc.js'
import { listRealms } from './lib/realm-config.js'

const E2E_OIDC_CLIENT_ID = 'e2e-tests'
const E2E_PASSWORD_USER = 'e2e_user'
const E2E_PASSWORD_VALUE = process.env.E2E_TEST_USER_PASSWORD ?? 'e2e_password'

const LDAP_USER = 'ldap_user'
const LDAP_PASSWORD = 'ldap_password'

describe('Login flows', () => {
  describe('master realm', () => {
    it('issues an access token for the initial admin user via admin-cli (direct access grants)', async () => {
      const user = process.env.KC_BOOTSTRAP_ADMIN_USERNAME ?? 'admin'
      const pass = process.env.KC_BOOTSTRAP_ADMIN_PASSWORD ?? 'admin'

      const { status, json } = await postForm(tokenEndpoint('master'), {
        grant_type: 'password',
        client_id: 'admin-cli',
        username: user,
        password: pass,
      })

      expect(status).toBe(200)
      expect(typeof json?.access_token).toBe('string')
      expect(json?.access_token).toBeTruthy()
      expect(json?.token_type).toBe('Bearer')
      expect(json?.expires_in).toBeDefined()
    })

    it('exposes realm master OpenID configuration', async () => {
      const res = await fetch(wellKnownUrl('master'))
      expect(res.status).toBe(200)
      const doc = (await res.json()) as Record<string, unknown>
      expect(String(doc.issuer)).toContain('/realms/master')
    })
  })

  describe.each(listRealms())(
    '%s realm',
    (realm) => {
      let oidcClientSecret!: string
      let clientInternalId: string | undefined
      let userInternalId: string | undefined

      beforeAll(async () => {
        const kc = await getAuthenticatedAdmin()

        const existingClients = await kc.clients.find({
          realm,
          clientId: E2E_OIDC_CLIENT_ID,
        })
        for (const c of existingClients) {
          if (c.id) {
            await kc.clients.del({ realm, id: c.id })
          }
        }

        const { id } = await kc.clients.create({
          realm,
          clientId: E2E_OIDC_CLIENT_ID,
          name: 'E2E tests',
          protocol: 'openid-connect',
          enabled: true,
          publicClient: false,
          serviceAccountsEnabled: true,
          standardFlowEnabled: false,
          implicitFlowEnabled: false,
          directAccessGrantsEnabled: true,
          bearerOnly: false,
          redirectUris: [],
          webOrigins: [],
        })
        clientInternalId = id

        const secretRep = await kc.clients.getClientSecret({ realm, id })
        oidcClientSecret = secretRep.value ?? ''
        expect(oidcClientSecret).toBeTruthy()

        const existingUsers = await kc.users.find({
          realm,
          username: E2E_PASSWORD_USER,
          exact: true,
        })
        for (const u of existingUsers) {
          if (u.id) {
            await kc.users.del({ realm, id: u.id })
          }
        }

        const { id: uid } = await kc.users.create({
          realm,
          username: E2E_PASSWORD_USER,
          enabled: true,
          email: `${E2E_PASSWORD_USER}@example.invalid`,
          emailVerified: true,
          firstName: 'E2E',
          lastName: 'Tests',
          credentials: [
            { type: 'password', value: E2E_PASSWORD_VALUE, temporary: false },
          ],
        })
        userInternalId = uid
      })

      afterAll(async () => {
        const kc = await getAuthenticatedAdmin()
        if (userInternalId) {
          await kc.users.del({ realm, id: userInternalId }).catch(() => {
            /* best-effort teardown */
          })
        }
        if (clientInternalId) {
          await kc.clients.del({ realm, id: clientInternalId }).catch(() => {
            /* best-effort teardown */
          })
        }
      })

      it('serves the well known endpoint', async () => {
        const res = await fetch(wellKnownUrl(realm))
        expect(res.status).toBe(200)
        const doc = (await res.json()) as Record<string, unknown>
        expect(typeof doc.issuer).toBe('string')
        expect(String(doc.issuer)).toContain(`/realms/${realm}`)
        expect(typeof doc.token_endpoint).toBe('string')
        expect(String(doc.token_endpoint)).toContain('/protocol/openid-connect/token')
      })

      it('publishes JWKS for the realm', async () => {
        const baseUrl = getKeycloakBaseUrl()
        const res = await fetch(
          `${baseUrl}/realms/${encodeURIComponent(realm)}/protocol/openid-connect/certs`,
        )
        expect(res.status).toBe(200)
        const doc = (await res.json()) as { keys?: unknown[] }
        expect(Array.isArray(doc.keys)).toBe(true)
        expect(doc.keys!.length).toBeGreaterThan(0)
      })

      it('has direct access grants enabled on the e2e-tests client', async () => {
        const kc = await getAuthenticatedAdmin()
        const client = await kc.clients.findOne({
          realm,
          id: clientInternalId!,
        })
        expect(client?.directAccessGrantsEnabled).toBe(true)
      })

      it('issues an access token via client_credentials', async () => {
        const { status, json } = await postForm(tokenEndpoint(realm), {
          grant_type: 'client_credentials',
          client_id: E2E_OIDC_CLIENT_ID,
          client_secret: oidcClientSecret,
        })

        expect(status).toBe(200)
        expect(typeof json?.access_token).toBe('string')
        expect(json?.access_token).toBeTruthy()
        expect(json?.token_type).toBe('Bearer')
      })

      it('rejects client_credentials with a bad secret', async () => {
        const { status, json } = await postForm(tokenEndpoint(realm), {
          grant_type: 'client_credentials',
          client_id: E2E_OIDC_CLIENT_ID,
          client_secret: 'definitely-not-the-real-secret',
        })

        expect(status).toBeGreaterThanOrEqual(400)
        expect(json?.error).toBeTruthy()
      })

      it('issues an access token via password grant (resource owner password)', async () => {
        const { status, json } = await postForm(tokenEndpoint(realm), {
          grant_type: 'password',
          client_id: E2E_OIDC_CLIENT_ID,
          client_secret: oidcClientSecret,
          username: E2E_PASSWORD_USER,
          password: E2E_PASSWORD_VALUE,
        })

        expect(status, JSON.stringify(json)).toBe(200)
        expect(typeof json?.access_token).toBe('string')
        expect(json?.access_token).toBeTruthy()
        expect(json?.token_type).toBe('Bearer')
      })

      it('issues an access token via password grant for an LDAP user', async () => {
        const { status, json } = await postForm(tokenEndpoint(realm), {
          grant_type: 'password',
          client_id: E2E_OIDC_CLIENT_ID,
          client_secret: oidcClientSecret,
          username: LDAP_USER,
          password: LDAP_PASSWORD,
        })

        expect(status, JSON.stringify(json)).toBe(200)
        expect(typeof json?.access_token).toBe('string')
        expect(json?.access_token).toBeTruthy()
      })

      it('rejects password grant with wrong password', async () => {
        const { status, json } = await postForm(tokenEndpoint(realm), {
          grant_type: 'password',
          client_id: E2E_OIDC_CLIENT_ID,
          client_secret: oidcClientSecret,
          username: E2E_PASSWORD_USER,
          password: 'not-the-password-for-this-user',
        })

        expect(status).toBeGreaterThanOrEqual(400)
        expect(json?.error).toBeTruthy()
      })
    },
  )
})
