const baseUrl = (process.env.KEYCLOAK_URL ?? 'http://127.0.0.1:8081').replace(/\/$/, '')

export function getKeycloakBaseUrl(): string {
  return baseUrl
}

export function tokenEndpoint(realm: string): string {
  return `${baseUrl}/realms/${encodeURIComponent(realm)}/protocol/openid-connect/token`
}

export function wellKnownUrl(realm: string): string {
  return `${baseUrl}/realms/${encodeURIComponent(realm)}/.well-known/openid-configuration`
}

export async function postForm(url: string, fields: Record<string, string>): Promise<{
  status: number
  json: Record<string, unknown> | null
  text: string
}> {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(fields),
  })
  const text = await res.text()
  let json: Record<string, unknown> | null = null
  try {
    json = JSON.parse(text) as Record<string, unknown>
  } catch {}
  return { status: res.status, json, text }
}
