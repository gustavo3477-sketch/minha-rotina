const HEX_PATTERN = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i

export function isHexColor(value: string): boolean {
  return HEX_PATTERN.test(value)
}

function normalizeHex(hex: string): string {
  const h = hex.replace('#', '')
  return h.length === 3
    ? h
        .split('')
        .map((c) => c + c)
        .join('')
    : h
}

export function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const h = normalizeHex(hex)
  const num = parseInt(h, 16)
  return { r: (num >> 16) & 255, g: (num >> 8) & 255, b: num & 255 }
}

/** Cores de tokens antigos (pré-personalização), mantidas para compatibilidade
 * com dados já salvos que ainda referenciam nomes de token em vez de hex. */
const LEGACY_TOKEN_HEX: Record<string, string> = {
  work: '#ef5b57',
  off: '#22c55e',
  extra: '#f97316',
  appointment: '#3b82f6',
  special: '#a855f7',
  primary: '#3b82f6',
}

export function toHex(color: string): string {
  if (isHexColor(color)) return `#${normalizeHex(color)}`
  return LEGACY_TOKEN_HEX[color] ?? '#3b82f6'
}

/** Luminância relativa (WCAG) para decidir texto branco ou escuro sobre uma cor de fundo. */
export function getContrastTextColor(color: string): string {
  const { r, g, b } = hexToRgb(toHex(color))
  const [rl, gl, bl] = [r, g, b].map((c) => {
    const cs = c / 255
    return cs <= 0.03928 ? cs / 12.92 : Math.pow((cs + 0.055) / 1.055, 2.4)
  })
  const luminance = 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
  return luminance > 0.55 ? '#111827' : '#ffffff'
}

export interface ResolvedDayColor {
  background: string
  text: string
}

export function resolveDayColor(color: string): ResolvedDayColor {
  const hex = toHex(color)
  return { background: hex, text: getContrastTextColor(hex) }
}

export interface PresetColor {
  name: string
  hex: string
}

export const QUICK_COLOR_PALETTE: PresetColor[] = [
  { name: 'Vermelho', hex: '#ef4444' },
  { name: 'Verde', hex: '#22c55e' },
  { name: 'Azul', hex: '#3b82f6' },
  { name: 'Laranja', hex: '#f97316' },
  { name: 'Amarelo', hex: '#eab308' },
  { name: 'Roxo', hex: '#a855f7' },
  { name: 'Rosa', hex: '#ec4899' },
  { name: 'Cinza', hex: '#6b7280' },
  { name: 'Ciano', hex: '#06b6d4' },
]
