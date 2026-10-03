import { describe, expect, it } from 'vitest'
import { computeRunInfo, resolveDay } from './schedule-engine'
import { createDefault2x2Schedule, createDefaultDayTypes, OFF_DAY_TYPE_ID, WORK_DAY_TYPE_ID } from './default-data'
import { createId } from './id'
import { fromISODate, toISODate } from './date-utils'
import type { CyclePosition, DayResolution, DayType, ScheduleException, ScheduleVersion } from '../types'

const dayTypes = createDefaultDayTypes()

function resolve(iso: string, versions: ScheduleVersion[], exceptions: ScheduleException[] = []) {
  return resolveDay(fromISODate(iso), { versions, dayTypes, exceptions })
}

describe('escala 2x2 com domingo como folga fixa fora da contagem', () => {
  // 2024-01-01 é uma segunda-feira (fato de calendário conhecido).
  // 2024-01-03 é, portanto, uma quarta-feira.
  const version = createDefault2x2Schedule({
    referenceDate: '2024-01-03', // quarta-feira = Trabalho (1º dia)
    workStart: '13:00',
    workEnd: '01:00',
  })

  it('resolve corretamente a data de referência como 1º dia de serviço', () => {
    const r = resolve('2024-01-03', [version])
    expect(r.dayType.classification).toBe('WORK')
    expect(r.cycleDayNumber).toBe(1)
    expect(r.cycleDayCount).toBe(2)
  })

  it('segue a sequência SERVIÇO, SERVIÇO, FOLGA, FOLGA a partir da referência', () => {
    const expected: Array<['WORK' | 'REST', number, number]> = [
      ['WORK', 1, 2], // qua 03/01 - serviço dia 1
      ['WORK', 2, 2], // qui 04/01 - serviço dia 2
      ['REST', 1, 2], // sex 05/01 - folga dia 1
      ['REST', 2, 2], // sáb 06/01 - folga dia 2
    ]
    const dates = ['2024-01-03', '2024-01-04', '2024-01-05', '2024-01-06']
    dates.forEach((iso, i) => {
      const r = resolve(iso, [version])
      const [classification, dayNumber, dayCount] = expected[i]
      expect(r.dayType.classification, iso).toBe(classification)
      expect(r.cycleDayNumber, iso).toBe(dayNumber)
      expect(r.cycleDayCount, iso).toBe(dayCount)
    })
  })

  it('domingo é sempre folga fixa, mesmo caindo "no meio" do ciclo', () => {
    const r = resolve('2024-01-07', [version]) // domingo
    expect(r.isFixedDay).toBe(true)
    expect(r.dayType.classification).toBe('REST')
  })

  it('domingo NÃO incrementa/consome o ciclo — segunda continua de onde parou', () => {
    // sáb 06/01 = folga dia 2/2 ; dom 07/01 = folga fixa (fora da contagem);
    // logo seg 08/01 deve retomar o ciclo como serviço dia 1/2.
    const sat = resolve('2024-01-06', [version])
    const mon = resolve('2024-01-08', [version])
    expect(sat.dayType.classification).toBe('REST')
    expect(sat.cycleDayNumber).toBe(2)
    expect(mon.dayType.classification).toBe('WORK')
    expect(mon.cycleDayNumber).toBe(1)
  })

  it('exemplo do prompt: sex FOLGA1/2, sáb FOLGA2/2, dom folga fixa (não conta), seg TRABALHO1/2, ter TRABALHO2/2', () => {
    const fri = resolve('2024-01-05', [version])
    const sat = resolve('2024-01-06', [version])
    const sun = resolve('2024-01-07', [version])
    const mon = resolve('2024-01-08', [version])
    const tue = resolve('2024-01-09', [version])

    expect(fri.dayType.classification).toBe('REST')
    expect(fri.cycleDayNumber).toBe(1)
    expect(sat.dayType.classification).toBe('REST')
    expect(sat.cycleDayNumber).toBe(2)
    expect(sun.isFixedDay).toBe(true)
    expect(mon.dayType.classification).toBe('WORK')
    expect(mon.cycleDayNumber).toBe(1)
    expect(tue.dayType.classification).toBe('WORK')
    expect(tue.cycleDayNumber).toBe(2)
  })

  it('exemplo do prompt: sáb TRABALHO1/2, dom folga fixa (não conta), seg TRABALHO2/2, ter FOLGA1/2', () => {
    // Nova âncora: 2024-01-06 (sábado) = serviço 1º dia.
    const v2 = createDefault2x2Schedule({ referenceDate: '2024-01-06', workStart: '13:00', workEnd: '01:00' })
    const sat = resolve('2024-01-06', [v2])
    const sun = resolve('2024-01-07', [v2])
    const mon = resolve('2024-01-08', [v2])
    const tue = resolve('2024-01-09', [v2])

    expect(sat.dayType.classification).toBe('WORK')
    expect(sat.cycleDayNumber).toBe(1)
    expect(sun.isFixedDay).toBe(true)
    expect(mon.dayType.classification).toBe('WORK')
    expect(mon.cycleDayNumber).toBe(2)
    expect(tue.dayType.classification).toBe('REST')
    expect(tue.cycleDayNumber).toBe(1)
  })

  it('funciona corretamente para datas ANTERIORES à data de referência', () => {
    // 2024-01-02 (terça, dia antes da referência) deveria ser folga dia 2/2
    // (retrocedendo: qua=serv1, então ter=folga2, seg=folga1, dom=fixa, sáb=serv2, sex=serv1 ...)
    const tue = resolve('2024-01-02', [version])
    expect(tue.dayType.classification).toBe('REST')
    expect(tue.cycleDayNumber).toBe(2)

    const mon = resolve('2024-01-01', [version])
    expect(mon.dayType.classification).toBe('REST')
    expect(mon.cycleDayNumber).toBe(1)
  })

  it('mantém a coerência ao longo de virada de semana, mês, ano e ano bissexto', () => {
    // varre 3 anos consecutivos (inclui 2024, bissexto) e garante duas invariantes:
    // 1) todo domingo é folga fixa;
    // 2) removendo os domingos, a sequência remanescente é sempre WORK,WORK,REST,REST repetindo.
    let cursor = fromISODate('2023-06-01')
    const end = fromISODate('2026-06-01')
    const nonSundayClassifications: DayResolution['dayType']['classification'][] = []

    while (cursor <= end) {
      const iso = toISODate(cursor)
      const r = resolve(iso, [version])
      if (cursor.getDay() === 0) {
        expect(r.isFixedDay, iso).toBe(true)
      } else {
        expect(r.isFixedDay, iso).toBe(false)
        nonSundayClassifications.push(r.dayType.classification)
      }
      cursor = new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate() + 1)
    }

    // A fase absoluta depende de onde a varredura começou em relação à âncora,
    // mas a sequência (removidos os domingos) precisa ser periódica de período 4
    // e cada período precisa ser uma rotação válida de [SERVIÇO,SERVIÇO,FOLGA,FOLGA]
    // (nunca alternando dia a dia).
    const validRotations = [
      ['WORK', 'WORK', 'REST', 'REST'],
      ['WORK', 'REST', 'REST', 'WORK'],
      ['REST', 'REST', 'WORK', 'WORK'],
      ['REST', 'WORK', 'WORK', 'REST'],
    ]
    const firstFour = nonSundayClassifications.slice(0, 4)
    expect(validRotations).toContainEqual(firstFour)

    for (let i = 4; i < nonSundayClassifications.length; i++) {
      expect(nonSundayClassifications[i], `posição ${i} vs ${i - 4}`).toBe(
        nonSundayClassifications[i - 4],
      )
    }
  })

  it('respeita 29 de fevereiro em ano bissexto sem quebrar a contagem', () => {
    // 2024 é bissexto. Verifica que 28/02, 29/02 e 01/03 seguem a sequência sem saltos.
    const d28 = resolve('2024-02-28', [version])
    const d29 = resolve('2024-02-29', [version])
    const d01 = resolve('2024-03-01', [version])
    // Nenhuma é domingo neste calendário (28/02/2024=quarta), então devem ser consecutivas no ciclo.
    expect(d28.isFixedDay).toBe(false)
    expect(d29.isFixedDay).toBe(false)
    expect(d01.isFixedDay).toBe(false)
  })

  it('exceção pontual sobrepõe a regra do ciclo e preserva o tipo original', () => {
    const exception: ScheduleException = {
      id: createId(),
      date: '2024-01-03', // normalmente seria SERVIÇO 1/2
      dayTypeId: OFF_DAY_TYPE_ID,
      reason: 'Troca de plantão',
      originalDayTypeId: WORK_DAY_TYPE_ID,
    }
    const r = resolve('2024-01-03', [version], [exception])
    expect(r.isException).toBe(true)
    expect(r.dayType.classification).toBe('REST')
  })
})

