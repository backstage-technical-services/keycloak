import { describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import { buildTestMatrix, flowsEnabled } from './lib/realm-config.js'

describe.each(buildTestMatrix())('identity providers $realm', ({ realm, config }) => {
  it('has the Google alumni IdP', async () => {
    const kc = await getAuthenticatedAdmin()
    const idp = await kc.identityProviders.findOne({ realm, alias: 'google' })
    expect(idp).toBeDefined()
    expect(idp!.providerId).toBe('google')
    expect(idp!.enabled).not.toBe(false)
    expect(idp!.displayName).toBe('Alumni')
    expect(idp!.trustEmail).toBe(true)
    expect(idp!.config?.hostedDomain).toBe('bath.edu')
    expect(idp!.config?.syncMode).toBe('IMPORT')

    if (flowsEnabled(config)) {
      expect(idp!.firstBrokerLoginFlowAlias).toBe('BTS - First broker login')
      expect(idp!.postBrokerLoginFlowAlias).toBe('BTS - IdP post login')
    }
  })

  it('has the University of Bath CAS IdP', async () => {
    const kc = await getAuthenticatedAdmin()
    const idp = await kc.identityProviders.findOne({ realm, alias: 'cas' })
    expect(idp).toBeDefined()
    expect(idp!.providerId).toBe('cas')
    expect(idp!.enabled).not.toBe(false)
    expect(idp!.displayName).toBe('University of Bath')
    expect(idp!.config?.casServerUrlPrefix).toBe('https://auth.bath.ac.uk')

    if (flowsEnabled(config)) {
      expect(idp!.firstBrokerLoginFlowAlias).toBe('BTS - First CAS login')
      expect(idp!.postBrokerLoginFlowAlias).toBe('BTS - IdP post login')
    }
  })
})
