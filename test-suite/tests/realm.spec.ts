import { describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import { buildTestMatrix, durationToSeconds, flowsEnabled } from './lib/realm-config.js'

describe.each(buildTestMatrix())('realm $realm', ({ realm, config }) => {
  it('has expected realm settings', async () => {
    const kc = await getAuthenticatedAdmin()
    const rep = await kc.realms.findOne({ realm })
    expect(rep).toBeDefined()
    expect(rep!.realm).toBe(realm)
    expect(rep!.displayName).toBe(config['display-name'])
    expect(rep!.enabled).not.toBe(false)
    expect(rep!.loginTheme).toBe('bts-keycloak-theme')
    expect(rep!.registrationAllowed).toBe(false)
    expect(rep!.resetPasswordAllowed).toBe(true)
    expect(rep!.rememberMe).toBe(true)
    expect(rep!.verifyEmail).toBe(true)
    expect(rep!.loginWithEmailAllowed).toBe(true)
    expect(rep!.duplicateEmailsAllowed).toBe(false)
    expect(rep!.sslRequired).toBe(process.env.KEYCLOAK_EXPECT_SSL_REQUIRED ?? 'none')
    expect(rep!.passwordPolicy).toContain('length(5)')
    expect(rep!.accessTokenLifespan).toBe(durationToSeconds(config.tokens['access-lifespan']))

    if (flowsEnabled(config)) {
      expect(rep!.browserFlow).toBe('BTS - Browser')
    }
  })

  it('records user and admin events', async () => {
    const kc = await getAuthenticatedAdmin()
    const events = await kc.realms.getConfigEvents({ realm })
    expect(events.eventsEnabled).toBe(true)
    expect(events.adminEventsEnabled).toBe(true)
    expect(events.adminEventsDetailsEnabled).toBe(true)
    expect([...(events.eventsListeners ?? [])].sort()).toEqual(['jboss-logging', 'metrics-listener'])
  })
})
