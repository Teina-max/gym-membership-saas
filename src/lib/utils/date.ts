const APP_TIMEZONE = 'Europe/Paris'

export function toLocalTime(utcDate: string | Date): Date {
  const date = typeof utcDate === 'string' ? new Date(utcDate) : utcDate
  return new Date(date.toLocaleString('en-US', { timeZone: APP_TIMEZONE }))
}

export function formatLocalDate(utcDate: string | Date): string {
  const date = typeof utcDate === 'string' ? new Date(utcDate) : utcDate
  return date.toLocaleDateString('fr-FR', {
    timeZone: APP_TIMEZONE,
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
}

export function formatLocalDateTime(utcDate: string | Date): string {
  const date = typeof utcDate === 'string' ? new Date(utcDate) : utcDate
  return date.toLocaleString('fr-FR', {
    timeZone: APP_TIMEZONE,
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
