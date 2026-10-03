export type ColorToken =
  | 'work'
  | 'off'
  | 'extra'
  | 'appointment'
  | 'special'
  | 'primary'
  | 'success'
  | 'warning'
  | 'danger'

interface TokenClasses {
  text: string
  bg: string
  bgSoft: string
  border: string
}

const TOKEN_CLASSES: Record<ColorToken, TokenClasses> = {
  work: { text: 'text-work', bg: 'bg-work', bgSoft: 'bg-work/15', border: 'border-work' },
  off: { text: 'text-off', bg: 'bg-off', bgSoft: 'bg-off/15', border: 'border-off' },
  extra: { text: 'text-extra', bg: 'bg-extra', bgSoft: 'bg-extra/15', border: 'border-extra' },
  appointment: {
    text: 'text-appointment',
    bg: 'bg-appointment',
    bgSoft: 'bg-appointment/15',
    border: 'border-appointment',
  },
  special: {
    text: 'text-special',
    bg: 'bg-special',
    bgSoft: 'bg-special/15',
    border: 'border-special',
  },
  primary: {
    text: 'text-primary',
    bg: 'bg-primary',
    bgSoft: 'bg-primary/15',
    border: 'border-primary',
  },
  success: {
    text: 'text-success',
    bg: 'bg-success',
    bgSoft: 'bg-success/15',
    border: 'border-success',
  },
  warning: {
    text: 'text-warning',
    bg: 'bg-warning',
    bgSoft: 'bg-warning/15',
    border: 'border-warning',
  },
  danger: { text: 'text-danger', bg: 'bg-danger', bgSoft: 'bg-danger/15', border: 'border-danger' },
}

export function getTokenClasses(token: string): TokenClasses {
  return TOKEN_CLASSES[token as ColorToken] ?? TOKEN_CLASSES.primary
}

export function isKnownToken(token: string): token is ColorToken {
  return token in TOKEN_CLASSES
}
