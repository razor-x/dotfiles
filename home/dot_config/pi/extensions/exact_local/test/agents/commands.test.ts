import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionUIContext,
  RegisteredCommand,
} from '@earendil-works/pi-coding-agent'
import { describe, expect, it, vi } from 'vitest'
import type { AgentsService } from '@/agents/application.ts'
import {
  createProvisioningAction,
  registerAgentsCommand,
} from '@/agents/commands.ts'
import { stub } from '../stub.ts'

const id = '33333333-3333-4333-8333-333333333333'
type CommandOptions = Omit<RegisteredCommand, 'name' | 'sourceInfo'>

describe('/agents', () => {
  it('routes the selected creation action through the application service', async () => {
    const beginPromotion = vi.fn(async () => ({
      id,
      stateFile: `/state/agents/agents/${id}.json`,
      lifecycle: 'provisioning' as const,
    }))
    const service = stub<AgentsService>({ beginPromotion })
    const { handler, registerCommand } = register(service)
    const select = vi.fn(async () => createProvisioningAction)
    const input = vi.fn(async () => ' api-cache ')
    const notify = vi.fn()
    const waitForIdle = vi.fn(async () => undefined)

    await handler('', commandContext({ select, input, notify, waitForIdle }))

    expect(registerCommand).toHaveBeenCalledWith(
      'agents',
      expect.objectContaining({
        description: expect.any(String),
        handler: expect.any(Function),
      }),
    )
    expect(select).toHaveBeenCalledWith('Agents', [createProvisioningAction])
    expect(input).toHaveBeenCalledWith('Agent name')
    expect(waitForIdle).toHaveBeenCalledOnce()
    expect(beginPromotion).toHaveBeenCalledWith({
      cwd: '/repos/example',
      name: 'api-cache',
    })
    expect(notify).toHaveBeenCalledWith(
      expect.stringContaining(`State: /state/agents/agents/${id}.json`),
      'info',
    )
    expect(notify).toHaveBeenCalledWith(
      expect.stringContaining('No branch, worktree, Pi session, Kitty tab'),
      'info',
    )
  })

  it('has no effect when selection is cancelled', async () => {
    const beginPromotion = vi.fn()
    const { handler } = register(stub<AgentsService>({ beginPromotion }))
    const input = vi.fn()
    const waitForIdle = vi.fn()

    await handler(
      '',
      commandContext({
        select: vi.fn(async () => undefined),
        input,
        notify: vi.fn(),
        waitForIdle,
      }),
    )

    expect(input).not.toHaveBeenCalled()
    expect(waitForIdle).not.toHaveBeenCalled()
    expect(beginPromotion).not.toHaveBeenCalled()
  })

  it('shows help and performs no operation for unknown subcommands', async () => {
    const beginPromotion = vi.fn()
    const { handler } = register(stub<AgentsService>({ beginPromotion }))
    const select = vi.fn()
    const notify = vi.fn()

    await handler(
      'delete everything',
      commandContext({
        select,
        input: vi.fn(),
        notify,
        waitForIdle: vi.fn(),
      }),
    )

    expect(select).not.toHaveBeenCalled()
    expect(beginPromotion).not.toHaveBeenCalled()
    expect(notify).toHaveBeenCalledWith(
      expect.stringContaining('Usage:'),
      'warning',
    )
  })
})

function register(agents: AgentsService) {
  let options: CommandOptions | undefined
  const registerCommand = vi.fn((_: string, command: CommandOptions) => {
    options = command
  })
  registerAgentsCommand(
    stub<Pick<ExtensionAPI, 'registerCommand'>>({ registerCommand }),
    agents,
  )
  if (!options) throw new Error('command was not registered')
  return { handler: options.handler, registerCommand }
}

function commandContext(input: {
  select: ExtensionUIContext['select']
  input: ExtensionUIContext['input']
  notify: ExtensionUIContext['notify']
  waitForIdle: ExtensionCommandContext['waitForIdle']
}): ExtensionCommandContext {
  return stub<ExtensionCommandContext>({
    cwd: '/repos/example',
    hasUI: true,
    waitForIdle: input.waitForIdle,
    ui: stub<ExtensionUIContext>({
      select: input.select,
      input: input.input,
      notify: input.notify,
    }),
  })
}
