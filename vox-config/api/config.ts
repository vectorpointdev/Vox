export const config = { runtime: "edge" };

export default function handler() {
  return Response.json({
    model: process.env.WHISPER_MODEL || "base.en",
    modelRepo: process.env.WHISPER_MODEL_REPO || "argmaxinc/whisperkit-coreml",
  });
}
