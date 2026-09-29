#!/usr/bin/env npx tsx

import { generateImage } from '../../../../scripts/api/replicate'
import { optimizePrompt } from '../../../../scripts/utils/prompt-optimizer'

interface GenerateImageInput {
  description: string
  assetType?: 'vehicle' | 'obstacle' | 'prop' | 'general'
  baseImagePath?: string
}

interface GenerateImageOutput {
  imagePath: string
  prompt: string
}

async function main() {
  try {
    // Parse JSON input from command line argument
    const input: GenerateImageInput = JSON.parse(process.argv[2] || '{}')

    if (!input.description) {
      throw new Error('description is required')
    }

    // Optimize the prompt for game assets
    const optimizedPrompt = optimizePrompt({
      description: input.description,
      assetType: input.assetType || 'general',
    })

    console.error(`Optimized prompt: ${optimizedPrompt}`)
    console.error('Calling Replicate API...')

    // Generate the image
    const result = await generateImage({
      prompt: optimizedPrompt,
      aspectRatio: '1:1',
      baseImage: input.baseImagePath,
    })

    // Output JSON result
    const output: GenerateImageOutput = {
      imagePath: result.imageUrl,
      prompt: optimizedPrompt,
    }

    console.log(JSON.stringify(output, null, 2))
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error(JSON.stringify({ error: errorMessage }))
    process.exit(1)
  }
}

main()
