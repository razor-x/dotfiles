import { homedir } from 'node:os'
import { join, resolve } from 'node:path'

export function defaultAgentsStateRoot(
  environment: NodeJS.ProcessEnv = process.env,
  home: string = homedir(),
): string {
  const configured = environment.XDG_STATE_HOME?.trim()
  const stateHome = configured
    ? resolve(configured)
    : join(home, '.local', 'state')
  return join(stateHome, 'pi-agents')
}