describe('dias fixos customizáveis (não limitados a domingo)', () => {
  it('permite configurar outro dia da semana como fixo fora do ciclo', () => {
    const version = createDefault2x2Schedule({ referenceDate: '2024-01-03', workStart: '13:00', workEnd: '01:00' })
    // habilita também sábado como fixo (além de domingo)
    version.fixedDayRules = version.fixedDayRules.map((r) =>
      r.weekday === 6 ? { ...r, enabled: true } : r,
    )
    const sat = resolve('2024-01-06', [version])
    expect(sat.isFixedDay).toBe(true)
  })
})

describe('versões de escala com vigência (alteração futura não afeta o histórico)', () => {
  it('usa a regra antiga antes de effectiveFrom e a nova a partir dela', () => {
    const oldVersion = createDefault2x2Schedule({ referenceDate: '2024-01-03', workStart: '13:00', workEnd: '01:00' })
    const newVersion: ScheduleVersion = {
      ...createDefault2x2Schedule({ referenceDate: '2024-10-01', workStart: '07:00', workEnd: '19:00' }),
      effectiveFrom: '2024-10-01',
    }

    const beforeChange = resolve('2024-09-30', [oldVersion, newVersion])
    const afterChange = resolve('2024-10-01', [oldVersion, newVersion])

    expect(beforeChange.startTime).toBe('13:00')
    expect(afterChange.startTime).toBe('07:00')
  })
})

