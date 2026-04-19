const QR_PREFIX = 'GYM'

export function generateQrPayload(memberId: string, token: string, expiresAt: number): string {
  return `${QR_PREFIX}:${memberId}:${token}:${expiresAt}`
}

export function parseQrPayload(payload: string): {
  memberId: string
  token: string
  expiresAt: number
} | null {
  const parts = payload.split(':')
  if (parts.length !== 4 || parts[0] !== QR_PREFIX) return null

  return {
    memberId: parts[1],
    token: parts[2],
    expiresAt: Number(parts[3]),
  }
}
