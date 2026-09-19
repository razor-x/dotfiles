import { createConnection } from 'node:net'
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { Type } from 'typebox'

const pngSignature = Buffer.from('89504e470d0a1a0a', 'hex')

export async function requestCapture(
  endpoint: string,
  signal?: AbortSignal,
): Promise<Buffer> {
  const deadline = AbortSignal.timeout(15_000)
  const socket = createConnection({
    path: endpoint,
    signal: signal ? AbortSignal.any([signal, deadline]) : deadline,
  })
  const chunks: Buffer[] = []
  let length = 0
  socket.once('connect', () => socket.write('capture\n'))
  try {
    for await (const chunk of socket) {
      const bytes = Buffer.from(chunk)
      length += bytes.length
      if (length > 20 * 1024 * 1024) {
        throw new Error('Capture exceeds 20 MiB')
      }
      chunks.push(bytes)
    }
    const image = Buffer.concat(chunks)
    if (!image.subarray(0, 8).equals(pngSignature)) {
      throw new Error(
        image.toString('utf8', 0, 512) || 'Empty capture response',
      )
    }
    return image
  } finally {
    socket.destroy()
  }
}

export default function captureUi(pi: ExtensionAPI): void {
  pi.registerTool({
    name: 'capture_ui',
    label: 'Capture UI',
    description:
      'Capture the Kitty window selected by the human-launched just capture-pi-ui helper. Returns a fresh PNG (maximum 20 MiB).',
    parameters: Type.Object({}),
    async execute(_id, _params, signal) {
      try {
        const image = await requestCapture(
          `/tmp/pi-capture-ui-${process.getuid?.()}/capture.sock`,
          signal,
        )
        return {
          content: [
            {
              type: 'image',
              data: image.toString('base64'),
              mimeType: 'image/png',
            },
          ],
          details: {},
        }
      } catch (error) {
        throw new Error(
          `Capture failed: ${error instanceof Error ? error.message : String(error)}. Run just capture-pi-ui outside the sandbox and select a dedicated Kitty window showing this session.`,
        )
      }
    },
  })
}