describe('computeRunInfo — agrupamento de posições contíguas do ciclo (inclui wraparound)', () => {
  it('mescla o fim e o início do ciclo quando compartilham o mesmo tipo de dia', () => {
    const workId = 'w'
    const restId = 'r'
    const positions: CyclePosition[] = [
      { id: '1', order: 1, dayTypeId: restId }, // FOLGA A
      { id: '2', order: 2, dayTypeId: workId },
      { id: '3', order: 3, dayTypeId: workId },
      { id: '4', order: 4, dayTypeId: restId }, // FOLGA B (adjacente à FOLGA A via wraparound)
    ]
    expect(computeRunInfo(positions, 3)).toEqual({ dayNumber: 1, dayCount: 2 }) // FOLGA B = dia 1 de 2
    expect(computeRunInfo(positions, 0)).toEqual({ dayNumber: 2, dayCount: 2 }) // FOLGA A = dia 2 de 2
    expect(computeRunInfo(positions, 1)).toEqual({ dayNumber: 1, dayCount: 2 })
    expect(computeRunInfo(positions, 2)).toEqual({ dayNumber: 2, dayCount: 2 })
  })
})

describe('ciclo totalmente personalizado (nomes, horários e tipos por posição)', () => {
  it('permite posições de trabalho com nomes e horários distintos (ex.: diurno/noturno)', () => {
    const dt: DayType[] = [
      { id: 'w', displayName: 'TRABALHO', classification: 'WORK', color: 'work', icon: 'Briefcase' },
      { id: 'r', displayName: 'DESCANSO', classification: 'REST', color: 'off', icon: 'Leaf' },
    ]
    const version: ScheduleVersion = {
      id: 'v1',
      name: 'Personalizada',
      effectiveFrom: '2024-01-03',
      referenceDate: '2024-01-03',
      referencePositionIndex: 0,
      cyclePositions: [
        { id: 'p1', order: 1, dayTypeId: 'w', nameOverride: 'DIURNO', startTime: '07:00', endTime: '19:00' },
        { id: 'p2', order: 2, dayTypeId: 'w', nameOverride: 'NOTURNO', startTime: '19:00', endTime: '07:00', crossesMidnight: true },
        { id: 'p3', order: 3, dayTypeId: 'r' },
        { id: 'p4', order: 4, dayTypeId: 'r' },
      ],
      fixedDayRules: [
        { weekday: 0, enabled: true, dayTypeId: 'r' },
        { weekday: 1, enabled: false, dayTypeId: 'r' },
        { weekday: 2, enabled: false, dayTypeId: 'r' },
        { weekday: 3, enabled: false, dayTypeId: 'r' },
        { weekday: 4, enabled: false, dayTypeId: 'r' },
        { weekday: 5, enabled: false, dayTypeId: 'r' },
        { weekday: 6, enabled: false, dayTypeId: 'r' },
      ],
    }
    const r = resolveDay(fromISODate('2024-01-03'), { versions: [version], dayTypes: dt, exceptions: [] })
    expect(r.label).toBe('DIURNO')
    const r2 = resolveDay(fromISODate('2024-01-04'), { versions: [version], dayTypes: dt, exceptions: [] })
    expect(r2.label).toBe('NOTURNO')
    expect(r2.crossesMidnight).toBe(true)
  })
})
