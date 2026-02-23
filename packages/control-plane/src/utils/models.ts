/**
 * Model validation and extraction utilities.
 *
 * Re-exports from @wrench/shared for backward compatibility.
 */

export {
  VALID_MODELS,
  type ValidModel,
  DEFAULT_MODEL,
  type ReasoningEffort,
  type ModelReasoningConfig,
  MODEL_REASONING_CONFIG,
  normalizeModelId,
  isValidModel,
  extractProviderAndModel,
  getValidModelOrDefault,
  supportsReasoning,
  getReasoningConfig,
  getDefaultReasoningEffort,
  isValidReasoningEffort,
} from "@wrench/shared";
