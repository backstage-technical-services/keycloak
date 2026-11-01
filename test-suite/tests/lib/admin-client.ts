import KeycloakAdminClient from '@keycloak/keycloak-admin-client'

const baseUrl = (process.env.KEYCLOAK_URL ?? 'http://127.0.0.1:8081').replace(/\/$/, '')

const credentials = {
  grantType: 'client_credentials' as const,
  clientId: 'test',
  clientSecret: 'test',
}

let cached: KeycloakAdminClient | null = null

/**
 * Authenticated admin client (master realm, bootstrap client `test` / `test`).
 * Reused across spec files. Re-authenticates via client_credentials when the JWT
 * expires (no usable refresh token on this grant).
 */
export async function getAuthenticatedAdmin(): Promise<KeycloakAdminClient> {
  if (cached) {
    return cached
  }
  const kc = new KeycloakAdminClient({
    baseUrl,
    realmName: 'master',
  })
  kc.registerTokenProvider({
    getAccessToken: async () => {
      if (kc.accessToken && !kc.isTokenExpired()) {
        return kc.accessToken
      }
      await kc.auth(credentials)
      if (!kc.accessToken) {
        throw new Error('Keycloak admin auth succeeded but no access token was set')
      }
      return kc.accessToken
    },
  })
  cached = kc
  return kc
}
