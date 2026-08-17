import { randomUUID } from 'node:crypto'
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import {
  AgentsApplication,
  type AgentsApplicationPorts,
  type AgentsService,
} from './application.ts'
import { PiCommandRunner } from './adapters/command-runner.ts'
import { GitRepositoryResolver } from './adapters/git-repository.ts'
import { registerAgentsCommand } from './commands.ts'
import { defaultAgentsStateRoot } from './config.ts'
import { FileAgentStore } from './state-store.ts'

export function registerAgents(
  pi: Pick<ExtensionAPI, 'registerCommand'>,
  services: AgentsService,
): void {
  registerAgentsCommand(pi, services)
}

export function createProductionAgentsService(
  pi: Pick<ExtensionAPI, 'exec'>,
  stateRoot = defaultAgentsStateRoot(),
): AgentsService {
  const ports: AgentsApplicationPorts = {
    agents: new FileAgentStore(stateRoot),
    repositories: new GitRepositoryResolver(new PiCommandRunner(pi)),
    clock: { now: () => new Date() },
    ids: { generate: () => randomUUID() },
  }
  return new AgentsApplication(ports)
}

export default function agentsExtension(pi: ExtensionAPI): void {
  registerAgents(pi, createProductionAgentsService(pi))
}
