import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

const setPi = '\x1b]1337;SetUserVar=IS_PI=MQ==\x07'
const clearPi = '\x1b]1337;SetUserVar=IS_PI\x07'

export default function kitty(pi: ExtensionAPI): void {
  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode === 'tui') process.stdout.write(setPi)
  })
  pi.on('session_shutdown', (_event, ctx) => {
    if (ctx.mode === 'tui') process.stdout.write(clearPi)
  })
}
