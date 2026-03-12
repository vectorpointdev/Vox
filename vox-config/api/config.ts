import type { VercelRequest, VercelResponse } from "@vercel/node";

export default function handler(_req: VercelRequest, res: VercelResponse) {
  res.json({
    model: process.env.WHISPER_MODEL || "base.en",
    modelRepo:
      process.env.WHISPER_MODEL_REPO || "argmaxinc/whisperkit-coreml",
  });
}
