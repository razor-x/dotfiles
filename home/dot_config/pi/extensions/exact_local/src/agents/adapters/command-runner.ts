import type {
  ExecOptions,
  ExecResult,
  ExtensionAPI,
} from '@earendil-works/pi-coding-agent'

export interface CommandRunner {
  run(
    command: string,
    args: readonly string[],
    options?: ExecOptions,
  ): Promise<ExecResult>
}

export class PiCommandRunner implements CommandRunner {
  private readonly pi: Pick<ExtensionAPI, 'exec'>

  constructor(pi: Pick<ExtensionAPI, 'exec'>) {
    this.pi = pi
  }

  run(
    command: string,
    args: readonly string[],
    options?: ExecOptions,
  ): Promise<ExecResult> {
    return this.pi.exec(command, [...args], options)
  }
}
