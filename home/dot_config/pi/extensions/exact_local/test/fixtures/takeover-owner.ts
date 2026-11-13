import { appendFileSync } from 'node:fs'
import { startTakeoverService } from '../../src/lib/takeover.ts'

const [directory, sessionFile] = process.argv.slice(2)
const service = await startTakeoverService(directory)
service.bind(
  () => ({ sessionFile, name: 'Child session' }),
  () => {
    // Simulate our shutdown hook finishing before other cleanup has finished.
    service.unbind()
    process.send?.('shutdown')
  },
)
process.on('message', (message) => {
  if (message === 'finish') {
    appendFileSync(sessionFile, 'final cleanup\n')
    process.exit(0)
  }
})
process.send?.('ready')
