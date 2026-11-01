import { describe, expect, it } from 'vitest'

import { getAuthenticatedAdmin } from './lib/admin-client.js'
import { buildTestMatrix } from './lib/realm-config.js'

const expectedSmtpHost = process.env.KEYCLOAK_EXPECT_SMTP_HOST ?? 'mail'
const expectedSmtpPort = process.env.KEYCLOAK_EXPECT_SMTP_PORT ?? '25'
const expectedSmtpStartTls = process.env.KEYCLOAK_EXPECT_SMTP_STARTTLS === 'true'

describe.each(buildTestMatrix())('SMTP $realm', ({ realm }) => {
  it('uses SMTP settings from Terraform', async () => {
    const kc = await getAuthenticatedAdmin()
    const rep = await kc.realms.findOne({ realm })
    const smtp = rep?.smtpServer as Record<string, unknown> | undefined
    expect(smtp).toBeDefined()
    expect(smtp!.host).toBe(expectedSmtpHost)
    expect(String(smtp!.port)).toBe(expectedSmtpPort)
    expect(smtp!.from).toBe('no-reply@bts-crew.com')
    expect(smtp!.fromDisplayName).toBe('Backstage Auth')
    expect(smtp!.replyTo).toBe('sec@bts-crew.com')
    expect(smtp!.replyToDisplayName).toBe('Backstage Secretary')
    const startTlsRaw = smtp!.startTls ?? smtp!.starttls ?? smtp!.startTLS ?? smtp!.enableTls
    const startTlsOn = startTlsRaw === true || startTlsRaw === 'true' || startTlsRaw === 'True'
    expect(startTlsOn).toBe(expectedSmtpStartTls)
  })
})
