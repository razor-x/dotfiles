import { createProvisioningRecord } from './domain.ts'
import type { RepositoryResolver } from './adapters/git-repository.ts'
import type { AgentStore } from './state-store.ts'

export interface Clock {
  now(): Date
}

export interface IdGenerator {
  generate(): string
}

export type BeginPromotionInput = {
  cwd: string
  name: string
  signal?: AbortSignal
}

export type BeginPromotionResult = {
  id: string
  stateFile: string
  lifecycle: 'provisioning'
}

export interface AgentsService {
  beginPromotion(input: BeginPromotionInput): Promise<BeginPromotionResult>
}

export type AgentsApplicationPorts = {
  agents: AgentStore
  repositories: RepositoryResolver
  clock: Clock
  ids: IdGenerator
}

export class AgentsApplication implements AgentsService {
  private readonly ports: AgentsApplicationPorts

  constructor(ports: AgentsApplicationPorts) {
    this.ports = ports
  }

  async beginPromotion(
    input: BeginPromotionInput,
  ): Promise<BeginPromotionResult> {
    const repository = await this.ports.repositories.resolvePrimary(
      input.cwd,
      input.signal,
    )
    const record = createProvisioningRecord({
      id: this.ports.ids.generate(),
      name: input.name,
      repository,
      now: this.ports.clock.now().toISOString(),
    })
    const stateFile = await this.ports.agents.create(record)

    return {
      id: record.id,
      stateFile,
      lifecycle: 'provisioning',
    }
  }
}
